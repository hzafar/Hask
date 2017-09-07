{- CIS 194 HW 10
   due Monday, 1 April
-}

module AParser where

import Control.Applicative

import Data.Char

-- A parser for a value of type a is a function which takes a String
-- represnting the input to be parsed, and succeeds or fails; if it
-- succeeds, it returns the parsed value along with the remainder of
-- the input.
newtype Parser a = Parser { runParser :: String -> Maybe (a, String) }

-- For example, 'satisfy' takes a predicate on Char, and constructs a
-- parser which succeeds only if it sees a Char that satisfies the
-- predicate (which it then returns).  If it encounters a Char that
-- does not satisfy the predicate (or an empty input), it fails.
satisfy :: (Char -> Bool) -> Parser Char
satisfy p = Parser f
	where
	f [] = Nothing		-- fail on the empty input
	f (x:xs)			-- check if x satisfies the predicate
						-- if so, return x along with the remainder
						-- of the input (that is, xs)
		| p x		= Just (x, xs)
		| otherwise	= Nothing  -- otherwise, fail

-- Using satisfy, we can define the parser 'char c' which expects to
-- see exactly the character c, and fails otherwise.
char :: Char -> Parser Char
char c = satisfy (== c)

{- For example:

*Parser> runParser (satisfy isUpper) "ABC"
Just ('A',"BC")
*Parser> runParser (satisfy isUpper) "abc"
Nothing
*Parser> runParser (char 'x') "xyz"
Just ('x',"yz")

-}

-- For convenience, we've also provided a parser for positive
-- integers.
posInt :: Parser Integer
posInt = Parser f
  where
	f xs
		| null ns	= Nothing
		| otherwise	= Just (read ns, rest)
		where (ns, rest) = span isDigit xs

------------------------------------------------------------
-- Your code goes below here
------------------------------------------------------------

first :: (a -> b) -> (a,c) -> (b,c)
first fn (f,s) = (fn f, s)

safeAp :: (a -> b) -> Maybe (a, String) -> Maybe (b, String)
safeAp fn Nothing = Nothing
safeAp fn (Just val) = Just (first fn val)

-- (a -> b) -> f a -> f b
instance Functor Parser where
	fmap fn p = Parser {runParser = (safeAp fn) . (runParser p)}


applyToMaybe :: (a -> b) -> Maybe (a, String) -> Maybe (b, String)
applyToMaybe _ Nothing = Nothing
applyToMaybe partFunc (Just (val, rest)) = Just ((partFunc val), rest)


ranFirstApp :: (String -> Maybe (a, String)) -> Maybe ((a -> b), String) -> Maybe (b, String)
ranFirstApp _ Nothing = Nothing
ranFirstApp rp2 (Just (partFunc, rest)) = applyToMaybe partFunc (rp2 rest)


instance Applicative Parser where
	pure fn = Parser {runParser = \s -> Just (fn, s)}
	(<*>) (Parser rp1) (Parser rp2) = Parser {runParser = (ranFirstApp rp2) . rp1}


makePair :: Char -> Char -> (Char, Char)
makePair a b = (a,b)

abParser :: Parser (Char, Char)
abParser = makePair <$> (char 'a') <*> (char 'b')


burnTwo :: Char -> Char -> ()
burnTwo _ _ = ()

abParser_ :: Parser ()
abParser_ = burnTwo <$> (char 'a') <*> (char 'b')


pairFormat :: Integer -> Char -> Integer -> [Integer]
pairFormat a _ b = [a, b]

intPair :: Parser [Integer]
intPair = pairFormat <$> posInt <*> (char ' ') <*> posInt



instance Alternative Parser where
	empty = Parser {runParser = \_ -> Nothing}
	(<|>) (Parser rp1) (Parser rp2) = Parser {runParser = \s -> ((rp1 s) <|> (rp2 s))}



negIntParser :: Parser ()
negIntParser = (\_ _ -> ()) <$> (char '-') <*> posInt


burn :: Parser a -> Parser ()
burn p = (\_ -> ()) <$> p


intOrUppercase :: Parser ()
intOrUppercase = (burn (satisfy isUpper)) <|> negIntParser <|> (burn posInt)