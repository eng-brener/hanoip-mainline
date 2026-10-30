#!/usr/bin/python3
"""Testes da política do hanoip-fp-guard (sem aparelho, sem root)."""
import importlib.machinery
import importlib.util
import os
import types
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
_loader = importlib.machinery.SourceFileLoader(
    "guard", os.path.join(HERE, "hanoip-fp-guard"))
_spec = importlib.util.spec_from_loader("guard", _loader)
g = importlib.util.module_from_spec(_spec)
_loader.exec_module(g)

H = 3600


class FakeSys:
    UNLOCK_FLAG = "/etc/hanoip-fp/unlock-enabled"

    def __init__(self):
        self.saved = None
        self.files = set()
        self.os = types.SimpleNamespace(
            path=types.SimpleNamespace(exists=lambda p: p in self.files),
            unlink=self.files.discard)

    def load(self):
        return g.Policy(self.saved)

    def save(self, p):
        self.saved = p.to_dict()

    def enabled(self, flag):
        return flag in self.files


class PolicyTest(unittest.TestCase):
    def test_boot_needs_pin(self):
        self.assertEqual(g.Policy().reason(0), "precisa do PIN depois do boot")

    def test_credential_allows(self):
        p = g.Policy()
        p.credential(100)
        self.assertIsNone(p.reason(101))

    def test_72h_timeout(self):
        p = g.Policy()
        p.credential(0)
        self.assertIsNone(p.reason(72 * H))
        self.assertEqual(p.reason(72 * H + 1), "72 h sem PIN")

    def test_five_failures_lock_30s(self):
        p = g.Policy()
        p.credential(0)
        for _ in range(4):
            p.failure(10)
        self.assertIsNone(p.reason(10))
        p.failure(10)
        self.assertIn("bloqueado", p.reason(10))
        self.assertIn("bloqueado", p.reason(39.5))
        self.assertIsNone(p.reason(40))

    def test_success_resets_counter(self):
        p = g.Policy()
        p.credential(0)
        for _ in range(4):
            p.failure(1)
        p.success()
        p.failure(2)
        self.assertIsNone(p.reason(2))
        self.assertEqual(p.fails, 1)

    def test_twenty_failures_need_pin(self):
        p = g.Policy()
        p.credential(0)
        t = 0
        for _ in range(20):
            t += 31		# espera cada bloqueio de 30 s passar
            p.failure(t)
        self.assertEqual(p.reason(t + 10 * H), "muitos erros: só com PIN")
        p.credential(t + 10 * H)
        self.assertIsNone(p.reason(t + 10 * H))

    def test_lockdown_until_pin(self):
        p = g.Policy()
        p.credential(0)
        p.lockdown = True
        self.assertEqual(p.reason(1), "lockdown")
        p.credential(2)
        self.assertIsNone(p.reason(3))

    def test_roundtrip(self):
        p = g.Policy()
        p.credential(5)
        p.failure(6)
        q = g.Policy(p.to_dict())
        self.assertEqual(q.to_dict(), p.to_dict())


class GuardTest(unittest.TestCase):
    def setUp(self):
        self.s = FakeSys()
        self.g = g.Guard(self.s)

    def test_new_unlocked_session_is_login(self):
        self.g.observe("c2", 1000, False, 50)
        self.assertIsNone(self.g.p.reason(51))
        self.assertEqual(self.s.saved["sid"], "c2")

    def test_new_locked_session_is_not_credential(self):
        self.g.observe("c2", 1000, True, 50)
        self.assertIsNotNone(self.g.p.reason(51))

    def test_pin_unlock_detected(self):
        self.g.observe("c2", 1000, False, 0)
        self.g.p.lockdown = True
        self.g.observe("c2", 1000, True, 100)
        self.g.observe("c2", 1000, False, 200)	# não fomos nós
        self.assertFalse(self.g.p.lockdown)
        self.assertEqual(self.g.p.cred_at, 200)

    def test_our_unlock_is_not_credential(self):
        self.g.observe("c2", 1000, False, 0)
        self.g.observe("c2", 1000, True, 100)
        self.g.our_unlock = 200
        self.g.observe("c2", 1000, False, 201)
        self.assertEqual(self.g.p.cred_at, 0)

    def test_restart_keeps_state(self):
        self.g.observe("c2", 1000, False, 0)
        for _ in range(5):
            self.g.verdict("Verify result: verify-no-match (done)", 10)
        g2 = g.Guard(self.s)			# serviço reiniciado
        g2.observe("c2", 1000, True, 11)	# mesma sessão: nada muda
        self.assertIn("bloqueado", g2.p.reason(11))
        self.assertEqual(g2.p.cred_at, 0)

    def test_verdicts(self):
        self.g.observe("c2", 1000, False, 0)
        self.assertTrue(self.g.verdict("Verify result: verify-match (done)", 1))
        self.assertFalse(self.g.verdict("Verify result: verify-no-match (done)", 2))
        self.assertEqual(self.g.p.fails, 1)
        self.assertFalse(self.g.verdict("Verify result: verify-retry-scan", 3))
        self.assertEqual(self.g.p.fails, 1)	# repetir não conta como erro

    def test_unlock_switch(self):
        self.assertFalse(self.g.unlock_enabled())
        self.s.files.add(FakeSys.UNLOCK_FLAG)
        self.assertTrue(self.g.unlock_enabled())

    def test_status_has_no_secrets(self):
        p = g.Policy()
        p.credential(0)
        d = g.status_dict(p, 1)
        self.assertEqual(set(d), {"unlock", "sudo", "reason", "fails", "lockdown"})

    def test_lockdown_request_file(self):
        self.g.observe("c2", 1000, False, 0)
        self.s.files.add("/run/user/1000/hanoip-fp-lockdown")
        self.g.observe("c2", 1000, True, 5)
        self.assertEqual(self.g.p.reason(6), "lockdown")
        self.assertFalse(self.s.files)


if __name__ == "__main__":
    unittest.main()
