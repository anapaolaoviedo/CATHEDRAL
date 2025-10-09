--here is where de definition of 'algorithm' will be
-- The shape of an Algorithm
data Algorithm = Algorithm
    { algName :: Name
    , algParadigm :: Paradigm
    , algComplexity :: Complexity
    --, algDescription :: Description
    }

-- The paradigms
data Paradigm = DivideAndConquer | Greedy | DynamicProgramming | BruteForce | Backtracking 

-- The complexity classes
data Complexity = Constant | Linear | Cuadraric | Exponential | Logarithmic 

data Name = Dijkstra | Lomuto | BubbleSort | QuickSort | MergeSort | MedianOfMedians | Karatsuab 

--data Description = 