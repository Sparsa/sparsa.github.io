---
layout: post
title: "Proving Fast Mersenne Modulo Correct in Lean 4"
date: 2026-05-10
description: "Proving the shift-and-add Mersenne modulo trick correct in Lean 4."
---
Hardware datapaths often need to compute `a mod (2^n − 1)`, a so-called **Mersenne modulo** efficiently. This shows up in hashing, CRC circuits, residue number systems, and checksum logic. The naïve approach uses a hardware divider, which is expensive. The fast approach uses only a shift and an add. In this post, I'll walk through the trick, prove it correct in **Lean 4**, and connect it to formal hardware verification.

---

## The Fast Trick

The identity we want to exploit is:

> For any natural number `a` and base `b = 2^k`:
> `a mod (b − 1) = (a / b + a mod b) mod (b − 1)`

In plain terms: split `a` into its upper `k` bits (the quotient when divided by `2^k`) and its lower `k` bits (the remainder), add them together, then reduce once more. For the specific case `k = 32`:

```
a mod 4294967295 = (a >> 32) + (a & 0xFFFFFFFF)
```

with one conditional subtraction if the sum overflows 4294967295. In Lean 4:

```lean
def mod_fast (input : Nat) :=
  let MOD := (input >>> 32) + (input &&& 4294967295)
  if MOD ≥ 4294967295 then MOD - 4294967295 else MOD
```

No division. No multiplier. Just a shift, a bitwise AND, an addition, and a comparison.

---

## Why It Works: The Algebra

The key algebraic lemma is:

```lean
theorem mod_pred (a b : Nat) (hb : 1 < b) :
    a % (b - 1) = (a / b + a % b) % (b - 1)
```

The proof proceeds by showing that `a` can be rewritten as:

```
a = (a / b) * (b − 1) + (a / b + a % b)
```

which follows from the standard division identity `a = (a / b) * b + a % b` combined with `(a / b) * (b − 1) = (a / b) * b − (a / b)`. Once we have this decomposition, Lean's `Nat.mul_add_mod_self_right` immediately gives us the result, since `(a/b) * (b−1)` is an exact multiple of `(b−1)`.

The full proof in Lean 4:

```lean
theorem mod_pred (a b : Nat) (hb : 1 < b) :
    a % (b - 1) = (a / b + a % b) % (b - 1) := by
  have h1 : a / b * (b - 1) + a / b = a / b * b := by
    cases b with
    | zero => simp
    | succ n => simp [Nat.mul_succ]
  have hdiv := Nat.div_add_mod a b
  have k : a = a / b * (b - 1) + (a / b + a % b) := by omega
  have lhs : a % (b - 1) = (a / b * (b - 1) + (a / b + a % b)) % (b - 1) := by
    rw [← k]
  rw [lhs]
  exact Nat.mul_add_mod_self_right (a / b) (b - 1) (a / b + a % b)
```

---

## Connecting Bitwise Operations to Arithmetic

In Lean 4 (and hardware), `>>>` is a logical right shift and `&&&` is bitwise AND. Before we can use `mod_pred`, we need to establish that these operations correspond to their arithmetic counterparts:

```lean
-- Right shift is integer division by a power of two
a >>> 32 = a / 2^32

-- AND with a mask of n ones is modulo 2^n
a &&& 4294967295 = a % 4294967296
```

Both of these are available as tactics in Lean:

- `Nat.shiftRight_eq_div_pow`
- `Nat.and_two_pow_sub_one_eq_mod`

With these in hand, the bridge from bitwise to arithmetic is just rewriting.

---

## The Correctness Theorem

The main theorem states that `mod_fast` agrees with `mod_orig` (naïve `%`) for all inputs below `2^33`:

```lean
def mod_orig (a : Nat) := a % 4294967295

theorem check_equality (a : Nat) (h : a < 2^33) :
    mod_orig a = mod_fast a
```

The bound `a < 2^33` is tight. The single conditional subtraction in `mod_fast` can only correct for one overflow, so if the sum `(a >>> 32) + (a &&& 0xFFFFFFFF)` exceeds `2 * 4294967295`, the result would be wrong. When `a < 2^33`:

- `a >>> 32 ≤ 1` (at most one extra bit above the lower 32)
- `a &&& 0xFFFFFFFF ≤ 4294967295`
- Their sum is at most `1 + 4294967295 = 4294967296`, which is within one subtraction of the modulus

The proof structure:

```lean
theorem check_equality (a : Nat) (h : a < 2^33) :
    mod_orig a = mod_fast a := by
  -- 1. Rewrite >>> and &&& to / and %
  -- 2. Apply mod_pred to get the algebraic form
  -- 3. Establish bounds on the sum
  -- 4. Split on whether the sum exceeds the modulus
  -- 5. Close both branches with omega
```

Steps 4 and 5 are the key: once we know the sum is less than `2 * 4294967295`, the conditional subtraction either fires (and `omega` verifies the arithmetic) or it doesn't (and `omega` verifies that too).

---

## Hardware Relevance

This pattern, fast modulo via shift-and-add, appears directly in RTL. A synthesised implementation might look like:

```systemverilog
logic [32:0] sum;
assign sum = {1'b0, data_in[63:32]} + data_in[31:0];
assign result = (sum >= 32'hFFFFFFFF) ? sum - 32'hFFFFFFFF : sum[31:0];
```

Formal verification of such a block typically uses an SVA property asserting equivalence to the reference model. What the Lean 4 proof gives us is something stronger: a *machine-checked* proof that the RTL logic template is algebraically correct, independent of any simulation or model checking run. It also precisely characterises the valid input range, which is exactly the kind of constraint you want to carry into a coverage closure plan.

---

## Key Takeaways

- `a mod (2^k − 1)` can be computed with a shift, a bitwise AND, an addition, and at most one subtraction — no divider needed.
- The algebraic justification is `mod_pred`, which follows from the standard division identity.
- Lean 4's `omega` tactic handles the arithmetic reasoning after the algebraic setup is in place; Mathlib supplies the bitwise-to-arithmetic bridge lemmas.
- The input bound `a < 2^33` is not arbitrary — it is the exact condition under which one conditional subtraction suffices.

---

## References

- [Lean 4](https://lean-lang.org/)
- [Mathlib4](https://leanprover-community.github.io/mathlib4_docs/)
- [Mersenne Numbers and Residue Arithmetic](https://en.wikipedia.org/wiki/Mersenne_prime)

---

*Part of my ongoing notes on formal verification of arithmetic hardware. Feedback welcome!*
