module Zasedani exposing
    ( Zasedani
    , Zpr
    , adminMode
    , datAnalytics
    , devPanel
    , errorsAsStrs
    , goTo
    , id
    , listener
    , openDevPanel
    , poca
    , recordApiError
    , recordStorageDecodeError
    , setAdminPassword
    , turnOnAdminMode
    , ziskatAnalytics
    , zmodernizovat
    )

import Admin
import Analytics
import Api
import Browser.Navigation as Nav
import Json.Decode as Decode
import Ports.FromJs as FromJs
import Route exposing (Route)
import Storage exposing (Storage)
import Util.Maybe as MaybeUtil
import View.DevPanel as DevPanel



---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type alias Zasedani =
    { navKey : Nav.Key
    , adminMode : Maybe String
    , storage : Storage
    , devPanel : Maybe DevPanel.Modelka
    , errors : List Error
    , analytics : Analytics.Modelka
    , id : String
    }


type Error
    = InitError Decode.Error
    | StorageDecodeError Decode.Error
    | ApiError Api.Error


type Zpr
    = StorageUpdated Storage



---------------------------------------------------------------
-- POCA --
---------------------------------------------------------------


type alias Flags =
    { storage : Storage
    , id : String
    }


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
            , devPanel = Nothing
            , errors =
                [ adminError
                    |> Maybe.map InitError
                    |> MaybeUtil.toList
                ]
                    |> List.concat
            , analytics = Analytics.poca
            , id = flags.id
            }
    in
    Decode.decodeValue
        (Decode.map2 Flags
            (Decode.field "storage" Storage.decoder)
            (Decode.field "id" Decode.string)
        )
        json
        |> Result.map fromFlags



---------------------------------------------------------------
-- INTERNAL HELPERS --
---------------------------------------------------------------


datStorage : Storage -> Zasedani -> Zasedani
datStorage storage zasedani =
    { zasedani | storage = storage }


recordError : Error -> Zasedani -> Zasedani
recordError error zasedani =
    { zasedani | errors = error :: zasedani.errors }



---------------------------------------------------------------
-- ZMODERNIZOVAT --
---------------------------------------------------------------


zmodernizovat : Zpr -> Zasedani -> Zasedani
zmodernizovat zpr zasedani =
    case zpr of
        StorageUpdated storage ->
            datStorage storage zasedani



---------------------------------------------------------------
-- INTERNAL HELPERS --
---------------------------------------------------------------


errorToString : { sensitive : Bool } -> Error -> String
errorToString args superError =
    case superError of
        InitError error ->
            "Initialization error : " ++ Decode.errorToString error

        StorageDecodeError error ->
            "Storage Decode Error : " ++ Decode.errorToString error

        ApiError error ->
            "Api Error : " ++ Api.errorToString { sensitive = args.sensitive } error



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


id : Zasedani -> String
id zasedani =
    zasedani.id


recordApiError : Api.Error -> Zasedani -> Zasedani
recordApiError error =
    recordError (ApiError error)


openDevPanel : Zasedani -> Zasedani
openDevPanel zasedani =
    { zasedani | devPanel = Just DevPanel.poca }


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


devPanel : Zasedani -> Maybe DevPanel.Modelka
devPanel =
    .devPanel


errorsAsStrs : { sensitive : Bool } -> Zasedani -> List String
errorsAsStrs args zasedani =
    List.map
        (errorToString { sensitive = args.sensitive })
        zasedani.errors


datAnalytics : Analytics.Modelka -> Zasedani -> Zasedani
datAnalytics analyticsModelka zasedani =
    { zasedani | analytics = analyticsModelka }


ziskatAnalytics : Zasedani -> Analytics.Modelka
ziskatAnalytics zasedani =
    zasedani.analytics



---------------------------------------------------------------
-- PORTS INCOMING --
---------------------------------------------------------------


listener : FromJs.Listener Zpr
listener =
    Storage.listener StorageUpdated
