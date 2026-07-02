--demo: build algorithms with full specs and check them on real inputs

import Cathedral.Core.Types
import Cathedral.Core.Predicate
import MergeSort (mergeSort)

-- ← ALGORITHM 2: Binary Search
-- input: (sorted array, target). output: index of target, if present
binarySearch :: Algorithm ([Int], Int) (Maybe Int)
binarySearch = Algorithm
    { algName = "Binary Search"
    , algParadigm = DivideAndConquer
    , algComplexity = Logarithmic
    , algDescription = "Check middle, search half"
    , implementation = bsearch
    , precondition = mkPrecondition (\(arr, _) -> isSorted arr)
    , postcondition = mkPostcondition (\(arr, x) result ->
        case result of
          Just i  -> validIndex arr i && arr !! i == x
          Nothing -> x `notElem` arr)
    , invariants = [mkInvariant "If x is in arr, then x is in arr[low..high]"]
    }

bsearch :: ([Int], Int) -> Maybe Int
bsearch (arr, x) = go 0 (length arr - 1)
  where
    go low high
      | low > high = Nothing
      | otherwise =
          let mid = (low + high) `div` 2
          in case compare (arr !! mid) x of
               EQ -> Just mid
               LT -> go (mid + 1) high
               GT -> go low (mid - 1)

-- print an algorithm card (Algorithm has no Show: it contains functions)
describe :: Algorithm a b -> IO ()
describe alg = do
    putStrLn $ "  " ++ algName alg
    putStrLn $ "    paradigm:    " ++ show (algParadigm alg)
    putStrLn $ "    complexity:  " ++ show (algComplexity alg)
    putStrLn $ "    description: " ++ algDescription alg
    mapM_ (\(Invariant inv) -> putStrLn $ "    invariant:   " ++ inv)
          (invariants alg)

-- run an algorithm on an input and check it against its own spec
runAndCheck :: (Show a, Show b) => Algorithm a b -> a -> IO ()
runAndCheck alg input = do
    let output = implementation alg input
    putStrLn $ "  " ++ algName alg ++ " " ++ show input ++ " = " ++ show output
    putStrLn $ "    meets specification: " ++ show (checkSpecification alg input output)

main :: IO ()
main = do
    putStrLn "Cathedral - algorithms with specifications"
    putStrLn ""
    describe mergeSort
    putStrLn ""
    describe binarySearch
    putStrLn ""
    putStrLn "Checking implementations against their specs:"
    runAndCheck mergeSort [5, 2, 8, 1, 9, 3]
    runAndCheck binarySearch ([1, 2, 3, 5, 8, 9], 5)
    runAndCheck binarySearch ([1, 2, 3, 5, 8, 9], 7)
