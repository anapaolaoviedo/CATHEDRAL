module Cathedral.Core.Types where

-- here i need to add the predicates. i wanna keep it rooted into logic 
-- fro now im gonna keep it simple 

type Predicate a = a -> Bool 

--precondition of what must be true before BEFORE the algorithm runs 
newtype Precondition a = Precondition (Predicate a)
    deriving (Show)

--postcondition is what must be true after the algorithm runs 
newtype Postcondition a b = Postcondition (a -> b -> Bool)
    deriving (Show)

--invariant is what bust me true during the algorithm 
-- for now just a string 
newtype Invariant = Invariant String 
    deriving (Show, Eq)

-- helper to create a precondition form a predicate 
mkPrecondition :: (a -> Bool)-> Precondition a 
mkPrecondition = Precondition 

--helper to create a postcondition from a two arguement predicate 
mkPostcondition :: (a -> b -> Bool) -> Postcondition a b 
mkPostcondition = Postcondition 

--helper to create an invariant from description
mkInvariant :: String -> Invariant 
mkInvariant = Invariant 

--helper always true predicate
alwaysTrue :: Predicate a 
alwaysTrue = const True 

--helper always flase predicate 
alwaysFalse :: Predicate a
alwaysFalse = const False 

--helper combine two predicates with AND 
andPred :: Predicate a -> Predicate a -> Predicate a 
andPred p1 p2 = \x -> p1 x && p2 x 

--helper combine two predicates with OR 
ordPred :: Predicate a -> Predicate a -> Predicate a 
ordPred p1 p2 = \x -> p1 x || p2 x 

-- helper to negate a predicate
notPred :: Predicate a -> Predicate a
notPred p = \x -> not (p x)




