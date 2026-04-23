---
layout: post
title: "Formal Golden Models for RTL Verification with Lean4"
date: 2026-4-15
---

There is a gap at the heart of hardware verification that we rarely talk about directly.

On one side, you have formal verification — theorem provers, model checkers, property languages. This world is mathematically rigorous. If a property holds, it holds for *all* inputs, forever. But formal tools are famously hard to write and maintain, and they often struggle to scale to complex, stateful designs without significant human guidance.

On the other side, you have simulation-based verification — cocotb testbenches, constrained-random stimulus, coverage-driven flows. This world is practical and scalable. But it relies on a *reference model* being correct, and that model is usually just more software — written in Python or C, informal, untested, and trusted implicitly.

The question I kept coming back to is: what if the reference model were formally verified?

This post describes a flow I've been building that attempts to close this gap. The idea is to write the golden model in **Lean4** — a dependently typed theorem prover — prove properties about it directly, and then expose it to a cocotb simulation testbench via FFI. The RTL is then checked for equivalence against a model we can actually trust.

---

## Why Lean4?

Lean4 is a functional programming language and interactive theorem prover built on dependent type theory. It sits in the same family as Coq, Agda, and Isabelle, but with a key difference: it is also a practical systems programming language. Lean4 compiles to native code, has a real FFI, and is fast enough to use as a runtime library — not just a proof assistant.

This makes it uniquely suited for this use case. In most verification flows, there is a painful translation boundary between the formal world and the simulation world. You prove things about a mathematical model in one language, then re-implement that model in Python or C for the testbench, and silently hope the two match. With Lean4, the model you proved is the model you run.

---

## The Structure of the Flow

The flow has three layers.

**Layer 1: The Lean4 golden model.**
You write the design's behavior as a pure function (or a small state machine) in Lean4. For a combinational block, this might be a single function from inputs to outputs. For a sequential design, it is a step function from `(State, Input) → (State, Output)`.

```lean
structure State where
  address  : UInt32
  counter  : UInt16

def step (s : State) (input : Input) : State × Output :=
  -- formally specify the RTL behavior here
  ...
```

The key point is that this is real, executable Lean4 code — not a specification language or a pseudocode sketch. You can run it, test it, and prove properties about it.

**Layer 2: Proofs about the model.**
Once the model is written, you prove properties that matter for correctness. These might be:

- Invariants that must hold across all reachable states
- Equivalence between two representations (e.g., a high-level spec and a detailed implementation)
- Arithmetic properties (e.g., that 32-bit address wrapping is handled correctly under all inputs)

```lean
theorem address_wraps_at_32bit (s : State) (i : Input) :
    (step s i).1.address &&& 0xFFFFFFFF = (step s i).1.address := by
  simp [step, mask32]
  bv_omega
```

For arithmetic goals over `BitVec`, Lean4's `bv_omega` tactic handles most cases automatically. For more complex properties, you build the proof step by step in the interactive editor, with the type checker rejecting any gap.

**Layer 3: The cocotb testbench.**
The Lean4 model is compiled to a shared library and loaded into the Python testbench via `ctypes`. The testbench drives the RTL, queries the Lean4 model for the expected output, and compares them.

```python
class MyDesignModel:
    def __init__(self, lib):
        self.lib = lib
        self.state = ...  # initialize from Lean4

    def step(self, input_val):
        return self.lib.lean_step(self.state, input_val)
```

This is where **Hypothesis** comes in. Rather than writing manual test vectors, you use Hypothesis's stateful testing framework to generate random sequences of operations automatically. The testbench becomes a property: "for all input sequences, the RTL output matches the Lean4 golden model."

```python
class RTLStateMachine(RuleBasedStateMachine):

    @initialize(base=strategies.integers(min_value=0, max_value=2**32-1))
    def setup(self, base):
        self.model.reset()
        # synchronize DUT and model

    @rule(data=strategies.integers())
    def step(self, data):
        rtl_out  = drive_and_sample(self.dut, data)
        lean_out = self.model.step(data)
        assert rtl_out == lean_out
```

Hypothesis will find the shortest input sequence that violates the property — a genuine counterexample, not just a failing test vector.

---

## The FFI Bridge

Getting Lean4 to talk to Python requires a few careful steps that aren't obviously documented in one place.

The Lean4 runtime (`libleanshared.so`) must be loaded with `RTLD_GLOBAL` *before* loading the design's compiled library. This is because the design library has unresolved symbols that depend on Lean's runtime, and the dynamic linker needs to resolve them globally.

```python
import ctypes, ctypes.util

lean_rt = ctypes.CDLL("libleanshared.so", mode=ctypes.RTLD_GLOBAL)
design  = ctypes.CDLL("./libMyDesign.so")
```

The module initializer must be called before any Lean functions are used. When you compile with `-R` pointing to the source directory, the initializer is named after the module:

```python
init_fn = design.initialize_MyModule
init_fn.restype  = ctypes.c_void_p
init_fn.argtypes = [ctypes.c_int, ctypes.c_void_p]
init_fn(1, None)  # pass 1, not 0
```

Passing `0` here silently corrupts the runtime. This is one of those details that costs hours to debug and three seconds to fix.

Functions marked `@[export]` in Lean4 are accessible by their exported name:

```lean
@[export lean_step]
def leanStep (s : State) (input : UInt64) : UInt64 :=
  (step s (decodeInput input)).encodeOutput
```

You pack inputs and outputs into fixed-width integers for simplicity across the FFI boundary. More complex types require careful marshaling, but for most verification use cases, integers are sufficient.

---

## What You Get

The payoff is that you end up with something more trustworthy than either a pure simulation flow or a pure formal flow.

The Lean4 model is not just trusted software — it is software with machine-checked proofs attached. When the testbench finds a mismatch, you know the RTL is wrong, not the model. When the proofs hold, you know specific properties are guaranteed, not just likely.

Hypothesis gives you the depth of randomized testing without the manual effort of writing test vectors. It will find bugs in corner cases — overflow at address boundaries, flag computation on the last beat of a burst, counter wraparound — that hand-written tests would miss.

And because everything is wired together — Lean compilation, RTL elaboration, simulation — in a single pipeline, regression is one command.

---

## Limitations and Open Questions

This flow is not a replacement for formal sign-off. The simulation coverage is better than hand-written tests, but it is still finite sampling. For full correctness, you would need to prove the RTL equivalent to the Lean model directly, which requires an equivalence checking step on top of this flow — something like DPV or a custom model checking setup.

The FFI boundary also introduces a marshaling layer that must be written carefully. If the encoding of inputs and outputs is wrong, you get false passes rather than counterexamples, which is the most dangerous kind of failure.

Finally, Lean4's tactic set for `BitVec` arithmetic is powerful but not complete. Some goals require manual case splits or rewrites that can be time-consuming, especially for properties involving IEEE 754 rounding or multi-word arithmetic.

---

## Closing Thought

The thing I find most interesting about this flow is not any individual piece — Lean4, cocotb, and Hypothesis all exist independently. It is the combination: the idea that a proof and a simulation testbench can share the same model, rather than each trusting a separate, informal implementation of the same specification.

In most verification flows today, the gap between what we prove and what we test is papered over by convention and hope. This is an attempt to close it.

---

*Feedback and discussion welcome. The framework described here is part of ongoing work — expect the details to evolve.*
