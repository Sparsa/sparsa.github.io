---
title: "Understanding Memory Coherency and Cache Coherence Protocols"
date: 2025-07-14
description: "An overview of cache coherency challenges and coherence protocols in multicore systems."
---



As modern processors are increasingly multicore, each core typically has its own private caches (like L1, L2), and sometimes shares a last-level cache (LLC or L3). This architecture improves performance but introduces a critical issue: **cache coherency**.

## Why Cache Coherency Matters

When different cores **read** the same memory location, it's fine to have multiple cached copies. However, when one or more cores **write** to the same address, inconsistency can arise:

> _Imagine two caches having the same memory element and they both write to it. Whose data is valid for the next computation?_

To resolve this, each **cache line** is associated with a **state**, and **protocols** define how caches interact and transition between these states based on operations like reads and writes.

---

## MESI Protocol (Modified, Exclusive, Shared, Invalid)

The **MESI protocol** is a basic cache coherence protocol where each cache line can be in one of four states:

### 🟠 Modified (M)

- The cache line is **dirty**—it has been modified and not written back to memory.
- This copy is **exclusive** to one cache.
- Must write back to memory before eviction or sharing.

### 🟣 Exclusive (E)

- The cache has the **only** copy, and it matches main memory (i.e., it's clean).
- Transitions silently to Modified on a write.
- No other caches have a copy.

### 🟢 Shared (S)

- The data is **clean** and possibly held by multiple caches.
- Writes require transitioning to Modified and invalidating others.

### 🔴 Invalid (I)

- The cache line is **not valid** and must be re-fetched.

---

## MOESI Protocol: An Optimization

MOESI extends MESI by adding an **Owned (O)** state:

### 🟡 Owned (O)

- The cache line is **dirty**, but **shared** among multiple caches.
- The cache in the **Owned** state must **supply data** to others upon request.
- This avoids immediate write-backs to memory.

### Summary of States

| State     | Dirty | Shared | Memory Up-to-date | Owner |
| --------- | ----- | ------ | ----------------- | ----- |
| Modified  | ✅    | ❌     | ❌                | ✅    |
| Owned     | ✅    | ✅     | ❌                | ✅    |
| Exclusive | ❌    | ❌     | ✅                | ✅    |
| Shared    | ❌    | ✅     | ✅                | ❌    |
| Invalid   | —    | —     | —                | —    |

---

## State Transitions: Conceptual Example

1. **Core A** loads address `X` → State: **Exclusive**
2. **Core A** writes to `X` → State: **Modified**
3. **Core B** reads `X`:
   - **MESI**: Core A must write back, Core B gets Shared
   - **MOESI**: Core A transitions to **Owned**, Core B gets Shared without write-back

---

## Final Thoughts

Cache coherence ensures all cores operate on **consistent memory views**, which is crucial for correctness in parallel programs. MESI provides a good base protocol, while MOESI reduces memory traffic by allowing **dirty sharing** through the Owned state.

As processors scale further (manycore, GPUs, etc.), protocols like **MOESIF**, **MESIF**, or **directory-based coherence** become more relevant.

---

