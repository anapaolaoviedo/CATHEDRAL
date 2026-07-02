# CLAUDE.md — CATHEDRAL PROJECT

## Vision

**Cathedral** is a computational research experiment that teaches machines to *understand* algorithms—not just execute them, but reason about them formally, explain them rigorously, and place them within a knowledge graph of algorithmic structure.

Given an algorithm A and a specification S (preconditions, postconditions, cost bounds), Cathedral produces:

1. **Obligations**: Formal proof goals (partial correctness, total correctness, complexity bounds, resource invariants)
2. **Witnesses**: Proof objects π that discharge each obligation (kernel-verified, not heuristic)
3. **Placement**: Insert A into a knowledge graph 𝒢 with typed edges (refinement, reduction, equivalence, domination)
4. **Explanations**: Natural-language derivations grounded in π (never in mere embeddings)
5. **Transformations**: Correctness-preserving rewrites (loop-to-recurrence, fusion, tail-recursion, divide-step factoring)

**Non-negotiable Law**: No statement enters an explanation unless entailed by a proof. The neural layer proposes hints; the proof engine judges truth.

---

# PART 1: ARCHITECTURE

## System Overview

```
┌─────────────────────────────────────────────────────────┐
│                    CATHEDRAL SYSTEM                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  INPUT: Algorithm A, Specification S                    │
│           ↓                                              │
│  [1] PARSING & NORMALIZATION (Haskell)                 │
│      Code/pseudocode → AST/CFG → Canonical Prog        │
│           ↓                                              │
│  [2] ABDUCTIVE HINTS (Python/PyTorch)                  │
│      Neural layer suggests invariants H with p∈[0,1]    │
│           ↓                                              │
│  [3] PROOF SEARCH (Haskell)                            │
│      Goal-directed engine discharges 𝒪(A,S) via H      │
│      Only kernel-checked proofs survive                  │
│           ↓                                              │
│  [4] COMPLEXITY EXTRACTION (Haskell)                   │
│      Akra-Bazzi / Master method → Θ(·) with conditions │
│           ↓                                              │
│  [5] GRAPH PLACEMENT (Python/Neo4j)                     │
│      Insert A into 𝒢 with typed morphisms              │
│           ↓                                              │
│  [6] EXPLANATION SYNTHESIS (Haskell)                   │
│      Linearize π into prose via templates               │
│           ↓                                              │
│  OUTPUT: Proof objects, explanations, graph insertion  │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## The Five Components

---

## COMPONENT 1: PARSER & NORMALIZATION

**Purpose**: Ingest algorithm description (pseudocode, code, or formal syntax) and produce a canonical intermediate representation.

**Input**: 
- Pseudocode (imperative, recursive, functional)
- Haskell/Python code
- Formal description (control flow graph + annotated predicates)

**Output**:
- Abstract syntax tree (AST)
- Control flow graph (CFG) with entry/exit
- Canonical `Prog` structure (defined below)
- Extracted metadata: parameters, return type, side effects

**Key Structures** (Haskell):

```haskell
-- Canonical representation
data Prog = Prog 
  { name :: String
  , params :: [Param]          -- input parameters
  , returnType :: Type
  , precond :: Pred            -- P: precondition
  , postcond :: Pred           -- Q: postcondition
  , body :: Statement          -- the algorithm body
  , costBound :: Maybe Expr    -- claimed Θ(·) or O(·)
  }

data Statement
  = Assign Var Expr
  | Seq [Statement]
  | If Pred Statement Statement
  | While Pred Inv Statement      -- Inv = loop invariant (annotated)
  | For Var Expr Expr Statement
  | Call String [Expr]            -- recursive or external calls
  | Return Expr

data Pred = Pred String          -- first-order logic formula (strings for now)
data Expr = Expr String          -- arithmetic/set expressions
data Type = Int | Array Type | Tuple [Type] | ...
data Param = Param String Type
```

**Implementation Tasks**:

1. **Parser**: Write lexer/parser for pseudocode
   - Handle imperative constructs: `for`, `while`, assignment
   - Handle recursion: distinguish tail-call from general recursion
   - Extract annotated invariants `{Inv: ...}`
   - Recognize common patterns (binary search, merge sort, etc.)

2. **CFG Builder**: Construct control flow graph
   - Nodes: basic blocks (sequences of assignments)
   - Edges: branch conditions, loop back-edges
   - Compute dominators, back-edges, loop structure
   - Identify loop-free paths (for acyclic verification)

3. **Type Inference**: Infer types when not explicit
   - Array dimensions, recursive types
   - Cost model: is this about time, space, or both?

4. **Canonicalization**: Normalize to `Prog`
   - Loop normalization: `while` → canonical form
   - Recursion detection: tail-recursive vs general
   - Variable scoping resolution

---

## COMPONENT 2: ABDUCTIVE HINTS (Neural Layer)

**Purpose**: Propose candidate invariants, lemmas, and algorithmic relationships to guide proof search.

**Input**:
- Canonical `Prog`
- (Optional) Knowledge graph 𝒢 of prior algorithms

**Output**:
- Set of hints H = {h₁, h₂, ...}
- Each hint h = (formula, confidence p ∈ [0,1], reasoning)
- Proposed lemmas and cut points

**Key Structures**:

```haskell
data Hint = Hint
  { formula :: Pred          -- suggested invariant
  , confidence :: Double     -- [0,1]
  , category :: HintType     -- LoopInv | Lemma | Similarity | ...
  , source :: String         -- "neural", "prior_algo", "user"
  }

data HintType
  = LoopInvariant           -- for while loops
  | WeakestPrecondition     -- for program slices
  | RecurrenceRelation      -- T(n) = ... (for recursive calls)
  | AlgorithmicSimilarity   -- "resembles Merge Sort"
  | TerminationMetric       -- variant function for termination
```

**Implementation Tasks** (Python with PyTorch):

1. **Vector Embedding of Algorithms**
   - Encode AST as feature vector (structural patterns, variable flow, call graph)
   - Use pre-trained transformer or graph neural network (GNN)
   - Retrieve similar algorithms from knowledge graph: `top-k(cosine_sim(A, 𝒢))`

2. **Invariant Suggestion**
   - Neural model trained on labeled (program, invariant) pairs
   - For `while` loops, generate candidate loop invariants
   - Rank by confidence; return top-5

3. **Recurrence Relation Extraction** (for recursion)
   - Analyze recursive calls: depth of recursion, branching factor
   - Suggest recurrence relation (e.g., T(n) = 2T(n/2) + Θ(n) for merge sort)
   - Confidence based on pattern matching

4. **Similarity Matching**
   - Compare A to graph 𝒢; find neighbors (refinements, reductions, variants)
   - Propose: "This looks like Quicksort with deterministic pivot"
   - Suggest existing proofs from neighbors as hints

5. **Lemma Synthesis**
   - Identify cut points in proof search (where you'd need auxiliary lemmas)
   - Generate lemmas via inductive synthesis or specification slicing

**Training Data** (to bootstrap):

```
(BinarySearch, "low ≤ x ≤ high ∧ arr[low:high] sorted")
(MergeSort, "left sorted ∧ right sorted ∧ lo ≤ left ≤ mid ≤ right ≤ hi")
(QuickSort, "pivot in place ∧ left < pivot ≤ right")
(DFS, "visited ⊆ nodes ∧ curr node ∈ visited")
(BFS, "visited ∪ queue = reachable ∧ no cycles in visited")
```

---

## COMPONENT 3: PROOF SEARCH ENGINE

**Purpose**: Discharge proof obligations using hints; only accept kernel-verified proofs.

**Input**:
- Canonical `Prog` (with precondition P, postcondition Q)
- Hints H from neural layer
- Cost bound claim (if any)

**Output**:
- Proof objects π: π : 𝒪 → ⊤ (each obligation discharged)
- Failure diagnosis (if proof fails)

**Key Proof Obligations** 𝒪(A, S):

```
𝒪(A, S) = {
  ⊢ PartialCorrectness(A, P, Q)     -- if A terminates, Q holds
  ⊢ TotalCorrectness(A, P, Q)       -- A terminates ∧ Q holds
  ⊢ ComplexityBound(A, O(f(n)))     -- time/space is O(f(n))
  ⊢ Termination(A)                  -- A always terminates
  ⊢ ResourceInvariant(A, R)         -- e.g., "uses ≤ k bytes"
}
```

**Proof Strategies**:

### Strategy 1: Weakest Precondition (for partial correctness)

```haskell
-- WP(S, Q) computes the weakest precondition
-- WP(skip, Q) = Q
-- WP(x := e, Q) = Q[e/x]
-- WP(S1; S2, Q) = WP(S1, WP(S2, Q))
-- WP(if P then S1 else S2, Q) = (P → WP(S1, Q)) ∧ (¬P → WP(S2, Q))
-- WP(while I do S, Q) = I ∧ (I ∧ ¬cond → Q) ∧ (I ∧ cond → WP(S, I))
--   ^ loop invariant I must be found (use hints!)

weakestPrecondition :: Statement -> Pred -> Pred
weakestPrecondition Skip q = q
weakestPrecondition (Assign x e) q = substitute e x q
weakestPrecondition (Seq stmts) q = 
  foldr weakestPrecondition q stmts
weakestPrecondition (If p s1 s2) q =
  Pred $ "((" ++ p ++ " -> " ++ show (weakestPrecondition s1 q) ++ ") & " ++
         "(~" ++ p ++ " -> " ++ show (weakestPrecondition s2 q) ++ "))"
weakestPrecondition (While p inv s) q =
  -- Requires loop invariant inv (from hints)
  Pred $ inv ++ " & ((" ++ inv ++ " & ~" ++ p ++ ") -> " ++ show q ++ ") & " ++
         "((" ++ inv ++ " & " ++ p ++ ") -> " ++ show (weakestPrecondition s inv) ++ ")"
```

### Strategy 2: Floyd-Hoare Logic (for annotated programs)

```haskell
-- Hoare triple: ⊢ {P} S {Q}
-- Use weakest precondition to generate verification conditions (VCs)
-- Discharge VCs using SMT solver (Z3, CVC4)

data HoareTriple = HoareTriple Pred Statement Pred

verifyTriple :: HoareTriple -> [Hint] -> Either String ProofObject
verifyTriple (HoareTriple p s q) hints = do
  let wp = weakestPrecondition s q
  let vc = Pred $ "(" ++ show p ++ " -> " ++ show wp ++ ")"  -- verification condition
  
  -- Try to prove vc using SMT solver + hints
  proof <- proveViaZ3 vc hints
  return proof
```

### Strategy 3: Recurrence Solving (for recursion)

```haskell
-- For recursive function, extract recurrence relation
-- Solve via Master theorem, Akra-Bazzi, or guess-and-verify

data Recurrence = Recurrence
  { relation :: String      -- e.g., "T(n) = 2*T(n/2) + n"
  , baseCase :: (Int, Int)  -- e.g., (1, 1) means T(1)=1
  }

-- Master theorem: T(n) = a*T(n/b) + f(n)
-- Case 1: if f(n) = O(n^(log_b(a) - ε)) then T(n) = Θ(n^log_b(a))
-- Case 2: if f(n) = Θ(n^log_b(a)) then T(n) = Θ(n^log_b(a) * log n)
-- Case 3: if f(n) = Ω(n^(log_b(a) + ε)) then T(n) = Θ(f(n))

solveRecurrence :: Recurrence -> Either String Expr
solveRecurrence rec = 
  -- Try Master theorem first
  case masterTheorem rec of
    Just result -> Right result
    Nothing -> 
      -- Fall back to Akra-Bazzi or guess-and-verify
      akraBazzi rec
```

### Strategy 4: Termination (using hints)

```haskell
-- Termination via variant function (decreasing measure)
-- For while loop: find expression φ(vars) that:
--   1. φ is non-negative integer when loop condition holds
--   2. φ decreases on each iteration
--   3. φ = 0 implies loop condition false

data TerminationProof = TerminationProof
  { variantFunc :: Expr      -- e.g., "high - low"
  , baseStep :: Pred         -- loop_cond → variant ≥ 0
  , inductiveStep :: Pred    -- (inv ∧ cond ∧ variant = k) → WP(body, variant < k)
  }

proveTermination :: Statement -> [Hint] -> Either String TerminationProof
proveTermination (While cond inv body) hints = do
  -- Extract variant from hints
  let variantCandidates = filterHints TerminationMetric hints
  variant <- selectBestVariant body variantCandidates
  
  -- Prove base step: loop_cond → variant ≥ 0
  baseStepProof <- proveViaZ3 (Pred $ cond ++ " -> " ++ show variant ++ " >= 0") []
  
  -- Prove inductive step
  let inductiveGoal = Pred $ 
        inv ++ " & " ++ cond ++ " & " ++ show variant ++ " = k -> " ++
        show (weakestPrecondition body (Pred $ show variant ++ " < k"))
  inductiveProof <- proveViaZ3 inductiveGoal []
  
  return $ TerminationProof variant baseStepProof inductiveProof
```

**Kernel-Checked Proofs**:

All proofs must ultimately reduce to facts checkable by:
1. **SMT Solver** (Z3, CVC4): verify verification conditions
2. **Recurrence Solver**: apply Master theorem / Akra-Bazzi with side-condition checks
3. **Structural Checker**: verify loop invariants satisfy Hoare conditions

Accept proof only if all discharge checks pass.

---

## COMPONENT 4: COMPLEXITY EXTRACTION

**Purpose**: Extract or verify asymptotic complexity bounds from program structure.

**Input**:
- Canonical `Prog` with loop/recursion structure
- (Optional) Claimed bound from specification

**Output**:
- Complexity class Θ(f(n)) with explicit side-conditions
- If conditions fail, return separate upper/lower bounds

**Analysis Strategies**:

### Strategy 1: Loop Counting

```haskell
-- For each loop, count iterations based on control structure
-- Multiply by loop body cost

data LoopAnalysis = LoopAnalysis
  { loopVar :: String           -- e.g., "i"
  , loopBound :: Expr           -- e.g., "n"
  , iterationCost :: Expr       -- cost per iteration
  , totalCost :: Expr           -- cost * iterations
  }

-- Example: for i = 0 to n-1: do work(i)
-- iterations = n
-- iteration_cost = cost(work(i))
-- total_cost = n * cost(work(i))

-- Nested loops multiply
-- for i = 0 to n:
--   for j = 0 to n:
--     O(1)
-- → O(n²)
```

### Strategy 2: Recurrence Solving (for recursion)

```haskell
-- Binary recursion: T(n) = 2*T(n/2) + Θ(n)
-- Master theorem applies:
-- a = 2, b = 2, f(n) = Θ(n)
-- log_b(a) = log_2(2) = 1
-- f(n) = Θ(n) = Θ(n^1)
-- Case 2: T(n) = Θ(n log n)

extractRecurrence :: Statement -> Maybe Recurrence
extractRecurrence stmt =
  case stmt of
    (Call fname _) -> lookupRecurrenceForFunction fname
    other -> tryInferFromStructure other

-- Akra-Bazzi for non-uniform recursion
-- T(n) = Θ(n^p * (1 + ∫₁ⁿ (f(u) / u^(p+1)) du))
-- where p solves: Σ aᵢ / bᵢᵖ = 1

akraBazziSolve :: [Recurrence] -> Expr
```

### Strategy 3: Worst-Case vs Best-Case

```haskell
-- Distinguish branches: some paths may be O(1), others O(n)
-- Report full spectrum or use worst-case

data ComplexityBounds = ComplexityBounds
  { worstCase :: Expr
  , bestCase :: Expr
  , averageCase :: Maybe Expr   -- if distribution known
  , conditions :: [Pred]        -- side-conditions (e.g., "n > 0", "array sorted")
  }

-- Example: Binary search
-- worst-case: Θ(log n) if array is sorted
-- best-case: Θ(1) if element is at array[mid]
-- side-condition: "array must be sorted"
-- If condition violated, report weaker bound
```

**Implementation**:

1. Walk AST/CFG; identify loops and recursive calls
2. For each loop, compute iteration count (use hints or Z3 constraint solving)
3. For each recursion, extract recurrence relation
4. Apply Master theorem / Akra-Bazzi / manual analysis
5. Compute composite cost (nested loops multiply, sequential add)
6. Verify side-conditions; report bounds + conditions

---

## COMPONENT 5: KNOWLEDGE GRAPH & PLACEMENT

**Purpose**: Insert algorithm A into a graph 𝒢 of known algorithms with typed edges.

**Graph Structure**:

```
Nodes: algorithms (each node = Prog with proof object)
Edges: typed relationships
  ├─ refinement(A, B)      -- A specializes B (B is more general)
  ├─ reduction(A, B)       -- A solves problem P; B solves P'; P reduces to P'
  ├─ equivalence(A, B)     -- same problem, same complexity, different approach
  ├─ domination(A, B)      -- A dominates B (better on all inputs)
  ├─ generalizes_to(A, B)  -- A is instance of pattern B
  └─ uses(A, B)            -- A calls B as subroutine
```

**Data Structure** (Python/Neo4j):

```python
class AlgorithmNode:
    def __init__(self, name, prog, proof_obj, complexity):
        self.name = name
        self.prog = prog  # Canonical Prog
        self.proof = proof_obj  # Proof witness
        self.complexity = complexity  # Complexity bounds
        self.graph_id = None  # Neo4j node ID

class EdgeType(Enum):
    REFINEMENT = "refinement"
    REDUCTION = "reduction"
    EQUIVALENCE = "equivalence"
    DOMINATION = "domination"
    GENERALIZES_TO = "generalizes_to"
    USES = "uses"

class AlgorithmEdge:
    def __init__(self, source, target, edge_type, metadata=None):
        self.source = source  # AlgorithmNode
        self.target = target
        self.edge_type = edge_type  # EdgeType
        self.metadata = metadata or {}  # e.g., {"pivot_strategy": "deterministic"}
```

**Placement Algorithm**:

```python
def place_in_graph(A, proof_A, G):
    """
    Insert algorithm A into knowledge graph G.
    
    1. Embed A in vector space
    2. Find k-nearest neighbors in G
    3. Compute edge types (refinement? reduction? new?)
    4. Insert A as node
    5. Add edges to neighbors
    """
    
    # Step 1: Embed
    embedding_A = embed_algorithm(A)
    
    # Step 2: Find neighbors
    neighbors = G.knn_search(embedding_A, k=5)
    
    # Step 3: Compute edges
    edges = []
    for neighbor in neighbors:
        edge_type = infer_edge_type(A, neighbor)
        # edge_type ∈ {refinement, reduction, equivalence, domination, generalizes_to, uses}
        
        if edge_type == EdgeType.REFINEMENT:
            # A specializes neighbor (e.g., QuickSort specializes Partition-based sort)
            # Verify: A more specific, same problem, same or better complexity
            verify_refinement(A, neighbor)
        
        elif edge_type == EdgeType.REDUCTION:
            # A solves problem P, neighbor solves P', and P reduces to P'
            # E.g., MaxSubarray reduces to finding optimal cut point
            verify_reduction(A, neighbor)
        
        elif edge_type == EdgeType.DOMINATION:
            # A dominates neighbor: ∀ inputs, A ≥ neighbor (or better)
            # Requires complexity comparison + empirical validation
            verify_domination(A, neighbor)
        
        edges.append(AlgorithmEdge(A, neighbor, edge_type))
    
    # Step 4: Insert node
    node_A = AlgorithmNode(A.name, A, proof_A, A.cost_bound)
    G.insert_node(node_A)
    
    # Step 5: Add edges
    for edge in edges:
        G.insert_edge(edge)
    
    return node_A

# Edge inference rules
def infer_edge_type(A, B):
    """
    Compare A and B:
    - Do they solve the same problem?
    - If yes, are they equivalent? Does one dominate?
    - If no, does one reduce to the other?
    - Is one a specialization (refinement)?
    """
    
    if same_problem(A, B):
        if equivalent_complexity(A, B):
            return EdgeType.EQUIVALENCE
        elif dominates(A, B):
            return EdgeType.DOMINATION
        else:
            return None  # Uncomparable
    else:
        if refines(A, B):
            return EdgeType.REFINEMENT
        elif reduces_to(A, B):
            return EdgeType.REDUCTION
        elif generalizes_to(A, B):
            return EdgeType.GENERALIZES_TO
        else:
            return None
```

**Graph Queries** (examples):

```cypher
-- Find all algorithms that reduce binary search
MATCH (binsearch)-[:reduction]->(A) 
RETURN A

-- Find equivalent algorithms
MATCH (A)-[:equivalence]-(B)
RETURN A, B

-- Find refinements of Quicksort
MATCH (A)-[:refinement]->(:Algorithm {name: "Quicksort"})
RETURN A

-- Find all algorithms with O(n log n) complexity
MATCH (A:Algorithm) 
WHERE A.complexity = "O(n log n)"
RETURN A
```

---

## COMPONENT 6: EXPLANATION SYNTHESIS

**Purpose**: Generate natural-language explanations from proof objects π.

**Input**:
- Proof object π (structured, tree of proof steps)
- Algorithm A
- Audience (beginner / student / expert)

**Output**:
- Markdown or HTML explanation
- Proof steps linearized into prose
- Complexity analysis explained
- Intuitive insight (why this works)

**Proof Structure** (Haskell):

```haskell
data ProofStep
  = SMTVerified Pred String         -- verified by Z3, reason string
  | HoareStep HoareTriple String    -- Hoare logic step with comment
  | MasterTheorem String String     -- (relation, result)
  | CaseAnalysis [ProofStep]        -- branching case split
  | Induction String ProofStep ProofStep  -- (var, base, inductive)
  | LemmaApplication String [ProofStep]   -- (lemma name, supporting proofs)
  | Assumption Pred                 -- from precondition or hint
```

**Template-Based Explanation**:

```python
def explain_proof(A, proof, audience="student"):
    """
    Transform proof object into prose.
    Never include a statement unless it appears in proof.
    """
    
    explanation = []
    
    # Section 1: Algorithm overview
    explanation.append(explain_algorithm_overview(A))
    
    # Section 2: Correctness
    explanation.append("## Correctness\n\n")
    explanation.append(explain_correctness(proof.correctness_part))
    
    # Section 3: Complexity
    explanation.append("## Complexity\n\n")
    explanation.append(explain_complexity(proof.complexity_part))
    
    # Section 4: Why it works (intuition)
    explanation.append("## Why This Works\n\n")
    explanation.append(explain_intuition(A, proof))
    
    return "\n\n".join(explanation)

def explain_correctness(proof_tree):
    """
    Linearize proof tree into prose.
    Each node → English sentence(s).
    """
    
    if isinstance(proof_tree, SMTVerified):
        return f"We verify the condition `{proof_tree.condition}` using symbolic reasoning: {proof_tree.reason}."
    
    elif isinstance(proof_tree, HoareStep):
        (pre, stmt, post) = proof_tree.triple
        return f"By Hoare logic, if we have {pre} before executing {stmt}, we ensure {post} afterward."
    
    elif isinstance(proof_tree, Induction):
        var = proof_tree.var
        base = explain_correctness(proof_tree.base)
        inductive = explain_correctness(proof_tree.inductive)
        return f"""
By induction on {var}:

**Base case**: {base}

**Inductive case**: {inductive}

Therefore, by induction, the algorithm is correct for all values of {var}.
"""
    
    elif isinstance(proof_tree, CaseAnalysis):
        cases = [explain_correctness(branch) for branch in proof_tree.branches]
        return "By case analysis:\n" + "\n\n".join([f"**Case {i}**: {c}" for i, c in enumerate(cases, 1)])
    
    # ... more cases

def explain_complexity(proof_tree):
    """
    Explain complexity analysis.
    """
    
    if isinstance(proof_tree, MasterTheorem):
        relation, result = proof_tree
        return f"""
The algorithm satisfies the recurrence {relation}.

By the Master Theorem, we conclude: **{result}**
"""
    
    # ... handle loop analysis, case breakdown, etc.

def explain_intuition(A, proof):
    """
    High-level "why does this work" based on algorithm structure.
    """
    
    if is_divideconquer(A):
        return f"""
This is a divide-and-conquer algorithm:
1. **Divide**: {describe_division(A)}
2. **Conquer**: {describe_subproblem_solve(A)}
3. **Combine**: {describe_combine(A)}

The key insight is that the cost of combining is dominated by the recursive cost, 
giving us the {extract_complexity(proof)} overall bound.
"""
    
    elif is_greedyalgorithm(A):
        return f"""
This is a greedy algorithm: at each step, we {describe_greedy_choice(A)}.

The correctness argument is: any other choice at this step would lead to a 
suboptimal solution. Therefore, the greedy choice is optimal.
"""
    
    # ... more algorithm styles

# Example output:
"""
## Binary Search

### Correctness

**Precondition**: The input array `arr` is sorted in ascending order.

**Postcondition**: If the target `x` exists in `arr`, we return its index. 
Otherwise, we return -1.

We prove correctness by induction on the loop invariant:
> **Invariant**: If `x` exists in `arr`, then `x` exists in `arr[low:high+1]`.

**Base case**: Initially, `low=0` and `high=n-1`, so the entire array is in the range. ✓

**Inductive case**: Suppose the invariant holds. If `arr[mid] == x`, we return `mid`. 
If `arr[mid] > x`, then `x` must be in `arr[low:mid-1]` (since the array is sorted), 
so we update `high = mid-1`. If `arr[mid] < x`, then `x` must be in `arr[mid+1:high]`, 
so we update `low = mid+1`.

In all cases, the invariant is preserved.

**Loop termination**: The width `high - low` decreases by at least half on each iteration. 
When `low > high`, the loop exits and we return -1 (element not found).

By induction and loop termination, the algorithm is correct. ✓

### Complexity

The algorithm executes the loop body at most ⌈log₂(n)⌉ times, 
because each iteration halves the search range.

Therefore, **Time complexity: Θ(log n)**  
**Space complexity: Θ(1)** (only a constant number of variables)

### Why This Works

Binary search exploits the **sortedness** of the input. By comparing the target 
to the midpoint, we can eliminate half of the remaining elements in one step. 

This is far more efficient than linear search (which requires Θ(n) comparisons). 
The logarithmic complexity makes binary search practical even for very large datasets.
"""
```

---

# PART 2: TECHNICAL SPECIFICATIONS

## Tech Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Parser** | Haskell (Parsec or BNFC) | Strong type system, easy AST construction |
| **Proof Search** | Haskell + Z3 bindings | Haskell for logic; Z3 for SMT solving |
| **Complexity Analysis** | Haskell | Symbolic computation, Master theorem solver |
| **Neural Hints** | Python (PyTorch, scikit-learn) | Embeddings, similarity search, neural networks |
| **Knowledge Graph** | Python + Neo4j | Graph database for efficient queries |
| **Explanation Synthesis** | Haskell or Python | Template-based text generation |
| **API & Frontend** | Python (FastAPI) | REST endpoint for Cathedral system |

## External Libraries

### Haskell
```cabal
base >= 4.14
text >= 1.2
parsec >= 3.1
containers >= 0.6
mtl >= 2.2
z3 >= 4.8          -- SMT solver bindings
pretty >= 1.1      -- Pretty printing
```

### Python
```
z3-solver >= 4.12.2       -- Z3 Python bindings
torch >= 2.0              -- Neural networks
scikit-learn >= 1.0       -- Similarity, clustering
neo4j >= 5.0              -- Graph database client
networkx >= 3.0           -- Graph analysis
fastapi >= 0.100          -- REST API
numpy >= 1.24
```

## Integration Points

```
┌─────────────────────────────────────────────────────────────┐
│                      REST API (FastAPI)                      │
├─────────────────────────────────────────────────────────────┤
│  POST /analyze       -- submit algorithm + spec               │
│  GET  /result/{id}   -- fetch proof + explanation            │
│  GET  /graph/search  -- query knowledge graph                │
└─────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────┐
│  Worker Process (Haskell + Python)                           │
│                                                               │
│  [1] Parse & normalize (Haskell)                             │
│  [2] Get hints (Python: NN + graph similarity)              │
│  [3] Proof search (Haskell + Z3)                            │
│  [4] Complexity extraction (Haskell)                        │
│  [5] Graph insertion (Python: Neo4j)                        │
│  [6] Explain synthesis (Haskell)                            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

# PART 3: IMPLEMENTATION ROADMAP

## Phase 1: Foundation (Weeks 1-4)

**Goal**: Build the core parsing and normalization pipeline.

- [ ] Haskell: Lexer & parser for pseudocode
- [ ] Haskell: AST construction and pretty printing
- [ ] Haskell: CFG builder from AST
- [ ] Haskell: Type inference engine
- [ ] Test suite: parsing 20+ classic algorithms (binary search, merge sort, quicksort, etc.)

**Deliverable**: `cathedral-parse` executable; reads pseudocode, outputs canonical `Prog`

---

## Phase 2: Proof Search (Weeks 5-10)

**Goal**: Build weakest precondition calculus and SMT integration.

- [ ] Haskell: Weakest precondition compiler (WP calculus)
- [ ] Haskell: Verification condition generator
- [ ] Haskell: Z3 SMT solver bindings (prove VCs)
- [ ] Haskell: Floyd-Hoare logic verification
- [ ] Haskell: Loop invariant extraction from hints
- [ ] Test: verify binary search, insertion sort, selection sort

**Deliverable**: `cathedral-verify` executable; takes Prog + hints, outputs proof object

---

## Phase 3: Complexity Analysis (Weeks 11-14)

**Goal**: Extract and analyze complexity from algorithms.

- [ ] Haskell: Loop counting and iteration analysis
- [ ] Haskell: Recurrence relation extraction
- [ ] Haskell: Master theorem solver
- [ ] Haskell: Akra-Bazzi complexity solver
- [ ] Test: verify O(n), O(n log n), O(n²), O(2^n) algorithms

**Deliverable**: `cathedral-complexity` executable; outputs Θ(·) bounds with conditions

---

## Phase 4: Neural Hints (Weeks 15-18)

**Goal**: Build abductive hint generation.

- [ ] Python: Algorithm embedding (vector representation)
- [ ] Python: Loop invariant suggestion NN
- [ ] Python: Recurrence relation recognizer
- [ ] Python: Algorithm similarity model
- [ ] Training: 100+ (algorithm, proof) pairs
- [ ] Test: suggest hints for unknown algorithms

**Deliverable**: `hint-server` Python service; takes Prog, returns hints H

---

## Phase 5: Knowledge Graph (Weeks 19-22)

**Goal**: Build graph database and placement logic.

- [ ] Python: Algorithm embedding for graph queries
- [ ] Python: Neo4j schema design (nodes, edges, properties)
- [ ] Python: Edge type inference (refinement, reduction, equivalence, etc.)
- [ ] Python: Graph insertion + query API
- [ ] Test: insert 50 classic algorithms, verify relationships

**Deliverable**: `graph-manager` Python service; manages Neo4j insertion and queries

---

## Phase 6: Explanation Synthesis (Weeks 23-26)

**Goal**: Generate natural-language explanations from proofs.

- [ ] Haskell: Proof tree linearization
- [ ] Haskell: Explanation templates (correctness, complexity, intuition)
- [ ] Haskell: Markdown generation
- [ ] Test: generate explanations for 20+ algorithms
- [ ] Refinement: human review, readability improvements

**Deliverable**: `explain` executable; takes proof + audience level, outputs markdown

---

## Phase 7: Integration & API (Weeks 27-30)

**Goal**: Build REST API and end-to-end pipeline.

- [ ] Python: FastAPI server
- [ ] Python: Job queue (Celery or similar)
- [ ] Haskell/Python: Glue code (inter-process communication)
- [ ] Test: end-to-end from input algorithm to explanation
- [ ] Documentation: API specification, examples

**Deliverable**: `cathedral-api` service; full system accessible via REST

---

## Phase 8: Polish & Evaluation (Weeks 31-32)

**Goal**: Evaluate system quality; fix bugs; prepare for release.

- [ ] Benchmark: test on 50 algorithms; measure proof time, explanation quality
- [ ] Error handling: graceful failures, helpful error messages
- [ ] Documentation: write README, user guide, developer guide
- [ ] Release: make publicly available (GitHub + research paper?)

**Deliverable**: Public Cathedral release; research-quality system

---

# PART 4: EXAMPLES

## Example 1: Binary Search

**Input** (pseudocode):
```
function BinarySearch(arr: Array<Int>, x: Int) -> Int
  precondition: arr is sorted
  postcondition: result = -1 or arr[result] = x
  
  low := 0
  high := length(arr) - 1
  
  while low <= high
    {Inv: x in arr[low:high+1] if exists}
    do
      mid := (low + high) / 2
      if arr[mid] == x then
        return mid
      else if arr[mid] < x then
        low := mid + 1
      else
        high := mid - 1
  
  return -1
```

**Processing**:

1. **Parse**: Convert to AST/CFG
2. **Hints**: Neural layer suggests `{Inv: "x in arr[low:high+1]", p=0.95}`
3. **Proof Search**: 
   - WP calculus discharge loop invariant
   - SMT verify: `low <= high ∧ Inv ∧ loop_cond → WP(body, Inv)`
   - ✓ Proof found
4. **Complexity**: Loop runs ⌊log₂(n)⌋+1 times → Θ(log n)
5. **Graph**: Insert into 𝒢; compare to other search algorithms
   - Link: `equivalence` to Ternary Search (same complexity)
   - Link: `domination` to Linear Search (for unsorted arrays)
6. **Explanation**:

```markdown
# Binary Search

## Correctness

We verify correctness by induction on the loop invariant:

> **Invariant**: If target `x` exists in the array, then it lies in `arr[low:high+1]`.

**Base case**: Initially, `low=0` and `high=n-1`, so the entire array is in scope.

**Inductive case**: Suppose the invariant holds at the start of an iteration.
- If `arr[mid] == x`, we return immediately. ✓
- If `arr[mid] > x`, then by sortedness, `x` can only be in the left half.
  We set `high = mid-1`. The invariant is preserved.
- If `arr[mid] < x`, then `x` can only be in the right half.
  We set `low = mid+1`. The invariant is preserved.

**Termination**: The range `high - low` shrinks by at least half each iteration.
When `low > high`, the loop exits and returns -1 (not found).

By induction, the algorithm correctly finds the target or returns -1.

## Complexity

Each iteration halves the search range. The maximum number of iterations is ⌈log₂(n)⌉.

**Time Complexity**: Θ(log n)
**Space Complexity**: Θ(1)

## Why This Works

Binary search exploits the sortedness of the input. Each comparison eliminates
half of the remaining candidates. This divide-and-conquer strategy is vastly 
more efficient than linear search for large datasets.
```

---

## Example 2: Merge Sort

**Processing**:

1. **Parse**: Recursive algorithm detected; extract calls to `Merge()`
2. **Hints**: 
   - Neural suggests: `T(n) = 2*T(n/2) + Θ(n)`
   - Confidence: 0.99
3. **Proof Search**: 
   - Recursion base case: `T(1) = Θ(1)` ✓
   - Recursive case justified by recurrence relation
4. **Complexity**: 
   - Apply Master theorem: a=2, b=2, f(n)=Θ(n)
   - log_b(a) = 1, so f(n) = Θ(n^1)
   - Case 2: T(n) = Θ(n log n)
5. **Graph**:
   - Link: `equivalence` to Heap Sort (same complexity, different approach)
   - Link: `domination` to Bubble Sort (merge sort is always faster)
6. **Explanation**: [See above: explains divide-and-conquer, recurrence, master theorem]

---

# PART 5: SUCCESS CRITERIA

✅ **Parsing**: Accepts pseudocode for 50+ classic algorithms  
✅ **Proof Search**: Automatically discharges partial/total correctness for 30+ algorithms  
✅ **Complexity**: Correctly extracts Θ(·) bounds for Θ(n), Θ(n log n), Θ(n²), Θ(2^n) classes  
✅ **Hints**: Neural layer suggests correct invariants with p > 0.8 for 80%+ of test cases  
✅ **Graph**: Successfully inserts algorithms with correct edge types (refinement, reduction, etc.)  
✅ **Explanations**: Generated proofs are readable, grounded in formal proofs (no hearsay)  
✅ **End-to-End**: Submit algorithm → receive proof object + explanation + graph position in < 10s  

---

**The Non-Negotiable Law**:  
No statement enters an explanation unless entailed by a proof. The neural layer proposes hints; the proof engine judges truth. Heresy is excluded.

---

*Cathedral: Building a Mind in Mathematics*  
*Created: July 2026*  
*Vision: Teach machines to understand algorithms the way mathematicians do.*