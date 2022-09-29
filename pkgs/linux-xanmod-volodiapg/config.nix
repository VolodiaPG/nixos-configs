{ lib, ... }:

with lib.kernel;
{
  LOCALVERSION = freeform "-volodiapg";
  EXPERT = yes;
  WERROR = no;

  # BBR & CAKE
  TCP_CONG_CUBIC = lib.mkForce module;
  TCP_CONG_BBR2 = yes;
  DEFAULT_BBR2 = yes;
  NET_SCH_CAKE = module;

  # FQ-PIE Packet Scheduling
  NET_SCH_DEFAULT = yes;
  DEFAULT_FQ_PIE = yes;

  # Disable unused features
  CRYPTO_842 = no;
  DEBUG_MISC = no;
  DEBUG_PREEMPT = no;
  DEFAULT_SECURITY_APPARMOR = yes;
  FTRACE = lib.mkForce no;
  GCC_PLUGINS = no;
  HIBERNATION = no;
  KEXEC = no;
  KEXEC_FILE = lib.mkForce no;
  PROVIDE_OHCI1394_DMA_INIT = no;
  SECURITY_SELINUX = no;
  X86_SGX = lib.mkForce no;

  # Disable unused features - clear errors
  BPF_EVENTS = lib.mkForce (option no);
  FTRACE_SYSCALLS = lib.mkForce (option no);
  FUNCTION_PROFILER = lib.mkForce (option no);
  FUNCTION_TRACER = lib.mkForce (option no);
  NET_DROP_MONITOR = lib.mkForce (option no);
  RING_BUFFER_BENCHMARK = lib.mkForce (option no);
  SCHED_TRACER = lib.mkForce (option no);
  STACK_TRACER = lib.mkForce (option no);
  X86_SGX_KVM = lib.mkForce (option no);

  # Fonts
  FONTS = yes;
  FONT_8x16 = yes;

  # Ksmbd
  CIFS_SMB_DIRECT = yes;
  CIFS_SWN_UPCALL = yes;
  SMB_SERVER = module;
  SMB_SERVER_CHECK_CAP_NET_ADMIN = yes;
  SMB_SERVER_KERBEROS5 = yes;
  SMB_SERVER_SMBDIRECT = yes;

  # Lockup detector
  LOCKUP_DETECTOR = yes;
  SOFTLOCKUP_DETECTOR = yes;
  HARDLOCKUP_DETECTOR_PERF = yes;
  HARDLOCKUP_DETECTOR = yes;

  # Prefer EXT4 driver
  EXT2_FS = no;
  EXT3_FS = no;
  EXT4_USE_FOR_EXT2 = yes;

  # Prefer EXT4 driver - clear errors
  EXT2_FS_POSIX_ACL = lib.mkForce (option no);
  EXT2_FS_SECURITY = lib.mkForce (option no);
  EXT2_FS_XATTR = lib.mkForce (option no);
  EXT3_FS_POSIX_ACL = lib.mkForce (option no);
  EXT3_FS_SECURITY = lib.mkForce (option no);

  # Reduce log buffer size
  LOG_BUF_SHIFT = freeform "12";
  LOG_CPU_MAX_BUF_SHIFT = freeform "12";
  PRINTK_SAFE_LOG_BUF_SHIFT = freeform "10";

  # Various tunings
  ACPI_APEI = yes;
  ACPI_APEI_GHES = yes;
  ACPI_DPTF = yes;
  ACPI_FPDT = yes;
  ACPI_PCI_SLOT = yes;
  BPF_JIT_ALWAYS_ON = lib.mkForce yes;
  ENERGY_MODEL = yes;
  FAT_DEFAULT_UTF8 = yes;
  FORTIFY_SOURCE = yes;
  FSCACHE_STATS = yes;
  HARDENED_USERCOPY = yes;
  MAGIC_SYSRQ = no;
  NTFS_FS = no;
  PARAVIRT_TIME_ACCOUNTING = yes;
  PM_AUTOSLEEP = yes;
  PSTORE_ZSTD_COMPRESS = yes;
  PSTORE_ZSTD_COMPRESS_DEFAULT = yes;
  SHUFFLE_PAGE_ALLOCATOR = yes;
  SLAB_FREELIST_HARDENED = yes;
  SLAB_FREELIST_RANDOM = yes;
  WQ_POWER_EFFICIENT_DEFAULT = no; # uses more energy

  # ZRAM & Zswap
  ZRAM = module;
  ZRAM_DEF_COMP_ZSTD = yes;
  ZSWAP_COMPRESSOR_DEFAULT_ZSTD = yes;
  ZSWAP_ZPOOL_DEFAULT_ZSMALLOC = yes;
  ZSWAP_DEFAULT_ON = yes;
  ZBUD = lib.mkForce no;
  Z3FOLD = no;
  ZSMALLOC = lib.mkForce yes;

  ################################################################
  # Below are tunes from blacksys3 (xanmod kernel)
  ################################################################

  # Haswell & newer
  GENERIC_CPU3 = yes;

  # Disable some debugging
  SLUB_DEBUG = no;
  # PM_DEBUG = no;
  # PM_ADVANCED_DEBUG = no;
  # PM_SLEEP_DEBUG = no;
  ACPI_DEBUG = no;
  # SCHED_DEBUG = no;
  LATENCYTOP = no;

  # Enable CC_OPTIMIZE_FOR_PERFORMANCE_O3
  CC_OPTIMIZE_FOR_PERFORMANCE = no;
  CC_OPTIMIZE_FOR_SIZE = no;
  # CC_OPTIMIZE_FOR_PERFORMANCE_O3 = yes;

  # Set PCIEASPM DRIVER to performance
  PCIEASPM = yes;
  PCIEASPM_PERFORMANCE = yes;

  # Set PCIE_BUS for performance
  PCIE_BUS_PERFORMANCE = yes;

  SCHED_AUTOGROUP_DEFAULT_ENABLED = yes;

  #Enable multigenerational LRU with xanmod config
  ARCH_HAS_NONLEAF_PMD_YOUNG = yes;
  LRU_GEN = yes;
  # NR_LRU_GENS = freeform "4";
  # TIERS_PER_GEN = freeform "2";
  LRU_GEN_ENABLED = no;
  LRU_GEN_STATS = no;

  # Disabling Kyber I/O scheduler
  # MQ_IOSCHED_KYBER = no;

  ################################################################
  # Below are tunes from nixpkgs (xanmod kernel)
  ################################################################

  # AMD P-state driver
  # Seems causing issues on an AMD VM?
  X86_AMD_PSTATE = lib.mkForce no;

  # Paragon's NTFS3 driver
  NTFS3_FS = module;
  NTFS3_LZX_XPRESS = yes;
  NTFS3_FS_POSIX_ACL = yes;

  PREEMPT_RCU = yes;
  TASKS_RCU = yes;
  UNINLINE_SPIN_UNLOCK = yes;

  # Preemptive Full Tickless Kernel at 500Hz
  SCHED_CORE = yes;
  PREEMPT_VOLUNTARY = lib.mkForce no;
  PREEMPT = lib.mkForce yes;
  PREEMPTION = yes;
  PREEMPT_BUILD = yes;
  NO_HZ_FULL = yes;
  HZ_500 = yes;
  HZ = freeform "500";
  HZ_PERIODIC = no;
  NO_HZ_IDLE = no;
  CONTEXT_TRACKING_FORCE = no;
  NO_HZ = yes;
  NO_HZ_COMMON = yes;
  CONTEXT_TRACKING = yes;
  VIRT_CPU_ACCOUNTING_GEN = yes;

  # Graysky's additional CPU optimizations
  CC_OPTIMIZE_FOR_PERFORMANCE_O3 = yes;

  # Futex WAIT_MULTIPLE implementation for Wine / Proton Fsync.
  FUTEX = yes;
  FUTEX_PI = yes;

  # WineSync driver for fast kernel-backed Wine
  WINESYNC = module;
}
