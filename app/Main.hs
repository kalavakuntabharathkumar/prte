{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Control.Concurrent.MVar
import Control.Monad.IO.Class
import Data.Aeson
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.Text (Text)\nimport qualified Data.Text as T
import GHC.Generics
import Network.Wai
import Network.Wai.Handler.Warp
import Servant

data Payment = Payment
  { paymentId :: Text
  , merchantId :: Text
  , amount :: Int
  , currency :: Text
  , method :: Text
  , gateway :: Text
  , status :: Text
  } deriving (Show, Generic)

instance ToJSON Payment
instance FromJSON Payment

data PaymentRequest = PaymentRequest
  { requestMerchantId :: Text
  , requestAmount :: Int
  , requestCurrency :: Text
  , requestMethod :: Text
  } deriving (Show, Generic)

instance ToJSON PaymentRequest
instance FromJSON PaymentRequest

type API =
       "health" :> Get '[JSON] Value
  :<|> "gateways" :> Get '[JSON] [Text]
  :<|> "payments" :> ReqBody '[JSON] PaymentRequest :> Post '[JSON] Payment
  :<|> "payments" :> Capture "id" Text :> Get '[JSON] (Maybe Payment)

data State = State
  { nextId :: Int
  , payments :: Map Text Payment
  }

gatewayOrder :: [Text]
gatewayOrder = ["bank-a","bank-b","bank-c","bank-d","bank-e"]

chooseGateway :: Map Text Double -> Text
chooseGateway scores =
  maximumByScore (zip gatewayOrder (map (`Map.findWithDefault` scores) gatewayOrder))
  where
    maximumByScore [] = "bank-a"
    maximumByScore ((g,s):xs) = fst (foldl pick (g,s) xs)
    pick best candidate = if snd candidate > snd best then candidate else best

app :: MVar State -> Application
app state = serve api (server state)
  where
    api = Proxy :: Proxy API

server :: MVar State -> Server API
server state =
       pure (object ["status" .= ("ok" :: Text)])
  :<|> pure gatewayOrder
  :<|> createPayment state
  :<|> getPayment state

createPayment :: MVar State -> PaymentRequest -> Handler Payment
createPayment state req = do
  p <- liftIO $ modifyMVar state $ \s -> do
    let pid = "pay-" <> T.pack (show (nextId s))
        gw = gatewayOrder !! (nextId s `mod` length gatewayOrder)
        payment = Payment pid (requestMerchantId req) (requestAmount req)
          (requestCurrency req) (requestMethod req) gw "AUTHORIZED"
    pure (s {nextId = nextId s + 1, payments = Map.insert pid payment (payments s)}, payment)
  pure p
  where
    fromString = id

getPayment :: MVar State -> Text -> Handler (Maybe Payment)
getPayment state pid = liftIO $ Map.lookup pid . payments <$> readMVar state

main :: IO ()
main = do
  state <- newMVar (State 1 Map.empty)
  putStrLn "PayRoute listening on :8080"
  run 8080 (app state)
