module Zasedani exposing
    ( Zasedani
    , Zpr
    , adminMode
    , goTo
    , listener
    , poca
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


type alias Zasedani =
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


poca : Decode.Value -> Nav.Key -> Result Decode.Error Zasedani
poca json navKey =
    let
        fromFlags : Flags -> Zasedani
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


setStorage : Storage -> Zasedani -> Zasedani
setStorage storage zasedani =
    { zasedani | storage = storage }


recordError : Error -> Zasedani -> Zasedani
recordError error zasedani =
    { zasedani | errors = error :: zasedani.errors }



---------------------------------------------------------------
-- UPDATE --
---------------------------------------------------------------


update : Zpr -> Zasedani -> Zasedani
update msg zasedani =
    case msg of
        StorageUpdated storage ->
            setStorage storage zasedani



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


recordStorageDecodeError : Maybe Decode.Error -> Zasedani -> Zasedani
recordStorageDecodeError maybeError zasedani =
    case maybeError of
        Just error ->
            recordError (StorageDecodeError error) zasedani

        Nothing ->
            zasedani


adminMode : Zasedani -> Maybe String
adminMode zasedani =
    zasedani.adminMode


turnOnAdminMode : Zasedani -> ( Zasedani, Cmd msg )
turnOnAdminMode zasedani =
    let
        ( initValue, cmd ) =
            Admin.poca
    in
    ( { zasedani | adminMode = Just initValue }
    , cmd
    )


setAdminPassword : String -> Zasedani -> Zasedani
setAdminPassword str zasedani =
    { zasedani | adminMode = Just str }


goTo : Zasedani -> Route -> Cmd msg
goTo zasedani route =
    Nav.pushUrl zasedani.navKey (Route.toString route)



---------------------------------------------------------------
-- PORTS INCOMING --
---------------------------------------------------------------


listener : FromJs.Listener Zpr
listener =
    Storage.listener StorageUpdated
