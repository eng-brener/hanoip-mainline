savedcmd_camss-format.o := aarch64-linux-gnu-gcc -Wp,-MMD,./.camss-format.o.d -nostdinc -I/src/linux/arch/arm64/include -I/src/obj/arch/arm64/include/generated -I/src/linux/include -I/src/obj/include -I/src/linux/arch/arm64/include/uapi -I/src/obj/arch/arm64/include/generated/uapi -I/src/linux/include/uapi -I/src/obj/include/generated/uapi -include /src/linux/include/linux/compiler-version.h -include /src/linux/include/linux/kconfig.h -include /src/linux/include/linux/compiler_types.h -D__KERNEL__ -mlittle-endian -DCC_USING_PATCHABLE_FUNCTION_ENTRY -DKASAN_SHADOW_SCALE_SHIFT= -fshort-wchar -funsigned-char -fno-common -fno-PIE -fno-strict-aliasing -std=gnu11 -fms-extensions -mgeneral-regs-only -DCONFIG_CC_HAS_K_CONSTRAINT=1 -Wno-psabi -mabi=lp64 -fno-asynchronous-unwind-tables -fno-unwind-tables -mbranch-protection=none -Wa,-march=armv8.5-a -DARM64_ASM_ARCH='"armv8.5-a"' -ffixed-x18 -DKASAN_SHADOW_SCALE_SHIFT= -fno-delete-null-pointer-checks -O2 -fno-allow-store-data-races -fstack-protector-strong -fno-omit-frame-pointer -fno-optimize-sibling-calls -ftrivial-auto-var-init=zero -fno-stack-clash-protection -fpatchable-function-entry=4,2 -fsanitize=shadow-call-stack -falign-functions=8 -fstrict-flex-arrays=3 -fno-strict-overflow -fno-stack-check -fconserve-stack -fno-builtin-wcslen -Wall -Wextra -Wundef -Werror=implicit-function-declaration -Werror=implicit-int -Werror=return-type -Werror=strict-prototypes -Wno-format-security -Wno-trigraphs -Wno-frame-address -Wno-address-of-packed-member -Wmissing-declarations -Wmissing-prototypes -Wframe-larger-than=2048 -Wno-main -Wno-type-limits -Wno-dangling-pointer -Wvla-larger-than=1 -Wno-pointer-sign -Wcast-function-type -Wno-array-bounds -Wno-stringop-overflow -Wno-alloc-size-larger-than -Wimplicit-fallthrough=5 -Werror=date-time -Werror=incompatible-pointer-types -Werror=designated-init -Wenum-conversion -Wunused -Wno-unused-but-set-variable -Wno-unused-const-variable -Wno-packed-not-aligned -Wno-format-overflow -Wno-format-truncation -Wno-stringop-truncation -Wno-override-init -Wno-missing-field-initializers -Wno-shift-negative-value -Wno-maybe-uninitialized -Wno-sign-compare -Wno-unused-parameter -g -fno-var-tracking -femit-struct-debug-baseonly -mstack-protector-guard=sysreg -mstack-protector-guard-reg=sp_el0 -mstack-protector-guard-offset=1344  -DMODULE  -DKBUILD_BASENAME='"camss_format"' -DKBUILD_MODNAME='"qcom_camss"' -D__KBUILD_MODNAME=qcom_camss -c -o camss-format.o camss-format.c  

source_camss-format.o := camss-format.c

deps_camss-format.o := \
  /src/linux/include/linux/compiler-version.h \
    $(wildcard include/config/CC_VERSION_TEXT) \
  /src/linux/include/linux/kconfig.h \
    $(wildcard include/config/CPU_BIG_ENDIAN) \
    $(wildcard include/config/BOOGER) \
    $(wildcard include/config/FOO) \
  /src/linux/include/linux/compiler_types.h \
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
  /src/linux/include/linux/compiler-context-analysis.h \
  /src/linux/include/linux/compiler_attributes.h \
  /src/linux/include/linux/compiler-gcc.h \
    $(wildcard include/config/ARCH_USE_BUILTIN_BSWAP) \
    $(wildcard include/config/SHADOW_CALL_STACK) \
    $(wildcard include/config/KCOV) \
    $(wildcard include/config/CC_HAS_TYPEOF_UNQUAL) \
  /src/linux/arch/arm64/include/asm/compiler.h \
    $(wildcard include/config/ARM64_PTR_AUTH_KERNEL) \
    $(wildcard include/config/ARM64_PTR_AUTH) \
    $(wildcard include/config/BUILTIN_RETURN_ADDRESS_STRIPS_PAC) \
  /src/obj/arch/arm64/include/generated/asm/percpu_types.h \
  /src/linux/include/asm-generic/percpu_types.h \
  /src/linux/include/linux/bits.h \
  /src/linux/include/vdso/bits.h \
  /src/linux/include/vdso/const.h \
  /src/linux/include/uapi/linux/const.h \
  /src/linux/include/uapi/linux/bits.h \
  /src/linux/include/linux/build_bug.h \
  /src/linux/include/linux/compiler.h \
    $(wildcard include/config/TRACE_BRANCH_PROFILING) \
    $(wildcard include/config/PROFILE_ALL_BRANCHES) \
    $(wildcard include/config/OBJTOOL) \
  /src/linux/arch/arm64/include/asm/rwonce.h \
    $(wildcard include/config/LTO) \
  /src/linux/include/asm-generic/rwonce.h \
  /src/linux/include/linux/kasan-checks.h \
    $(wildcard include/config/KASAN_GENERIC) \
    $(wildcard include/config/KASAN_SW_TAGS) \
  /src/linux/include/linux/types.h \
    $(wildcard include/config/HAVE_UID16) \
    $(wildcard include/config/UID16) \
    $(wildcard include/config/ARCH_DMA_ADDR_T_64BIT) \
    $(wildcard include/config/PHYS_ADDR_T_64BIT) \
    $(wildcard include/config/64BIT) \
    $(wildcard include/config/ARCH_32BIT_USTAT_F_TINODE) \
    $(wildcard include/config/KVFREE_RCU_BATCHED) \
  /src/linux/include/uapi/linux/types.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/types.h \
  /src/linux/include/uapi/asm-generic/types.h \
  /src/linux/include/asm-generic/int-ll64.h \
  /src/linux/include/uapi/asm-generic/int-ll64.h \
  /src/linux/arch/arm64/include/uapi/asm/bitsperlong.h \
  /src/linux/include/asm-generic/bitsperlong.h \
  /src/linux/include/uapi/asm-generic/bitsperlong.h \
  /src/linux/include/uapi/linux/posix_types.h \
  /src/linux/include/linux/stddef.h \
  /src/linux/include/uapi/linux/stddef.h \
  /src/linux/arch/arm64/include/uapi/asm/posix_types.h \
  /src/linux/include/uapi/asm-generic/posix_types.h \
  /src/linux/include/linux/kcsan-checks.h \
    $(wildcard include/config/KCSAN_WEAK_MEMORY) \
    $(wildcard include/config/KCSAN_IGNORE_ATOMICS) \
  /src/linux/include/linux/overflow.h \
  /src/linux/include/linux/limits.h \
  /src/linux/include/uapi/linux/limits.h \
  /src/linux/include/vdso/limits.h \
  /src/linux/include/linux/const.h \
  /src/linux/include/linux/bug.h \
    $(wildcard include/config/GENERIC_BUG) \
    $(wildcard include/config/PRINTK) \
    $(wildcard include/config/BUG_ON_DATA_CORRUPTION) \
  /src/linux/arch/arm64/include/asm/bug.h \
  /src/linux/include/linux/stringify.h \
  /src/linux/arch/arm64/include/asm/asm-bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE) \
  /src/linux/arch/arm64/include/asm/brk-imm.h \
  /src/linux/include/asm-generic/bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE_DETAILED) \
    $(wildcard include/config/BUG) \
    $(wildcard include/config/GENERIC_BUG_RELATIVE_POINTERS) \
    $(wildcard include/config/SMP) \
  /src/linux/include/linux/instrumentation.h \
    $(wildcard include/config/NOINSTR_VALIDATION) \
  /src/linux/include/linux/once_lite.h \
  /src/linux/include/linux/panic.h \
    $(wildcard include/config/PANIC_TIMEOUT) \
  /src/linux/include/linux/stdarg.h \
  /src/linux/include/linux/printk.h \
    $(wildcard include/config/MESSAGE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_QUIET) \
    $(wildcard include/config/EARLY_PRINTK) \
    $(wildcard include/config/PRINTK_INDEX) \
    $(wildcard include/config/DYNAMIC_DEBUG) \
    $(wildcard include/config/DYNAMIC_DEBUG_CORE) \
  /src/linux/include/linux/init.h \
    $(wildcard include/config/MEMORY_HOTPLUG) \
    $(wildcard include/config/HAVE_ARCH_PREL32_RELOCATIONS) \
  /src/linux/include/linux/kern_levels.h \
  /src/linux/include/linux/linkage.h \
    $(wildcard include/config/ARCH_USE_SYM_ANNOTATIONS) \
  /src/linux/include/linux/export.h \
    $(wildcard include/config/MODVERSIONS) \
    $(wildcard include/config/GENDWARFKSYMS) \
  /src/linux/arch/arm64/include/asm/linkage.h \
  /src/linux/include/linux/ratelimit_types.h \
  /src/linux/include/uapi/linux/param.h \
  /src/linux/arch/arm64/include/uapi/asm/param.h \
  /src/linux/include/asm-generic/param.h \
    $(wildcard include/config/HZ) \
  /src/linux/include/uapi/asm-generic/param.h \
  /src/linux/include/linux/spinlock_types_raw.h \
    $(wildcard include/config/DEBUG_SPINLOCK) \
    $(wildcard include/config/DEBUG_LOCK_ALLOC) \
  /src/linux/arch/arm64/include/asm/spinlock_types.h \
  /src/linux/include/asm-generic/qspinlock_types.h \
    $(wildcard include/config/NR_CPUS) \
  /src/linux/include/asm-generic/qrwlock_types.h \
  /src/linux/arch/arm64/include/uapi/asm/byteorder.h \
  /src/linux/include/linux/byteorder/little_endian.h \
  /src/linux/include/uapi/linux/byteorder/little_endian.h \
  /src/linux/include/linux/swab.h \
  /src/linux/include/uapi/linux/swab.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/swab.h \
  /src/linux/include/uapi/asm-generic/swab.h \
  /src/linux/include/linux/byteorder/generic.h \
  /src/linux/include/linux/lockdep_types.h \
    $(wildcard include/config/PROVE_RAW_LOCK_NESTING) \
    $(wildcard include/config/LOCKDEP) \
    $(wildcard include/config/LOCK_STAT) \
  /src/linux/include/linux/dynamic_debug.h \
    $(wildcard include/config/JUMP_LABEL) \
  /src/linux/include/linux/jump_label.h \
    $(wildcard include/config/HAVE_ARCH_JUMP_LABEL_RELATIVE) \
  /src/linux/include/linux/cleanup.h \
  /src/linux/include/linux/err.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/errno.h \
  /src/linux/include/uapi/asm-generic/errno.h \
  /src/linux/include/uapi/asm-generic/errno-base.h \
  /src/linux/include/linux/args.h \
  /src/linux/arch/arm64/include/asm/jump_label.h \
  /src/linux/arch/arm64/include/asm/insn.h \
  /src/linux/arch/arm64/include/asm/insn-def.h \
  /src/linux/include/linux/errno.h \
  /src/linux/include/uapi/linux/errno.h \
  /src/linux/include/linux/lcm.h \
  camss-format.h \

camss-format.o: $(deps_camss-format.o)

$(deps_camss-format.o):
