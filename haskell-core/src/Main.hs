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