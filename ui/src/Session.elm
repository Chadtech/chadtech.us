module Session exposing
    ( Msg
    , Session
    , adminIsOn
    , goTo
    , init
    , listener
    , setAdminPassword
    , turnOnAdminMode
    , update
    )

import Browser.Navigation as Nav
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.Incoming
import Route exposing (Route)
import Storage exposing (Storage)
import Util.Maybe as MaybeUtil



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type alias Session =
    { navKey : Nav.Key
    , admin : AdminMode
    , storage : Storage
    , errors : List Error
    }


type Error
    = InitError Decode.Error


type AdminMode
    = AdminMode__Off
    | AdminMode__On { password : String }


type Msg
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
                ( admin, adminError ) =
                    case Storage.get adminModeKey Decode.string flags.storage of
                        Ok (Just password) ->
                            ( AdminMode__On { password = password }
                            , Nothing
                            )

                        Ok Nothing ->
                            ( AdminMode__Off, Nothing )

                        Err error ->
                            ( AdminMode__Off, Just <| InitError error )
            in
            { navKey = navKey
            , admin = admin
            , storage = flags.storage
            , errors =
                [ MaybeUtil.toList adminError ]
                    |> List.concat
            }
    in
    Decode.decodeValue
        (Decode.map Flags Storage.decoder)
        json
        |> Result.map fromFlags



---------------------------------------------------------------
-- INTERNAL HELPERS --
---------------------------------------------------------------


adminModeKey : String
adminModeKey =
    "admin_mode"


setStorage : Storage -> Session -> Session
setStorage storage session =
    { session | storage = storage }



---------------------------------------------------------------
-- UPDATE --
---------------------------------------------------------------


update : Msg -> Session -> Session
update msg session =
    case msg of
        StorageUpdated storage ->
            setStorage storage session



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


adminIsOn : Session -> Bool
adminIsOn session =
    session.admin /= AdminMode__Off


turnOnAdminMode : Session -> ( Session, Cmd msg )
turnOnAdminMode session =
    ( { session | admin = AdminMode__On { password = "" } }
    , Storage.set adminModeKey <| Encode.string ""
    )


setAdminPassword : String -> Session -> Session
setAdminPassword str session =
    case session.admin of
        AdminMode__Off ->
            session

        AdminMode__On params ->
            { session | admin = AdminMode__On { params | password = str } }


goTo : Session -> Route -> Cmd msg
goTo session route =
    Nav.pushUrl session.navKey (Route.toString route)



---------------------------------------------------------------
-- PORTS INCOMING --
---------------------------------------------------------------


listener : Ports.Incoming.Listener Msg
listener =
    Storage.listener StorageUpdated
