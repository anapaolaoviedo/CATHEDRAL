module MergeSort where

import Cathedral.Core.Types (Algorithm(..))
import Cathedral.Core.Predicate


mergeSort :: Algorithm [Int] [Int]
mergeSort = Algorithm
  { algoName = "Merge Sort"
  , algoType = Sorting
  , algoPrecondition = mkPrecondition (\input -> not (null input))
    
  , algoPostcondition = mkPostcondition (\input output -> 
      isSorted output && sameElements input output)
    
  , algoInvariant = [mkInvariant "Divide-and-conquer: split, sort halves, merge"]
  }
  where
    isSorted :: [Int] -> Bool
    isSorted [] = True
    isSorted [_] = True
    isSorted (x:y:rest) = x <= y && isSorted (y:rest)
    
    sameElements :: [Int] -> [Int] -> Bool
    sameElements xs ys = sort xs == sort ys
      where sort = Data.List.sort  -- you'll need to import this