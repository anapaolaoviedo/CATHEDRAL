module MergeSort where

import Cathedral.Core.Types
import Cathedral.Core.Predicate

-- Merge Sort as a full Algorithm: implementation + specification
mergeSort :: Algorithm [Int] [Int]
mergeSort = Algorithm
  { algName = "Merge Sort"
  , algParadigm = DivideAndConquer
  , algComplexity = Linearithmic
  , algDescription = "Split array, sort halves, merge"
  , implementation = msort
  , precondition = mkPrecondition alwaysTrue
  , postcondition = mkPostcondition (\input output ->
      isSorted output && sameElements input output)
  , invariants = [mkInvariant "Divide-and-conquer: split, sort halves, merge"]
  }

msort :: [Int] -> [Int]
msort [] = []
msort [x] = [x]
msort xs = merge (msort left) (msort right)
  where
    (left, right) = splitAt (length xs `div` 2) xs

merge :: [Int] -> [Int] -> [Int]
merge [] ys = ys
merge xs [] = xs
merge (x:xs) (y:ys)
  | x <= y    = x : merge xs (y:ys)
  | otherwise = y : merge (x:xs) ys
