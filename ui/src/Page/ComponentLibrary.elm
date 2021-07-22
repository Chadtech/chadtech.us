module Page.ComponentLibrary exposing (Modelka, Zpr, datZasedani, getLayout, handleRouteChange, mapZasedani, poca, pohled, setLayout, track, ziskatZasedani, zmodernizovat)

import Analytics
import Layout exposing (Layout)
import Route.ComponentLibrary as Route exposing (Route)
import View.Cell exposing (Cell)
import Zasedani exposing (Zasedani)



---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type alias Modelka =
    { layout : Layout
    , zasedani : Zasedani
    , page : Page
    }


type Page
    = Page__Button


type Zpr
    = Zpr



--------------------------------------------------------------------------------
-- POCA --
--------------------------------------------------------------------------------


poca : Zasedani -> Layout -> Route -> Modelka
poca zasedani layout route =
    { layout = layout
    , zasedani = zasedani
    , page = routeToPage route
    }



--------------------------------------------------------------------------------
-- ROUTE HANDLING --
--------------------------------------------------------------------------------


handleRouteChange : Route -> Modelka -> Modelka
handleRouteChange route =
    datPage (routeToPage route)



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


mapZasedani : (Zasedani -> Zasedani) -> Modelka -> Modelka
mapZasedani f model =
    datZasedani (f <| ziskatZasedani model) model


datZasedani : Zasedani -> Modelka -> Modelka
datZasedani zasedani modelka =
    { modelka | zasedani = zasedani }


ziskatZasedani : Modelka -> Zasedani
ziskatZasedani modelka =
    modelka.zasedani


getLayout : Modelka -> Layout
getLayout model =
    model.layout


setLayout : Layout -> Modelka -> Modelka
setLayout layout model =
    { model | layout = layout }



--------------------------------------------------------------------------------
-- HELPERS --
--------------------------------------------------------------------------------


datPage : Page -> Modelka -> Modelka
datPage page modelka =
    { modelka | page = page }


routeToPage : Route -> Page
routeToPage route =
    case route of
        Route.Button ->
            Page__Button



--------------------------------------------------------------------------------
-- POHLED --
--------------------------------------------------------------------------------


pohled : Modelka -> List (Cell Zpr)
pohled modelka =
    []



---------------------------------------------------------------
-- ZMODERNIZOVAT --
---------------------------------------------------------------


zmodernizovat : Zpr -> Modelka -> Modelka
zmodernizovat zpr modelka =
    case zpr of
        Zpr ->
            modelka



--------------------------------------------------------------------------------
-- POHLED --
--------------------------------------------------------------------------------


track : Zpr -> Analytics.Event
track zpr =
    case zpr of
        Zpr ->
            Analytics.none
