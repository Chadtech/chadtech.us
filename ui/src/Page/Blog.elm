module Page.Blog exposing
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
import Ports.FromJs as FromJs
import Session exposing (Session)
import Style.Color as Color
import Style.Size as Size
import View.Cell as Cell exposing (Cell)



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
    [ blogSection
    , blogNav
    ]


blogSection : Cell Msg
blogSection =
    Cell.fromHtml []
        |> indentBox


blogNav : Cell Msg
blogNav =
    Cell.fromHtml []
        |> indentBox
        |> Cell.withExactWidth (Size.extraLarge 5)


indentBox : Cell msg -> Cell msg
indentBox cell =
    cell
        |> Cell.indent
        |> Cell.withBackgroundColor Color.background1



--------------------------------------------------------------------------------
-- PORTS --
--------------------------------------------------------------------------------


incomingPortsListener : FromJs.Listener Msg
incomingPortsListener =
    FromJs.none
