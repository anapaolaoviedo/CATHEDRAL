module Cathedral.Core.Types where

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
data Algorithm = Algorithm
    { algName        :: String
    , algParadigm    :: Paradigm
    , algComplexity  :: Complexity
    , algDescription :: String
    } deriving (Eq, Show)