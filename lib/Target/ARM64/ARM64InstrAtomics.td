//===- ARM64InstrAtomics.td - ARM64 Atomic codegen support -*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// ARM64 Atomic operand code-gen constructs.
//
//===----------------------------------------------------------------------===//

//===----------------------------------
// Atomic fences
//===----------------------------------
def : Pat<(atomic_fence (i64 4), (imm)), (DMB (i32 0x9))>;
def : Pat<(atomic_fence (imm), (imm)), (DMB (i32 0xb))>;

//===----------------------------------
// Atomic loads
//===----------------------------------

// When they're actually atomic, only one addressing mode (GPR64sp) is
// supported, but when they're relaxed and anything can be used, all the
// standard modes would be valid and may give efficiency gains.

// A atomic load operation that actually needs acquire semantics.
class acquiring_load<PatFrag base>
  : PatFrag<(ops node:$ptr), (base node:$ptr), [{
  AtomicOrdering Ordering = cast<AtomicSDNode>(N)->getOrdering();
  assert(Ordering != AcquireRelease && "unexpected load ordering");
  return Ordering == Acquire || Ordering == SequentiallyConsistent;
}]>;

// An atomic load operation that does not need either acquire or release
// semantics.
class relaxed_load<PatFrag base>
  : PatFrag<(ops node:$ptr), (base node:$ptr), [{
  AtomicOrdering Ordering = cast<AtomicSDNode>(N)->getOrdering();
  return Ordering == Monotonic || Ordering == Unordered;
}]>;

// 8-bit loads
def : Pat<(acquiring_load<atomic_load_8>  GPR64sp:$ptr), (LDARB GPR64sp:$ptr)>;
def : Pat<(relaxed_load<atomic_load_8> ro_indexed8:$addr),
          (LDRBBro ro_indexed8:$addr)>;
def : Pat<(relaxed_load<atomic_load_8> am_indexed8:$addr),
          (LDRBBui am_indexed8:$addr)>;
def : Pat<(relaxed_load<atomic_load_8> am_unscaled8:$addr),
          (LDURBBi am_unscaled8:$addr)>;

// 16-bit loads
def : Pat<(acquiring_load<atomic_load_16> GPR64sp:$ptr), (LDARH GPR64sp:$ptr)>;
def : Pat<(relaxed_load<atomic_load_16> ro_indexed16:$addr),
          (LDRHHro ro_indexed16:$addr)>;
def : Pat<(relaxed_load<atomic_load_16> am_indexed16:$addr),
          (LDRHHui am_indexed16:$addr)>;
def : Pat<(relaxed_load<atomic_load_16> am_unscaled16:$addr),
          (LDURHHi am_unscaled16:$addr)>;

// 32-bit loads
def : Pat<(acquiring_load<atomic_load_32> GPR64sp:$ptr), (LDARW GPR64sp:$ptr)>;
def : Pat<(relaxed_load<atomic_load_32> ro_indexed32:$addr),
          (LDRWro ro_indexed32:$addr)>;
def : Pat<(relaxed_load<atomic_load_32> am_indexed32:$addr),
          (LDRWui am_indexed32:$addr)>;
def : Pat<(relaxed_load<atomic_load_32> am_unscaled32:$addr),
          (LDURWi am_unscaled32:$addr)>;

// 64-bit loads
def : Pat<(acquiring_load<atomic_load_64> GPR64sp:$ptr), (LDARX GPR64sp:$ptr)>;
def : Pat<(relaxed_load<atomic_load_64> ro_indexed64:$addr),
          (LDRXro ro_indexed64:$addr)>;
def : Pat<(relaxed_load<atomic_load_64> am_indexed64:$addr),
          (LDRXui am_indexed64:$addr)>;
def : Pat<(relaxed_load<atomic_load_64> am_unscaled64:$addr),
          (LDURXi am_unscaled64:$addr)>;

//===----------------------------------
// Atomic stores
//===----------------------------------

// When they're actually atomic, only one addressing mode (GPR64sp) is
// supported, but when they're relaxed and anything can be used, all the
// standard modes would be valid and may give efficiency gains.

// A store operation that actually needs release semantics.
class releasing_store<PatFrag base>
  : PatFrag<(ops node:$ptr, node:$val), (base node:$ptr, node:$val), [{
  AtomicOrdering Ordering = cast<AtomicSDNode>(N)->getOrdering();
  assert(Ordering != AcquireRelease && "unexpected store ordering");
  return Ordering == Release || Ordering == SequentiallyConsistent;
}]>;

// An atomic store operation that doesn't actually need to be atomic on ARM64.
class relaxed_store<PatFrag base>
  : PatFrag<(ops node:$ptr, node:$val), (base node:$ptr, node:$val), [{
  AtomicOrdering Ordering = cast<AtomicSDNode>(N)->getOrdering();
  return Ordering == Monotonic || Ordering == Unordered;
}]>;

// 8-bit stores
def : Pat<(releasing_store<atomic_store_8> GPR64sp:$ptr, GPR32:$val),
          (STLRB GPR32:$val, GPR64sp:$ptr)>;
def : Pat<(relaxed_store<atomic_store_8> ro_indexed8:$ptr, GPR32:$val),
          (STRBBro GPR32:$val, ro_indexed8:$ptr)>;
def : Pat<(relaxed_store<atomic_store_8> am_indexed8:$ptr, GPR32:$val),
          (STRBBui GPR32:$val, am_indexed8:$ptr)>;
def : Pat<(relaxed_store<atomic_store_8> am_unscaled8:$ptr, GPR32:$val),
          (STURBBi GPR32:$val, am_unscaled8:$ptr)>;

// 16-bit stores
def : Pat<(releasing_store<atomic_store_16> GPR64sp:$ptr, GPR32:$val),
          (STLRH GPR32:$val, GPR64sp:$ptr)>;
def : Pat<(relaxed_store<atomic_store_16> ro_indexed16:$ptr, GPR32:$val),
          (STRHHro GPR32:$val, ro_indexed16:$ptr)>;
def : Pat<(relaxed_store<atomic_store_16> am_indexed16:$ptr, GPR32:$val),
          (STRHHui GPR32:$val, am_indexed16:$ptr)>;
def : Pat<(relaxed_store<atomic_store_16> am_unscaled16:$ptr, GPR32:$val),
          (STURHHi GPR32:$val, am_unscaled16:$ptr)>;

// 32-bit stores
def : Pat<(releasing_store<atomic_store_32> GPR64sp:$ptr, GPR32:$val),
          (STLRW GPR32:$val, GPR64sp:$ptr)>;
def : Pat<(relaxed_store<atomic_store_32> ro_indexed32:$ptr, GPR32:$val),
          (STRWro GPR32:$val, ro_indexed32:$ptr)>;
def : Pat<(relaxed_store<atomic_store_32> am_indexed32:$ptr, GPR32:$val),
          (STRWui GPR32:$val, am_indexed32:$ptr)>;
def : Pat<(relaxed_store<atomic_store_32> am_unscaled32:$ptr, GPR32:$val),
          (STURWi GPR32:$val, am_unscaled32:$ptr)>;

// 64-bit stores
def : Pat<(releasing_store<atomic_store_64> GPR64sp:$ptr, GPR64:$val),
          (STLRX GPR64:$val, GPR64sp:$ptr)>;
def : Pat<(relaxed_store<atomic_store_64> ro_indexed64:$ptr, GPR64:$val),
          (STRXro GPR64:$val, ro_indexed64:$ptr)>;
def : Pat<(relaxed_store<atomic_store_64> am_indexed64:$ptr, GPR64:$val),
          (STRXui GPR64:$val, am_indexed64:$ptr)>;
def : Pat<(relaxed_store<atomic_store_64> am_unscaled64:$ptr, GPR64:$val),
          (STURXi GPR64:$val, am_unscaled64:$ptr)>;

//===----------------------------------
// Low-level exclusive operations
//===----------------------------------

// Load-exclusives.

def ldxr_1 : PatFrag<(ops node:$ptr), (int_arm64_ldxr node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i8;
}]>;

def ldxr_2 : PatFrag<(ops node:$ptr), (int_arm64_ldxr node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i16;
}]>;

def ldxr_4 : PatFrag<(ops node:$ptr), (int_arm64_ldxr node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i32;
}]>;

def ldxr_8 : PatFrag<(ops node:$ptr), (int_arm64_ldxr node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i64;
}]>;

def : Pat<(ldxr_1 am_noindex:$addr),
          (SUBREG_TO_REG (i64 0), (LDXRB am_noindex:$addr), sub_32)>;
def : Pat<(ldxr_2 am_noindex:$addr),
          (SUBREG_TO_REG (i64 0), (LDXRH am_noindex:$addr), sub_32)>;
def : Pat<(ldxr_4 am_noindex:$addr),
          (SUBREG_TO_REG (i64 0), (LDXRW am_noindex:$addr), sub_32)>;
def : Pat<(ldxr_8 am_noindex:$addr), (LDXRX am_noindex:$addr)>;

def : Pat<(and (ldxr_1 am_noindex:$addr), 0xff),
          (SUBREG_TO_REG (i64 0), (LDXRB am_noindex:$addr), sub_32)>;
def : Pat<(and (ldxr_2 am_noindex:$addr), 0xffff),
          (SUBREG_TO_REG (i64 0), (LDXRH am_noindex:$addr), sub_32)>;
def : Pat<(and (ldxr_4 am_noindex:$addr), 0xffffffff),
          (SUBREG_TO_REG (i64 0), (LDXRW am_noindex:$addr), sub_32)>;

// Load-exclusives.

def ldaxr_1 : PatFrag<(ops node:$ptr), (int_arm64_ldaxr node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i8;
}]>;

def ldaxr_2 : PatFrag<(ops node:$ptr), (int_arm64_ldaxr node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i16;
}]>;

def ldaxr_4 : PatFrag<(ops node:$ptr), (int_arm64_ldaxr node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i32;
}]>;

def ldaxr_8 : PatFrag<(ops node:$ptr), (int_arm64_ldaxr node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i64;
}]>;

def : Pat<(ldaxr_1 am_noindex:$addr),
          (SUBREG_TO_REG (i64 0), (LDAXRB am_noindex:$addr), sub_32)>;
def : Pat<(ldaxr_2 am_noindex:$addr),
          (SUBREG_TO_REG (i64 0), (LDAXRH am_noindex:$addr), sub_32)>;
def : Pat<(ldaxr_4 am_noindex:$addr),
          (SUBREG_TO_REG (i64 0), (LDAXRW am_noindex:$addr), sub_32)>;
def : Pat<(ldaxr_8 am_noindex:$addr), (LDAXRX am_noindex:$addr)>;

def : Pat<(and (ldaxr_1 am_noindex:$addr), 0xff),
          (SUBREG_TO_REG (i64 0), (LDAXRB am_noindex:$addr), sub_32)>;
def : Pat<(and (ldaxr_2 am_noindex:$addr), 0xffff),
          (SUBREG_TO_REG (i64 0), (LDAXRH am_noindex:$addr), sub_32)>;
def : Pat<(and (ldaxr_4 am_noindex:$addr), 0xffffffff),
          (SUBREG_TO_REG (i64 0), (LDAXRW am_noindex:$addr), sub_32)>;

// Store-exclusives.

def stxr_1 : PatFrag<(ops node:$val, node:$ptr),
                     (int_arm64_stxr node:$val, node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i8;
}]>;

def stxr_2 : PatFrag<(ops node:$val, node:$ptr),
                     (int_arm64_stxr node:$val, node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i16;
}]>;

def stxr_4 : PatFrag<(ops node:$val, node:$ptr),
                     (int_arm64_stxr node:$val, node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i32;
}]>;

def stxr_8 : PatFrag<(ops node:$val, node:$ptr),
                     (int_arm64_stxr node:$val, node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i64;
}]>;


def : Pat<(stxr_1 GPR64:$val, am_noindex:$addr),
          (STXRB (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;
def : Pat<(stxr_2 GPR64:$val, am_noindex:$addr),
          (STXRH (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;
def : Pat<(stxr_4 GPR64:$val, am_noindex:$addr),
          (STXRW (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;
def : Pat<(stxr_8 GPR64:$val, am_noindex:$addr),
          (STXRX GPR64:$val, am_noindex:$addr)>;

def : Pat<(stxr_1 (zext (and GPR32:$val, 0xff)), am_noindex:$addr),
          (STXRB GPR32:$val, am_noindex:$addr)>;
def : Pat<(stxr_2 (zext (and GPR32:$val, 0xffff)), am_noindex:$addr),
          (STXRH GPR32:$val, am_noindex:$addr)>;
def : Pat<(stxr_4 (zext GPR32:$val), am_noindex:$addr),
          (STXRW GPR32:$val, am_noindex:$addr)>;

def : Pat<(stxr_1 (and GPR64:$val, 0xff), am_noindex:$addr),
          (STXRB (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;
def : Pat<(stxr_2 (and GPR64:$val, 0xffff), am_noindex:$addr),
          (STXRH (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;
def : Pat<(stxr_4 (and GPR64:$val, 0xffffffff), am_noindex:$addr),
          (STXRW (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;

// Store-release-exclusives.

def stlxr_1 : PatFrag<(ops node:$val, node:$ptr),
                     (int_arm64_stlxr node:$val, node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i8;
}]>;

def stlxr_2 : PatFrag<(ops node:$val, node:$ptr),
                     (int_arm64_stlxr node:$val, node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i16;
}]>;

def stlxr_4 : PatFrag<(ops node:$val, node:$ptr),
                     (int_arm64_stlxr node:$val, node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i32;
}]>;

def stlxr_8 : PatFrag<(ops node:$val, node:$ptr),
                     (int_arm64_stlxr node:$val, node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::i64;
}]>;


def : Pat<(stlxr_1 GPR64:$val, am_noindex:$addr),
          (STLXRB (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;
def : Pat<(stlxr_2 GPR64:$val, am_noindex:$addr),
          (STLXRH (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;
def : Pat<(stlxr_4 GPR64:$val, am_noindex:$addr),
          (STLXRW (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;
def : Pat<(stlxr_8 GPR64:$val, am_noindex:$addr),
          (STLXRX GPR64:$val, am_noindex:$addr)>;

def : Pat<(stlxr_1 (zext (and GPR32:$val, 0xff)), am_noindex:$addr),
          (STLXRB GPR32:$val, am_noindex:$addr)>;
def : Pat<(stlxr_2 (zext (and GPR32:$val, 0xffff)), am_noindex:$addr),
          (STLXRH GPR32:$val, am_noindex:$addr)>;
def : Pat<(stlxr_4 (zext GPR32:$val), am_noindex:$addr),
          (STLXRW GPR32:$val, am_noindex:$addr)>;

def : Pat<(stlxr_1 (and GPR64:$val, 0xff), am_noindex:$addr),
          (STLXRB (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;
def : Pat<(stlxr_2 (and GPR64:$val, 0xffff), am_noindex:$addr),
          (STLXRH (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;
def : Pat<(stlxr_4 (and GPR64:$val, 0xffffffff), am_noindex:$addr),
          (STLXRW (EXTRACT_SUBREG GPR64:$val, sub_32), am_noindex:$addr)>;


// And clear exclusive.

def : Pat<(int_arm64_clrex), (CLREX 0xf)>;
