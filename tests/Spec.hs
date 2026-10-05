module Main where

import Test.Hspec
import Test.QuickCheck
import Data.List (nub)
import Data.Text (Text)
import qualified Data.Text as T

choose :: [(Text, Double)] -> Text
choose [] = "bank-a"
choose xs = fst $ foldl1 ( b -> if snd b > snd a then b else a) xs

main :: IO ()
main = hspec $ do
  describe "gateway routing" $ do
    it "selects the highest success-rate gateway" $ property $
      \rates -> not (null rates) ==> choose rates == fst (foldl1 maxRate rates)
    it "keeps gateway names unique" $ property $
      \xs -> let gs = map (("bank-" <>) . T.pack . show) (take 5 (xs :: [Int]))
              in length gs == length (nub gs)
  where
    maxRate a b = if snd b > snd a then b else a
