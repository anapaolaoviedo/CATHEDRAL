module Cathedral.Core.Types where
import Cathedral.Core.Predicate 

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

--module Cathedral.Core.Properties where 
  -- Check if input satisfies precondition
checkPrecondition :: Precondition a -> a -> Bool
checkPrecondition (Precondition p)  = p 

-- Check if output satisfies postcondition given input
checkPostcondition :: Postcondition a b -> a -> b -> Bool
checkPostcondition (Postcondition p) = p  

-- Helper to check if algorithm respects specification
checkSpecification :: Algorithm a b -> a -> b -> Bool
checkSpecification alg input output =
  let Precondition pre = precondition alg
      Postcondition post = postcondition alg
  in pre input && post input output