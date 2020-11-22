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

import Layout exposing (Layout)
import Ports.Incoming
import Session exposing (Session)
import View.Cell as Cell exposing (Cell)
import View.Row as Row



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type alias Model =
    { session : Session
    , layout : Layout
    }


type Msg
    = Msg



--------------------------------------------------------------------------------
-- INIT --
--------------------------------------------------------------------------------


init : Session -> Layout -> Model
init session layout =
    { session = session
    , layout = layout
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


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
-- UPDATE --
--------------------------------------------------------------------------------


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg ->
            ( model, Cmd.none )



--------------------------------------------------------------------------------
-- VIEW --
--------------------------------------------------------------------------------


view : Model -> List (Cell Msg)
view model =
    [ Row.toCell
        [ Row.fromString "Admin Panel"
        ]
    ]



--------------------------------------------------------------------------------
-- PORTS --
--------------------------------------------------------------------------------


incomingPortsListener : Ports.Incoming.Listener Msg
incomingPortsListener =
    Ports.Incoming.none
