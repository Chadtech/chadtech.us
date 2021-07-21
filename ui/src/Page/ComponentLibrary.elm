module Page.ComponentLibrary exposing (Modelka, Zpr, poca)

import Layout exposing (Layout)
import Route.ComponentLibrary as Route exposing (Route)
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
