module Page.Admin exposing
    ( Model
    , Msg
    , getLayout
    , getSession
    , handleRouteChange
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
import Route
import Route.Admin as AdminRoute exposing (Route)
import Session exposing (Session)
import Style.Size as Size
import View.Button as Button
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
    , navItem : NavItem
    }


type Msg
    = PasswordFieldUpdated String


type NavItem
    = NavItem__Blog



--------------------------------------------------------------------------------
-- INIT --
--------------------------------------------------------------------------------


init : Session -> Layout -> Route -> Model
init session layout route =
    let
        ( adminPassword, maybeError ) =
            Admin.fromStorage session.storage
    in
    { session =
        session
            |> Session.recordStorageDecodeError maybeError
    , layout = layout
    , adminPassword = Maybe.withDefault "" adminPassword
    , navItem = routeToNavItem route
    }



--------------------------------------------------------------------------------
-- ROUTE HANDLING --
--------------------------------------------------------------------------------


handleRouteChange : Route -> Model -> Model
handleRouteChange route =
    setNavItem (routeToNavItem route)



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


setPasswordField : String -> Model -> Model
setPasswordField newField model =
    { model | adminPassword = newField }


setNavItem : NavItem -> Model -> Model
setNavItem navItem model =
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
    [ nav model.navItem
    , body model
    ]


nav : NavItem -> Cell Msg
nav activeNavItem =
    let
        navItemView : NavItem -> Row Msg
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


body : Model -> Cell Msg
body model =
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



--------------------------------------------------------------------------------
-- PORTS --
--------------------------------------------------------------------------------


incomingPortsListener : FromJs.Listener Msg
incomingPortsListener =
    FromJs.none
