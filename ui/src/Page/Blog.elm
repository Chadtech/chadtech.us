module Page.Blog exposing
    ( Modelka
    , Zpr
    , getLayout
    , incomingPortsListener
    , init
    , setLayout
    , setSession
    , update
    , view
    , ziskatZasedani
    )

import Layout exposing (Layout)
import Ports.FromJs as FromJs
import Style.Color as Color
import Style.Size as Size
import View.Cell as Cell exposing (Cell)
import Zasedani exposing (Zasedani)



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type alias Modelka =
    { session : Zasedani
    , layout : Layout
    }


type Zpr
    = Msg



--------------------------------------------------------------------------------
-- INIT --
--------------------------------------------------------------------------------


init : Zasedani -> Layout -> Modelka
init session layout =
    { session = session
    , layout = layout
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


setSession : Zasedani -> Modelka -> Modelka
setSession session model =
    { model | session = session }


ziskatZasedani : Modelka -> Zasedani
ziskatZasedani model =
    model.session


getLayout : Modelka -> Layout
getLayout model =
    model.layout


setLayout : Layout -> Modelka -> Modelka
setLayout layout model =
    { model | layout = layout }



--------------------------------------------------------------------------------
-- UPDATE --
--------------------------------------------------------------------------------


update : Zpr -> Modelka -> ( Modelka, Cmd Zpr )
update msg model =
    case msg of
        Msg ->
            ( model, Cmd.none )



--------------------------------------------------------------------------------
-- VIEW --
--------------------------------------------------------------------------------


view : Modelka -> List (Cell Zpr)
view model =
    [ blogSection
    , blogNav
    ]


blogSection : Cell Zpr
blogSection =
    Cell.fromHtml []
        |> indentBox


blogNav : Cell Zpr
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


incomingPortsListener : FromJs.Listener Zpr
incomingPortsListener =
    FromJs.none
