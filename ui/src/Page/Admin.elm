module Page.Admin exposing
    ( Model
    , Msg
    , getLayout
    , getSession
    , incomingPortsListener
    , init
    , setLayout
    , setSession
    , update
    , view
    )

import Admin
import Layout exposing (Layout)
import Ports.FromJs as FromJs
import Session exposing (Session)
import Style.Size as Size
import View.Cell as Cell exposing (Cell)
import View.Row as Row exposing (Row)
import View.TextField as TextField



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type alias Model =
    { session : Session
    , layout : Layout
    , adminPassword : String
    }


type Msg
    = PasswordFieldUpdated String



--------------------------------------------------------------------------------
-- INIT --
--------------------------------------------------------------------------------


init : Session -> Layout -> Model
init session layout =
    let
        ( adminPassword, maybeError ) =
            Admin.fromStorage session.storage
    in
    { session =
        session
            |> Session.recordStorageDecodeError maybeError
    , layout = layout
    , adminPassword = Maybe.withDefault "" adminPassword
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


mapSession : (Session -> Session) -> Model -> Model
mapSession f model =
    setSession (f <| getSession model) model


setSession : Session -> Model -> Model
setSession session model =
    { model | session = session }


getSession : Model -> Session
getSession model =
    model.session


getLayout : Model -> Layout
getLayout model =
    model.layout


setLayout : Layout -> Model -> Model
setLayout layout model =
    { model | layout = layout }



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


setPasswordField : String -> Model -> Model
setPasswordField newField model =
    { model | adminPassword = newField }



--------------------------------------------------------------------------------
-- UPDATE --
--------------------------------------------------------------------------------


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PasswordFieldUpdated str ->
            ( model
                |> setPasswordField str
                |> mapSession (Session.setAdminPassword str)
            , Admin.save str
            )



--------------------------------------------------------------------------------
-- VIEW --
--------------------------------------------------------------------------------


view : Model -> List (Cell Msg)
view model =
    [ Row.fromString "Admin Panel"
    , Row.fromCells
        [ Cell.fromString "Admin Password"
            |> Cell.withExactWidth (Size.extraLarge 4)
            |> Cell.verticallyCenterContent
        , TextField.simple
            model.adminPassword
            PasswordFieldUpdated
            |> TextField.toCell
            |> Cell.withExactWidth (Size.extraLarge 5)
        ]
    ]
        |> Row.withSpaceBetween Size.medium
        |> Row.toCell
        |> List.singleton



--------------------------------------------------------------------------------
-- PORTS --
--------------------------------------------------------------------------------


incomingPortsListener : FromJs.Listener Msg
incomingPortsListener =
    FromJs.none
