
---
layout: post
title: "Lean4 Tactics I Keep Coming Back To"
date: 2025-10-22
---

Learning Lean4 has a particular shape to it. The type theory is deep, the dependent types take time to internalize, and the error messages are occasionally cryptic. But the tactic language — the part you use when actually proving things interactively — is surprizingly learnable. You accumulate a small vocabulary of tactics, and most proofs are written with maybe eight or ten of them.

This is a record of the tactics I reach for most often, written partly as reference and partly as the explanation I wish I'd had earlier. It is not exhaustive. It is the core vocabulary.

---

## The Tactics

### `simp`

Start here. When you are stuck and have no idea what to try, try `simp`.

`simp` applies a collection of rewrite rules — lemmas tagged with `@[simp]` in Lean's standard library, plus any you add — to simplify the current goal. It works forward (simplifying the goal) and sometimes closes it entirely.

```lean
theorem foo (n : Nat) : n + 0 = n := by
  simp
```

A few useful variants:

- `simp at h` — simplifies hypothesis `h` instead of the goal
- `simp [myLemma]` — adds `myLemma` to the simp set for this call
- `simp_all` — simplifies both the goal and all hypotheses simultaneously

`simp_all` is powerful but expensive. On a complex theorem it can time out or slow the server noticeably. Use it when `simp` alone isn't enough, but reach for it deliberately rather than as a first resort.

---

### `omega`

Use this to close linear arithmetic goals over integers and naturals. Inequalities, equalities, modular arithmetic — if it is linear and the variables are integers, `omega` will usually handle it without any help.

```lean
theorem bar (n m : Nat) (h : n < m) : n + 1 ≤ m := by
  omega
```

For hardware verification, where almost everything is `BitVec`, the relevant variant is **`bv_omega`**. It handles the same class of goals but over bitvectors, including wrapping arithmetic. It has become one of the most-used tactics in my Lean4 hardware work.

```lean
theorem wrap (x : BitVec 32) : (x + 1 - 1) = x := by
  bv_omega
```

If your goal involves bitvector arithmetic and `omega` fails, try `bv_omega` before reaching for anything heavier.

---

### `split`

When your goal or a hypothesis contains `if ... then ... else` or a `match` expression, `split` breaks the proof into one subgoal per branch — automatically, without you having to name the cases manually.

```lean
def abs (n : Int) : Int :=
  if n ≥ 0 then n else -n

theorem abs_nonneg (n : Int) : abs n ≥ 0 := by
  simp [abs]
  split
  · omega
  · omega
```

This is especially useful in hardware models, where functions tend to be written as chains of conditional checks. `split` turns each conditional into a separate, manageable subgoal.

---

### `cases`

Where `split` works on the *goal*, `cases` works on a *hypothesis* (or a term). It destructs the hypothesis into its possible constructors, creating one subgoal per constructor.

```lean
theorem or_elim' (h : P ∨ Q) : Q ∨ P := by
  cases h with
  | inl hp => exact Or.inr hp
  | inr hq => exact Or.inl hq
```

A subtlety worth knowing: if you write `cases h` without the `with` clause, the generated hypotheses are unnamed. In that situation, `rename_i` (below) is your friend.

There is also `cases h : expr` — the named variant — which gives you an explicit hypothesis `h : expr = <constructor>` in each branch. This is often necessary when you need to refer back to *why* you are in a particular case during the proof.

---

### `rename_i`

Lean sometimes generates hypotheses with auto-generated names like `h✝` or `h✝¹`. These are hard to work with. `rename_i` lets you rename them in order.

```lean
cases someExpr
· rename_i h₁
  -- now h₁ refers to the unnamed hypothesis in this branch
  exact h₁
```

It is a small quality-of-life tactic, but without it, proofs with multiple unnamed hypotheses become very hard to read and debug.

---

### `have`

`have` lets you introduce an intermediate fact — either derived from existing hypotheses, or stated as a new subgoal you then prove inline.

```lean
theorem transitivity (h₁ : a < b) (h₂ : b < c) : a < c := by
  have h₃ : a < b := h₁   -- naming an existing fact
  have h₄ : b < c := h₂
  omega
```

The more interesting use is proving a helper lemma inline rather than breaking it out into a separate theorem:

```lean
have key : someComplexExpression = simplifiedForm := by
  simp [myDef]
  bv_omega
rw [key]
```

This keeps the proof localized and readable when you need a fact that is too specific to be worth a top-level lemma.

---

### `contradiction`

When you have two hypotheses that cannot both be true, `contradiction` closes the goal automatically. You do not need to spell out which pair contradicts — Lean finds it.

```lean
theorem absurd_example (h₁ : x = 0) (h₂ : x ≠ 0) : False := by
  contradiction
```

This comes up often at the end of case splits, where certain branches are structurally impossible. Rather than constructing the explicit absurdity, just call `contradiction` and move on.

---

### `constructor`

When the *goal* is a structure or a conjunction, `constructor` breaks it into one subgoal per field. For `And`, it gives you two subgoals. For a custom structure, one per field.

```lean
theorem and_intro (hp : P) (hq : Q) : P ∧ Q := by
  constructor
  · exact hp
  · exact hq
```

It is the goal-side counterpart to `cases`. `cases` destructs hypotheses; `constructor` destructs goals.

---

## Proof Organization

A proof that works is not the same as a proof that is readable. As proofs grow — particularly over hardware models with many conditional branches — structure matters.

**Use `·` to mark branches.** After any tactic that creates multiple subgoals (`split`, `cases`, `constructor`), prefix each branch with `·`. This makes the tree structure of the proof visible.

```lean
split
· -- first branch
  simp
· -- second branch
  omega
```

**Use `{ ... }` to delimit blocks explicitly.** When branches are long or nested, wrapping them in braces makes it unambiguous where each branch ends. I tend to combine this with `·` for the outermost level and braces for inner nesting.

**Use `<;>` to broadcast a tactic across all branches.** If the same tactic closes every branch of a `split` or `cases`, you can write it once:

```lean
split <;> simp
split <;> bv_omega
```

This reduces noise significantly when the cases are symmetric. The tradeoff is readability: `<;>` can obscure what is actually happening in each branch. Use it freely when the tactic is trivial (like `simp` or `omega`), but write the branches out explicitly when the proof is more involved and you want a reader to be able to follow it.

---

## A Note on Learning

The best way to build tactic intuition is to work through small, self-contained proofs where you can experiment freely. The Lean4 InfoView panel — showing the current goal and hypotheses at any point in the proof — is the main feedback loop. Learn to read it quickly.

When stuck: try `simp`, then `omega` or `bv_omega`, then `split` or `cases` to break the problem apart. Most goals eventually yield to some combination of these.

---

*This post is part of an ongoing series of notes on Lean4 for hardware verification*
