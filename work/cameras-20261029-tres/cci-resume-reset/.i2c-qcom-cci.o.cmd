savedcmd_i2c-qcom-cci.o := aarch64-linux-gnu-gcc -Wp,-MMD,./.i2c-qcom-cci.o.d -nostdinc -I/src/linux/arch/arm64/include -I/src/obj/arch/arm64/include/generated -I/src/linux/include -I/src/obj/include -I/src/linux/arch/arm64/include/uapi -I/src/obj/arch/arm64/include/generated/uapi -I/src/linux/include/uapi -I/src/obj/include/generated/uapi -include /src/linux/include/linux/compiler-version.h -include /src/linux/include/linux/kconfig.h -include /src/linux/include/linux/compiler_types.h -D__KERNEL__ -mlittle-endian -DCC_USING_PATCHABLE_FUNCTION_ENTRY -DKASAN_SHADOW_SCALE_SHIFT= -fshort-wchar -funsigned-char -fno-common -fno-PIE -fno-strict-aliasing -std=gnu11 -fms-extensions -mgeneral-regs-only -DCONFIG_CC_HAS_K_CONSTRAINT=1 -Wno-psabi -mabi=lp64 -fno-asynchronous-unwind-tables -fno-unwind-tables -mbranch-protection=none -Wa,-march=armv8.5-a -DARM64_ASM_ARCH='"armv8.5-a"' -ffixed-x18 -DKASAN_SHADOW_SCALE_SHIFT= -fno-delete-null-pointer-checks -O2 -fno-allow-store-data-races -fstack-protector-strong -fno-omit-frame-pointer -fno-optimize-sibling-calls -ftrivial-auto-var-init=zero -fno-stack-clash-protection -fpatchable-function-entry=4,2 -fsanitize=shadow-call-stack -falign-functions=8 -fstrict-flex-arrays=3 -fno-strict-overflow -fno-stack-check -fconserve-stack -fno-builtin-wcslen -Wall -Wextra -Wundef -Werror=implicit-function-declaration -Werror=implicit-int -Werror=return-type -Werror=strict-prototypes -Wno-format-security -Wno-trigraphs -Wno-frame-address -Wno-address-of-packed-member -Wmissing-declarations -Wmissing-prototypes -Wframe-larger-than=2048 -Wno-main -Wno-type-limits -Wno-dangling-pointer -Wvla-larger-than=1 -Wno-pointer-sign -Wcast-function-type -Wno-array-bounds -Wno-stringop-overflow -Wno-alloc-size-larger-than -Wimplicit-fallthrough=5 -Werror=date-time -Werror=incompatible-pointer-types -Werror=designated-init -Wenum-conversion -Wunused -Wno-unused-but-set-variable -Wno-unused-const-variable -Wno-packed-not-aligned -Wno-format-overflow -Wno-format-truncation -Wno-stringop-truncation -Wno-override-init -Wno-missing-field-initializers -Wno-shift-negative-value -Wno-maybe-uninitialized -Wno-sign-compare -Wno-unused-parameter -g -fno-var-tracking -femit-struct-debug-baseonly -mstack-protector-guard=sysreg -mstack-protector-guard-reg=sp_el0 -mstack-protector-guard-offset=1344  -DMODULE  -DKBUILD_BASENAME='"i2c_qcom_cci"' -DKBUILD_MODNAME='"i2c_qcom_cci"' -D__KBUILD_MODNAME=i2c_qcom_cci -c -o i2c-qcom-cci.o i2c-qcom-cci.c  

source_i2c-qcom-cci.o := i2c-qcom-cci.c

deps_i2c-qcom-cci.o := \
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
  /src/linux/include/linux/clk.h \
    $(wildcard include/config/COMMON_CLK) \
    $(wildcard include/config/HAVE_CLK_PREPARE) \
    $(wildcard include/config/HAVE_CLK) \
    $(wildcard include/config/OF) \
  /src/linux/include/linux/err.h \
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
  /src/obj/arch/arm64/include/generated/uapi/asm/errno.h \
  /src/linux/include/uapi/asm-generic/errno.h \
  /src/linux/include/uapi/asm-generic/errno-base.h \
  /src/linux/include/linux/kernel.h \
    $(wildcard include/config/PREEMPT_VOLUNTARY_BUILD) \
    $(wildcard include/config/PREEMPT_DYNAMIC) \
    $(wildcard include/config/HAVE_PREEMPT_DYNAMIC_CALL) \
    $(wildcard include/config/HAVE_PREEMPT_DYNAMIC_KEY) \
    $(wildcard include/config/PREEMPT_) \
    $(wildcard include/config/DEBUG_ATOMIC_SLEEP) \
    $(wildcard include/config/SMP) \
    $(wildcard include/config/MMU) \
    $(wildcard include/config/PROVE_LOCKING) \
    $(wildcard include/config/DYNAMIC_FTRACE) \
  /src/linux/include/linux/stdarg.h \
  /src/linux/include/linux/align.h \
  /src/linux/include/vdso/align.h \
  /src/linux/include/vdso/const.h \
  /src/linux/include/uapi/linux/const.h \
  /src/linux/include/linux/array_size.h \
  /src/linux/include/linux/limits.h \
  /src/linux/include/uapi/linux/limits.h \
  /src/linux/include/vdso/limits.h \
  /src/linux/include/linux/linkage.h \
    $(wildcard include/config/ARCH_USE_SYM_ANNOTATIONS) \
  /src/linux/include/linux/stringify.h \
  /src/linux/include/linux/export.h \
    $(wildcard include/config/MODVERSIONS) \
    $(wildcard include/config/GENDWARFKSYMS) \
  /src/linux/arch/arm64/include/asm/linkage.h \
  /src/linux/include/linux/container_of.h \
  /src/linux/include/linux/build_bug.h \
  /src/linux/include/linux/bitops.h \
  /src/linux/include/linux/bits.h \
  /src/linux/include/vdso/bits.h \
  /src/linux/include/uapi/linux/bits.h \
  /src/linux/include/linux/overflow.h \
  /src/linux/include/linux/const.h \
  /src/linux/include/linux/typecheck.h \
  /src/linux/include/uapi/linux/kernel.h \
  /src/linux/include/uapi/linux/sysinfo.h \
  /src/linux/include/asm-generic/bitops/generic-non-atomic.h \
  /src/linux/arch/arm64/include/asm/barrier.h \
    $(wildcard include/config/ARM64_PSEUDO_NMI) \
  /src/linux/arch/arm64/include/asm/alternative-macros.h \
  /src/linux/arch/arm64/include/asm/cpucaps.h \
    $(wildcard include/config/ARM64_EPAN) \
    $(wildcard include/config/ARM64_SVE) \
    $(wildcard include/config/ARM64_SME) \
    $(wildcard include/config/ARM64_CNP) \
    $(wildcard include/config/ARM64_MTE) \
    $(wildcard include/config/ARM64_BTI) \
    $(wildcard include/config/ARM64_TLB_RANGE) \
    $(wildcard include/config/ARM64_POE) \
    $(wildcard include/config/ARM64_GCS) \
    $(wildcard include/config/ARM64_HAFT) \
    $(wildcard include/config/UNMAP_KERNEL_AT_EL0) \
    $(wildcard include/config/ARM64_ERRATUM_843419) \
    $(wildcard include/config/ARM64_ERRATUM_1742098) \
    $(wildcard include/config/ARM64_ERRATUM_2645198) \
    $(wildcard include/config/ARM64_ERRATUM_2658417) \
    $(wildcard include/config/CAVIUM_ERRATUM_23154) \
    $(wildcard include/config/ARM64_WORKAROUND_DISABLE_CNP) \
    $(wildcard include/config/ARM64_WORKAROUND_REPEAT_TLBI_SYNC) \
    $(wildcard include/config/ARM64_ERRATUM_3194386) \
    $(wildcard include/config/ARM64_ERRATUM_4193714) \
    $(wildcard include/config/HW_PERF_EVENTS) \
    $(wildcard include/config/ARM64_LSUI) \
  /src/obj/arch/arm64/include/generated/asm/cpucap-defs.h \
  /src/linux/arch/arm64/include/asm/insn-def.h \
  /src/linux/arch/arm64/include/asm/brk-imm.h \
  /src/linux/include/asm-generic/barrier.h \
  /src/linux/arch/arm64/include/asm/bitops.h \
  /src/linux/include/asm-generic/bitops/builtin-__ffs.h \
  /src/linux/include/asm-generic/bitops/builtin-ffs.h \
  /src/linux/include/asm-generic/bitops/builtin-__fls.h \
  /src/linux/include/asm-generic/bitops/builtin-fls.h \
  /src/linux/include/asm-generic/bitops/ffz.h \
  /src/linux/include/asm-generic/bitops/fls64.h \
  /src/linux/include/asm-generic/bitops/sched.h \
  /src/linux/include/asm-generic/bitops/hweight.h \
  /src/linux/include/asm-generic/bitops/arch_hweight.h \
  /src/linux/include/asm-generic/bitops/const_hweight.h \
  /src/linux/include/asm-generic/bitops/atomic.h \
  /src/linux/include/linux/atomic.h \
  /src/linux/arch/arm64/include/asm/atomic.h \
  /src/linux/arch/arm64/include/asm/cmpxchg.h \
  /src/linux/arch/arm64/include/asm/lse.h \
  /src/linux/arch/arm64/include/asm/atomic_ll_sc.h \
    $(wildcard include/config/CC_HAS_K_CONSTRAINT) \
  /src/linux/arch/arm64/include/asm/alternative.h \
    $(wildcard include/config/MODULES) \
  /src/linux/include/linux/init.h \
    $(wildcard include/config/MEMORY_HOTPLUG) \
    $(wildcard include/config/HAVE_ARCH_PREL32_RELOCATIONS) \
  /src/linux/arch/arm64/include/asm/atomic_lse.h \
  /src/linux/include/linux/atomic/atomic-arch-fallback.h \
    $(wildcard include/config/GENERIC_ATOMIC64) \
  /src/linux/include/linux/atomic/atomic-long.h \
  /src/linux/include/linux/atomic/atomic-instrumented.h \
  /src/linux/include/linux/instrumented.h \
    $(wildcard include/config/DEBUG_ATOMIC) \
    $(wildcard include/config/DEBUG_ATOMIC_LARGEST_ALIGN) \
  /src/linux/include/linux/bug.h \
    $(wildcard include/config/GENERIC_BUG) \
    $(wildcard include/config/PRINTK) \
    $(wildcard include/config/BUG_ON_DATA_CORRUPTION) \
  /src/linux/arch/arm64/include/asm/bug.h \
  /src/linux/arch/arm64/include/asm/asm-bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE) \
  /src/linux/include/asm-generic/bug.h \
    $(wildcard include/config/DEBUG_BUGVERBOSE_DETAILED) \
    $(wildcard include/config/BUG) \
    $(wildcard include/config/GENERIC_BUG_RELATIVE_POINTERS) \
  /src/linux/include/linux/instrumentation.h \
    $(wildcard include/config/NOINSTR_VALIDATION) \
  /src/linux/include/linux/once_lite.h \
  /src/linux/include/linux/panic.h \
    $(wildcard include/config/PANIC_TIMEOUT) \
  /src/linux/include/linux/printk.h \
    $(wildcard include/config/MESSAGE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_DEFAULT) \
    $(wildcard include/config/CONSOLE_LOGLEVEL_QUIET) \
    $(wildcard include/config/EARLY_PRINTK) \
    $(wildcard include/config/PRINTK_INDEX) \
    $(wildcard include/config/DYNAMIC_DEBUG) \
    $(wildcard include/config/DYNAMIC_DEBUG_CORE) \
  /src/linux/include/linux/kern_levels.h \
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
  /src/linux/include/linux/args.h \
  /src/linux/arch/arm64/include/asm/jump_label.h \
  /src/linux/arch/arm64/include/asm/insn.h \
  /src/linux/include/linux/kmsan-checks.h \
    $(wildcard include/config/KMSAN) \
  /src/linux/include/asm-generic/bitops/instrumented-atomic.h \
  /src/linux/include/asm-generic/bitops/lock.h \
  /src/linux/include/asm-generic/bitops/instrumented-lock.h \
  /src/linux/include/asm-generic/bitops/non-atomic.h \
  /src/linux/include/asm-generic/bitops/non-instrumented-non-atomic.h \
  /src/linux/include/asm-generic/bitops/le.h \
  /src/linux/include/asm-generic/bitops/ext2-atomic-setbit.h \
  /src/linux/include/linux/kstrtox.h \
  /src/linux/include/linux/log2.h \
    $(wildcard include/config/ARCH_HAS_ILOG2_U32) \
    $(wildcard include/config/ARCH_HAS_ILOG2_U64) \
  /src/linux/include/linux/math.h \
  /src/obj/arch/arm64/include/generated/asm/div64.h \
  /src/linux/include/asm-generic/div64.h \
    $(wildcard include/config/CC_OPTIMIZE_FOR_PERFORMANCE) \
  /src/linux/include/linux/minmax.h \
  /src/linux/include/linux/sprintf.h \
  /src/linux/include/linux/static_call_types.h \
    $(wildcard include/config/HAVE_STATIC_CALL) \
    $(wildcard include/config/HAVE_STATIC_CALL_INLINE) \
  /src/linux/include/linux/trace_printk.h \
    $(wildcard include/config/TRACING) \
  /src/linux/include/linux/instruction_pointer.h \
  /src/linux/include/linux/util_macros.h \
    $(wildcard include/config/FOO_SUSPEND) \
  /src/linux/include/linux/wordpart.h \
  /src/linux/include/linux/notifier.h \
    $(wildcard include/config/TREE_SRCU) \
  /src/linux/include/linux/errno.h \
  /src/linux/include/uapi/linux/errno.h \
  /src/linux/include/linux/mutex.h \
    $(wildcard include/config/DEBUG_MUTEXES) \
    $(wildcard include/config/PREEMPT_RT) \
  /src/linux/arch/arm64/include/asm/current.h \
  /src/linux/include/linux/list.h \
    $(wildcard include/config/LIST_HARDENED) \
    $(wildcard include/config/DEBUG_LIST) \
  /src/linux/include/linux/poison.h \
    $(wildcard include/config/ILLEGAL_POINTER_VALUE) \
  /src/linux/include/linux/spinlock_types.h \
  /src/linux/include/linux/rwlock_types.h \
  /src/linux/include/linux/lockdep.h \
    $(wildcard include/config/DEBUG_LOCKING_API_SELFTESTS) \
    $(wildcard include/config/PREEMPT_COUNT) \
  /src/linux/include/linux/smp.h \
    $(wildcard include/config/UP_LATE_INIT) \
    $(wildcard include/config/PREEMPTION) \
    $(wildcard include/config/DEBUG_PREEMPT) \
    $(wildcard include/config/CSD_LOCK_WAIT_DEBUG) \
  /src/linux/include/linux/cpumask.h \
    $(wildcard include/config/FORCE_NR_CPUS) \
    $(wildcard include/config/HOTPLUG_CPU) \
    $(wildcard include/config/DEBUG_PER_CPU_MAPS) \
    $(wildcard include/config/CPUMASK_OFFSTACK) \
  /src/linux/include/linux/bitmap.h \
  /src/linux/include/linux/find.h \
  /src/linux/include/linux/string.h \
    $(wildcard include/config/BINARY_PRINTF) \
  /src/linux/include/uapi/linux/string.h \
  /src/linux/arch/arm64/include/asm/string.h \
    $(wildcard include/config/ARCH_HAS_UACCESS_FLUSHCACHE) \
  /src/linux/include/linux/bitmap-str.h \
  /src/linux/include/linux/cpumask_types.h \
  /src/linux/include/linux/threads.h \
    $(wildcard include/config/BASE_SMALL) \
  /src/linux/include/linux/gfp_types.h \
    $(wildcard include/config/KASAN_HW_TAGS) \
  /src/linux/include/linux/numa.h \
    $(wildcard include/config/NUMA_KEEP_MEMINFO) \
    $(wildcard include/config/NUMA) \
    $(wildcard include/config/HAVE_ARCH_NODE_DEV_GROUP) \
  /src/linux/include/linux/nodemask.h \
    $(wildcard include/config/HIGHMEM) \
  /src/linux/include/linux/nodemask_types.h \
    $(wildcard include/config/NODES_SHIFT) \
  /src/linux/include/linux/random.h \
    $(wildcard include/config/VMGENID) \
  /src/linux/include/uapi/linux/random.h \
  /src/linux/include/uapi/linux/ioctl.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/ioctl.h \
  /src/linux/include/asm-generic/ioctl.h \
  /src/linux/include/uapi/asm-generic/ioctl.h \
  /src/linux/include/linux/irqnr.h \
  /src/linux/include/uapi/linux/irqnr.h \
  /src/linux/arch/arm64/include/asm/sparsemem.h \
    $(wildcard include/config/ARM64_64K_PAGES) \
  /src/linux/arch/arm64/include/asm/pgtable-prot.h \
    $(wildcard include/config/HAVE_ARCH_USERFAULTFD_WP) \
    $(wildcard include/config/ARM64_LPA2) \
    $(wildcard include/config/ARM64_PA_BITS) \
  /src/linux/arch/arm64/include/asm/memory.h \
    $(wildcard include/config/ARM64_VA_BITS) \
    $(wildcard include/config/ARM64_16K_PAGES) \
    $(wildcard include/config/KASAN_SHADOW_OFFSET) \
    $(wildcard include/config/KASAN) \
    $(wildcard include/config/ARM64_4K_PAGES) \
    $(wildcard include/config/RANDOMIZE_BASE) \
    $(wildcard include/config/DEBUG_VIRTUAL) \
    $(wildcard include/config/EFI) \
    $(wildcard include/config/ARM_GIC_V3_ITS) \
  /src/linux/include/linux/sizes.h \
  /src/linux/arch/arm64/include/asm/page-def.h \
  /src/linux/include/vdso/page.h \
    $(wildcard include/config/PAGE_SHIFT) \
  /src/linux/include/linux/mmdebug.h \
    $(wildcard include/config/DEBUG_VM) \
    $(wildcard include/config/DEBUG_VM_IRQSOFF) \
    $(wildcard include/config/DEBUG_VM_PGFLAGS) \
  /src/linux/arch/arm64/include/asm/boot.h \
  /src/linux/arch/arm64/include/asm/sections.h \
  /src/linux/include/asm-generic/sections.h \
    $(wildcard include/config/HAVE_FUNCTION_DESCRIPTORS) \
  /src/linux/arch/arm64/include/asm/sysreg.h \
    $(wildcard include/config/BROKEN_GAS_INST) \
    $(wildcard include/config/ARM64_PA_BITS_52) \
    $(wildcard include/config/AMPERE_ERRATUM_AC04_CPU_23) \
  /src/linux/include/linux/kasan-tags.h \
  /src/linux/arch/arm64/include/asm/gpr-num.h \
  /src/obj/arch/arm64/include/generated/asm/sysreg-defs.h \
  /src/linux/include/linux/bitfield.h \
  /src/linux/include/asm-generic/memory_model.h \
    $(wildcard include/config/FLATMEM) \
    $(wildcard include/config/SPARSEMEM_VMEMMAP) \
    $(wildcard include/config/SPARSEMEM) \
  /src/linux/include/linux/pfn.h \
  /src/linux/arch/arm64/include/asm/pgtable-hwdef.h \
    $(wildcard include/config/PGTABLE_LEVELS) \
    $(wildcard include/config/ARM64_CONT_PTE_SHIFT) \
    $(wildcard include/config/ARM64_CONT_PMD_SHIFT) \
    $(wildcard include/config/ARM64_VA_BITS_52) \
  /src/linux/arch/arm64/include/asm/cpufeature.h \
    $(wildcard include/config/ARM64_SW_TTBR0_PAN) \
    $(wildcard include/config/ARM64_DEBUG_PRIORITY_MASKING) \
    $(wildcard include/config/ARM64_BTI_KERNEL) \
    $(wildcard include/config/ARM64_HW_AFDBM) \
    $(wildcard include/config/ARM64_AMU_EXTN) \
  /src/linux/arch/arm64/include/asm/cputype.h \
  /src/linux/arch/arm64/include/asm/hwcap.h \
    $(wildcard include/config/COMPAT) \
  /src/linux/arch/arm64/include/uapi/asm/hwcap.h \
  /src/obj/arch/arm64/include/generated/asm/kernel-hwcap.h \
  /src/linux/arch/arm64/include/asm/pgtable-types.h \
  /src/linux/arch/arm64/include/asm/rsi.h \
  /src/linux/arch/arm64/include/asm/rsi_cmds.h \
  /src/linux/include/linux/arm-smccc.h \
    $(wildcard include/config/HAVE_ARM_SMCCC) \
    $(wildcard include/config/ARM) \
  /src/linux/include/linux/uuid.h \
  /src/linux/arch/arm64/include/asm/rsi_smc.h \
  /src/linux/include/linux/smp_types.h \
  /src/linux/include/linux/llist.h \
    $(wildcard include/config/ARCH_HAVE_NMI_SAFE_CMPXCHG) \
  /src/linux/include/linux/preempt.h \
    $(wildcard include/config/HAS_SEPARATE_PREEMPT_RESCHED_BITS) \
    $(wildcard include/config/TRACE_PREEMPT_TOGGLE) \
    $(wildcard include/config/PREEMPT_NOTIFIERS) \
    $(wildcard include/config/PREEMPT_NONE) \
    $(wildcard include/config/PREEMPT_VOLUNTARY) \
    $(wildcard include/config/PREEMPT) \
    $(wildcard include/config/PREEMPT_LAZY) \
  /src/linux/arch/arm64/include/asm/preempt.h \
  /src/linux/include/linux/thread_info.h \
    $(wildcard include/config/THREAD_INFO_IN_TASK) \
    $(wildcard include/config/GENERIC_ENTRY) \
    $(wildcard include/config/ARCH_HAS_PREEMPT_LAZY) \
    $(wildcard include/config/HAVE_ARCH_WITHIN_STACK_FRAMES) \
    $(wildcard include/config/SH) \
  /src/linux/include/linux/restart_block.h \
  /src/linux/include/linux/time64.h \
  /src/linux/include/linux/math64.h \
    $(wildcard include/config/ARCH_SUPPORTS_INT128) \
  /src/linux/include/vdso/math64.h \
  /src/linux/include/vdso/time64.h \
  /src/linux/include/uapi/linux/time.h \
  /src/linux/include/uapi/linux/time_types.h \
  /src/linux/arch/arm64/include/asm/thread_info.h \
    $(wildcard include/config/ARM64_MPAM) \
  /src/linux/arch/arm64/include/asm/stack_pointer.h \
  /src/linux/arch/arm64/include/asm/smp.h \
    $(wildcard include/config/ARM64_ACPI_PARKING_PROTOCOL) \
  /src/linux/arch/arm64/include/asm/percpu.h \
  /src/linux/include/asm-generic/percpu.h \
    $(wildcard include/config/HAVE_SETUP_PER_CPU_AREA) \
  /src/linux/include/linux/percpu-defs.h \
    $(wildcard include/config/ARCH_MODULE_NEEDS_WEAK_PER_CPU) \
    $(wildcard include/config/AMD_MEM_ENCRYPT) \
  /src/linux/arch/arm64/include/asm/processor.h \
    $(wildcard include/config/KUSER_HELPERS) \
    $(wildcard include/config/ARM64_FORCE_52BIT) \
    $(wildcard include/config/HAVE_HW_BREAKPOINT) \
    $(wildcard include/config/ARM64_TAGGED_ADDR_ABI) \
  /src/linux/include/linux/cache.h \
    $(wildcard include/config/ARCH_HAS_CACHE_LINE_SIZE) \
  /src/linux/include/vdso/cache.h \
  /src/linux/arch/arm64/include/asm/cache.h \
  /src/linux/include/linux/kasan-enabled.h \
    $(wildcard include/config/ARCH_DEFER_KASAN) \
  /src/linux/include/linux/static_key.h \
  /src/linux/arch/arm64/include/asm/mte-def.h \
  /src/linux/include/vdso/processor.h \
  /src/linux/arch/arm64/include/asm/vdso/processor.h \
  /src/linux/arch/arm64/include/asm/hw_breakpoint.h \
    $(wildcard include/config/CPU_PM) \
  /src/linux/arch/arm64/include/asm/virt.h \
    $(wildcard include/config/KVM) \
  /src/linux/arch/arm64/include/asm/ptrace.h \
  /src/linux/arch/arm64/include/uapi/asm/ptrace.h \
  /src/linux/arch/arm64/include/uapi/asm/sve_context.h \
  /src/linux/include/linux/irqchip/arm-gic-v3-prio.h \
  /src/linux/arch/arm64/include/asm/stacktrace/frame.h \
  /src/linux/arch/arm64/include/asm/kasan.h \
  /src/linux/arch/arm64/include/asm/mte-kasan.h \
  /src/linux/arch/arm64/include/asm/pointer_auth.h \
  /src/linux/include/uapi/linux/prctl.h \
  /src/linux/arch/arm64/include/asm/spectre.h \
  /src/linux/arch/arm64/include/asm/fpsimd.h \
  /src/linux/arch/arm64/include/uapi/asm/sigcontext.h \
  /src/linux/include/linux/osq_lock.h \
  /src/linux/include/linux/debug_locks.h \
  /src/linux/include/linux/mutex_types.h \
    $(wildcard include/config/MUTEX_SPIN_ON_OWNER) \
  /src/linux/include/linux/rwsem.h \
    $(wildcard include/config/RWSEM_SPIN_ON_OWNER) \
    $(wildcard include/config/DEBUG_RWSEMS) \
    $(wildcard include/config/DETECT_HUNG_TASK_BLOCKER) \
  /src/linux/include/linux/spinlock.h \
  /src/linux/include/linux/irqflags.h \
    $(wildcard include/config/TRACE_IRQFLAGS) \
    $(wildcard include/config/IRQSOFF_TRACER) \
    $(wildcard include/config/PREEMPT_TRACER) \
    $(wildcard include/config/DEBUG_IRQFLAGS) \
    $(wildcard include/config/TRACE_IRQFLAGS_SUPPORT) \
  /src/linux/include/linux/irqflags_types.h \
  /src/linux/arch/arm64/include/asm/irqflags.h \
  /src/linux/include/linux/interrupt_rc.h \
  /src/linux/include/linux/processor.h \
  /src/linux/include/linux/bottom_half.h \
  /src/obj/arch/arm64/include/generated/asm/mmiowb.h \
  /src/linux/include/asm-generic/mmiowb.h \
    $(wildcard include/config/MMIOWB) \
  /src/linux/arch/arm64/include/asm/spinlock.h \
  /src/obj/arch/arm64/include/generated/asm/qspinlock.h \
  /src/linux/include/asm-generic/qspinlock.h \
    $(wildcard include/config/QUEUED_SPINLOCKS_TRACE_CONTENDED_RELEASE) \
  /src/linux/include/linux/tracepoint-defs.h \
    $(wildcard include/config/TRACEPOINTS) \
  /src/obj/arch/arm64/include/generated/asm/qrwlock.h \
  /src/linux/include/asm-generic/qrwlock.h \
  /src/linux/include/linux/rwlock.h \
  /src/linux/include/linux/spinlock_api_smp.h \
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
  /src/linux/include/linux/rwlock_api_smp.h \
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
  /src/linux/include/linux/srcu.h \
    $(wildcard include/config/TINY_SRCU) \
    $(wildcard include/config/NEED_SRCU_NMI_SAFE) \
    $(wildcard include/config/PROVE_RCU) \
  /src/linux/include/linux/rcupdate.h \
    $(wildcard include/config/PREEMPT_RCU) \
    $(wildcard include/config/TINY_RCU) \
    $(wildcard include/config/RCU_STRICT_GRACE_PERIOD) \
    $(wildcard include/config/RCU_LAZY) \
    $(wildcard include/config/RCU_STALL_COMMON) \
    $(wildcard include/config/NO_HZ_FULL) \
    $(wildcard include/config/VIRT_XFER_TO_GUEST_WORK) \
    $(wildcard include/config/RCU_NOCB_CPU) \
    $(wildcard include/config/TASKS_RCU_GENERIC) \
    $(wildcard include/config/TASKS_RCU) \
    $(wildcard include/config/TASKS_RUDE_RCU) \
    $(wildcard include/config/TREE_RCU) \
    $(wildcard include/config/DEBUG_OBJECTS_RCU_HEAD) \
    $(wildcard include/config/ARCH_WEAK_RELEASE_ACQUIRE) \
  /src/linux/include/linux/sched.h \
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
    $(wildcard include/config/MEM_ALLOC_PROFILING) \
    $(wildcard include/config/SCHED_CLASS_EXT) \
    $(wildcard include/config/CGROUP_SCHED) \
    $(wildcard include/config/CFS_BANDWIDTH) \
    $(wildcard include/config/BLK_DEV_IO_TRACE) \
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
    $(wildcard include/config/POSIX_CPUTIMERS) \
    $(wildcard include/config/POSIX_CPU_TIMERS_TASK_WORK) \
    $(wildcard include/config/KEYS) \
    $(wildcard include/config/SYSVIPC) \
    $(wildcard include/config/DETECT_HUNG_TASK) \
    $(wildcard include/config/IO_URING) \
    $(wildcard include/config/AUDIT) \
    $(wildcard include/config/AUDITSYSCALL) \
    $(wildcard include/config/UBSAN) \
    $(wildcard include/config/UBSAN_TRAP) \
    $(wildcard include/config/COMPACTION) \
    $(wildcard include/config/TASK_XACCT) \
    $(wildcard include/config/CPUSETS) \
    $(wildcard include/config/X86_CPU_RESCTRL) \
    $(wildcard include/config/PERF_EVENTS) \
    $(wildcard include/config/NUMA_BALANCING) \
    $(wildcard include/config/SCHED_CACHE) \
    $(wildcard include/config/ARCH_HAS_LAZY_MMU_MODE) \
    $(wildcard include/config/FAULT_INJECTION) \
    $(wildcard include/config/LATENCYTOP) \
    $(wildcard include/config/KUNIT) \
    $(wildcard include/config/FUNCTION_GRAPH_TRACER) \
    $(wildcard include/config/MEMCG) \
    $(wildcard include/config/UPROBES) \
    $(wildcard include/config/BCACHE) \
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
    $(wildcard include/config/MEM_ALLOC_PROFILING_DEBUG) \
    $(wildcard include/config/SCHED_MM_CID) \
  /src/linux/include/uapi/linux/sched.h \
  /src/linux/include/linux/futex_types.h \
    $(wildcard include/config/FUTEX) \
    $(wildcard include/config/FUTEX_PRIVATE_HASH) \
    $(wildcard include/config/FUTEX_ROBUST_UNLOCK) \
  /src/linux/include/linux/pid_types.h \
  /src/linux/include/linux/sem_types.h \
  /src/linux/include/linux/shm.h \
  /src/linux/arch/arm64/include/asm/page.h \
  /src/linux/include/linux/personality.h \
  /src/linux/include/uapi/linux/personality.h \
  /src/linux/include/asm-generic/getorder.h \
  /src/linux/arch/arm64/include/asm/shmparam.h \
  /src/linux/include/asm-generic/shmparam.h \
  /src/linux/include/linux/kmsan_types.h \
  /src/linux/include/linux/plist_types.h \
  /src/linux/include/linux/hrtimer_types.h \
  /src/linux/include/linux/timerqueue_types.h \
  /src/linux/include/linux/rbtree_types.h \
  /src/linux/include/linux/timer_types.h \
  /src/linux/include/linux/seccomp_types.h \
    $(wildcard include/config/SECCOMP) \
  /src/linux/include/linux/refcount_types.h \
  /src/linux/include/linux/resource.h \
  /src/linux/include/uapi/linux/resource.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/resource.h \
  /src/linux/include/asm-generic/resource.h \
  /src/linux/include/uapi/asm-generic/resource.h \
  /src/linux/include/linux/latencytop.h \
  /src/linux/include/linux/sched/prio.h \
  /src/linux/include/linux/sched/types.h \
  /src/linux/include/linux/signal_types.h \
    $(wildcard include/config/OLD_SIGACTION) \
  /src/linux/include/uapi/linux/signal.h \
  /src/linux/arch/arm64/include/asm/signal.h \
  /src/linux/arch/arm64/include/uapi/asm/signal.h \
  /src/linux/include/asm-generic/signal.h \
  /src/linux/include/uapi/asm-generic/signal.h \
  /src/linux/include/uapi/asm-generic/signal-defs.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/siginfo.h \
  /src/linux/include/uapi/asm-generic/siginfo.h \
  /src/linux/include/linux/syscall_user_dispatch_types.h \
    $(wildcard include/config/SYSCALL_USER_DISPATCH) \
  /src/linux/include/linux/mm_types_task.h \
    $(wildcard include/config/ARCH_WANT_BATCHED_UNMAP_TLB_FLUSH) \
  /src/linux/arch/arm64/include/asm/tlbbatch.h \
  /src/linux/include/linux/netdevice_xmit.h \
    $(wildcard include/config/NET_ACT_MIRRED) \
    $(wildcard include/config/NET_EGRESS) \
    $(wildcard include/config/NF_DUP_NETDEV) \
  /src/linux/include/linux/task_io_accounting.h \
    $(wildcard include/config/TASK_IO_ACCOUNTING) \
  /src/linux/include/linux/posix-timers_types.h \
    $(wildcard include/config/POSIX_TIMERS) \
  /src/linux/include/linux/rseq_types.h \
    $(wildcard include/config/RSEQ) \
    $(wildcard include/config/RSEQ_SLICE_EXTENSION) \
  /src/linux/include/linux/irq_work_types.h \
  /src/linux/include/linux/workqueue_types.h \
  /src/linux/include/linux/seqlock_types.h \
  /src/linux/include/linux/kcsan.h \
  /src/linux/include/linux/rv.h \
    $(wildcard include/config/RV_LTL_MONITOR) \
    $(wildcard include/config/RV_HA_MONITOR) \
    $(wildcard include/config/RV_REACTORS) \
  /src/linux/include/linux/uidgid_types.h \
  /src/linux/include/linux/unwind_deferred_types.h \
  /src/obj/arch/arm64/include/generated/asm/kmap_size.h \
  /src/linux/include/asm-generic/kmap_size.h \
    $(wildcard include/config/DEBUG_KMAP_LOCAL) \
  /src/obj/include/generated/rq-offsets.h \
  /src/linux/include/linux/sched/ext.h \
    $(wildcard include/config/EXT_SUB_SCHED) \
    $(wildcard include/config/EXT_GROUP_SCHED) \
  /src/linux/include/linux/context_tracking_irq.h \
    $(wildcard include/config/CONTEXT_TRACKING_IDLE) \
  /src/linux/include/linux/rcutree.h \
  /src/linux/include/linux/workqueue.h \
    $(wildcard include/config/DEBUG_OBJECTS_WORK) \
    $(wildcard include/config/FREEZER) \
    $(wildcard include/config/SYSFS) \
    $(wildcard include/config/WQ_WATCHDOG) \
  /src/linux/include/linux/alloc_tag.h \
    $(wildcard include/config/MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT) \
  /src/linux/include/linux/codetag.h \
    $(wildcard include/config/CODE_TAGGING) \
  /src/linux/include/linux/timer.h \
    $(wildcard include/config/DEBUG_OBJECTS_TIMERS) \
    $(wildcard include/config/NO_HZ_COMMON) \
  /src/linux/include/linux/ktime.h \
  /src/linux/include/linux/jiffies.h \
  /src/linux/include/linux/time.h \
  /src/linux/include/linux/time32.h \
  /src/linux/include/linux/timex.h \
  /src/linux/include/uapi/linux/timex.h \
  /src/linux/arch/arm64/include/asm/timex.h \
  /src/linux/arch/arm64/include/asm/arch_timer.h \
    $(wildcard include/config/ARM_ARCH_TIMER_OOL_WORKAROUND) \
  /src/linux/include/linux/percpu.h \
    $(wildcard include/config/KMALLOC_PARTITION_CACHES) \
    $(wildcard include/config/PAGE_SIZE_4KB) \
    $(wildcard include/config/NEED_PER_CPU_PAGE_FIRST_CHUNK) \
  /src/linux/include/clocksource/arm_arch_timer.h \
    $(wildcard include/config/ARM_ARCH_TIMER) \
  /src/linux/include/linux/timecounter.h \
  /src/linux/include/asm-generic/timex.h \
  /src/linux/include/vdso/time32.h \
  /src/linux/include/vdso/time.h \
  /src/linux/include/vdso/jiffies.h \
  /src/obj/include/generated/timeconst.h \
  /src/linux/include/vdso/ktime.h \
  /src/linux/include/linux/timekeeping.h \
    $(wildcard include/config/POSIX_AUX_CLOCKS) \
    $(wildcard include/config/GENERIC_CMOS_UPDATE) \
  /src/linux/include/linux/clocksource_ids.h \
  /src/linux/include/linux/debugobjects.h \
    $(wildcard include/config/DEBUG_OBJECTS) \
    $(wildcard include/config/DEBUG_OBJECTS_FREE) \
  /src/linux/include/linux/rcu_segcblist.h \
  /src/linux/include/linux/srcutree.h \
  /src/linux/include/linux/rcu_node_tree.h \
    $(wildcard include/config/RCU_FANOUT) \
    $(wildcard include/config/RCU_FANOUT_LEAF) \
  /src/linux/include/linux/completion.h \
  /src/linux/include/linux/swait.h \
  /src/linux/include/linux/wait.h \
  /src/linux/include/linux/i2c.h \
    $(wildcard include/config/I2C) \
    $(wildcard include/config/I2C_SLAVE) \
    $(wildcard include/config/I2C_BOARDINFO) \
    $(wildcard include/config/I2C_MUX) \
    $(wildcard include/config/ACPI) \
  /src/linux/include/linux/acpi.h \
    $(wildcard include/config/ACPI_TABLE_LIB) \
    $(wildcard include/config/ACPI_DEBUGGER) \
    $(wildcard include/config/X86) \
    $(wildcard include/config/LOONGARCH) \
    $(wildcard include/config/RISCV) \
    $(wildcard include/config/ACPI_PROCESSOR_CSTATE) \
    $(wildcard include/config/ACPI_PROCESSOR_IDLE) \
    $(wildcard include/config/ACPI_HOTPLUG_CPU) \
    $(wildcard include/config/ACPI_HOTPLUG_IOAPIC) \
    $(wildcard include/config/X86_IO_APIC) \
    $(wildcard include/config/PCI) \
    $(wildcard include/config/ACPI_WMI) \
    $(wildcard include/config/ACPI_THERMAL_LIB) \
    $(wildcard include/config/ACPI_HMAT) \
    $(wildcard include/config/ACPI_NUMA) \
    $(wildcard include/config/HIBERNATION) \
    $(wildcard include/config/PM_SLEEP) \
    $(wildcard include/config/ACPI_HOTPLUG_MEMORY) \
    $(wildcard include/config/ACPI_CONTAINER) \
    $(wildcard include/config/ACPI_GTDT) \
    $(wildcard include/config/ACPI_MRRM) \
    $(wildcard include/config/SUSPEND) \
    $(wildcard include/config/PM) \
    $(wildcard include/config/ACPI_EC) \
    $(wildcard include/config/GPIOLIB) \
    $(wildcard include/config/ACPI_TABLE_UPGRADE) \
    $(wildcard include/config/ACPI_WATCHDOG) \
    $(wildcard include/config/ACPI_SPCR_TABLE) \
    $(wildcard include/config/ACPI_GENERIC_GSI) \
    $(wildcard include/config/ACPI_LPIT) \
    $(wildcard include/config/ACPI_PPTT) \
    $(wildcard include/config/ACPI_PCC) \
    $(wildcard include/config/ACPI_FFH) \
  /src/linux/include/linux/ioport.h \
    $(wildcard include/config/MEMORY_HOTREMOVE) \
  /src/linux/include/linux/resource_ext.h \
  /src/linux/include/linux/slab.h \
    $(wildcard include/config/FAILSLAB) \
    $(wildcard include/config/KFENCE) \
    $(wildcard include/config/SLUB_TINY) \
    $(wildcard include/config/SLAB_OBJ_EXT) \
    $(wildcard include/config/SLUB_DEBUG) \
    $(wildcard include/config/KMALLOC_PARTITION_RANDOM) \
    $(wildcard include/config/KMALLOC_PARTITION_TYPED) \
    $(wildcard include/config/ZONE_DMA) \
    $(wildcard include/config/SLAB_BUCKETS) \
  /src/linux/include/linux/gfp.h \
    $(wildcard include/config/ZONE_DMA32) \
    $(wildcard include/config/ZONE_DEVICE) \
    $(wildcard include/config/CONTIG_ALLOC) \
  /src/linux/include/linux/mmzone.h \
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
  /src/linux/include/linux/list_nulls.h \
  /src/linux/include/linux/seqlock.h \
    $(wildcard include/config/CC_IS_GCC) \
    $(wildcard include/config/GCC_VERSION) \
    $(wildcard include/config/UBSAN_ALIGNMENT) \
  /src/linux/include/linux/pageblock-flags.h \
    $(wildcard include/config/HUGETLB_PAGE_SIZE_VARIABLE) \
  /src/linux/include/linux/page-flags-layout.h \
  /src/obj/include/generated/bounds.h \
  /src/linux/include/linux/mm_types.h \
    $(wildcard include/config/HAVE_ALIGNED_STRUCT_PAGE) \
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
  /src/linux/include/linux/auxvec.h \
  /src/linux/include/uapi/linux/auxvec.h \
  /src/linux/arch/arm64/include/uapi/asm/auxvec.h \
  /src/linux/include/linux/kref.h \
  /src/linux/include/linux/refcount.h \
  /src/linux/include/linux/rbtree.h \
  /src/linux/include/linux/maple_tree.h \
    $(wildcard include/config/DEBUG_MAPLE_TREE) \
  /src/linux/include/linux/uprobes.h \
  /src/linux/arch/arm64/include/asm/uprobes.h \
  /src/linux/arch/arm64/include/asm/debug-monitors.h \
  /src/linux/arch/arm64/include/asm/esr.h \
  /src/linux/arch/arm64/include/asm/probes.h \
    $(wildcard include/config/KPROBES) \
  /src/linux/include/linux/percpu_counter.h \
  /src/linux/arch/arm64/include/asm/mmu.h \
    $(wildcard include/config/ARM64_E0PD) \
  /src/linux/include/linux/page-flags.h \
    $(wildcard include/config/PAGE_IDLE_FLAG) \
    $(wildcard include/config/ARCH_USES_PG_ARCH_2) \
    $(wildcard include/config/ARCH_USES_PG_ARCH_3) \
    $(wildcard include/config/MIGRATION) \
    $(wildcard include/config/DEBUG_KMAP_LOCAL_FORCE_MAP) \
  /src/linux/include/linux/local_lock.h \
  /src/linux/include/linux/local_lock_internal.h \
  /src/linux/include/linux/zswap.h \
    $(wildcard include/config/ZSWAP) \
  /src/linux/include/linux/memory_hotplug.h \
    $(wildcard include/config/ARCH_HAS_ADD_PAGES) \
  /src/obj/arch/arm64/include/generated/asm/mmzone.h \
  /src/linux/include/asm-generic/mmzone.h \
  /src/linux/include/linux/topology.h \
    $(wildcard include/config/USE_PERCPU_NUMA_NODE_ID) \
    $(wildcard include/config/SCHED_SMT) \
    $(wildcard include/config/GENERIC_ARCH_TOPOLOGY) \
  /src/linux/include/linux/arch_topology.h \
  /src/linux/arch/arm64/include/asm/topology.h \
  /src/linux/arch/arm64/include/asm/numa.h \
  /src/linux/include/asm-generic/numa.h \
    $(wildcard include/config/NUMA_EMU) \
  /src/linux/include/asm-generic/topology.h \
  /src/linux/include/linux/percpu-refcount.h \
  /src/linux/include/linux/hash.h \
    $(wildcard include/config/HAVE_ARCH_HASH) \
  /src/linux/include/linux/kasan.h \
    $(wildcard include/config/KASAN_STACK) \
    $(wildcard include/config/KASAN_VMALLOC) \
  /src/linux/include/linux/device.h \
    $(wildcard include/config/GENERIC_MSI_IRQ) \
    $(wildcard include/config/ENERGY_MODEL) \
    $(wildcard include/config/PINCTRL) \
    $(wildcard include/config/ARCH_HAS_DMA_OPS) \
    $(wildcard include/config/DMA_DECLARE_COHERENT) \
    $(wildcard include/config/DMA_CMA) \
    $(wildcard include/config/SWIOTLB) \
    $(wildcard include/config/SWIOTLB_DYNAMIC) \
    $(wildcard include/config/DEVTMPFS) \
  /src/linux/include/linux/dev_printk.h \
  /src/linux/include/linux/ratelimit.h \
  /src/linux/include/linux/energy_model.h \
  /src/linux/include/linux/kobject.h \
    $(wildcard include/config/UEVENT_HELPER) \
    $(wildcard include/config/DEBUG_KOBJECT_RELEASE) \
  /src/linux/include/linux/sysfs.h \
  /src/linux/include/linux/kernfs.h \
    $(wildcard include/config/KERNFS) \
  /src/linux/include/linux/idr.h \
  /src/linux/include/linux/radix-tree.h \
  /src/linux/include/linux/xarray.h \
    $(wildcard include/config/XARRAY_MULTI) \
  /src/linux/include/linux/sched/mm.h \
    $(wildcard include/config/MMU_LAZY_TLB_REFCOUNT) \
    $(wildcard include/config/ARCH_HAS_MEMBARRIER_CALLBACKS) \
    $(wildcard include/config/ARCH_HAS_SYNC_CORE_BEFORE_USERMODE) \
  /src/linux/include/linux/sync_core.h \
    $(wildcard include/config/ARCH_HAS_PREPARE_SYNC_CORE_CMD) \
  /src/linux/include/linux/sched/coredump.h \
  /src/linux/include/linux/uidgid.h \
    $(wildcard include/config/MULTIUSER) \
    $(wildcard include/config/USER_NS) \
  /src/linux/include/linux/highuid.h \
  /src/linux/include/linux/kobject_ns.h \
  /src/linux/include/linux/stat.h \
  /src/linux/arch/arm64/include/asm/stat.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/stat.h \
  /src/linux/include/uapi/asm-generic/stat.h \
  /src/linux/arch/arm64/include/asm/compat.h \
  /src/linux/include/asm-generic/compat.h \
    $(wildcard include/config/COMPAT_FOR_U64_ALIGNMENT) \
  /src/linux/include/linux/sched/task_stack.h \
    $(wildcard include/config/STACK_GROWSUP) \
    $(wildcard include/config/DEBUG_STACK_USAGE) \
  /src/linux/include/uapi/linux/magic.h \
  /src/linux/include/uapi/linux/stat.h \
  /src/linux/include/linux/sched/cpufreq.h \
    $(wildcard include/config/CPU_FREQ) \
  /src/linux/include/linux/sched/topology.h \
    $(wildcard include/config/SCHED_CLUSTER) \
    $(wildcard include/config/SCHED_MC) \
    $(wildcard include/config/CPU_FREQ_GOV_SCHEDUTIL) \
  /src/linux/include/linux/sched/idle.h \
  /src/linux/include/linux/sched/sd_flags.h \
  /src/linux/include/linux/klist.h \
  /src/linux/include/linux/pm.h \
    $(wildcard include/config/VT_CONSOLE_SLEEP) \
    $(wildcard include/config/CXL_SUSPEND) \
    $(wildcard include/config/PM_CLK) \
    $(wildcard include/config/PM_GENERIC_DOMAINS) \
  /src/linux/include/linux/device/bus.h \
  /src/linux/include/linux/device/class.h \
  /src/linux/include/linux/device/devres.h \
    $(wildcard include/config/HAS_IOMEM) \
  /src/linux/include/linux/device/driver.h \
  /src/linux/include/linux/module.h \
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
  /src/linux/include/linux/buildid.h \
    $(wildcard include/config/VMCORE_INFO) \
  /src/linux/include/linux/kmod.h \
  /src/linux/include/linux/umh.h \
  /src/linux/include/linux/sysctl.h \
    $(wildcard include/config/SYSCTL) \
  /src/linux/include/uapi/linux/sysctl.h \
  /src/linux/include/linux/elf.h \
    $(wildcard include/config/ARCH_HAVE_EXTRA_ELF_NOTES) \
    $(wildcard include/config/ARCH_USE_GNU_PROPERTY) \
    $(wildcard include/config/ARCH_HAVE_ELF_PROT) \
  /src/linux/arch/arm64/include/asm/elf.h \
    $(wildcard include/config/COMPAT_VDSO) \
  /src/obj/arch/arm64/include/generated/asm/user.h \
  /src/linux/include/asm-generic/user.h \
  /src/linux/include/uapi/linux/elf.h \
  /src/linux/include/uapi/linux/elf-em.h \
  /src/linux/include/linux/fs.h \
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
  /src/linux/include/linux/fs/super.h \
  /src/linux/include/linux/fs/super_types.h \
    $(wildcard include/config/QUOTA) \
    $(wildcard include/config/FS_ENCRYPTION) \
    $(wildcard include/config/FS_VERITY) \
  /src/linux/include/linux/fs_dirent.h \
  /src/linux/include/linux/errseq.h \
  /src/linux/include/linux/list_lru.h \
  /src/linux/include/linux/shrinker.h \
    $(wildcard include/config/SHRINKER_DEBUG) \
  /src/linux/include/linux/list_bl.h \
  /src/linux/include/linux/bit_spinlock.h \
  /src/linux/include/linux/percpu-rwsem.h \
  /src/linux/include/linux/rcuwait.h \
  /src/linux/include/linux/sched/signal.h \
    $(wildcard include/config/SCHED_AUTOGROUP) \
    $(wildcard include/config/BSD_PROCESS_ACCT) \
    $(wildcard include/config/TASKSTATS) \
  /src/linux/include/linux/rculist.h \
    $(wildcard include/config/PROVE_RCU_LIST) \
  /src/linux/include/linux/signal.h \
    $(wildcard include/config/DYNAMIC_SIGFRAME) \
    $(wildcard include/config/PROC_FS) \
  /src/linux/include/linux/sched/jobctl.h \
  /src/linux/include/linux/sched/task.h \
    $(wildcard include/config/HAVE_EXIT_THREAD) \
    $(wildcard include/config/ARCH_WANTS_DYNAMIC_TASK_STRUCT) \
    $(wildcard include/config/HAVE_ARCH_THREAD_STRUCT_WHITELIST) \
  /src/linux/include/linux/uaccess.h \
    $(wildcard include/config/ARCH_HAS_SUBPAGE_FAULTS) \
    $(wildcard include/config/ARCH_MEMORY_ORDER_TSO) \
    $(wildcard include/config/HARDENED_USERCOPY) \
  /src/linux/include/linux/fault-inject-usercopy.h \
    $(wildcard include/config/FAULT_INJECTION_USERCOPY) \
  /src/linux/include/linux/nospec.h \
  /src/linux/include/linux/ucopysize.h \
    $(wildcard include/config/HARDENED_USERCOPY_DEFAULT_ON) \
  /src/linux/arch/arm64/include/asm/uaccess.h \
    $(wildcard include/config/CC_HAS_ASM_GOTO_OUTPUT) \
  /src/linux/arch/arm64/include/asm/kernel-pgtable.h \
    $(wildcard include/config/RELOCATABLE) \
  /src/linux/arch/arm64/include/asm/asm-extable.h \
  /src/linux/arch/arm64/include/asm/mte.h \
  /src/linux/arch/arm64/include/asm/extable.h \
    $(wildcard include/config/BPF_JIT) \
  /src/linux/include/asm-generic/access_ok.h \
    $(wildcard include/config/ALTERNATE_USER_ADDRESS_SPACE) \
  /src/linux/include/linux/cred.h \
  /src/linux/include/linux/capability.h \
  /src/linux/include/uapi/linux/capability.h \
  /src/linux/include/linux/key.h \
    $(wildcard include/config/KEY_NOTIFICATIONS) \
    $(wildcard include/config/NET) \
  /src/linux/include/linux/assoc_array.h \
    $(wildcard include/config/ASSOCIATIVE_ARRAY) \
  /src/linux/include/linux/sched/user.h \
    $(wildcard include/config/VFIO_PCI_ZDEV_KVM) \
    $(wildcard include/config/IOMMUFD) \
    $(wildcard include/config/SECRETMEM) \
    $(wildcard include/config/WATCH_QUEUE) \
  /src/linux/include/linux/pid.h \
  /src/linux/include/linux/rhashtable-types.h \
  /src/linux/include/linux/posix-timers.h \
  /src/linux/include/linux/alarmtimer.h \
    $(wildcard include/config/RTC_CLASS) \
  /src/linux/include/linux/hrtimer.h \
    $(wildcard include/config/HIGH_RES_TIMERS) \
    $(wildcard include/config/TIME_LOW_RES) \
    $(wildcard include/config/TIMERFD) \
  /src/linux/include/linux/hrtimer_rearm.h \
    $(wildcard include/config/HRTIMER_REARM_DEFERRED) \
  /src/linux/include/linux/timerqueue.h \
  /src/linux/include/linux/rcuref.h \
  /src/linux/include/linux/rcu_sync.h \
  /src/linux/include/linux/quota.h \
    $(wildcard include/config/QUOTA_NETLINK_INTERFACE) \
  /src/linux/include/uapi/linux/dqblk_xfs.h \
  /src/linux/include/linux/dqblk_v1.h \
  /src/linux/include/linux/dqblk_v2.h \
  /src/linux/include/linux/dqblk_qtree.h \
  /src/linux/include/linux/projid.h \
  /src/linux/include/uapi/linux/quota.h \
  /src/linux/include/linux/unicode.h \
  /src/linux/include/linux/dcache.h \
  /src/linux/include/linux/rculist_bl.h \
  /src/linux/include/linux/lockref.h \
    $(wildcard include/config/ARCH_USE_CMPXCHG_LOCKREF) \
  /src/linux/include/linux/stringhash.h \
    $(wildcard include/config/DCACHE_WORD_ACCESS) \
  /src/linux/include/linux/vfsdebug.h \
    $(wildcard include/config/DEBUG_VFS) \
  /src/linux/include/linux/wait_bit.h \
  /src/linux/include/linux/kdev_t.h \
  /src/linux/include/uapi/linux/kdev_t.h \
  /src/linux/include/linux/path.h \
  /src/linux/include/linux/semaphore.h \
  /src/linux/include/linux/fcntl.h \
    $(wildcard include/config/ARCH_32BIT_OFF_T) \
  /src/linux/include/uapi/linux/fcntl.h \
  /src/linux/arch/arm64/include/uapi/asm/fcntl.h \
  /src/linux/include/uapi/asm-generic/fcntl.h \
  /src/linux/include/uapi/linux/openat2.h \
  /src/linux/include/linux/migrate_mode.h \
  /src/linux/include/linux/delayed_call.h \
  /src/linux/include/linux/ioprio.h \
  /src/linux/include/linux/sched/rt.h \
  /src/linux/include/linux/iocontext.h \
    $(wildcard include/config/BLK_ICQ) \
  /src/linux/include/uapi/linux/ioprio.h \
  /src/linux/include/linux/mount.h \
  /src/linux/include/linux/mnt_idmapping.h \
  /src/linux/include/linux/rw_hint.h \
  /src/linux/include/linux/file_ref.h \
  /src/linux/include/uapi/linux/fs.h \
  /src/linux/include/linux/moduleparam.h \
    $(wildcard include/config/ALPHA) \
    $(wildcard include/config/PPC64) \
  /src/linux/include/linux/rbtree_latch.h \
  /src/linux/include/linux/error-injection.h \
  /src/linux/include/asm-generic/error-injection.h \
  /src/linux/arch/arm64/include/asm/module.h \
  /src/linux/include/asm-generic/module.h \
    $(wildcard include/config/HAVE_MOD_ARCH_SPECIFIC) \
  /src/linux/include/linux/device-id/acpi.h \
  /src/linux/include/linux/device-id/of.h \
  /src/obj/arch/arm64/include/generated/asm/device.h \
  /src/linux/include/asm-generic/device.h \
  /src/linux/include/linux/pm_wakeup.h \
  /src/linux/include/linux/property.h \
  /src/linux/include/linux/fwnode.h \
  /src/linux/include/linux/node.h \
    $(wildcard include/config/HMEM_REPORTING) \
  /src/linux/include/acpi/acpi.h \
  /src/linux/include/acpi/platform/acenv.h \
  /src/linux/include/acpi/platform/acgcc.h \
  /src/linux/include/acpi/platform/aclinux.h \
    $(wildcard include/config/ACPI_REDUCED_HARDWARE_ONLY) \
    $(wildcard include/config/ACPI_DEBUG) \
  /src/linux/include/linux/ctype.h \
  /src/linux/include/acpi/acnames.h \
  /src/linux/include/acpi/actypes.h \
  /src/linux/include/acpi/acexcep.h \
  /src/linux/include/acpi/actbl.h \
  /src/linux/include/acpi/actbl1.h \
  /src/linux/include/acpi/actbl2.h \
  /src/linux/include/acpi/actbl3.h \
  /src/linux/include/acpi/acrestyp.h \
  /src/linux/include/acpi/platform/acenvex.h \
  /src/linux/include/acpi/platform/aclinuxex.h \
  /src/linux/include/acpi/platform/acgccex.h \
  /src/linux/include/acpi/acoutput.h \
  /src/linux/include/acpi/acpiosxf.h \
  /src/linux/include/acpi/acpixf.h \
  /src/linux/include/acpi/acconfig.h \
  /src/linux/include/acpi/acbuffer.h \
  /src/linux/include/acpi/acpi_numa.h \
  /src/linux/include/linux/device-id/i2c.h \
  /src/linux/include/linux/regulator/consumer.h \
    $(wildcard include/config/REGULATOR) \
  /src/linux/include/linux/suspend.h \
    $(wildcard include/config/VT) \
    $(wildcard include/config/HIBERNATION_SNAPSHOT_DEV) \
    $(wildcard include/config/PM_SLEEP_DEBUG) \
    $(wildcard include/config/PM_AUTOSLEEP) \
  /src/linux/include/linux/swap.h \
    $(wildcard include/config/DEVICE_PRIVATE) \
    $(wildcard include/config/THP_SWAP) \
  /src/linux/include/linux/memcontrol.h \
    $(wildcard include/config/MEMCG_NMI_SAFETY_REQUIRES_ATOMIC) \
  /src/linux/include/linux/cgroup.h \
    $(wildcard include/config/DEBUG_CGROUP_REF) \
    $(wildcard include/config/CGROUP_CPUACCT) \
    $(wildcard include/config/SOCK_CGROUP_DATA) \
    $(wildcard include/config/CGROUP_DATA) \
    $(wildcard include/config/CGROUP_BPF) \
  /src/linux/include/uapi/linux/cgroupstats.h \
  /src/linux/include/uapi/linux/taskstats.h \
  /src/linux/include/linux/seq_file.h \
  /src/linux/include/linux/string_helpers.h \
  /src/linux/include/linux/string_choices.h \
  /src/linux/include/linux/ns_common.h \
  /src/linux/include/linux/ns/ns_common_types.h \
    $(wildcard include/config/IPC_NS) \
    $(wildcard include/config/NET_NS) \
    $(wildcard include/config/PID_NS) \
    $(wildcard include/config/TIME_NS) \
    $(wildcard include/config/UTS_NS) \
  /src/linux/include/linux/ns/nstree_types.h \
  /src/linux/include/uapi/linux/nsfs.h \
  /src/linux/include/linux/nsproxy.h \
  /src/linux/include/linux/user_namespace.h \
    $(wildcard include/config/INOTIFY_USER) \
    $(wildcard include/config/FANOTIFY) \
    $(wildcard include/config/BINFMT_MISC) \
    $(wildcard include/config/PERSISTENT_KEYRINGS) \
  /src/linux/include/linux/rculist_nulls.h \
  /src/linux/include/linux/kernel_stat.h \
    $(wildcard include/config/GENERIC_IRQ_STAT_SNAPSHOT) \
    $(wildcard include/config/HAVE_VIRT_CPU_ACCOUNTING_IDLE) \
  /src/linux/include/linux/interrupt.h \
    $(wildcard include/config/IRQ_FORCED_THREADING) \
    $(wildcard include/config/GENERIC_IRQ_PROBE) \
  /src/linux/include/linux/irqreturn.h \
  /src/linux/include/linux/hardirq.h \
  /src/linux/include/linux/context_tracking_state.h \
    $(wildcard include/config/CONTEXT_TRACKING_USER) \
    $(wildcard include/config/CONTEXT_TRACKING) \
    $(wildcard include/config/RCU_DYNTICKS_TORTURE) \
  /src/linux/include/linux/ftrace_irq.h \
    $(wildcard include/config/HWLAT_TRACER) \
    $(wildcard include/config/OSNOISE_TRACER) \
  /src/linux/include/linux/vtime.h \
    $(wildcard include/config/VIRT_CPU_ACCOUNTING) \
    $(wildcard include/config/IRQ_TIME_ACCOUNTING) \
  /src/linux/arch/arm64/include/asm/hardirq.h \
  /src/linux/arch/arm64/include/asm/irq.h \
  /src/linux/include/asm-generic/irq.h \
  /src/linux/arch/arm64/include/asm/kvm_arm.h \
  /src/linux/include/asm-generic/hardirq.h \
  /src/linux/include/linux/irq.h \
    $(wildcard include/config/GENERIC_IRQ_EFFECTIVE_AFF_MASK) \
    $(wildcard include/config/GENERIC_IRQ_IPI) \
    $(wildcard include/config/IRQ_DOMAIN_HIERARCHY) \
    $(wildcard include/config/DEPRECATED_IRQ_CPU_ONOFFLINE) \
    $(wildcard include/config/GENERIC_IRQ_MIGRATION) \
    $(wildcard include/config/GENERIC_PENDING_IRQ) \
    $(wildcard include/config/HARDIRQS_SW_RESEND) \
    $(wildcard include/config/GENERIC_IRQ_CHIP) \
    $(wildcard include/config/GENERIC_IRQ_MULTI_HANDLER) \
  /src/linux/include/linux/irqhandler.h \
  /src/linux/include/linux/io.h \
    $(wildcard include/config/HAS_IOPORT_MAP) \
    $(wildcard include/config/STRICT_DEVMEM) \
  /src/linux/arch/arm64/include/asm/io.h \
  /src/linux/include/linux/pgtable.h \
    $(wildcard include/config/HIGHPTE) \
    $(wildcard include/config/ARCH_HAS_NONLEAF_PMD_YOUNG) \
    $(wildcard include/config/ARCH_HAS_HW_PTE_YOUNG) \
    $(wildcard include/config/GUP_GET_PXX_LOW_HIGH) \
    $(wildcard include/config/ARCH_WANT_PMD_MKWRITE) \
    $(wildcard include/config/HAVE_ARCH_TRANSPARENT_HUGEPAGE_PUD) \
    $(wildcard include/config/MEM_SOFT_DIRTY) \
    $(wildcard include/config/HAVE_ARCH_SOFT_DIRTY) \
    $(wildcard include/config/ARCH_HAS_PMD_SOFTLEAVES) \
    $(wildcard include/config/ARCH_HAS_PTE_PROTNONE) \
    $(wildcard include/config/HAVE_ARCH_HUGE_VMAP) \
    $(wildcard include/config/X86_ESPFIX64) \
  /src/linux/arch/arm64/include/asm/pgtable.h \
    $(wildcard include/config/ARCH_SUPPORTS_PMD_PFNMAP) \
    $(wildcard include/config/PAGE_TABLE_CHECK) \
    $(wildcard include/config/ARM64_CONTPTE) \
  /src/linux/arch/arm64/include/asm/proc-fns.h \
  /src/linux/arch/arm64/include/asm/tlbflush.h \
  /src/linux/include/linux/mmu_notifier.h \
  /src/linux/include/linux/mmap_lock.h \
  /src/linux/include/linux/interval_tree.h \
  /src/linux/arch/arm64/include/asm/fixmap.h \
    $(wildcard include/config/ACPI_APEI_GHES) \
    $(wildcard include/config/ARM_SDE_INTERFACE) \
  /src/linux/include/asm-generic/fixmap.h \
  /src/linux/arch/arm64/include/asm/por.h \
  /src/linux/include/linux/page_table_check.h \
  /src/linux/include/asm-generic/pgtable_uffd.h \
    $(wildcard include/config/PTE_MARKER_UFFD_WP) \
  /src/obj/arch/arm64/include/generated/asm/early_ioremap.h \
  /src/linux/include/asm-generic/early_ioremap.h \
    $(wildcard include/config/GENERIC_EARLY_IOREMAP) \
  /src/linux/include/asm-generic/io.h \
    $(wildcard include/config/GENERIC_IOMAP) \
    $(wildcard include/config/TRACE_MMIO_ACCESS) \
    $(wildcard include/config/HAS_IOPORT) \
    $(wildcard include/config/GENERIC_IOREMAP) \
  /src/linux/include/asm-generic/pci_iomap.h \
    $(wildcard include/config/NO_GENERIC_PCI_IOPORT_MAP) \
    $(wildcard include/config/GENERIC_PCI_IOMAP) \
  /src/linux/include/linux/logic_pio.h \
    $(wildcard include/config/INDIRECT_PIO) \
  /src/obj/arch/arm64/include/generated/asm/irq_regs.h \
  /src/linux/include/asm-generic/irq_regs.h \
  /src/linux/include/linux/irqdesc.h \
    $(wildcard include/config/GENERIC_IRQ_DEBUGFS) \
    $(wildcard include/config/SPARSE_IRQ) \
    $(wildcard include/config/IRQ_DOMAIN) \
  /src/linux/include/linux/irq_work.h \
    $(wildcard include/config/IRQ_WORK) \
  /src/linux/arch/arm64/include/asm/irq_work.h \
  /src/obj/arch/arm64/include/generated/asm/hw_irq.h \
  /src/linux/include/asm-generic/hw_irq.h \
  /src/linux/include/linux/cgroup-defs.h \
    $(wildcard include/config/CGROUP_NET_CLASSID) \
    $(wildcard include/config/CGROUP_NET_PRIO) \
  /src/linux/include/linux/u64_stats_sync.h \
  /src/obj/arch/arm64/include/generated/asm/local64.h \
  /src/linux/include/asm-generic/local64.h \
  /src/obj/arch/arm64/include/generated/asm/local.h \
  /src/linux/include/asm-generic/local.h \
  /src/linux/include/linux/bpf-cgroup-defs.h \
    $(wildcard include/config/BPF_LSM) \
  /src/linux/include/linux/psi_types.h \
  /src/linux/include/linux/kthread.h \
  /src/linux/include/linux/cgroup_subsys.h \
    $(wildcard include/config/CGROUP_DEVICE) \
    $(wildcard include/config/CGROUP_FREEZER) \
    $(wildcard include/config/CGROUP_PERF) \
    $(wildcard include/config/CGROUP_HUGETLB) \
    $(wildcard include/config/CGROUP_PIDS) \
    $(wildcard include/config/CGROUP_RDMA) \
    $(wildcard include/config/CGROUP_MISC) \
    $(wildcard include/config/CGROUP_DMEM) \
    $(wildcard include/config/CGROUP_DEBUG) \
  /src/linux/include/linux/cgroup_namespace.h \
  /src/linux/include/linux/cgroup_refcnt.h \
  /src/linux/include/linux/vm_event_item.h \
    $(wildcard include/config/BALLOON) \
    $(wildcard include/config/BALLOON_MIGRATION) \
    $(wildcard include/config/DEBUG_TLBFLUSH) \
    $(wildcard include/config/PER_VMA_LOCK_STATS) \
  /src/linux/include/linux/page_counter.h \
  /src/linux/include/linux/vmpressure.h \
  /src/linux/include/linux/eventfd.h \
  /src/linux/include/uapi/linux/eventfd.h \
  /src/linux/include/linux/mm.h \
    $(wildcard include/config/HAVE_ARCH_MMAP_RND_BITS) \
    $(wildcard include/config/HAVE_ARCH_MMAP_RND_COMPAT_BITS) \
    $(wildcard include/config/PPC32) \
    $(wildcard include/config/X86_USER_SHADOW_STACK) \
    $(wildcard include/config/RISCV_USER_CFI) \
    $(wildcard include/config/ARCH_HAS_PKEYS) \
    $(wildcard include/config/ARCH_PKEY_BITS) \
    $(wildcard include/config/PARISC) \
    $(wildcard include/config/SPARC64) \
    $(wildcard include/config/HAVE_ARCH_USERFAULTFD_MINOR) \
    $(wildcard include/config/USERFAULTFD_RWP) \
    $(wildcard include/config/MSEAL_SYSTEM_MAPPINGS) \
    $(wildcard include/config/FIND_NORMAL_PAGE) \
    $(wildcard include/config/SHMEM) \
    $(wildcard include/config/ARCH_HAS_PTE_SPECIAL) \
    $(wildcard include/config/ARCH_SUPPORTS_PUD_PFNMAP) \
    $(wildcard include/config/ASYNC_KERNEL_PGTABLE_FREE) \
    $(wildcard include/config/SPLIT_PTE_PTLOCKS) \
    $(wildcard include/config/DEBUG_VM_RB) \
    $(wildcard include/config/PAGE_POISONING) \
    $(wildcard include/config/INIT_ON_ALLOC_DEFAULT_ON) \
    $(wildcard include/config/INIT_ON_FREE_DEFAULT_ON) \
    $(wildcard include/config/DEBUG_PAGEALLOC) \
    $(wildcard include/config/ARCH_WANT_OPTIMIZE_DAX_VMEMMAP) \
    $(wildcard include/config/HUGETLBFS) \
    $(wildcard include/config/MAPPING_DIRTY_HELPERS) \
    $(wildcard include/config/PAGE_POOL) \
  /src/linux/include/linux/pgalloc_tag.h \
  /src/linux/include/linux/range.h \
  /src/linux/include/linux/page_ext.h \
  /src/linux/include/linux/stacktrace.h \
    $(wildcard include/config/ARCH_STACKWALK) \
    $(wildcard include/config/STACKTRACE) \
    $(wildcard include/config/HAVE_RELIABLE_STACKTRACE) \
  /src/linux/include/linux/page_ref.h \
    $(wildcard include/config/DEBUG_PAGE_REF) \
  /src/linux/include/linux/memremap.h \
    $(wildcard include/config/PCI_P2PDMA) \
  /src/linux/include/linux/cacheinfo.h \
    $(wildcard include/config/ARCH_HAS_CPU_CACHE_ALIASING) \
  /src/linux/include/linux/cpuhplock.h \
  /src/linux/include/linux/iommu-debug-pagealloc.h \
    $(wildcard include/config/IOMMU_DEBUG_PAGEALLOC) \
  /src/linux/include/linux/huge_mm.h \
    $(wildcard include/config/PGTABLE_HAS_HUGE_LEAVES) \
    $(wildcard include/config/PERSISTENT_HUGE_ZERO_FOLIO) \
  /src/linux/include/linux/vmstat.h \
    $(wildcard include/config/VM_EVENT_COUNTERS) \
  /src/linux/include/linux/writeback.h \
  /src/linux/include/linux/flex_proportions.h \
  /src/linux/include/linux/backing-dev-defs.h \
    $(wildcard include/config/DEBUG_FS) \
  /src/linux/include/linux/blk_types.h \
    $(wildcard include/config/FAIL_MAKE_REQUEST) \
    $(wildcard include/config/BLK_CGROUP_IOCOST) \
    $(wildcard include/config/BLK_INLINE_ENCRYPTION) \
    $(wildcard include/config/BLK_DEV_INTEGRITY) \
  /src/linux/include/linux/bvec.h \
  /src/linux/include/linux/highmem.h \
  /src/linux/include/linux/cacheflush.h \
  /src/linux/arch/arm64/include/asm/cacheflush.h \
  /src/linux/include/linux/kgdb.h \
    $(wildcard include/config/HAVE_ARCH_KGDB) \
    $(wildcard include/config/KGDB) \
    $(wildcard include/config/KGDB_HONOUR_BLOCKLIST) \
  /src/linux/include/linux/kprobes.h \
    $(wildcard include/config/KRETPROBE_ON_RETHOOK) \
    $(wildcard include/config/OPTPROBES) \
    $(wildcard include/config/KPROBES_ON_FTRACE) \
  /src/linux/include/linux/ftrace.h \
    $(wildcard include/config/TRACER_SNAPSHOT) \
    $(wildcard include/config/HAVE_FUNCTION_GRAPH_FREGS) \
    $(wildcard include/config/FUNCTION_TRACER) \
    $(wildcard include/config/HAVE_DYNAMIC_FTRACE_WITH_ARGS) \
    $(wildcard include/config/HAVE_FTRACE_REGS_HAVING_PT_REGS) \
    $(wildcard include/config/HAVE_REGS_AND_STACK_ACCESS_API) \
    $(wildcard include/config/DYNAMIC_FTRACE_WITH_REGS) \
    $(wildcard include/config/DYNAMIC_FTRACE_WITH_ARGS) \
    $(wildcard include/config/DYNAMIC_FTRACE_WITH_DIRECT_CALLS) \
    $(wildcard include/config/DYNAMIC_FTRACE_WITH_JMP) \
    $(wildcard include/config/STACK_TRACER) \
    $(wildcard include/config/DYNAMIC_FTRACE_WITH_CALL_OPS) \
    $(wildcard include/config/FRAME_POINTER) \
    $(wildcard include/config/FUNCTION_GRAPH_RETVAL) \
    $(wildcard include/config/FTRACE_SYSCALLS) \
  /src/linux/include/linux/trace_recursion.h \
    $(wildcard include/config/FTRACE_RECORD_RECURSION) \
    $(wildcard include/config/FTRACE_VALIDATE_RCU_IS_WATCHING) \
  /src/linux/include/linux/trace_clock.h \
  /src/obj/arch/arm64/include/generated/asm/trace_clock.h \
  /src/linux/include/asm-generic/trace_clock.h \
  /src/linux/include/linux/kallsyms.h \
    $(wildcard include/config/KALLSYMS_ALL) \
  /src/linux/include/linux/ptrace.h \
  /src/linux/include/linux/pid_namespace.h \
    $(wildcard include/config/MEMFD_CREATE) \
  /src/linux/include/uapi/linux/ptrace.h \
  /src/linux/include/linux/seccomp.h \
    $(wildcard include/config/HAVE_ARCH_SECCOMP_FILTER) \
    $(wildcard include/config/SECCOMP_FILTER) \
    $(wildcard include/config/CHECKPOINT_RESTORE) \
    $(wildcard include/config/SECCOMP_CACHE_DEBUG) \
  /src/linux/include/uapi/linux/seccomp.h \
  /src/linux/arch/arm64/include/asm/seccomp.h \
  /src/obj/arch/arm64/include/generated/asm/unistd_compat_32.h \
  /src/linux/include/asm-generic/seccomp.h \
  /src/linux/include/uapi/linux/unistd.h \
  /src/linux/arch/arm64/include/asm/unistd.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/unistd_64.h \
  /src/linux/arch/arm64/include/asm/ftrace.h \
  /src/linux/include/linux/compat.h \
    $(wildcard include/config/ARCH_HAS_SYSCALL_WRAPPER) \
    $(wildcard include/config/X86_X32_ABI) \
    $(wildcard include/config/COMPAT_OLD_SIGACTION) \
    $(wildcard include/config/ODD_RT_SIGACTION) \
  /src/linux/include/linux/sem.h \
  /src/linux/include/uapi/linux/sem.h \
  /src/linux/include/linux/ipc.h \
  /src/linux/include/uapi/linux/ipc.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/ipcbuf.h \
  /src/linux/include/uapi/asm-generic/ipcbuf.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/sembuf.h \
  /src/linux/include/uapi/asm-generic/sembuf.h \
  /src/linux/include/linux/socket.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/socket.h \
  /src/linux/include/uapi/asm-generic/socket.h \
  /src/obj/arch/arm64/include/generated/uapi/asm/sockios.h \
  /src/linux/include/uapi/asm-generic/sockios.h \
  /src/linux/include/uapi/linux/sockios.h \
  /src/linux/include/linux/uio.h \
    $(wildcard include/config/ARCH_HAS_COPY_MC) \
  /src/linux/include/uapi/linux/uio.h \
  /src/linux/include/uapi/linux/socket.h \
  /src/linux/include/uapi/linux/if.h \
  /src/linux/include/uapi/linux/libc-compat.h \
  /src/linux/include/uapi/linux/hdlc/ioctl.h \
  /src/linux/include/uapi/linux/aio_abi.h \
  /src/linux/arch/arm64/include/asm/syscall_wrapper.h \
  /src/linux/include/linux/ftrace_regs.h \
  /src/linux/include/linux/objpool.h \
  /src/linux/include/linux/rethook.h \
  /src/linux/arch/arm64/include/asm/kprobes.h \
  /src/linux/include/asm-generic/kprobes.h \
  /src/linux/arch/arm64/include/asm/kgdb.h \
  /src/linux/include/asm-generic/cacheflush.h \
  /src/linux/include/linux/kmsan.h \
  /src/linux/include/linux/dma-direction.h \
  /src/linux/include/linux/highmem-internal.h \
  /src/linux/include/linux/folio_batch.h \
  /src/linux/include/linux/bio.h \
    $(wildcard include/config/BLK_DEV_ZONED) \
  /src/linux/include/linux/mempool.h \
  /src/linux/include/linux/pagemap.h \
  /src/linux/include/linux/hugetlb_inline.h \
  /src/linux/include/uapi/linux/mempolicy.h \
  /src/linux/include/linux/freezer.h \
  /src/linux/include/uapi/regulator/regulator.h \
  /src/linux/include/linux/rtmutex.h \
    $(wildcard include/config/DEBUG_RT_MUTEXES) \
  /src/linux/include/linux/irqdomain.h \
    $(wildcard include/config/IRQ_DOMAIN_NOMAP) \
  /src/linux/include/linux/irqdomain_defs.h \
  /src/linux/include/linux/of.h \
    $(wildcard include/config/OF_DYNAMIC) \
    $(wildcard include/config/SPARC) \
    $(wildcard include/config/OF_PROMTREE) \
    $(wildcard include/config/OF_KOBJ) \
    $(wildcard include/config/OF_NUMA) \
    $(wildcard include/config/OF_OVERLAY) \
  /src/linux/include/uapi/linux/i2c.h \
  /src/linux/include/linux/platform_device.h \
    $(wildcard include/config/HIBERNATE_CALLBACKS) \
    $(wildcard include/config/SUPERH) \
  /src/linux/include/linux/device-id/platform.h \
  /src/linux/include/linux/pm_runtime.h \

i2c-qcom-cci.o: $(deps_i2c-qcom-cci.o)

$(deps_i2c-qcom-cci.o):
