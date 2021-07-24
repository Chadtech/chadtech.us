module Page.ComponentLibrary exposing (Modelka, Zpr, datZasedani, getLayout, handleRouteChange, mapZasedani, poca, pohled, setLayout, track, ziskatZasedani, zmodernizovat)

import Analytics
import Html.Styled as H exposing (Html)
import Layout exposing (Layout)
import Route
import Route.ComponentLibrary as ComponentLibraryRoute exposing (Route)
import Style.Size as Size exposing (Size)
import SyntaxHighlight
import View.Button as Button
import View.Cell as Cell exposing (Cell)
import View.Row as Row exposing (Row)
import Zasedani exposing (Zasedani)



---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type alias Modelka =
    { layout : Layout
    , zasedani : Zasedani
    , page : Page
    }


type alias Example zpr =
    { code : String
    , pohled : Cell zpr
    }


type Page
    = Page__Button
    | Page__Menu


type NavItem
    = NavItem__Button
    | NavItem__Menu


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
        ComponentLibraryRoute.Button ->
            Page__Button

        ComponentLibraryRoute.Menu ->
            Page__Menu


navItemToLabel : NavItem -> String
navItemToLabel navItem =
    case navItem of
        NavItem__Button ->
            "Button"

        NavItem__Menu ->
            "Menu"


navItemToRoute : NavItem -> Route
navItemToRoute navItem =
    case navItem of
        NavItem__Button ->
            ComponentLibraryRoute.Button

        NavItem__Menu ->
            ComponentLibraryRoute.Menu


pageToNavItem : Page -> NavItem
pageToNavItem page =
    case page of
        Page__Button ->
            NavItem__Button

        Page__Menu ->
            NavItem__Menu


navItems : List NavItem
navItems =
    let
        _ =
            case NavItem__Button of
                NavItem__Button ->
                    ()

                NavItem__Menu ->
                    ()
    in
    [ NavItem__Button
    , NavItem__Menu
    ]



--------------------------------------------------------------------------------
-- POHLED --
--------------------------------------------------------------------------------


pohled : Modelka -> List (Cell Zpr)
pohled modelka =
    [ nav modelka.page
    , body modelka.page
    ]


nav : Page -> Cell Zpr
nav page =
    let
        width : Size
        width =
            Size.extraLarge 4

        navItemView : NavItem -> Row Zpr
        navItemView navItem =
            Button.fromLabel
                (navItemToLabel navItem)
                |> Button.withLink
                    (Route.fromComponentLibraryRoute <|
                        navItemToRoute navItem
                    )
                |> Button.when (navItem == pageToNavItem page) Button.active
                |> Button.toCell
                |> Cell.withExactWidth width
                |> Row.fromCell
    in
    navItems
        |> List.map navItemView
        |> Row.withSpaceBetween Size.small
        |> Row.toCell
        |> Cell.withExactWidth width


body : Page -> Cell Zpr
body page =
    case page of
        Page__Button ->
            buttonPage

        Page__Menu ->
            menuPage


menuPage : Cell Zpr
menuPage =
    Cell.none


buttonPage : Cell Zpr
buttonPage =
    let
        simpleExample : Example Zpr
        simpleExample =
            let
                button : Cell zpr
                button =
                    Button.fromLabel "Button"
                        |> Button.toCell
            in
            { code = """
button : Cell zpr
button =
    Button.fromLabel "Button"
        |> Button.toCell
            """
            , pohled =
                [ button ]
                    |> List.map Row.fromCell
                    |> Row.toCell
            }
    in
    [ simpleExample ]
        |> List.map exampleToRow
        |> Row.toCell


exampleToRow : Example zpr -> Row zpr
exampleToRow example =
    let
        codeHtml : List (Html zpr)
        codeHtml =
            case SyntaxHighlight.elm example.code of
                Ok code ->
                    [ SyntaxHighlight.useTheme SyntaxHighlight.monokai
                    , SyntaxHighlight.toBlockHtml Nothing code
                    ]
                        |> List.map H.fromUnstyled

                Err _ ->
                    [ H.text "ERROR PARSING CODE" ]
    in
    [ Cell.fromHtml codeHtml
        |> Cell.indent
    , example.pohled
    ]
        |> Cell.withSpaceBetween Size.medium
        |> Row.fromCells



---------------------------------------------------------------
-- ZMODERNIZOVAT --
---------------------------------------------------------------


zmodernizovat : Zpr -> Modelka -> Modelka
zmodernizovat zpr modelka =
    case zpr of
        Zpr ->
            modelka



--------------------------------------------------------------------------------
-- TRACK --
--------------------------------------------------------------------------------


track : Zpr -> Analytics.Event
track zpr =
    case zpr of
        Zpr ->
            Analytics.none
