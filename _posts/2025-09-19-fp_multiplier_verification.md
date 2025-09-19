title: "Datapath Verification of Floating-Point Multipliers with Case Splitting"
date: 2025-09-19
categories: [hardware-verification, floating-point, formal-methods]
tags: [dpv, synopsys, ieee754, datapath, softfloat, case-splitting]
-------------------------------------------------------------------

Floating-point multiplication is a core operation in many designs, but verifying it can be quite complex. This post discusses how we used **Synopsys DPV (Hector)** for datapath verification of a floating-point multiplier, leveraging **SoftFloat** as a reference, and applying **case splitting techniques** to achieve convergence.

---

## Overview of Floating-Point Multiplication

In IEEE 754 floating-point multiplication, the datapath involves:

- Multiplying **mantissas**
- Computing the **result exponent**
- Determining the **sign bit**

### Key Complexity Drivers

1. **Multiplier logic**
2. **Rounding logic**

Within the mantissa multiplier path, multiple things happen in parallel:

- Normalization handling
- Leading zero counting
- Detection of special cases
- Exponent handling

The final result combines mantissa product, exponent adjustment, sign determination, and additional metadata (e.g., zero counts).

---

## Verification Setup

We used the following approach:

- **Tool:** [DPV (Hector) from Synopsys](https://www.synopsys.com/)
- **Reference model:** [SoftFloat library](https://www.jhauser.us/arithmetic/SoftFloat.html)

The verification flow requires creating and compiling both the specification and implementation. For each, a `proc` is defined in TCL, which can then be invoked for compilation.

---

## Initial Equivalence Checking

The simplest assertion is to check equivalence of the outputs between RTL and C-model directly:

```tcl
assert spec_output == impl_output
```

However, this naive check rarely converges due to the complexity of floating-point arithmetic. Therefore, **case splitting** strategies must be applied.

---

## Case Splitting Strategy

We defined a TCL procedure for **case splitting**:

```tcl
proc case_split {} {
    caseSplitStrategy top -script "orch_multipliers"

    caseBegin any_inf
    caseAssume (impl.rs1_i(1)[30:23] == 8'b11111111 && impl.rs1_i(1)[22:0] == 0 )              || (impl.rs2_i(1)[30:23] == 8'b11111111 && impl.rs2_i(1)[22:0] == 0)

    caseBegin any_nan
    caseAssume (impl.rs1_i(1)[30:23] == 8'b11111111 && impl.rs1_i(1)[22:0] != 0 )              || (impl.rs2_i(1)[30:23] == 8'b11111111 && impl.rs2_i(1)[22:0] != 0)

    caseBegin any_zero
    caseAssume (impl.rs1_i(1)[30:0]== 0 ) || (impl.rs2_i(1)[30:0] == 0)

    caseBegin DD
    caseAssume (impl.rs1_i(1)[30:23] == 8'b00000000 && impl.rs1_i(1)[22:0] != 0 )              && (impl.rs2_i(1)[30:23] == 8'b00000000 && impl.rs2_i(1)[22:0] != 0)

    caseBegin NN
    caseAssume (impl.rs1_i(1)[30:23] != 8'b00000000 && impl.rs1_i(1)[30:23] != 8'b11111111 )              && (impl.rs2_i(1)[30:23] != 8'b00000000 && impl.rs2_i(1)[30:23] != 8'b11111111 )

    caseBegin ND
    caseAssume (impl.rs1_i(1)[30:23] != 8'b00000000 && impl.rs1_i(1)[30:23] != 8'b11111111 )              && (impl.rs2_i(1)[30:23] == 8'b00000000 && impl.rs2_i(1)[22:0] != 0)

    caseBegin DN
    caseAssume (impl.rs1_i(1)[30:23] == 8'b00000000 && impl.rs1_i(1)[22:0] != 0 )              && (impl.rs2_i(1)[30:23] != 8'b00000000 && impl.rs2_i(1)[30:23] != 8'b11111111)

    # Further enumerations added below...
}
set_hector_case_splitting_procedure "case_split"
```

---

## IEEE 754 Case Classification

Floating-point operands fall into **seven major categories**:

1. **Infinity (INF):**
   ```
   (exp == 255 && frac == 0)
   ```
2. **NaN (Not a Number):**
   ```
   (exp == 255 && frac != 0)
   ```
3. **Zero:**
   ```
   (sign, exp, frac == 0)
   ```
4. **Both Denormalized**
5. **Both Normalized**
6. **One Normalized, One Denormalized**
7. **One Denormalized, One Normalized**

The tool ensures case completeness by generating an additional assertion that checks whether all possibilities are covered.

### Classification Diagram

```mermaid
flowchart TD
    A[IEEE 754 Operand Classification] --> B[Infinity (INF)]
    A --> C[NaN]
    A --> D[Zero]
    A --> E[Both Denormalized]
    A --> F[Both Normalized]
    A --> G[One Normalized + One Denormalized]
    A --> H[One Denormalized + One Normalized]
```

---

## Deeper Case Splitting with `caseEnumerate`

The first four cases (INF, NaN, Zero, Denormalized) converged quickly.
However, for **mixed and normalized cases**, additional splitting was required.

We used the **`caseEnumerate`** command:

```tcl
caseEnumerate ND1 -type leading1 -expr impl.rs1_i(1)[22:0] -parent ND
caseEnumerate ND2 -type leading1 -expr impl.rs2_i(1)[22:0] -parent ND1
caseEnumerate DN1 -type leading1 -expr impl.rs1_i(1)[22:0] -parent DN
caseEnumerate DN2 -type leading1 -expr impl.rs2_i(1)[22:0] -parent DN1
caseEnumerate NN1 -type leading1 -expr impl.rs1_i(1)[4:0]  -parent NN
caseEnumerate NN2 -type leading1 -expr impl.rs2_i(1)[4:0]  -parent NN1
```

### Leading-One Enumeration

For an `n`-bit expression `E`:

- **FULL mode:** Creates `2^n` cases
- **LEADING_ONE mode:** Creates `n + 1` cases:
  - Case 0: `E = 0`
  - Case 1: Leading one at MSB
  - …
  - Case n: Leading one at LSB

Example for a 3-bit variable (`E` ∈ {0..7}):

- FULL: 8 cases (0–7)
- LEADING_ONE: 4 cases
  - `E=0`
  - `E∈{4,5,6,7}`
  - `E∈{2,3}`
  - `E=1`

This drastically reduces the number of branches, making datapath validation feasible.

---

## Conflict Handling

When creating multiple nested case splits, conflicts may arise. For example:

- A parent split assumes **E ≠ 0**
- A child split enumerates **E = 0**

The tool marks such branches as **conflict**.
This does **not** mean the proof is incorrect; completeness at the top level ensures correctness.

You can debug conflicts with:

```tcl
conflictcore
```

---

## Benefits of Case Splitting with Leading-One

- ✅ Reduces manual effort
- ✅ Decreases state-space explosion
- ✅ Ensures completeness with tool-generated assertions
- ✅ Particularly effective for datapath verification tasks

---

## References

- [IEEE 754 Standard for Floating-Point Arithmetic](https://ieeexplore.ieee.org/document/4610935)
- [SoftFloat Library – John Hauser](https://www.jhauser.us/arithmetic/SoftFloat.html)
- [Synopsys Formality &amp; DPV Documentation](https://www.synopsys.com/)

---

*This post is part of my ongoing notes on datapath verification techniques. Feedback and discussions are welcome!*jk:w
