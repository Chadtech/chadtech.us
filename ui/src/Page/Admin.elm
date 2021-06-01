module Page.Admin exposing
    ( Modelka
    , Zpr
    , datZasedani
    , getLayout
    , handleRouteChange
    , incomingPortsListener
    , poca
    , pohled
    , setLayout
    , ziskatZasedani
    , zmodernizovat
    )

import Admin
import Layout exposing (Layout)
import Ports.FromJs as FromJs
import Route
import Route.Admin as AdminRoute exposing (Route)
import Style.Size as Size
import View.Button as Button
import View.Cell as Cell exposing (Cell)
import View.Row as Row exposing (Row)
import View.TextField as TextField
import Zasedani exposing (Zasedani)



---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type alias Modelka =
    { zasedani : Zasedani
    , layout : Layout
    , adminPassword : String
    , navItem : NavItem
    }


type Zpr
    = PasswordFieldUpdated String


type NavItem
    = NavItem__Blog



--------------------------------------------------------------------------------
-- POCA --
--------------------------------------------------------------------------------


poca : Zasedani -> Layout -> Route -> Modelka
poca zasedani layout route =
    let
        ( adminPassword, maybeError ) =
            Admin.fromStorage zasedani.storage
    in
    { zasedani =
        zasedani
            |> Zasedani.recordStorageDecodeError maybeError
    , layout = layout
    , adminPassword = Maybe.withDefault "" adminPassword
    , navItem = routeToNavItem route
    }



--------------------------------------------------------------------------------
-- ROUTE HANDLING --
--------------------------------------------------------------------------------


handleRouteChange : Route -> Modelka -> Modelka
handleRouteChange route =
    datNavItem (routeToNavItem route)



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


mapZasedani : (Zasedani -> Zasedani) -> Modelka -> Modelka
mapZasedani f model =
    datZasedani (f <| ziskatZasedani model) model


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
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


navItemToRoute : NavItem -> Route
navItemToRoute navItem =
    case navItem of
        NavItem__Blog ->
            AdminRoute.Blog


navItemToLabel : NavItem -> String
navItemToLabel navItem =
    case navItem of
        NavItem__Blog ->
            "Blog"


setPasswordField : String -> Modelka -> Modelka
setPasswordField newField model =
    { model | adminPassword = newField }


datNavItem : NavItem -> Modelka -> Modelka
datNavItem navItem model =
    { model | navItem = navItem }


routeToNavItem : Route -> NavItem
routeToNavItem route =
    case route of
        AdminRoute.Blog ->
            NavItem__Blog


navItems : List NavItem
navItems =
    [ NavItem__Blog ]



--------------------------------------------------------------------------------
-- ZMODERNIZOVAT --
--------------------------------------------------------------------------------


zmodernizovat : Zpr -> Modelka -> ( Modelka, Cmd Zpr )
zmodernizovat zpr modelka =
    case zpr of
        PasswordFieldUpdated str ->
            ( modelka
                |> setPasswordField str
                |> mapZasedani (Zasedani.setAdminPassword str)
            , Admin.save str
            )



--------------------------------------------------------------------------------
-- VIEW --
--------------------------------------------------------------------------------


pohled : Modelka -> List (Cell Zpr)
pohled modelka =
    [ nav modelka.navItem
    , body modelka
    ]


nav : NavItem -> Cell Zpr
nav activeNavItem =
    let
        navItemView : NavItem -> Row Zpr
        navItemView navItem =
            Button.fromLabel
                (navItemToLabel navItem)
                |> Button.withLink
                    (Route.fromAdminRoute <| navItemToRoute navItem)
                |> Button.when (navItem == activeNavItem) Button.active
                |> Button.toRow
    in
    navItems
        |> List.map navItemView
        |> Row.toCell
        |> Cell.withExactWidth (Size.extraLarge 4)


body : Modelka -> Cell Zpr
body modelka =
    [ Row.fromString "Admin Panel"
    , Row.fromCells
        [ Cell.fromString "Admin Password"
            |> Cell.withExactWidth (Size.extraLarge 4)
            |> Cell.verticallyCenterContent
        , TextField.simple
            modelka.adminPassword
            PasswordFieldUpdated
            |> TextField.toCell
            |> Cell.withExactWidth (Size.extraLarge 5)
        ]
    ]
        |> Row.withSpaceBetween Size.medium
        |> Row.toCell



--------------------------------------------------------------------------------
-- PORTS --
--------------------------------------------------------------------------------


incomingPortsListener : FromJs.Listener Zpr
incomingPortsListener =
    FromJs.none
