module Page.Blog exposing
    ( Model
    , Msg
    , getLayout
    , getSession
    , incomingPortsListener
    , init
    , update
    , view
    )

import Layout exposing (Layout)
import Ports.Incoming
import Session exposing (Session)
import View.Row exposing (Row)



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


getSession : Model -> Session
getSession model =
    model.session


getLayout : Model -> Layout
getLayout model =
    model.layout



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


view : Model -> List (Row Msg)
view model =
    []



--------------------------------------------------------------------------------
-- PORTS --
--------------------------------------------------------------------------------


incomingPortsListener : Ports.Incoming.Listener Msg
incomingPortsListener =
    Ports.Incoming.none
