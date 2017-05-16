## Module Facebook.OAuthWeb

#### `ConnectionStatus`

``` purescript
data ConnectionStatus
```

The possible connection statuses of a user.

##### Instances
``` purescript
Generic ConnectionStatus
EncodeJson ConnectionStatus
DecodeJson ConnectionStatus
```

#### `AuthResponse`

``` purescript
newtype AuthResponse
```

##### Instances
``` purescript
Generic AuthResponse
Show AuthResponse
EncodeJson AuthResponse
DecodeJson AuthResponse
```

#### `LoginStatus`

``` purescript
newtype LoginStatus
  = LoginStatus { status :: ConnectionStatus, authResponse :: Maybe AuthResponse }
```

##### Instances
``` purescript
Generic LoginStatus
Show LoginStatus
EncodeJson LoginStatus
DecodeJson LoginStatus
```

#### `Facebook`

``` purescript
data Facebook :: Effect
```

#### `getLoginStatus`

``` purescript
getLoginStatus :: forall e. Aff (fb :: Facebook | e) LoginStatus
```

Get's the user's login status.  Aff only succeeds when status is Connected.

#### `login`

``` purescript
login :: forall e. Aff (fb :: Facebook | e) LoginStatus
```

Open a modal so the user can authorize/login to the app.
Aff only succeeds if the server response returns the Connected status.


