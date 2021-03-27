module Session exposing
    ( Session
    , Zpr
    , adminMode
    , goTo
    , init
    , listener
    , recordStorageDecodeError
    , setAdminPassword
    , turnOnAdminMode
    , update
    )

import Admin
import Browser.Navigation as Nav
import Json.Decode as Decode
import Ports.FromJs as FromJs
import Route exposing (Route)
import Storage exposing (Storage)
import Util.Maybe as MaybeUtil



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type alias Session =
    { navKey : Nav.Key
    , adminMode : Maybe String
    , storage : Storage
    , errors : List Error
    }


type Error
    = InitError Decode.Error
    | StorageDecodeError Decode.Error


type Zpr
    = StorageUpdated Storage



---------------------------------------------------------------
-- INIT --
---------------------------------------------------------------


type alias Flags =
    { storage : Storage }


init : Decode.Value -> Nav.Key -> Result Decode.Error Session
init json navKey =
    let
        fromFlags : Flags -> Session
        fromFlags flags =
            let
                ( adminPassword, adminError ) =
                    Admin.fromStorage flags.storage
            in
            { navKey = navKey
            , adminMode = adminPassword
            , storage = flags.storage
            , errors =
                [ adminError
                    |> Maybe.map InitError
                    |> MaybeUtil.toList
                ]
                    |> List.concat
            }
    in
    Decode.decodeValue
        (Decode.map Flags
            (Decode.field "storage" Storage.decoder)
        )
        json
        |> Result.map fromFlags



---------------------------------------------------------------
-- INTERNAL HELPERS --
---------------------------------------------------------------


setStorage : Storage -> Session -> Session
setStorage storage session =
    { session | storage = storage }


recordError : Error -> Session -> Session
recordError error session =
    { session | errors = error :: session.errors }



---------------------------------------------------------------
-- UPDATE --
---------------------------------------------------------------


update : Zpr -> Session -> Session
update msg session =
    case msg of
        StorageUpdated storage ->
            setStorage storage session



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


recordStorageDecodeError : Maybe Decode.Error -> Session -> Session
recordStorageDecodeError maybeError session =
    case maybeError of
        Just error ->
            recordError (StorageDecodeError error) session

        Nothing ->
            session


adminMode : Session -> Maybe String
adminMode session =
    session.adminMode


turnOnAdminMode : Session -> ( Session, Cmd msg )
turnOnAdminMode session =
    let
        ( initValue, cmd ) =
            Admin.init
    in
    ( { session | adminMode = Just initValue }
    , cmd
    )


setAdminPassword : String -> Session -> Session
setAdminPassword str session =
    { session | adminMode = Just str }


goTo : Session -> Route -> Cmd msg
goTo session route =
    Nav.pushUrl session.navKey (Route.toString route)



---------------------------------------------------------------
-- PORTS INCOMING --
---------------------------------------------------------------


listener : FromJs.Listener Zpr
listener =
    Storage.listener StorageUpdated
