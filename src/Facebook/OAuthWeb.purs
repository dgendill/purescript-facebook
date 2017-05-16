module Facebook.OAuthWeb (
    getLoginStatus,
    login,
    LoginStatus(..),
    AuthResponse,
    ConnectionStatus,
    Facebook
  ) where

import Prelude
import Control.Monad.Aff (Aff)
import Control.Monad.Eff (kind Effect)
import Control.Monad.Eff.Exception (error)
import Control.Monad.Except (throwError)
import Data.Argonaut (class DecodeJson, class EncodeJson, Json, encodeJson, fromNumber, fromObject, fromString, getField, toObject, toString)
import Data.Argonaut.Core (stringify)
import Data.Argonaut.Decode.Class (decodeJson)
import Data.Either (Either(..), either)
import Data.Generic (class Generic)
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.StrMap (fromFoldable)
import Data.Time.Duration (Milliseconds(..))
import Data.Tuple (Tuple(..))

-- | The possible connection statuses of a user.
-- \ See [LoginStatus](https://developers.facebook.com/docs/reference/javascript/FB.getLoginStatus)
data ConnectionStatus = Connected | NotAuthorized | Unknown

newtype AuthResponse = AuthResponse {
  accessToken :: String,
  expiresIn :: Milliseconds,
  signedRequest :: String,
  userID :: String
}

newtype LoginStatus = LoginStatus {
  status :: ConnectionStatus,
  authResponse :: Maybe AuthResponse
}

foreign import data Facebook :: Effect

foreign import getLoginStatusImpl :: forall e. Aff ( fb :: Facebook | e ) Json

-- | Get's the user's login status.  Aff only succeeds when status is Connected.
getLoginStatus :: forall e. Aff ( fb :: Facebook | e ) LoginStatus
getLoginStatus =
  getLoginStatusImpl >>=
  decodeJson >>>
  (either (error >>> throwError) (pure <<< id))

foreign import loginImpl :: forall e. Aff (fb :: Facebook | e ) Json

-- | Open a modal so the user can authorize/login to the app.
-- | Aff only succeeds if the server response returns the Connected status.
login :: forall e. Aff ( fb :: Facebook | e ) LoginStatus
login =
  loginImpl >>=
  decodeJson >>>
  (either (error >>> throwError) (pure <<< id))


derive instance genericCS :: Generic ConnectionStatus
derive instance genericAR :: Generic AuthResponse
derive instance genericLS :: Generic LoginStatus

instance showAuthResponse :: Show AuthResponse where show = encodeJson >>> stringify
instance showLoginStatus :: Show LoginStatus where show = encodeJson >>> stringify

instance encodeCS :: EncodeJson ConnectionStatus where
  encodeJson Connected = fromString "connected"
  encodeJson NotAuthorized = fromString "not_authorized"
  encodeJson Unknown = fromString "unknown"

instance encodeAR :: EncodeJson AuthResponse where
  encodeJson (AuthResponse {accessToken, expiresIn, signedRequest, userID}) = fromObject $ fromFoldable [
    Tuple "accessToken"   $ fromString accessToken,
    Tuple "expiresIn"     $ fromNumber $ unwrap expiresIn,
    Tuple "signedRequest" $ fromString signedRequest,
    Tuple "userID"        $ fromString userID
  ]

instance encodeLS :: EncodeJson LoginStatus where
  encodeJson (LoginStatus { status, authResponse }) = fromObject $ fromFoldable [
    Tuple "authResponse" $ encodeJson authResponse,
    Tuple "status" $ encodeJson status
  ]

instance decodeConnectionStatus :: DecodeJson ConnectionStatus where
  decodeJson json = do
    s <- maybeFail "Facebook connection status was not a string." (toString json)
    case s of
      "connected" -> Right Connected
      "not_authorized" -> Right NotAuthorized
      "unknown" -> Right Unknown
      _ -> Left $ "Unexpected Facebook connection status '" <> s <> "'. " <>
                  "Expected values are 'connected', 'not_authorized', and 'unknown'."

instance decodeAuthResponse :: DecodeJson AuthResponse where
  decodeJson json = case toObject json of
    Nothing -> Left $ "authResponse was not an object."
    Just obj -> do
      accessToken <- getField obj "accessToken"
      expiresInRaw <- getField obj "expiresIn"
      let expiresIn = Milliseconds expiresInRaw
      signedRequest <- getField obj "signedRequest"
      userID <- getField obj "userID"
      pure $ AuthResponse { accessToken, expiresIn, signedRequest, userID }

instance decodeLoginStatus :: DecodeJson LoginStatus where
  decodeJson json = do
    obj <- maybeFail "Could not read loginStatus" (toObject json)
    status <- getField obj "status"
    authResponse <- getField obj "authResponse"
    pure $ LoginStatus { status, authResponse }

maybeFail :: forall a. String -> Maybe a -> Either String a
maybeFail s m = case m of
  Just mm -> Right mm
  Nothing -> Left s
