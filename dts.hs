
import System.IO
--import Debug.Trace

{-/////////////////////////////////////// data ///////////////////////////////////////-}

type Info = ([String],[[String]])
type Table = ([String], Info)
--data Toxicity = Poisonous | Edible | NotClear
data Rules = Atrib String [(String,Rules)] | Poisonous | Edible | NotClear


{-/////////////////////////////////////// main ///////////////////////////////////////-}

main :: IO()
main = do
    --contents <- readFile "smallSet.txt"
    contents <- readFile "agaricus-lepiota.data"
    --putStrLn contents
    let a = infoLoader (lines contents)
    putStrLn "Computing decision tree. This might take a while."
    let tree = construeixArbre a
    let outputTree = testPrint "" tree
    writeFile "decisionTree.txt" outputTree
    putStrLn "The following decision tree has been computed:\n"
    putStrLn outputTree
    --printTable a
    poisonTest tree

    return()


{-///////////////////////////// printing decision trees //////////////////////////////-}

testPrintI :: String -> [(String,Rules)] -> String
testPrintI _ [] = ""
testPrintI a (x:xs) = a ++ (fst x) ++ "\n" ++ testPrint a (snd x) ++ testPrintI a xs

testPrint :: String -> Rules -> String
testPrint a Poisonous = a ++ " Poisonous\n"
testPrint a Edible = a ++ " Edible\n"
testPrint a NotClear = a ++ " NotClear\n"
testPrint a (Atrib _ [] )= ""
testPrint a (Atrib s l) = a ++ s ++ "\n" ++ a ++ "{\n" ++ (testPrintI (a++"  ") l) ++ a ++ "}\n"

printList :: [String] -> String
printList [] = ""
printList (x:xs) = x ++ [' '] ++ printList xs

printLoop :: [[String]] -> String
printLoop [] = []
printLoop (x:xs) = printList x ++ ['\n'] ++ printLoop xs

printTable :: Table -> IO()
printTable (a, (b,c)) = do
    putStrLn (printList a)
    putStrLn (printList b)
    putStrLn (printLoop c)

{-///////////////////////// auxiliary interacion functions ///////////////////////////-}

myConcat :: [String] -> String
myConcat [] = "]"
myConcat (x:xs) = ", "++x++myConcat xs


getAtribs :: [(String,Rules)] -> [String]
getAtribs [] = []
getAtribs (x:xs) = (fst x):getAtribs xs
{-
getAtribs (x:xs) 
    | elem (fst x) res = res
    | otherwise = (fst x):res 
    where 
        res = getAtribs xs
-}
{-/////////////////////////////////// interactive ////////////////////////////////////-}

poisonTest :: Rules -> IO()
poisonTest Poisonous = putStrLn "This mushroom is Poisonous! Be careful."
poisonTest Edible = putStrLn "This mushroom is Edible, enjoy!"
poisonTest NotClear = putStrLn "This mushroom is not safe to eat. Pleas contact an expert."
poisonTest (Atrib s l) = do 
    putStr "Introduce the "
    putStr s
    putStrLn ": "
    let a = getAtribs l
    putStr "The possible values for "
    putStr s
    putStr " are ["
    let b = (head a) ++ myConcat (tail a)
    putStrLn b
    putStrLn "If you need help, introduce \"?\" for more information on what the values mean."
    atr <- getLine
    if atr == "?" then do 
        c <- readFile "guide.txt"
        putStrLn c
        poisonTest (Atrib s l)
        return()
    else findAtrib atr l
    return()

findAtrib :: String -> [(String,Rules)] -> IO()
findAtrib _ [] = putStrLn "This attribute is not accounted for, please try again.\n"
findAtrib s (x:xs) = do
    if (fst x) == s then poisonTest (snd x)
        else findAtrib s xs
    return()

{-//////////////////////// auxiliary inicialization functions ////////////////////////-}

flipMat :: [[String]] -> [[String]]
flipMat [] = []
flipMat ([]:_) = []
flipMat a = [map (head) a]++(flipMat (map (tail) a))

{-
getOneRec :: [[String]] -> [String]
getOneRec [] = []
getOneRec (x:xs) = [(head x)] ++ getOneRec xs


dropOneRec :: [[String]] -> [[String]]
dropOneRec [] = []
dropOneRec (x:xs) = [tail x] ++ dropOneRec xs
-}

recWords :: [String] -> [[String]]
recWords [] = []
recWords (x:xs) = [words x] ++ recWords xs

{-/////////////////////////////////// data loading ///////////////////////////////////-}

infoLoader :: [String] -> Table
infoLoader [] = ([],([],[]))
--infoLoader (x:xs) = ((tail (words x)), toxicityLoader (flipMat (recWords xs)))
infoLoader (x:xs) = ((tail (words x)), (l, ls))
    where 
        (l:ls)= flipMat(recWords xs)

{-
toxicityLoader :: [[String]] -> Info
toxicityLoader [] = ([],[])
toxicityLoader (x:xs) = (x,xs)
--toxicityLoader s = ((map (head) s), decoder (map (tail) s))

decoder :: [[String]] -> [[String]]
decoder [] = []
decoder s = [getOneRec s] ++ decoder (dropOneRec s)
--decoder s = [(map (head) s)] ++ decoder (map (tail) s)
-}

{-///////////////////// auxiliary functions for data conversion //////////////////////-}

removeAtribX :: String -> [String] -> [String] -> [String]
removeAtribX _ [] _ = []
removeAtribX _ _ [] = []
removeAtribX s (x:xs) (y:ys)
    | s == y = removeAtribX s xs ys
    | otherwise = x:removeAtribX s xs ys

removeAtribY :: String -> [String] -> [String] -> [String]
removeAtribY _ [] _ = []
removeAtribY _ _ [] = []
removeAtribY s (x:xs) (y:ys)
    | s == y = removeAtribY s xs ys
    | otherwise = y:removeAtribY s xs ys

countAtribs :: String -> [String] -> [String] -> Int
countAtribs a b c = countAtribsI a b c 0 0

countAtribsI :: String -> [String] -> [String] -> Int -> Int -> Int
countAtribsI _ [] _ b c = if b > c then b else c
countAtribsI _ _ [] b c = if b > c then b else c
countAtribsI a (x:xs) (y:ys) b c 
    | a == y && x == "p" = countAtribsI a xs ys (b+1) c --si s'utilitza l'arxiu smallTest.txt cal
    | a == y && x == "e" = countAtribsI a xs ys b (c+1) --canviar p per poisonous i e per edible.
    | otherwise = countAtribsI a xs ys b c

getProb :: [String] -> [String] -> Int
getProb [] _ = 0
getProb _ [] = 0
getProb (x:xs) (y:ys) = (countAtribs y (x:xs) (y:ys)) + (getProb xNew yNew)
    where 
        xNew = removeAtribX y (x:xs) (y:ys)
        yNew = removeAtribY y (x:xs) (y:ys)

mostProbable :: Info  -> Int -> Int -> Float -> Int
mostProbable (_, []) _ pos _ = pos
mostProbable (a, (b:bs)) iter pos prob
    | prob == 1 = pos
    | p > prob = mostProbable (a, bs) (iter+1) (iter) p
    | otherwise = mostProbable (a, bs) (iter+1) pos prob
    where 
        p = (fromIntegral (getProb a b) :: Float)/(fromIntegral (length a) :: Float)

putFirst :: Int -> [a] -> [a] -> [a]
putFirst _ [] b = b
putFirst pos (a:as) b 
    | pos == 0 = [a]++b++as
    | otherwise = putFirst (pos-1) as (b++[a])

toxicityDirect :: String -> String -> [String] -> [String] -> Bool
toxicityDirect _ _ [] _ = True
toxicityDirect _ _ _ [] = True
toxicityDirect s t (x:xs) (y:ys)
    | s == y && x /= t = False
    | otherwise = toxicityDirect s t xs ys


eliminaPrimer :: [[String]] -> [[String]]
eliminaPrimer [] = []
eliminaPrimer a = map (tail) a

getPrimer :: [[String]] -> [[String]]
getPrimer [] = []
--getPrimer a = map (: []) $ map (head) a
getPrimer (a:as) = [[head a]] ++ getPrimer as

afegeirPrimer :: [[String]] -> [[String]] -> [[String]]
afegeirPrimer [] _ = []
afegeirPrimer a [] = a
afegeirPrimer (x:xs) (y:ys) = [x++y]++(afegeirPrimer xs ys)

divideixFiles :: String -> Info -> (Info,Info)
divideixFiles _ ([],_) = (([],[]), ([],[])) 
divideixFiles _ (_,[]) = (([],[]), ([],[])) 
divideixFiles s ((y:ys), (z:zs))
    | head z == s = (((y:(fst(fst res)), (afegeirPrimer (getPrimer (z:zs)) (snd (fst res)))), (snd res)))
    | otherwise = ((fst res), (y:(fst(snd res)), (afegeirPrimer (getPrimer (z:zs)) (snd (snd res)))))
    where 
        res = divideixFiles s (ys, (eliminaPrimer (z:zs)))

{-///////////////////////////////// data conversion //////////////////////////////////-}

construeixArbre :: Table -> Rules
construeixArbre ([], (_,_)) = NotClear
construeixArbre t = Atrib a (construeixFillsArbre (as, (b,c)))
    where
        p = mostProbable ((fst(snd t)), (snd(snd t))) 0 0 0
        (a:as) = putFirst p (fst t) []
        b = fst (snd t)
        c = putFirst p (snd (snd t)) []

construeixFillsArbre :: Table -> [(String,Rules)]
construeixFillsArbre (_,([],_)) = []
construeixFillsArbre (_,(_,[])) = []
construeixFillsArbre (a, ((b:bs), (c:cs))) 
    | direct = if b=="p" then [(s,Poisonous)] ++ construeixFillsArbre (a,(snd res)) 
        else if b=="e" then [(s,Edible)] ++ construeixFillsArbre (a,(snd res)) 
            else [(s,NotClear)] ++ construeixFillsArbre (a,(snd res)) 
    | cs == [] && all (==s) c = [(s,NotClear)]
    | otherwise = [(s,(construeixArbre (a,(fst (fst res), tail (snd (fst res))))))] ++ construeixFillsArbre (a,(snd res))
    where
        s = head c
        direct = toxicityDirect s b (b:bs) (c)
        res = divideixFiles s ((b:bs), (c:cs))
