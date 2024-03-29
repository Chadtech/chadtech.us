module Page.Blog exposing
    ( Modelka
    , Zpr
    , datZasedani
    , getLayout
    , incomingPortsListener
    , pendingRequests
    , poca
    , pohled
    , setLayout
    , track
    , ziskatZasedani
    , zmodernizovat
    )

import Analytics
import Api
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
    { zasedani : Zasedani
    , layout : Layout
    , api : Api.Modelka BlogApiKey
    }


type BlogApiKey
    = BlogApiKey


type Zpr
    = Msg



--------------------------------------------------------------------------------
-- POCA --
--------------------------------------------------------------------------------


poca : Zasedani -> Layout -> Modelka
poca zasedani layout =
    { zasedani = zasedani
    , layout = layout
    , api = Api.init
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


pendingRequests : Modelka -> Api.PendingRequestCount
pendingRequests modelka =
    Api.pendingRequests modelka.api


datZasedani : Zasedani -> Modelka -> Modelka
datZasedani zasedani model =
    { model | zasedani = zasedani }


ziskatZasedani : Modelka -> Zasedani
ziskatZasedani model =
    model.zasedani


getLayout : Modelka -> Layout
getLayout model =
    model.layout


setLayout : Layout -> Modelka -> Modelka
setLayout layout model =
    { model | layout = layout }



--------------------------------------------------------------------------------
-- ZMODERNIZOVAT --
--------------------------------------------------------------------------------


zmodernizovat : Zpr -> Modelka -> ( Modelka, Cmd Zpr )
zmodernizovat zpr modelka =
    case zpr of
        Msg ->
            ( modelka, Cmd.none )



--------------------------------------------------------------------------------
-- TRACK --
--------------------------------------------------------------------------------


track : Zpr -> Analytics.Event
track zpr =
    case zpr of
        Msg ->
            Analytics.none



--------------------------------------------------------------------------------
-- VIEW --
--------------------------------------------------------------------------------


pohled : Modelka -> List (Cell Zpr)
pohled model =
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
