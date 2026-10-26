savedcmd_qcom-spmi-sdam.o := aarch64-linux-gnu-gcc -Wp,-MMD,./.qcom-spmi-sdam.o.d -nostdinc -I/tmp/kernel-mainline/arch/arm64/include -I/tmp/kernel-mainline/arch/arm64/include/generated -I/tmp/kernel-mainline/include -I/tmp/kernel-mainline/include -I/tmp/kernel-mainline/arch/arm64/include/uapi -I/tmp/kernel-mainline/arch/arm64/include/generated/uapi -I/tmp/kernel-mainline/include/uapi -I/tmp/kernel-mainline/include/generated/uapi -include /tmp/kernel-mainline/include/linux/compiler-version.h -include /tmp/kernel-mainline/include/linux/kconfig.h -include /tmp/kernel-mainline/include/linux/compiler_types.h -D__KERNEL__ -mlittle-endian -DCC_USING_PATCHABLE_FUNCTION_ENTRY -DKASAN_SHADOW_SCALE_SHIFT= -fshort-wchar -funsigned-char -fno-common -fno-PIE -fno-strict-aliasing -std=gnu11 -fms-extensions -mgeneral-regs-only -DCONFIG_CC_HAS_K_CONSTRAINT=1 -Wno-psabi -mabi=lp64 -fno-asynchronous-unwind-tables -fno-unwind-tables -mbranch-protection=none -Wa,-march=armv8.5-a -DARM64_ASM_ARCH='"armv8.5-a"' -ffixed-x18 -DKASAN_SHADOW_SCALE_SHIFT= -fno-delete-null-pointer-checks -O2 -fno-allow-store-data-races -fstack-protector-strong -fno-omit-frame-pointer -fno-optimize-sibling-calls -ftrivial-auto-var-init=zero -fno-stack-clash-protection -fpatchable-function-entry=4,2 -fsanitize=shadow-call-stack -falign-functions=8 -fstrict-flex-arrays=3 -fno-strict-overflow -fno-stack-check -fconserve-stack -fno-builtin-wcslen -Wall -Wextra -Wundef -Werror=implicit-function-declaration -Werror=implicit-int -Werror=return-type -Werror=strict-prototypes -Wno-format-security -Wno-trigraphs -Wno-frame-address -Wno-address-of-packed-member -Wmissing-declarations -Wmissing-prototypes -Wframe-larger-than=2048 -Wno-main -Wno-type-limits -Wno-dangling-pointer -Wvla-larger-than=1 -Wno-pointer-sign -Wcast-function-type -Wno-array-bounds -Wno-stringop-overflow -Wno-alloc-size-larger-than -Wimplicit-fallthrough=5 -Werror=date-time -Werror=incompatible-pointer-types -Werror=designated-init -Wenum-conversion -Wunused -Wno-unused-but-set-variable -Wno-unused-const-variable -Wno-packed-not-aligned -Wno-format-overflow -Wno-format-truncation -Wno-stringop-truncation -Wno-override-init -Wno-missing-field-initializers -Wno-shift-negative-value -Wno-maybe-uninitialized -Wno-sign-compare -Wno-unused-parameter -g -fno-var-tracking -femit-struct-debug-baseonly -mstack-protector-guard=sysreg -mstack-protector-guard-reg=sp_el0 -mstack-protector-guard-offset=1344  -DMODULE  -DKBUILD_BASENAME='"qcom_spmi_sdam"' -DKBUILD_MODNAME='"qcom_spmi_sdam"' -D__KBUILD_MODNAME=qcom_spmi_sdam -c -o qcom-spmi-sdam.o qcom-spmi-sdam.c  

source_qcom-spmi-sdam.o := qcom-spmi-sdam.c

deps_qcom-spmi-sdam.o := \
  /tmp/kernel-mainline/include/linux/compiler-version.h \
    $(wildcard include/config/CC_VERSION_TEXT) \
  /tmp/kernel-mainline/include/linux/kconfig.h \
    $(wildcard include/config/CPU_BIG_ENDIAN) \
    $(wildcard include/config/BOOGER) \
    $(wildcard include/config/FOO) \
  /tmp/kernel-mainline/include/linux/compiler_types.h \
    $(wildcard include/config/DEBUG_INFO_BTF) \
    $(wildcard include/config/PAHOLE_HAS_BTF_TAG) \
    $(wildcard include/config/FUNCTION_ALIGNMENT) \
    $(wildcard include/config/CC_HAS_SANE_FUNCTION_ALIGNMENT) \
    $(wildcard include/config/X86_64) \
    $(wildcard include/config/ARM64) \
    $(wildcard include/config/LD_DEAD_CODE_DATA_ELIMINATION) \
    $(wildcard include/config/LTO_CLANG) \
    $(wildcard include/config/HAVE_ARCH_COMPILER_H) \
    $(wildcard include/config/KCSAN) \
    $(wildcard include/config/CC_HAS_ASSUME) \
    $(wildcard include/config/CC_HAS_COUNTED_BY) \
    $(wildcard include/config/FORTIFY_SOURCE) \
    $(wildcard include/config/UBSAN_BOUNDS) \
    $(wildcard include/config/CC_HAS_COUNTED_BY_PTR) \
    $(wildcard include/config/CC_HAS_MULTIDIMENSIONAL_NONSTRING) \
    $(wildcard include/config/CFI) \
    $(wildcard include/config/ARCH_USES_CFI_GENERIC_LLVM_PASS) \
    $(wildcard include/config/CC_HAS_BROKEN_COUNTED_BY_REF) \
    $(wildcard include/config/CC_HAS_ASM_INLINE) \
  /tmp/kernel-mainline/include/linux/compiler-context-analysis.h \
  /tmp/kernel-mainline/include/linux/compiler_attributes.h \
  /tmp/kernel-mainline/include/linux/compiler-gcc.h \
    $(wildcard include/config/ARCH_USE_BUILTIN_BSWAP) \
    $(wildcard include/config/SHADOW_CALL_STACK) \
    $(wildcard include/config/KCOV) \
    $(wildcard include/config/CC_HAS_TYPEOF_UNQUAL) \
  /tmp/kernel-mainline/arch/arm64/include/asm/compiler.h \
    $(wildcard include/config/ARM64_PTR_AUTH_KERNEL) \
    $(wildcard include/config/ARM64_PTR_AUTH) \
    $(wildcard include/config/BUILTIN_RETURN_ADDRESS_STRIPS_PAC) \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/percpu_types.h \
  /tmp/kernel-mainline/include/asm-generic/percpu_types.h \
  /tmp/kernel-mainline/include/linux/device.h \
    $(wildcard include/config/DEBUG_LOCK_ALLOC) \
    $(wildcard include/config/GENERIC_MSI_IRQ) \
    $(wildcard include/config/ENERGY_MODEL) \
    $(wildcard include/config/PINCTRL) \
    $(wildcard include/config/ARCH_HAS_DMA_OPS) \
    $(wildcard include/config/DMA_DECLARE_COHERENT) \
    $(wildcard include/config/DMA_CMA) \
    $(wildcard include/config/SWIOTLB) \
    $(wildcard include/config/SWIOTLB_DYNAMIC) \
    $(wildcard include/config/NUMA) \
    $(wildcard include/config/PM) \
    $(wildcard include/config/PM_SLEEP) \
    $(wildcard include/config/LOCKDEP) \
    $(wildcard include/config/OF) \
    $(wildcard include/config/DEVTMPFS) \
  /tmp/kernel-mainline/include/linux/dev_printk.h \
    $(wildcard include/config/PRINTK) \
    $(wildcard include/config/DYNAMIC_DEBUG) \
    $(wildcard include/config/DYNAMIC_DEBUG_CORE) \
  /tmp/kernel-mainline/include/linux/compiler.h \
    $(wildcard include/config/TRACE_BRANCH_PROFILING) \
    $(wildcard include/config/PROFILE_ALL_BRANCHES) \
    $(wildcard include/config/OBJTOOL) \
  /tmp/kernel-mainline/arch/arm64/include/asm/rwonce.h \
    $(wildcard include/config/LTO) \
  /tmp/kernel-mainline/include/asm-generic/rwonce.h \
  /tmp/kernel-mainline/include/linux/kasan-checks.h \
    $(wildcard include/config/KASAN_GENERIC) \
    $(wildcard include/config/KASAN_SW_TAGS) \
  /tmp/kernel-mainline/include/linux/types.h \
    $(wildcard include/config/HAVE_UID16) \
    $(wildcard include/config/UID16) \
    $(wildcard include/config/ARCH_DMA_ADDR_T_64BIT) \
    $(wildcard include/config/PHYS_ADDR_T_64BIT) \
    $(wildcard include/config/64BIT) \
    $(wildcard include/config/ARCH_32BIT_USTAT_F_TINODE) \
  /tmp/kernel-mainline/include/uapi/linux/types.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/uapi/asm/types.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/types.h \
  /tmp/kernel-mainline/include/asm-generic/int-ll64.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/int-ll64.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/bitsperlong.h \
  /tmp/kernel-mainline/include/asm-generic/bitsperlong.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/bitsperlong.h \
  /tmp/kernel-mainline/include/uapi/linux/posix_types.h \
  /tmp/kernel-mainline/include/linux/stddef.h \
  /tmp/kernel-mainline/include/uapi/linux/stddef.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/posix_types.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/posix_types.h \
  /tmp/kernel-mainline/include/linux/kcsan-checks.h \
    $(wildcard include/config/KCSAN_WEAK_MEMORY) \
    $(wildcard include/config/KCSAN_IGNORE_ATOMICS) \
  /tmp/kernel-mainline/include/linux/ratelimit.h \
  /tmp/kernel-mainline/include/linux/ratelimit_types.h \
  /tmp/kernel-mainline/include/linux/bits.h \
  /tmp/kernel-mainline/include/vdso/bits.h \
  /tmp/kernel-mainline/include/vdso/const.h \
  /tmp/kernel-mainline/include/uapi/linux/const.h \
  /tmp/kernel-mainline/include/uapi/linux/bits.h \
  /tmp/kernel-mainline/include/linux/build_bug.h \
  /tmp/kernel-mainline/include/linux/overflow.h \
  /tmp/kernel-mainline/include/linux/limits.h \
  /tmp/kernel-mainline/include/uapi/linux/limits.h \
  /tmp/kernel-mainline/include/vdso/limits.h \
  /tmp/kernel-mainline/include/linux/const.h \
  /tmp/kernel-mainline/include/uapi/linux/param.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/param.h \
  /tmp/kernel-mainline/include/asm-generic/param.h \
    $(wildcard include/config/HZ) \
  /tmp/kernel-mainline/include/uapi/asm-generic/param.h \
  /tmp/kernel-mainline/include/linux/spinlock_types_raw.h \
    $(wildcard include/config/SMP) \
    $(wildcard include/config/DEBUG_SPINLOCK) \
  /tmp/kernel-mainline/arch/arm64/include/asm/spinlock_types.h \
  /tmp/kernel-mainline/include/asm-generic/qspinlock_types.h \
    $(wildcard include/config/NR_CPUS) \
  /tmp/kernel-mainline/include/asm-generic/qrwlock_types.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/byteorder.h \
  /tmp/kernel-mainline/include/linux/byteorder/little_endian.h \
  /tmp/kernel-mainline/include/uapi/linux/byteorder/little_endian.h \
  /tmp/kernel-mainline/include/linux/swab.h \
  /tmp/kernel-mainline/include/uapi/linux/swab.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/uapi/asm/swab.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/swab.h \
  /tmp/kernel-mainline/include/linux/byteorder/generic.h \
  /tmp/kernel-mainline/include/linux/lockdep_types.h \
    $(wildcard include/config/PROVE_RAW_LOCK_NESTING) \
    $(wildcard include/config/LOCK_STAT) \
  /tmp/kernel-mainline/include/linux/sched.h \
    $(wildcard include/config/DEBUG_ATOMIC_SLEEP) \
    $(wildcard include/config/PREEMPT_RT) \
    $(wildcard include/config/VIRT_CPU_ACCOUNTING_NATIVE) \
    $(wildcard include/config/SCHED_INFO) \
    $(wildcard include/config/SCHEDSTATS) \
    $(wildcard include/config/SCHED_CORE) \
    $(wildcard include/config/FAIR_GROUP_SCHED) \
    $(wildcard include/config/RT_GROUP_SCHED) \
    $(wildcard include/config/RT_MUTEXES) \
    $(wildcard include/config/UCLAMP_TASK) \
    $(wildcard include/config/UCLAMP_BUCKETS_COUNT) \
    $(wildcard include/config/KMAP_LOCAL) \
    $(wildcard include/config/THREAD_INFO_IN_TASK) \
    $(wildcard include/config/MEM_ALLOC_PROFILING) \
    $(wildcard include/config/SCHED_CLASS_EXT) \
    $(wildcard include/config/CGROUP_SCHED) \
    $(wildcard include/config/CFS_BANDWIDTH) \
    $(wildcard include/config/PREEMPT_NOTIFIERS) \
    $(wildcard include/config/BLK_DEV_IO_TRACE) \
    $(wildcard include/config/PREEMPT_RCU) \
    $(wildcard include/config/TASKS_RCU) \
    $(wildcard include/config/TASKS_TRACE_RCU) \
    $(wildcard include/config/TRIVIAL_PREEMPT_RCU) \
    $(wildcard include/config/MEMCG_V1) \
    $(wildcard include/config/LRU_GEN) \
    $(wildcard include/config/COMPAT_BRK) \
    $(wildcard include/config/CGROUPS) \
    $(wildcard include/config/BLK_CGROUP) \
    $(wildcard include/config/PSI) \
    $(wildcard include/config/PAGE_OWNER) \
    $(wildcard include/config/EVENTFD) \
    $(wildcard include/config/ARCH_HAS_CPU_PASID) \
    $(wildcard include/config/X86_BUS_LOCK_DETECT) \
    $(wildcard include/config/TASK_DELAY_ACCT) \
    $(wildcard include/config/STACKPROTECTOR) \
    $(wildcard include/config/ARCH_HAS_SCALED_CPUTIME) \
    $(wildcard include/config/VIRT_CPU_ACCOUNTING_GEN) \
    $(wildcard include/config/NO_HZ_FULL) \
    $(wildcard include/config/POSIX_CPUTIMERS) \
    $(wildcard include/config/POSIX_CPU_TIMERS_TASK_WORK) \
    $(wildcard include/config/KEYS) \
    $(wildcard include/config/SYSVIPC) \
    $(wildcard include/config/DETECT_HUNG_TASK) \
    $(wildcard include/config/IO_URING) \
    $(wildcard include/config/AUDIT) \
    $(wildcard include/config/AUDITSYSCALL) \
    $(wildcard include/config/DETECT_HUNG_TASK_BLOCKER) \
    $(wildcard include/config/TRACE_IRQFLAGS) \
    $(wildcard include/config/UBSAN) \
    $(wildcard include/config/UBSAN_TRAP) \
    $(wildcard include/config/COMPACTION) \
    $(wildcard include/config/TASK_XACCT) \
    $(wildcard include/config/CPUSETS) \
    $(wildcard include/config/X86_CPU_RESCTRL) \
    $(wildcard include/config/PERF_EVENTS) \
    $(wildcard include/config/DEBUG_PREEMPT) \
    $(wildcard include/config/NUMA_BALANCING) \
    $(wildcard include/config/SCHED_CACHE) \
    $(wildcard include/config/ARCH_HAS_LAZY_MMU_MODE) \
    $(wildcard include/config/FAULT_INJECTION) \
    $(wildcard include/config/LATENCYTOP) \
    $(wildcard include/config/KMSAN) \
    $(wildcard include/config/KUNIT) \
    $(wildcard include/config/FUNCTION_GRAPH_TRACER) \
    $(wildcard include/config/TRACING) \
    $(wildcard include/config/MEMCG) \
    $(wildcard include/config/UPROBES) \
    $(wildcard include/config/BCACHE) \
    $(wildcard include/config/MMU) \
    $(wildcard include/config/VMAP_STACK) \
    $(wildcard include/config/LIVEPATCH) \
    $(wildcard include/config/SECURITY) \
    $(wildcard include/config/BPF_SYSCALL) \
    $(wildcard include/config/KSTACK_ERASE) \
    $(wildcard include/config/KSTACK_ERASE_METRICS) \
    $(wildcard include/config/X86_MCE) \
    $(wildcard include/config/KRETPROBES) \
    $(wildcard include/config/RETHOOK) \
    $(wildcard include/config/ARCH_HAS_PARANOID_L1D_FLUSH) \
    $(wildcard include/config/RV) \
    $(wildcard include/config/RV_PER_TASK_MONITORS) \
    $(wildcard include/config/USER_EVENTS) \
    $(wildcard include/config/UNWIND_USER) \
    $(wildcard include/config/SCHED_PROXY_EXEC) \
    $(wildcard include/config/PREEMPTION) \
    $(wildcard include/config/PREEMPT_DYNAMIC) \
    $(wildcard include/config/HAVE_PREEMPT_DYNAMIC_CALL) \
    $(wildcard include/config/HAVE_PREEMPT_DYNAMIC_KEY) \
    $(wildcard include/config/MEM_ALLOC_PROFILING_DEBUG) \
    $(wildcard include/config/SCHED_MM_CID) \
  /tmp/kernel-mainline/include/uapi/linux/sched.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/current.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/processor.h \
    $(wildcard include/config/COMPAT) \
    $(wildcard include/config/ARM64_64K_PAGES) \
    $(wildcard include/config/KUSER_HELPERS) \
    $(wildcard include/config/ARM64_FORCE_52BIT) \
    $(wildcard include/config/HAVE_HW_BREAKPOINT) \
    $(wildcard include/config/ARM64_MTE) \
    $(wildcard include/config/ARM64_GCS) \
    $(wildcard include/config/ARM64_TAGGED_ADDR_ABI) \
  /tmp/kernel-mainline/include/linux/cache.h \
    $(wildcard include/config/ARCH_HAS_CACHE_LINE_SIZE) \
  /tmp/kernel-mainline/include/uapi/linux/kernel.h \
  /tmp/kernel-mainline/include/uapi/linux/sysinfo.h \
  /tmp/kernel-mainline/include/vdso/cache.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/cache.h \
    $(wildcard include/config/KASAN_HW_TAGS) \
  /tmp/kernel-mainline/include/linux/bitops.h \
  /tmp/kernel-mainline/include/linux/typecheck.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/generic-non-atomic.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/barrier.h \
    $(wildcard include/config/ARM64_PSEUDO_NMI) \
  /tmp/kernel-mainline/arch/arm64/include/asm/alternative-macros.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/cpucaps.h \
    $(wildcard include/config/ARM64_EPAN) \
    $(wildcard include/config/ARM64_SVE) \
    $(wildcard include/config/ARM64_SME) \
    $(wildcard include/config/ARM64_CNP) \
    $(wildcard include/config/ARM64_BTI) \
    $(wildcard include/config/ARM64_TLB_RANGE) \
    $(wildcard include/config/ARM64_POE) \
    $(wildcard include/config/ARM64_HAFT) \
    $(wildcard include/config/UNMAP_KERNEL_AT_EL0) \
    $(wildcard include/config/ARM64_ERRATUM_843419) \
    $(wildcard include/config/ARM64_ERRATUM_1742098) \
    $(wildcard include/config/ARM64_ERRATUM_2645198) \
    $(wildcard include/config/ARM64_ERRATUM_2658417) \
    $(wildcard include/config/CAVIUM_ERRATUM_23154) \
    $(wildcard include/config/ARM64_WORKAROUND_DISABLE_CNP) \
    $(wildcard include/config/ARM64_WORKAROUND_REPEAT_TLBI) \
    $(wildcard include/config/ARM64_ERRATUM_3194386) \
    $(wildcard include/config/ARM64_ERRATUM_4193714) \
    $(wildcard include/config/HW_PERF_EVENTS) \
    $(wildcard include/config/ARM64_LSUI) \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/cpucap-defs.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/insn-def.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/brk-imm.h \
  /tmp/kernel-mainline/include/linux/stringify.h \
  /tmp/kernel-mainline/include/asm-generic/barrier.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/bitops.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/builtin-__ffs.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/builtin-ffs.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/builtin-__fls.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/builtin-fls.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/ffz.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/fls64.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/sched.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/hweight.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/arch_hweight.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/const_hweight.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/atomic.h \
  /tmp/kernel-mainline/include/linux/atomic.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/atomic.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/cmpxchg.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/lse.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/atomic_ll_sc.h \
    $(wildcard include/config/CC_HAS_K_CONSTRAINT) \
  /tmp/kernel-mainline/include/linux/export.h \
    $(wildcard include/config/MODVERSIONS) \
    $(wildcard include/config/GENDWARFKSYMS) \
  /tmp/kernel-mainline/include/linux/linkage.h \
    $(wildcard include/config/ARCH_USE_SYM_ANNOTATIONS) \
  /tmp/kernel-mainline/arch/arm64/include/asm/linkage.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/alternative.h \
    $(wildcard include/config/MODULES) \
  /tmp/kernel-mainline/include/linux/init.h \
    $(wildcard include/config/MEMORY_HOTPLUG) \
    $(wildcard include/config/HAVE_ARCH_PREL32_RELOCATIONS) \
  /tmp/kernel-mainline/arch/arm64/include/asm/atomic_lse.h \
  /tmp/kernel-mainline/include/linux/atomic/atomic-arch-fallback.h \
    $(wildcard include/config/GENERIC_ATOMIC64) \
  /tmp/kernel-mainline/include/linux/atomic/atomic-long.h \
  /tmp/kernel-mainline/include/linux/atomic/atomic-instrumented.h \
  /tmp/kernel-mainline/include/linux/instrumented.h \
    $(wildcard include/config/DEBUG_ATOMIC) \
    $(wildcard include/config/DEBUG_ATOMIC_LARGEST_ALIGN) \
  /tmp/kernel-mainline/include/linux/bug.h \
    $(wildcard include/config/GENERIC_BUG) \
    $(wildcard include/config/BUG_ON_DATA_CORRUPTION) \
  /tmp/kernel-mainline/arch/arm64/include/asm/bug.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/asm-bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE) \
  /tmp/kernel-mainline/include/asm-generic/bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE_DETAILED) \
    $(wildcard include/config/BUG) \
    $(wildcard include/config/GENERIC_BUG_RELATIVE_POINTERS) \
  /tmp/kernel-mainline/include/linux/instrumentation.h \
    $(wildcard include/config/NOINSTR_VALIDATION) \
  /tmp/kernel-mainline/include/linux/once_lite.h \
  /tmp/kernel-mainline/include/linux/panic.h \
    $(wildcard include/config/PANIC_TIMEOUT) \
  /tmp/kernel-mainline/include/linux/stdarg.h \
  /tmp/kernel-mainline/include/linux/printk.h \
    $(wildcard include/config/MESSAGE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_QUIET) \
    $(wildcard include/config/EARLY_PRINTK) \
    $(wildcard include/config/PRINTK_INDEX) \
  /tmp/kernel-mainline/include/linux/kern_levels.h \
  /tmp/kernel-mainline/include/linux/dynamic_debug.h \
    $(wildcard include/config/JUMP_LABEL) \
  /tmp/kernel-mainline/include/linux/jump_label.h \
    $(wildcard include/config/HAVE_ARCH_JUMP_LABEL_RELATIVE) \
  /tmp/kernel-mainline/include/linux/cleanup.h \
  /tmp/kernel-mainline/include/linux/err.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/uapi/asm/errno.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/errno.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/errno-base.h \
  /tmp/kernel-mainline/include/linux/args.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/jump_label.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/insn.h \
  /tmp/kernel-mainline/include/linux/kmsan-checks.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/instrumented-atomic.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/lock.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/instrumented-lock.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/non-atomic.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/non-instrumented-non-atomic.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/le.h \
  /tmp/kernel-mainline/include/asm-generic/bitops/ext2-atomic-setbit.h \
  /tmp/kernel-mainline/include/linux/kasan-enabled.h \
    $(wildcard include/config/ARCH_DEFER_KASAN) \
    $(wildcard include/config/KASAN) \
  /tmp/kernel-mainline/include/linux/static_key.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/cputype.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/sysreg.h \
    $(wildcard include/config/BROKEN_GAS_INST) \
    $(wildcard include/config/ARM64_PA_BITS_52) \
    $(wildcard include/config/ARM64_4K_PAGES) \
    $(wildcard include/config/ARM64_16K_PAGES) \
    $(wildcard include/config/AMPERE_ERRATUM_AC04_CPU_23) \
  /tmp/kernel-mainline/include/linux/kasan-tags.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/gpr-num.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/sysreg-defs.h \
  /tmp/kernel-mainline/include/linux/bitfield.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/mte-def.h \
  /tmp/kernel-mainline/include/linux/string.h \
    $(wildcard include/config/BINARY_PRINTF) \
  /tmp/kernel-mainline/include/linux/array_size.h \
  /tmp/kernel-mainline/include/linux/errno.h \
  /tmp/kernel-mainline/include/uapi/linux/errno.h \
  /tmp/kernel-mainline/include/uapi/linux/string.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/string.h \
    $(wildcard include/config/ARCH_HAS_UACCESS_FLUSHCACHE) \
  /tmp/kernel-mainline/include/linux/thread_info.h \
    $(wildcard include/config/GENERIC_ENTRY) \
    $(wildcard include/config/ARCH_HAS_PREEMPT_LAZY) \
    $(wildcard include/config/HAVE_ARCH_WITHIN_STACK_FRAMES) \
    $(wildcard include/config/SH) \
  /tmp/kernel-mainline/include/linux/restart_block.h \
  /tmp/kernel-mainline/include/linux/time64.h \
  /tmp/kernel-mainline/include/linux/math64.h \
    $(wildcard include/config/ARCH_SUPPORTS_INT128) \
  /tmp/kernel-mainline/include/linux/math.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/div64.h \
  /tmp/kernel-mainline/include/asm-generic/div64.h \
    $(wildcard include/config/CC_OPTIMIZE_FOR_PERFORMANCE) \
  /tmp/kernel-mainline/include/vdso/math64.h \
  /tmp/kernel-mainline/include/vdso/time64.h \
  /tmp/kernel-mainline/include/uapi/linux/time.h \
  /tmp/kernel-mainline/include/uapi/linux/time_types.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/thread_info.h \
    $(wildcard include/config/ARM64_SW_TTBR0_PAN) \
    $(wildcard include/config/ARM64_MPAM) \
  /tmp/kernel-mainline/arch/arm64/include/asm/memory.h \
    $(wildcard include/config/ARM64_VA_BITS) \
    $(wildcard include/config/KASAN_SHADOW_OFFSET) \
    $(wildcard include/config/RANDOMIZE_BASE) \
    $(wildcard include/config/DEBUG_VIRTUAL) \
    $(wildcard include/config/EFI) \
    $(wildcard include/config/ARM_GIC_V3_ITS) \
  /tmp/kernel-mainline/include/linux/sizes.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/page-def.h \
  /tmp/kernel-mainline/include/vdso/page.h \
    $(wildcard include/config/PAGE_SHIFT) \
  /tmp/kernel-mainline/include/linux/mmdebug.h \
    $(wildcard include/config/DEBUG_VM) \
    $(wildcard include/config/DEBUG_VM_IRQSOFF) \
    $(wildcard include/config/DEBUG_VM_PGFLAGS) \
  /tmp/kernel-mainline/arch/arm64/include/asm/boot.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/sections.h \
  /tmp/kernel-mainline/include/asm-generic/sections.h \
    $(wildcard include/config/HAVE_FUNCTION_DESCRIPTORS) \
  /tmp/kernel-mainline/include/asm-generic/memory_model.h \
    $(wildcard include/config/FLATMEM) \
    $(wildcard include/config/SPARSEMEM_VMEMMAP) \
    $(wildcard include/config/SPARSEMEM) \
  /tmp/kernel-mainline/include/linux/pfn.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/stack_pointer.h \
  /tmp/kernel-mainline/include/vdso/processor.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/vdso/processor.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/cpufeature.h \
    $(wildcard include/config/ARM64_DEBUG_PRIORITY_MASKING) \
    $(wildcard include/config/ARM64_BTI_KERNEL) \
    $(wildcard include/config/ARM64_PA_BITS) \
    $(wildcard include/config/ARM64_HW_AFDBM) \
    $(wildcard include/config/ARM64_AMU_EXTN) \
    $(wildcard include/config/ARM64_LPA2) \
  /tmp/kernel-mainline/arch/arm64/include/asm/hwcap.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/hwcap.h \
  /tmp/kernel-mainline/include/linux/log2.h \
    $(wildcard include/config/ARCH_HAS_ILOG2_U32) \
    $(wildcard include/config/ARCH_HAS_ILOG2_U64) \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/kernel-hwcap.h \
  /tmp/kernel-mainline/include/linux/kernel.h \
    $(wildcard include/config/PREEMPT_VOLUNTARY_BUILD) \
    $(wildcard include/config/PREEMPT_) \
    $(wildcard include/config/PROVE_LOCKING) \
    $(wildcard include/config/DYNAMIC_FTRACE) \
  /tmp/kernel-mainline/include/linux/align.h \
  /tmp/kernel-mainline/include/vdso/align.h \
  /tmp/kernel-mainline/include/linux/container_of.h \
  /tmp/kernel-mainline/include/linux/kstrtox.h \
  /tmp/kernel-mainline/include/linux/minmax.h \
  /tmp/kernel-mainline/include/linux/sprintf.h \
  /tmp/kernel-mainline/include/linux/static_call_types.h \
    $(wildcard include/config/HAVE_STATIC_CALL) \
    $(wildcard include/config/HAVE_STATIC_CALL_INLINE) \
  /tmp/kernel-mainline/include/linux/trace_printk.h \
  /tmp/kernel-mainline/include/linux/instruction_pointer.h \
  /tmp/kernel-mainline/include/linux/util_macros.h \
    $(wildcard include/config/FOO_SUSPEND) \
  /tmp/kernel-mainline/include/linux/wordpart.h \
  /tmp/kernel-mainline/include/linux/cpumask.h \
    $(wildcard include/config/FORCE_NR_CPUS) \
    $(wildcard include/config/HOTPLUG_CPU) \
    $(wildcard include/config/DEBUG_PER_CPU_MAPS) \
    $(wildcard include/config/CPUMASK_OFFSTACK) \
  /tmp/kernel-mainline/include/linux/bitmap.h \
  /tmp/kernel-mainline/include/linux/find.h \
  /tmp/kernel-mainline/include/linux/bitmap-str.h \
  /tmp/kernel-mainline/include/linux/cpumask_types.h \
  /tmp/kernel-mainline/include/linux/threads.h \
    $(wildcard include/config/BASE_SMALL) \
  /tmp/kernel-mainline/include/linux/gfp_types.h \
  /tmp/kernel-mainline/include/linux/numa.h \
    $(wildcard include/config/NUMA_KEEP_MEMINFO) \
    $(wildcard include/config/HAVE_ARCH_NODE_DEV_GROUP) \
  /tmp/kernel-mainline/include/linux/nodemask.h \
    $(wildcard include/config/HIGHMEM) \
  /tmp/kernel-mainline/include/linux/nodemask_types.h \
    $(wildcard include/config/NODES_SHIFT) \
  /tmp/kernel-mainline/include/linux/random.h \
    $(wildcard include/config/VMGENID) \
  /tmp/kernel-mainline/include/linux/list.h \
    $(wildcard include/config/LIST_HARDENED) \
    $(wildcard include/config/DEBUG_LIST) \
  /tmp/kernel-mainline/include/linux/poison.h \
    $(wildcard include/config/ILLEGAL_POINTER_VALUE) \
  /tmp/kernel-mainline/include/uapi/linux/random.h \
  /tmp/kernel-mainline/include/uapi/linux/ioctl.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/uapi/asm/ioctl.h \
  /tmp/kernel-mainline/include/asm-generic/ioctl.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/ioctl.h \
  /tmp/kernel-mainline/include/linux/irqnr.h \
  /tmp/kernel-mainline/include/uapi/linux/irqnr.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/sparsemem.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/pgtable-prot.h \
    $(wildcard include/config/HAVE_ARCH_USERFAULTFD_WP) \
  /tmp/kernel-mainline/arch/arm64/include/asm/pgtable-hwdef.h \
    $(wildcard include/config/PGTABLE_LEVELS) \
    $(wildcard include/config/ARM64_CONT_PTE_SHIFT) \
    $(wildcard include/config/ARM64_CONT_PMD_SHIFT) \
    $(wildcard include/config/ARM64_VA_BITS_52) \
  /tmp/kernel-mainline/arch/arm64/include/asm/pgtable-types.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/rsi.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/rsi_cmds.h \
  /tmp/kernel-mainline/include/linux/arm-smccc.h \
    $(wildcard include/config/HAVE_ARM_SMCCC) \
    $(wildcard include/config/ARM) \
  /tmp/kernel-mainline/include/linux/uuid.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/rsi_smc.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/hw_breakpoint.h \
    $(wildcard include/config/CPU_PM) \
  /tmp/kernel-mainline/arch/arm64/include/asm/virt.h \
    $(wildcard include/config/KVM) \
  /tmp/kernel-mainline/arch/arm64/include/asm/ptrace.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/ptrace.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/sve_context.h \
  /tmp/kernel-mainline/include/linux/irqchip/arm-gic-v3-prio.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/stacktrace/frame.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/kasan.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/mte-kasan.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/pointer_auth.h \
  /tmp/kernel-mainline/include/uapi/linux/prctl.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/spectre.h \
  /tmp/kernel-mainline/include/linux/smp.h \
    $(wildcard include/config/UP_LATE_INIT) \
    $(wildcard include/config/CSD_LOCK_WAIT_DEBUG) \
  /tmp/kernel-mainline/include/linux/smp_types.h \
  /tmp/kernel-mainline/include/linux/llist.h \
    $(wildcard include/config/ARCH_HAVE_NMI_SAFE_CMPXCHG) \
  /tmp/kernel-mainline/include/linux/preempt.h \
    $(wildcard include/config/PREEMPT_COUNT) \
    $(wildcard include/config/TRACE_PREEMPT_TOGGLE) \
    $(wildcard include/config/PREEMPT_NONE) \
    $(wildcard include/config/PREEMPT_VOLUNTARY) \
    $(wildcard include/config/PREEMPT) \
    $(wildcard include/config/PREEMPT_LAZY) \
  /tmp/kernel-mainline/arch/arm64/include/asm/preempt.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/smp.h \
    $(wildcard include/config/ARM64_ACPI_PARKING_PROTOCOL) \
  /tmp/kernel-mainline/arch/arm64/include/asm/percpu.h \
  /tmp/kernel-mainline/include/asm-generic/percpu.h \
    $(wildcard include/config/HAVE_SETUP_PER_CPU_AREA) \
  /tmp/kernel-mainline/include/linux/percpu-defs.h \
    $(wildcard include/config/ARCH_MODULE_NEEDS_WEAK_PER_CPU) \
    $(wildcard include/config/DEBUG_FORCE_WEAK_PER_CPU) \
    $(wildcard include/config/AMD_MEM_ENCRYPT) \
  /tmp/kernel-mainline/arch/arm64/include/asm/fpsimd.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/sigcontext.h \
  /tmp/kernel-mainline/include/linux/futex_types.h \
    $(wildcard include/config/FUTEX) \
    $(wildcard include/config/FUTEX_PRIVATE_HASH) \
    $(wildcard include/config/FUTEX_ROBUST_UNLOCK) \
  /tmp/kernel-mainline/include/linux/mutex_types.h \
    $(wildcard include/config/MUTEX_SPIN_ON_OWNER) \
    $(wildcard include/config/DEBUG_MUTEXES) \
  /tmp/kernel-mainline/include/linux/osq_lock.h \
  /tmp/kernel-mainline/include/linux/spinlock_types.h \
  /tmp/kernel-mainline/include/linux/rwlock_types.h \
  /tmp/kernel-mainline/include/linux/irqflags_types.h \
  /tmp/kernel-mainline/include/linux/pid_types.h \
  /tmp/kernel-mainline/include/linux/sem_types.h \
  /tmp/kernel-mainline/include/linux/shm.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/page.h \
  /tmp/kernel-mainline/include/linux/personality.h \
  /tmp/kernel-mainline/include/uapi/linux/personality.h \
  /tmp/kernel-mainline/include/asm-generic/getorder.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/shmparam.h \
  /tmp/kernel-mainline/include/asm-generic/shmparam.h \
  /tmp/kernel-mainline/include/linux/kmsan_types.h \
  /tmp/kernel-mainline/include/linux/plist_types.h \
  /tmp/kernel-mainline/include/linux/hrtimer_types.h \
  /tmp/kernel-mainline/include/linux/timerqueue_types.h \
  /tmp/kernel-mainline/include/linux/rbtree_types.h \
  /tmp/kernel-mainline/include/linux/timer_types.h \
  /tmp/kernel-mainline/include/linux/seccomp_types.h \
    $(wildcard include/config/SECCOMP) \
  /tmp/kernel-mainline/include/linux/refcount_types.h \
  /tmp/kernel-mainline/include/linux/resource.h \
  /tmp/kernel-mainline/include/uapi/linux/resource.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/uapi/asm/resource.h \
  /tmp/kernel-mainline/include/asm-generic/resource.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/resource.h \
  /tmp/kernel-mainline/include/linux/latencytop.h \
  /tmp/kernel-mainline/include/linux/sched/prio.h \
  /tmp/kernel-mainline/include/linux/sched/types.h \
  /tmp/kernel-mainline/include/linux/signal_types.h \
    $(wildcard include/config/OLD_SIGACTION) \
  /tmp/kernel-mainline/include/uapi/linux/signal.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/signal.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/signal.h \
  /tmp/kernel-mainline/include/asm-generic/signal.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/signal.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/signal-defs.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/uapi/asm/siginfo.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/siginfo.h \
  /tmp/kernel-mainline/include/linux/spinlock.h \
  /tmp/kernel-mainline/include/linux/irqflags.h \
    $(wildcard include/config/IRQSOFF_TRACER) \
    $(wildcard include/config/PREEMPT_TRACER) \
    $(wildcard include/config/DEBUG_IRQFLAGS) \
    $(wildcard include/config/TRACE_IRQFLAGS_SUPPORT) \
  /tmp/kernel-mainline/arch/arm64/include/asm/irqflags.h \
  /tmp/kernel-mainline/include/linux/bottom_half.h \
  /tmp/kernel-mainline/include/linux/lockdep.h \
    $(wildcard include/config/DEBUG_LOCKING_API_SELFTESTS) \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/mmiowb.h \
  /tmp/kernel-mainline/include/asm-generic/mmiowb.h \
    $(wildcard include/config/MMIOWB) \
  /tmp/kernel-mainline/arch/arm64/include/asm/spinlock.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/qspinlock.h \
  /tmp/kernel-mainline/include/asm-generic/qspinlock.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/qrwlock.h \
  /tmp/kernel-mainline/include/asm-generic/qrwlock.h \
  /tmp/kernel-mainline/include/linux/rwlock.h \
  /tmp/kernel-mainline/include/linux/spinlock_api_smp.h \
    $(wildcard include/config/INLINE_SPIN_LOCK) \
    $(wildcard include/config/INLINE_SPIN_LOCK_BH) \
    $(wildcard include/config/INLINE_SPIN_LOCK_IRQ) \
    $(wildcard include/config/INLINE_SPIN_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_SPIN_TRYLOCK) \
    $(wildcard include/config/INLINE_SPIN_TRYLOCK_BH) \
    $(wildcard include/config/UNINLINE_SPIN_UNLOCK) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_BH) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_SPIN_UNLOCK_IRQRESTORE) \
    $(wildcard include/config/GENERIC_LOCKBREAK) \
  /tmp/kernel-mainline/include/linux/rwlock_api_smp.h \
    $(wildcard include/config/INLINE_READ_LOCK) \
    $(wildcard include/config/INLINE_WRITE_LOCK) \
    $(wildcard include/config/INLINE_READ_LOCK_BH) \
    $(wildcard include/config/INLINE_WRITE_LOCK_BH) \
    $(wildcard include/config/INLINE_READ_LOCK_IRQ) \
    $(wildcard include/config/INLINE_WRITE_LOCK_IRQ) \
    $(wildcard include/config/INLINE_READ_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_WRITE_LOCK_IRQSAVE) \
    $(wildcard include/config/INLINE_READ_TRYLOCK) \
    $(wildcard include/config/INLINE_WRITE_TRYLOCK) \
    $(wildcard include/config/INLINE_READ_UNLOCK) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK) \
    $(wildcard include/config/INLINE_READ_UNLOCK_BH) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_BH) \
    $(wildcard include/config/INLINE_READ_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_IRQ) \
    $(wildcard include/config/INLINE_READ_UNLOCK_IRQRESTORE) \
    $(wildcard include/config/INLINE_WRITE_UNLOCK_IRQRESTORE) \
  /tmp/kernel-mainline/include/linux/syscall_user_dispatch_types.h \
  /tmp/kernel-mainline/include/linux/mm_types_task.h \
    $(wildcard include/config/ARCH_WANT_BATCHED_UNMAP_TLB_FLUSH) \
  /tmp/kernel-mainline/arch/arm64/include/asm/tlbbatch.h \
  /tmp/kernel-mainline/include/linux/netdevice_xmit.h \
    $(wildcard include/config/NET_ACT_MIRRED) \
    $(wildcard include/config/NET_EGRESS) \
    $(wildcard include/config/NF_DUP_NETDEV) \
  /tmp/kernel-mainline/include/linux/task_io_accounting.h \
    $(wildcard include/config/TASK_IO_ACCOUNTING) \
  /tmp/kernel-mainline/include/linux/posix-timers_types.h \
    $(wildcard include/config/POSIX_TIMERS) \
  /tmp/kernel-mainline/include/linux/rseq_types.h \
    $(wildcard include/config/RSEQ) \
    $(wildcard include/config/RSEQ_SLICE_EXTENSION) \
  /tmp/kernel-mainline/include/linux/irq_work_types.h \
  /tmp/kernel-mainline/include/linux/workqueue_types.h \
  /tmp/kernel-mainline/include/linux/seqlock_types.h \
  /tmp/kernel-mainline/include/linux/kcsan.h \
  /tmp/kernel-mainline/include/linux/rv.h \
    $(wildcard include/config/RV_LTL_MONITOR) \
    $(wildcard include/config/RV_HA_MONITOR) \
    $(wildcard include/config/RV_REACTORS) \
  /tmp/kernel-mainline/include/linux/uidgid_types.h \
  /tmp/kernel-mainline/include/linux/tracepoint-defs.h \
    $(wildcard include/config/TRACEPOINTS) \
  /tmp/kernel-mainline/include/linux/unwind_deferred_types.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/kmap_size.h \
  /tmp/kernel-mainline/include/asm-generic/kmap_size.h \
    $(wildcard include/config/DEBUG_KMAP_LOCAL) \
  /tmp/kernel-mainline/include/generated/rq-offsets.h \
  /tmp/kernel-mainline/include/linux/sched/ext.h \
    $(wildcard include/config/EXT_GROUP_SCHED) \
  /tmp/kernel-mainline/include/linux/energy_model.h \
  /tmp/kernel-mainline/include/linux/kobject.h \
    $(wildcard include/config/UEVENT_HELPER) \
    $(wildcard include/config/DEBUG_KOBJECT_RELEASE) \
  /tmp/kernel-mainline/include/linux/sysfs.h \
    $(wildcard include/config/SYSFS) \
  /tmp/kernel-mainline/include/linux/kernfs.h \
    $(wildcard include/config/KERNFS) \
  /tmp/kernel-mainline/include/linux/mutex.h \
  /tmp/kernel-mainline/include/linux/debug_locks.h \
  /tmp/kernel-mainline/include/linux/idr.h \
  /tmp/kernel-mainline/include/linux/radix-tree.h \
  /tmp/kernel-mainline/include/linux/percpu.h \
    $(wildcard include/config/KMALLOC_PARTITION_CACHES) \
    $(wildcard include/config/PAGE_SIZE_4KB) \
    $(wildcard include/config/NEED_PER_CPU_PAGE_FIRST_CHUNK) \
  /tmp/kernel-mainline/include/linux/alloc_tag.h \
    $(wildcard include/config/MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT) \
  /tmp/kernel-mainline/include/linux/codetag.h \
    $(wildcard include/config/CODE_TAGGING) \
  /tmp/kernel-mainline/include/linux/rcupdate.h \
    $(wildcard include/config/TINY_RCU) \
    $(wildcard include/config/RCU_STRICT_GRACE_PERIOD) \
    $(wildcard include/config/RCU_LAZY) \
    $(wildcard include/config/RCU_STALL_COMMON) \
    $(wildcard include/config/VIRT_XFER_TO_GUEST_WORK) \
    $(wildcard include/config/RCU_NOCB_CPU) \
    $(wildcard include/config/TASKS_RCU_GENERIC) \
    $(wildcard include/config/TASKS_RUDE_RCU) \
    $(wildcard include/config/TREE_RCU) \
    $(wildcard include/config/DEBUG_OBJECTS_RCU_HEAD) \
    $(wildcard include/config/PROVE_RCU) \
    $(wildcard include/config/ARCH_WEAK_RELEASE_ACQUIRE) \
  /tmp/kernel-mainline/include/linux/context_tracking_irq.h \
    $(wildcard include/config/CONTEXT_TRACKING_IDLE) \
  /tmp/kernel-mainline/include/linux/rcutree.h \
  /tmp/kernel-mainline/include/linux/xarray.h \
    $(wildcard include/config/XARRAY_MULTI) \
  /tmp/kernel-mainline/include/linux/gfp.h \
    $(wildcard include/config/ZONE_DMA) \
    $(wildcard include/config/ZONE_DMA32) \
    $(wildcard include/config/ZONE_DEVICE) \
    $(wildcard include/config/CONTIG_ALLOC) \
  /tmp/kernel-mainline/include/linux/mmzone.h \
    $(wildcard include/config/ARCH_FORCE_MAX_ORDER) \
    $(wildcard include/config/PAGE_BLOCK_MAX_ORDER) \
    $(wildcard include/config/HAVE_GIGANTIC_FOLIOS) \
    $(wildcard include/config/HUGETLB_PAGE) \
    $(wildcard include/config/HUGETLB_PAGE_OPTIMIZE_VMEMMAP) \
    $(wildcard include/config/CMA) \
    $(wildcard include/config/MEMORY_ISOLATION) \
    $(wildcard include/config/ZSMALLOC) \
    $(wildcard include/config/UNACCEPTED_MEMORY) \
    $(wildcard include/config/IOMMU_SUPPORT) \
    $(wildcard include/config/SWAP) \
    $(wildcard include/config/TRANSPARENT_HUGEPAGE) \
    $(wildcard include/config/LRU_GEN_STATS) \
    $(wildcard include/config/LRU_GEN_WALKS_MMU) \
    $(wildcard include/config/MEMORY_FAILURE) \
    $(wildcard include/config/PAGE_EXTENSION) \
    $(wildcard include/config/DEFERRED_STRUCT_PAGE_INIT) \
    $(wildcard include/config/HAVE_MEMORYLESS_NODES) \
    $(wildcard include/config/SPARSEMEM_EXTREME) \
    $(wildcard include/config/SPARSEMEM_VMEMMAP_PREINIT) \
    $(wildcard include/config/HAVE_ARCH_PFN_VALID) \
  /tmp/kernel-mainline/include/linux/list_nulls.h \
  /tmp/kernel-mainline/include/linux/wait.h \
  /tmp/kernel-mainline/include/linux/seqlock.h \
    $(wildcard include/config/CC_IS_GCC) \
    $(wildcard include/config/GCC_VERSION) \
    $(wildcard include/config/UBSAN_ALIGNMENT) \
  /tmp/kernel-mainline/include/linux/pageblock-flags.h \
    $(wildcard include/config/HUGETLB_PAGE_SIZE_VARIABLE) \
  /tmp/kernel-mainline/include/linux/page-flags-layout.h \
  /tmp/kernel-mainline/include/generated/bounds.h \
  /tmp/kernel-mainline/include/linux/mm_types.h \
    $(wildcard include/config/HAVE_ALIGNED_STRUCT_PAGE) \
    $(wildcard include/config/SLAB_OBJ_EXT) \
    $(wildcard include/config/HUGETLB_PMD_PAGE_TABLE_SHARING) \
    $(wildcard include/config/SLAB_FREELIST_HARDENED) \
    $(wildcard include/config/USERFAULTFD) \
    $(wildcard include/config/ANON_VMA_NAME) \
    $(wildcard include/config/PER_VMA_LOCK) \
    $(wildcard include/config/HAVE_ARCH_COMPAT_MMAP_BASES) \
    $(wildcard include/config/MEMBARRIER) \
    $(wildcard include/config/ARCH_HAS_ELF_CORE_EFLAGS) \
    $(wildcard include/config/AIO) \
    $(wildcard include/config/MMU_NOTIFIER) \
    $(wildcard include/config/SPLIT_PMD_PTLOCKS) \
    $(wildcard include/config/IOMMU_MM_DATA) \
    $(wildcard include/config/KSM) \
    $(wildcard include/config/MM_ID) \
    $(wildcard include/config/CORE_DUMP_DEFAULT_ELF_HEADERS) \
  /tmp/kernel-mainline/include/linux/auxvec.h \
  /tmp/kernel-mainline/include/uapi/linux/auxvec.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/auxvec.h \
  /tmp/kernel-mainline/include/linux/kref.h \
  /tmp/kernel-mainline/include/linux/refcount.h \
  /tmp/kernel-mainline/include/linux/rbtree.h \
  /tmp/kernel-mainline/include/linux/maple_tree.h \
    $(wildcard include/config/MAPLE_RCU_DISABLED) \
    $(wildcard include/config/DEBUG_MAPLE_TREE) \
  /tmp/kernel-mainline/include/linux/rwsem.h \
    $(wildcard include/config/RWSEM_SPIN_ON_OWNER) \
    $(wildcard include/config/DEBUG_RWSEMS) \
  /tmp/kernel-mainline/include/linux/completion.h \
  /tmp/kernel-mainline/include/linux/swait.h \
  /tmp/kernel-mainline/include/linux/uprobes.h \
  /tmp/kernel-mainline/include/linux/timer.h \
    $(wildcard include/config/DEBUG_OBJECTS_TIMERS) \
    $(wildcard include/config/NO_HZ_COMMON) \
  /tmp/kernel-mainline/include/linux/ktime.h \
  /tmp/kernel-mainline/include/linux/jiffies.h \
  /tmp/kernel-mainline/include/linux/time.h \
  /tmp/kernel-mainline/include/linux/time32.h \
  /tmp/kernel-mainline/include/linux/timex.h \
  /tmp/kernel-mainline/include/uapi/linux/timex.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/timex.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/arch_timer.h \
    $(wildcard include/config/ARM_ARCH_TIMER_OOL_WORKAROUND) \
  /tmp/kernel-mainline/include/clocksource/arm_arch_timer.h \
    $(wildcard include/config/ARM_ARCH_TIMER) \
  /tmp/kernel-mainline/include/linux/timecounter.h \
  /tmp/kernel-mainline/include/asm-generic/timex.h \
  /tmp/kernel-mainline/include/vdso/time32.h \
  /tmp/kernel-mainline/include/vdso/time.h \
  /tmp/kernel-mainline/include/vdso/jiffies.h \
  /tmp/kernel-mainline/include/generated/timeconst.h \
  /tmp/kernel-mainline/include/vdso/ktime.h \
  /tmp/kernel-mainline/include/linux/timekeeping.h \
    $(wildcard include/config/POSIX_AUX_CLOCKS) \
    $(wildcard include/config/GENERIC_CMOS_UPDATE) \
  /tmp/kernel-mainline/include/linux/clocksource_ids.h \
  /tmp/kernel-mainline/include/linux/debugobjects.h \
    $(wildcard include/config/DEBUG_OBJECTS) \
    $(wildcard include/config/DEBUG_OBJECTS_FREE) \
  /tmp/kernel-mainline/arch/arm64/include/asm/uprobes.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/debug-monitors.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/esr.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/probes.h \
    $(wildcard include/config/KPROBES) \
  /tmp/kernel-mainline/include/linux/workqueue.h \
    $(wildcard include/config/DEBUG_OBJECTS_WORK) \
    $(wildcard include/config/FREEZER) \
    $(wildcard include/config/WQ_WATCHDOG) \
  /tmp/kernel-mainline/include/linux/percpu_counter.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/mmu.h \
    $(wildcard include/config/ARM64_E0PD) \
  /tmp/kernel-mainline/include/linux/page-flags.h \
    $(wildcard include/config/PAGE_IDLE_FLAG) \
    $(wildcard include/config/ARCH_USES_PG_ARCH_2) \
    $(wildcard include/config/ARCH_USES_PG_ARCH_3) \
    $(wildcard include/config/MIGRATION) \
    $(wildcard include/config/DEBUG_KMAP_LOCAL_FORCE_MAP) \
  /tmp/kernel-mainline/include/linux/local_lock.h \
  /tmp/kernel-mainline/include/linux/local_lock_internal.h \
  /tmp/kernel-mainline/include/linux/zswap.h \
    $(wildcard include/config/ZSWAP) \
  /tmp/kernel-mainline/include/linux/memory_hotplug.h \
    $(wildcard include/config/ARCH_HAS_ADD_PAGES) \
    $(wildcard include/config/MEMORY_HOTREMOVE) \
  /tmp/kernel-mainline/include/linux/notifier.h \
    $(wildcard include/config/TREE_SRCU) \
  /tmp/kernel-mainline/include/linux/srcu.h \
    $(wildcard include/config/TINY_SRCU) \
    $(wildcard include/config/NEED_SRCU_NMI_SAFE) \
  /tmp/kernel-mainline/include/linux/rcu_segcblist.h \
  /tmp/kernel-mainline/include/linux/srcutree.h \
  /tmp/kernel-mainline/include/linux/rcu_node_tree.h \
    $(wildcard include/config/RCU_FANOUT) \
    $(wildcard include/config/RCU_FANOUT_LEAF) \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/mmzone.h \
  /tmp/kernel-mainline/include/asm-generic/mmzone.h \
  /tmp/kernel-mainline/include/linux/topology.h \
    $(wildcard include/config/USE_PERCPU_NUMA_NODE_ID) \
    $(wildcard include/config/SCHED_SMT) \
    $(wildcard include/config/GENERIC_ARCH_TOPOLOGY) \
  /tmp/kernel-mainline/include/linux/arch_topology.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/topology.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/numa.h \
  /tmp/kernel-mainline/include/asm-generic/numa.h \
    $(wildcard include/config/NUMA_EMU) \
  /tmp/kernel-mainline/include/asm-generic/topology.h \
  /tmp/kernel-mainline/include/linux/sched/mm.h \
    $(wildcard include/config/MMU_LAZY_TLB_REFCOUNT) \
    $(wildcard include/config/ARCH_HAS_MEMBARRIER_CALLBACKS) \
    $(wildcard include/config/ARCH_HAS_SYNC_CORE_BEFORE_USERMODE) \
  /tmp/kernel-mainline/include/linux/sync_core.h \
    $(wildcard include/config/ARCH_HAS_PREPARE_SYNC_CORE_CMD) \
  /tmp/kernel-mainline/include/linux/sched/coredump.h \
  /tmp/kernel-mainline/include/linux/uidgid.h \
    $(wildcard include/config/MULTIUSER) \
    $(wildcard include/config/USER_NS) \
  /tmp/kernel-mainline/include/linux/highuid.h \
  /tmp/kernel-mainline/include/linux/kobject_ns.h \
  /tmp/kernel-mainline/include/linux/stat.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/stat.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/uapi/asm/stat.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/stat.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/compat.h \
  /tmp/kernel-mainline/include/asm-generic/compat.h \
    $(wildcard include/config/COMPAT_FOR_U64_ALIGNMENT) \
  /tmp/kernel-mainline/include/linux/sched/task_stack.h \
    $(wildcard include/config/STACK_GROWSUP) \
    $(wildcard include/config/DEBUG_STACK_USAGE) \
  /tmp/kernel-mainline/include/uapi/linux/magic.h \
  /tmp/kernel-mainline/include/linux/kasan.h \
    $(wildcard include/config/KASAN_STACK) \
    $(wildcard include/config/KASAN_VMALLOC) \
  /tmp/kernel-mainline/include/uapi/linux/stat.h \
  /tmp/kernel-mainline/include/linux/sched/cpufreq.h \
    $(wildcard include/config/CPU_FREQ) \
  /tmp/kernel-mainline/include/linux/sched/topology.h \
    $(wildcard include/config/SCHED_CLUSTER) \
    $(wildcard include/config/SCHED_MC) \
    $(wildcard include/config/CPU_FREQ_GOV_SCHEDUTIL) \
  /tmp/kernel-mainline/include/linux/sched/idle.h \
  /tmp/kernel-mainline/include/linux/sched/sd_flags.h \
  /tmp/kernel-mainline/include/linux/ioport.h \
  /tmp/kernel-mainline/include/linux/klist.h \
  /tmp/kernel-mainline/include/linux/pm.h \
    $(wildcard include/config/VT_CONSOLE_SLEEP) \
    $(wildcard include/config/CXL_SUSPEND) \
    $(wildcard include/config/PM_CLK) \
    $(wildcard include/config/PM_GENERIC_DOMAINS) \
  /tmp/kernel-mainline/include/linux/device/bus.h \
    $(wildcard include/config/ACPI) \
  /tmp/kernel-mainline/include/linux/device/class.h \
  /tmp/kernel-mainline/include/linux/device/devres.h \
    $(wildcard include/config/HAS_IOMEM) \
  /tmp/kernel-mainline/include/linux/device/driver.h \
  /tmp/kernel-mainline/include/linux/module.h \
    $(wildcard include/config/MODULES_TREE_LOOKUP) \
    $(wildcard include/config/STACKTRACE_BUILD_ID) \
    $(wildcard include/config/ARCH_USES_CFI_TRAPS) \
    $(wildcard include/config/MODULE_SIG) \
    $(wildcard include/config/KALLSYMS) \
    $(wildcard include/config/BPF_EVENTS) \
    $(wildcard include/config/DEBUG_INFO_BTF_MODULES) \
    $(wildcard include/config/EVENT_TRACING) \
    $(wildcard include/config/MODULE_UNLOAD) \
    $(wildcard include/config/CONSTRUCTORS) \
    $(wildcard include/config/FUNCTION_ERROR_INJECTION) \
    $(wildcard include/config/MITIGATION_RETPOLINE) \
  /tmp/kernel-mainline/include/linux/buildid.h \
    $(wildcard include/config/VMCORE_INFO) \
  /tmp/kernel-mainline/include/linux/kmod.h \
  /tmp/kernel-mainline/include/linux/umh.h \
  /tmp/kernel-mainline/include/linux/sysctl.h \
    $(wildcard include/config/SYSCTL) \
  /tmp/kernel-mainline/include/uapi/linux/sysctl.h \
  /tmp/kernel-mainline/include/linux/elf.h \
    $(wildcard include/config/ARCH_HAVE_EXTRA_ELF_NOTES) \
    $(wildcard include/config/ARCH_USE_GNU_PROPERTY) \
    $(wildcard include/config/ARCH_HAVE_ELF_PROT) \
  /tmp/kernel-mainline/arch/arm64/include/asm/elf.h \
    $(wildcard include/config/COMPAT_VDSO) \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/user.h \
  /tmp/kernel-mainline/include/asm-generic/user.h \
  /tmp/kernel-mainline/include/uapi/linux/elf.h \
  /tmp/kernel-mainline/include/uapi/linux/elf-em.h \
  /tmp/kernel-mainline/include/linux/fs.h \
    $(wildcard include/config/FANOTIFY_ACCESS_PERMISSIONS) \
    $(wildcard include/config/FS_POSIX_ACL) \
    $(wildcard include/config/CGROUP_WRITEBACK) \
    $(wildcard include/config/IMA) \
    $(wildcard include/config/FILE_LOCKING) \
    $(wildcard include/config/FSNOTIFY) \
    $(wildcard include/config/EPOLL) \
    $(wildcard include/config/FS_DAX) \
    $(wildcard include/config/BLOCK) \
    $(wildcard include/config/UNICODE) \
  /tmp/kernel-mainline/include/linux/fs/super.h \
  /tmp/kernel-mainline/include/linux/fs/super_types.h \
    $(wildcard include/config/QUOTA) \
    $(wildcard include/config/FS_ENCRYPTION) \
    $(wildcard include/config/FS_VERITY) \
  /tmp/kernel-mainline/include/linux/fs_dirent.h \
  /tmp/kernel-mainline/include/linux/errseq.h \
  /tmp/kernel-mainline/include/linux/list_lru.h \
  /tmp/kernel-mainline/include/linux/shrinker.h \
    $(wildcard include/config/SHRINKER_DEBUG) \
  /tmp/kernel-mainline/include/linux/list_bl.h \
  /tmp/kernel-mainline/include/linux/bit_spinlock.h \
  /tmp/kernel-mainline/include/linux/percpu-rwsem.h \
  /tmp/kernel-mainline/include/linux/rcuwait.h \
  /tmp/kernel-mainline/include/linux/sched/signal.h \
    $(wildcard include/config/SCHED_AUTOGROUP) \
    $(wildcard include/config/BSD_PROCESS_ACCT) \
    $(wildcard include/config/TASKSTATS) \
  /tmp/kernel-mainline/include/linux/rculist.h \
    $(wildcard include/config/PROVE_RCU_LIST) \
  /tmp/kernel-mainline/include/linux/signal.h \
    $(wildcard include/config/DYNAMIC_SIGFRAME) \
    $(wildcard include/config/PROC_FS) \
  /tmp/kernel-mainline/include/linux/sched/jobctl.h \
  /tmp/kernel-mainline/include/linux/sched/task.h \
    $(wildcard include/config/HAVE_EXIT_THREAD) \
    $(wildcard include/config/ARCH_WANTS_DYNAMIC_TASK_STRUCT) \
    $(wildcard include/config/HAVE_ARCH_THREAD_STRUCT_WHITELIST) \
  /tmp/kernel-mainline/include/linux/uaccess.h \
    $(wildcard include/config/ARCH_HAS_SUBPAGE_FAULTS) \
    $(wildcard include/config/ARCH_MEMORY_ORDER_TSO) \
    $(wildcard include/config/HARDENED_USERCOPY) \
  /tmp/kernel-mainline/include/linux/fault-inject-usercopy.h \
    $(wildcard include/config/FAULT_INJECTION_USERCOPY) \
  /tmp/kernel-mainline/include/linux/nospec.h \
  /tmp/kernel-mainline/include/linux/ucopysize.h \
    $(wildcard include/config/HARDENED_USERCOPY_DEFAULT_ON) \
  /tmp/kernel-mainline/arch/arm64/include/asm/uaccess.h \
    $(wildcard include/config/CC_HAS_ASM_GOTO_OUTPUT) \
  /tmp/kernel-mainline/arch/arm64/include/asm/kernel-pgtable.h \
    $(wildcard include/config/RELOCATABLE) \
  /tmp/kernel-mainline/arch/arm64/include/asm/asm-extable.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/mte.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/extable.h \
    $(wildcard include/config/BPF_JIT) \
  /tmp/kernel-mainline/include/asm-generic/access_ok.h \
    $(wildcard include/config/ALTERNATE_USER_ADDRESS_SPACE) \
  /tmp/kernel-mainline/include/linux/cred.h \
  /tmp/kernel-mainline/include/linux/capability.h \
  /tmp/kernel-mainline/include/uapi/linux/capability.h \
  /tmp/kernel-mainline/include/linux/key.h \
    $(wildcard include/config/KEY_NOTIFICATIONS) \
    $(wildcard include/config/NET) \
  /tmp/kernel-mainline/include/linux/assoc_array.h \
    $(wildcard include/config/ASSOCIATIVE_ARRAY) \
  /tmp/kernel-mainline/include/linux/sched/user.h \
    $(wildcard include/config/VFIO_PCI_ZDEV_KVM) \
    $(wildcard include/config/IOMMUFD) \
    $(wildcard include/config/WATCH_QUEUE) \
  /tmp/kernel-mainline/include/linux/pid.h \
  /tmp/kernel-mainline/include/linux/rhashtable-types.h \
  /tmp/kernel-mainline/include/linux/posix-timers.h \
  /tmp/kernel-mainline/include/linux/alarmtimer.h \
    $(wildcard include/config/RTC_CLASS) \
  /tmp/kernel-mainline/include/linux/hrtimer.h \
    $(wildcard include/config/HIGH_RES_TIMERS) \
    $(wildcard include/config/TIME_LOW_RES) \
    $(wildcard include/config/TIMERFD) \
  /tmp/kernel-mainline/include/linux/hrtimer_defs.h \
  /tmp/kernel-mainline/include/linux/timerqueue.h \
  /tmp/kernel-mainline/include/linux/hrtimer_rearm.h \
    $(wildcard include/config/HRTIMER_REARM_DEFERRED) \
  /tmp/kernel-mainline/include/linux/rcuref.h \
  /tmp/kernel-mainline/include/linux/rcu_sync.h \
  /tmp/kernel-mainline/include/linux/quota.h \
    $(wildcard include/config/QUOTA_NETLINK_INTERFACE) \
  /tmp/kernel-mainline/include/uapi/linux/dqblk_xfs.h \
  /tmp/kernel-mainline/include/linux/dqblk_v1.h \
  /tmp/kernel-mainline/include/linux/dqblk_v2.h \
  /tmp/kernel-mainline/include/linux/dqblk_qtree.h \
  /tmp/kernel-mainline/include/linux/projid.h \
  /tmp/kernel-mainline/include/uapi/linux/quota.h \
  /tmp/kernel-mainline/include/linux/unicode.h \
  /tmp/kernel-mainline/include/linux/dcache.h \
  /tmp/kernel-mainline/include/linux/rculist_bl.h \
  /tmp/kernel-mainline/include/linux/lockref.h \
    $(wildcard include/config/ARCH_USE_CMPXCHG_LOCKREF) \
  /tmp/kernel-mainline/include/linux/stringhash.h \
    $(wildcard include/config/DCACHE_WORD_ACCESS) \
  /tmp/kernel-mainline/include/linux/hash.h \
    $(wildcard include/config/HAVE_ARCH_HASH) \
  /tmp/kernel-mainline/include/linux/vfsdebug.h \
    $(wildcard include/config/DEBUG_VFS) \
  /tmp/kernel-mainline/include/linux/wait_bit.h \
  /tmp/kernel-mainline/include/linux/kdev_t.h \
  /tmp/kernel-mainline/include/uapi/linux/kdev_t.h \
  /tmp/kernel-mainline/include/linux/path.h \
  /tmp/kernel-mainline/include/linux/semaphore.h \
  /tmp/kernel-mainline/include/linux/fcntl.h \
    $(wildcard include/config/ARCH_32BIT_OFF_T) \
  /tmp/kernel-mainline/include/uapi/linux/fcntl.h \
  /tmp/kernel-mainline/arch/arm64/include/uapi/asm/fcntl.h \
  /tmp/kernel-mainline/include/uapi/asm-generic/fcntl.h \
  /tmp/kernel-mainline/include/uapi/linux/openat2.h \
  /tmp/kernel-mainline/include/linux/migrate_mode.h \
  /tmp/kernel-mainline/include/linux/delayed_call.h \
  /tmp/kernel-mainline/include/linux/ioprio.h \
  /tmp/kernel-mainline/include/linux/sched/rt.h \
  /tmp/kernel-mainline/include/linux/iocontext.h \
    $(wildcard include/config/BLK_ICQ) \
  /tmp/kernel-mainline/include/uapi/linux/ioprio.h \
  /tmp/kernel-mainline/include/linux/mount.h \
  /tmp/kernel-mainline/include/linux/mnt_idmapping.h \
  /tmp/kernel-mainline/include/linux/slab.h \
    $(wildcard include/config/FAILSLAB) \
    $(wildcard include/config/KFENCE) \
    $(wildcard include/config/SLUB_TINY) \
    $(wildcard include/config/SLUB_DEBUG) \
    $(wildcard include/config/KMALLOC_PARTITION_RANDOM) \
    $(wildcard include/config/KMALLOC_PARTITION_TYPED) \
    $(wildcard include/config/SLAB_BUCKETS) \
    $(wildcard include/config/KVFREE_RCU_BATCHED) \
  /tmp/kernel-mainline/include/linux/percpu-refcount.h \
  /tmp/kernel-mainline/include/linux/rw_hint.h \
  /tmp/kernel-mainline/include/linux/file_ref.h \
  /tmp/kernel-mainline/include/uapi/linux/fs.h \
  /tmp/kernel-mainline/include/linux/moduleparam.h \
    $(wildcard include/config/ALPHA) \
    $(wildcard include/config/PPC64) \
  /tmp/kernel-mainline/include/linux/rbtree_latch.h \
  /tmp/kernel-mainline/include/linux/error-injection.h \
  /tmp/kernel-mainline/include/asm-generic/error-injection.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/module.h \
  /tmp/kernel-mainline/include/asm-generic/module.h \
    $(wildcard include/config/HAVE_MOD_ARCH_SPECIFIC) \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/device.h \
  /tmp/kernel-mainline/include/asm-generic/device.h \
  /tmp/kernel-mainline/include/linux/pm_wakeup.h \
  /tmp/kernel-mainline/include/linux/of.h \
    $(wildcard include/config/OF_DYNAMIC) \
    $(wildcard include/config/SPARC) \
    $(wildcard include/config/OF_PROMTREE) \
    $(wildcard include/config/OF_KOBJ) \
    $(wildcard include/config/OF_NUMA) \
    $(wildcard include/config/OF_OVERLAY) \
  /tmp/kernel-mainline/include/linux/mod_devicetable.h \
  /tmp/kernel-mainline/include/uapi/linux/mei.h \
  /tmp/kernel-mainline/include/uapi/linux/mei_uuid.h \
  /tmp/kernel-mainline/include/linux/property.h \
  /tmp/kernel-mainline/include/linux/fwnode.h \
  /tmp/kernel-mainline/include/linux/nvmem-provider.h \
    $(wildcard include/config/NVMEM) \
  /tmp/kernel-mainline/include/linux/gpio/consumer.h \
    $(wildcard include/config/GPIOLIB) \
    $(wildcard include/config/HTE) \
    $(wildcard include/config/GPIO_SYSFS) \
  /tmp/kernel-mainline/include/linux/gpio/defs.h \
  /tmp/kernel-mainline/include/linux/platform_device.h \
    $(wildcard include/config/SUSPEND) \
    $(wildcard include/config/HIBERNATE_CALLBACKS) \
    $(wildcard include/config/SUPERH) \
  /tmp/kernel-mainline/include/linux/regmap.h \
    $(wildcard include/config/REGMAP) \
  /tmp/kernel-mainline/include/linux/delay.h \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/delay.h \
  /tmp/kernel-mainline/include/asm-generic/delay.h \
  /tmp/kernel-mainline/include/linux/iopoll.h \
  /tmp/kernel-mainline/include/linux/io.h \
    $(wildcard include/config/HAS_IOPORT_MAP) \
    $(wildcard include/config/PCI) \
    $(wildcard include/config/STRICT_DEVMEM) \
  /tmp/kernel-mainline/arch/arm64/include/asm/io.h \
  /tmp/kernel-mainline/include/linux/pgtable.h \
    $(wildcard include/config/HIGHPTE) \
    $(wildcard include/config/ARCH_HAS_NONLEAF_PMD_YOUNG) \
    $(wildcard include/config/ARCH_HAS_HW_PTE_YOUNG) \
    $(wildcard include/config/GUP_GET_PXX_LOW_HIGH) \
    $(wildcard include/config/ARCH_WANT_PMD_MKWRITE) \
    $(wildcard include/config/HAVE_ARCH_TRANSPARENT_HUGEPAGE_PUD) \
    $(wildcard include/config/MEM_SOFT_DIRTY) \
    $(wildcard include/config/HAVE_ARCH_SOFT_DIRTY) \
    $(wildcard include/config/ARCH_ENABLE_THP_MIGRATION) \
    $(wildcard include/config/HAVE_ARCH_HUGE_VMAP) \
    $(wildcard include/config/X86_ESPFIX64) \
  /tmp/kernel-mainline/arch/arm64/include/asm/pgtable.h \
    $(wildcard include/config/ARCH_SUPPORTS_PMD_PFNMAP) \
    $(wildcard include/config/PAGE_TABLE_CHECK) \
    $(wildcard include/config/ARM64_CONTPTE) \
  /tmp/kernel-mainline/arch/arm64/include/asm/proc-fns.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/tlbflush.h \
  /tmp/kernel-mainline/include/linux/mmu_notifier.h \
  /tmp/kernel-mainline/include/linux/mmap_lock.h \
  /tmp/kernel-mainline/include/linux/interval_tree.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/fixmap.h \
    $(wildcard include/config/ACPI_APEI_GHES) \
    $(wildcard include/config/ARM_SDE_INTERFACE) \
  /tmp/kernel-mainline/include/asm-generic/fixmap.h \
  /tmp/kernel-mainline/arch/arm64/include/asm/por.h \
  /tmp/kernel-mainline/include/linux/page_table_check.h \
  /tmp/kernel-mainline/include/asm-generic/pgtable_uffd.h \
    $(wildcard include/config/PTE_MARKER_UFFD_WP) \
  /tmp/kernel-mainline/arch/arm64/include/generated/asm/early_ioremap.h \
  /tmp/kernel-mainline/include/asm-generic/early_ioremap.h \
    $(wildcard include/config/GENERIC_EARLY_IOREMAP) \
  /tmp/kernel-mainline/include/asm-generic/io.h \
    $(wildcard include/config/GENERIC_IOMAP) \
    $(wildcard include/config/TRACE_MMIO_ACCESS) \
    $(wildcard include/config/HAS_IOPORT) \
    $(wildcard include/config/GENERIC_IOREMAP) \
  /tmp/kernel-mainline/include/asm-generic/pci_iomap.h \
    $(wildcard include/config/NO_GENERIC_PCI_IOPORT_MAP) \
    $(wildcard include/config/GENERIC_PCI_IOMAP) \
  /tmp/kernel-mainline/include/linux/logic_pio.h \
    $(wildcard include/config/INDIRECT_PIO) \

qcom-spmi-sdam.o: $(deps_qcom-spmi-sdam.o)

$(deps_qcom-spmi-sdam.o):
