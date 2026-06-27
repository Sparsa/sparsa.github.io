---
layout: post
title: "The Verification Gap: What Proofs Actually Guarantee"
date: 2026-06-27
---

There is a question I keep coming back to, especially now that formal verification is being positioned as a serious engineering tool rather than an academic curiosity: *what does a proof actually guarantee?*

Not in the logical sense — that part is well understood. If your premises are correct and your inference rules are sound, your conclusion follows. The question is more uncomfortable than that. It is about what happens between the proof and the running system.

---

## Von Neumann's Invisible Hand

Every program you write, regardless of language, paradigm, or level of abstraction, eventually runs as a sequence of load/store operations, arithmetic on registers, and conditional branches. This is the von Neumann substrate: a mutable memory, a program counter, and an ALU grinding through state transitions one clock cycle at a time.

This is true whether you write imperative C, purely functional Haskell, or declarative Prolog. The CPU does not know about monads or unification or referential transparency. It knows about bytes and addresses.

The usual response to this observation is: so what? The compilation is correct by construction, the abstractions hold, and you reason at the level that matters. This is largely true. But it papers over something important when you add formal verification into the picture.

When you prove a theorem about a program in Lean 4 or Coq, you prove something about a *model* — a mathematical object that lives in the proof assistant's type theory. The claim is that this model faithfully represents the behavior of the program. But the model is not the binary. Between the two sits a stack of transformation layers, each one trusted rather than verified.

---

## The Trust Stack

If you draw it out explicitly, it looks like this:

```
Your proof
    ↓  trust: the proof checker kernel is sound
Specification / model
    ↓  trust: the spec captures what you actually meant
Source code
    ↓  trust: the compiler is correct
IR / assembly
    ↓  trust: the assembler and linker are correct
Binary
    ↓  trust: the CPU implements the ISA faithfully
Silicon
```

Each arrow is a gap. Your proof eliminates uncertainty *within* a single level. It does not touch the arrows.

For hardware, the picture is similar but arguably sharper. When I verify an RTL design — proving properties about a Lean 4 golden model and checking the RTL against it via simulation — there are still the synthesis tool, the place-and-route engine, the standard cell library characterization, and the fab process sitting between my proof and the actual transistors. A theorem about the Lean model says nothing about what the place-and-route tool does to a timing-critical path under corner conditions.

---

## What the Field Has Done About This

The research community has taken this problem seriously, and there are genuine partial solutions worth knowing about.

**CompCert** is a formally verified C compiler, proven correct in Coq. The compilation arrow — from C source to assembly — is no longer blind trust. The proof establishes that for any C program that compiles without undefined behavior, the generated assembly computes the same observable behavior. This is a substantial achievement. It also took years to build and covers one arrow in the stack.

**seL4** went further: a formally verified OS microkernel with a proof chain descending from an abstract functional specification, through a C implementation, to a compiled binary for a specific ARM target. The binary verification required a separate, hand-crafted argument connecting the C proof to the specific artifact produced by a specific compiler invocation. It is the most serious end-to-end effort in existence for a real system, and it covered roughly 10,000 lines of C. The engineering effort was enormous.

**CakeML** addresses the bootstrapping problem directly. It is an ML compiler that is proven correct, and crucially, the proof covers the compiler compiling itself. The trusted base shrinks further.

**The de Bruijn criterion**, baked into the architecture of Lean 4 and Coq, shrinks the trusted base for the proof checker itself. Instead of trusting the entire proof assistant — including the elaborator, the tactic engine, the notation system — you trust only the small kernel that checks proof terms. In Lean 4 this is on the order of a few thousand lines. You can read it. This is the right engineering instinct: you cannot eliminate the TCB, but you can minimize it and make it auditable.

---

## What Nobody Has Solved

The hardware layer is essentially unverified in production silicon. Intel and AMD microarchitectures implement the x86 ISA via microcode and out-of-order execution engines that are proprietary, not formally verified, and not published. The Spectre and Meltdown disclosures made this concrete: the ISA contract — the abstraction that every software proof implicitly relies on — was not honored under certain microarchitectural conditions. A formally verified program running on that CPU had guarantees that silently did not hold.

The specification problem is harder still, and no formal system can fully solve it. Even if every compilation arrow were verified, you would still need to ask whether the specification captures what you actually intended. This is sometimes called the oracle problem or the requirements gap. Formal methods push bugs into the specification, which is better than having them hidden in the implementation, but it shifts rather than eliminates the problem. The specification is written by humans with imperfect understanding of the requirements, and there is no formal system that can verify meaning.

---

## The Honest Framing

Formal verification does not give you absolute correctness. What it gives you is *conditional correctness*: if the specification is right, if the compiler is correct, if the hardware honors the ISA, then the properties you proved hold. The value is not that the conditions are guaranteed — they are not — but that they are *made explicit*.

In a conventional verification flow, the trust is hidden. You trust the simulator, the reference model, the testbench author, the synthesis tool, all silently and without a record. Formal verification forces you to name what you are trusting. It makes the TCB visible. And once it is visible, you can reason about it, audit it, and sometimes verify parts of it.

This is why the correct mental model is not "proof = correctness" but rather "proof = correctness relative to a named and bounded set of assumptions." The proof is a conditional guarantee with explicitly stated premises. Whether those premises hold is a separate, and often harder, question.

---

## A Parallel Worth Drawing

This is not unique to software or hardware. Mathematics itself runs on the same structure. A proof in ZFC set theory is correct relative to the ZFC axioms and the inference rules of first-order logic. Those are not themselves proven — they are taken as given, chosen because they are productive and have not produced contradictions yet. Gödel showed that any sufficiently expressive consistent system cannot prove its own consistency. There is no bedrock; there is only a foundation you choose and then reason above.

Formal verification is the engineering application of the same insight. You cannot verify all the way down. What you can do is choose your foundation deliberately, make it as small and auditable as possible, and be precise about what sits above it and what sits below.

For the work I do — verifying RTL against formally specified golden models — this means being clear that the proof covers the model, the simulation covers the agreement between model and RTL, and the rest of the stack is trusted. That is still better than simulation against an informal Python reference model with no proofs at all. The TCB is smaller and more explicit. But it is not zero, and pretending otherwise would be dishonest.

---

*The goal is not to eliminate uncertainty. It is to know exactly where it lives.*