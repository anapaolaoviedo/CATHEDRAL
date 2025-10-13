--my actual algorithms will live here 

import Cathedral.Core.Types


-- ← ALGORITHM 1: Merge Sort
mergeSort :: Algorithm
mergeSort = Algorithm
    { algName = "Merge Sort"
    , algParadigm = DivideAndConquer
    , algComplexity = Linearithmic
    , algDescription = "Split array, sort halves, merge"
    }

-- ← ALGORITHM 2: Binary Search
binarySearch :: Algorithm
binarySearch = Algorithm
    { algName = "Binary Search"
    , algParadigm = DivideAndConquer
    , algComplexity = Logarithmic
    , algDescription = "Check middle, search half"
    }

-- ← ALGORITHM 3: Dijkstra
dijkstra :: Algorithm
dijkstra = Algorithm
    {algName = "Dijkstra"
    , algParadigm = Greedy
    , algComplexity = Logarithmic
    , algDescription = "Find the shortest path in a graph"
    }

-- ← ALGORITHM 4: Depth First Search 
depthFirstSearch :: Algorithm 
depthFirstSearch == Algorithm 
    {algName = "Depth First Search"
    , algParadigm = GraphTraversal 
    , algComplexity = Logarithmic
    , algDescription = "Explores nodes level by level "
    }

-- ← ALGORITHM 5: Median of medians 
medianOfMedians :: Algorithm
medianOfMedians == Algorithm 
    {algName = "Median of Medians"
    , algParadigm = DivideAndConquer
    , algComplexity = Linear 
    , algDescription = "Divide into medians"

    }