module Cathedral.Core.Types 
module Cathedral.Core.Predicate 

-- | Algorithmic paradigms
data Paradigm
    = DivideAndConquer
    | Greedy
    | DynamicProgramming
    | BruteForce
    | GraphTraversal
    deriving (Eq, Show)

-- | Complexity classes
data Complexity
    = Constant          -- O(1)
    | Logarithmic       -- O(log n)
    | Linear            -- O(n)
    | Linearithmic      -- O(n log n)
    | Quadratic         -- O(n²)
    | Exponential       -- O(2^n)
    deriving (Eq, Show, Ord)

-- | Algorithm specification

data Algorithm a b = Algorithm
  { algName :: String
  , algparadigm :: Paradigm
  , algComplexity :: Complexity
  , algDescription :: String
  , implementation :: a -> b
  , precondition :: Precondition a
  , postcondition :: Postcondition a b
  , invariants :: [Invariant]
  }

    