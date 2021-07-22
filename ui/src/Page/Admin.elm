module Page.Admin exposing
    ( Modelka
    , Zpr
    , datZasedani
    , getLayout
    , handleRouteChange
    , incomingPortsListener
    , pendingRequests
    , poca
    , pohled
    , setLayout
    , track
    , ziskatZasedani
    , zmodernizovat
    )

import Admin
import Analytics
import Api
import Layout exposing (Layout)
import Page.Admin.Blog as Blog
import Ports.FromJs as FromJs
import Route
import Route.Admin as AdminRoute exposing (Route)
import Style.Size as Size exposing (Size)
import View.Button as Button
import View.Cell as Cell exposing (Cell)
import View.Row as Row exposing (Row)
import View.TextField as TextField
import Zasedani exposing (Zasedani)



---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type alias Modelka =
    { layout : Layout
    , zasedani : Zasedani
    , adminPassword : String
    , page : Page
    , api : Api.Modelka AdminApiKey
    }


type AdminApiKey
    = AdminApiKey


type alias Response value =
    Api.Response value AdminApiKey


type Page
    = Page__Blog Blog.Modelka
    | Page__Loading NavItem


type Zpr
    = PasswordFieldUpdated String
    | BlogZpr Blog.Zpr
    | BlogLoaded (Response Blog.Flags)


type NavItem
    = NavItem__Blog



--------------------------------------------------------------------------------
-- POCA --
--------------------------------------------------------------------------------


poca : Zasedani -> Layout -> Route -> ( Modelka, Cmd Zpr )
poca zasedani layout route =
    let
        ( adminPassword, maybeError ) =
            Admin.fromStorage zasedani.storage

        modelka : Modelka
        modelka =
            { layout = layout
            , adminPassword = Maybe.withDefault "" adminPassword
            , page = Page__Loading (routeToNavItem route)
            , zasedani = Zasedani.recordStorageDecodeError maybeError zasedani
            , api = Api.init
            }
    in
    loadPage route modelka



--------------------------------------------------------------------------------
-- ROUTE HANDLING --
--------------------------------------------------------------------------------


handleRouteChange : Route -> Modelka -> ( Modelka, Cmd Zpr )
handleRouteChange route modelka =
    modelka
        |> datPage (Page__Loading (routeToNavItem route))
        |> loadPage route



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


pendingRequests : Modelka -> Api.PendingRequestCount
pendingRequests modelka =
    Api.pendingRequests modelka.api


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
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


pageToNavItem : Page -> NavItem
pageToNavItem page =
    case page of
        Page__Blog _ ->
            NavItem__Blog

        Page__Loading navItem ->
            navItem


loadPage : Route -> Modelka -> ( Modelka, Cmd Zpr )
loadPage route modelka =
    case route of
        AdminRoute.Blog ->
            Blog.load BlogLoaded modelka


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


datPasswordField : String -> Modelka -> Modelka
datPasswordField newField modelka =
    { modelka | adminPassword = newField }


datPage : Page -> Modelka -> Modelka
datPage page modelka =
    { modelka | page = page }


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
                |> datPasswordField str
                |> mapZasedani (Zasedani.setAdminPassword str)
            , Admin.save str
            )

        BlogZpr subZpr ->
            case modelka.page of
                Page__Blog subModelka ->
                    let
                        ( novaSubModelka, cmd ) =
                            Blog.zmodernizovat subZpr subModelka
                    in
                    ( datPage
                        (Page__Blog novaSubModelka)
                        modelka
                    , Cmd.map BlogZpr cmd
                    )

                _ ->
                    ( modelka, Cmd.none )

        BlogLoaded response ->
            ( Api.handle response handleBlogLoaded modelka
            , Cmd.none
            )


handleBlogLoaded : Result Api.Error Blog.Flags -> Modelka -> Modelka
handleBlogLoaded result modelka =
    case result of
        Ok flags ->
            datPage
                (Page__Blog <| Blog.poca flags)
                modelka

        Err error ->
            mapZasedani
                (Zasedani.recordApiError error)
                modelka



--------------------------------------------------------------------------------
-- TRACK --
--------------------------------------------------------------------------------


track : Zpr -> Analytics.Event
track zpr =
    case zpr of
        PasswordFieldUpdated _ ->
            Analytics.none

        BlogZpr subZpr ->
            Blog.track subZpr

        BlogLoaded _ ->
            Analytics.none



--------------------------------------------------------------------------------
-- VIEW --
--------------------------------------------------------------------------------


pohled : Modelka -> List (Cell Zpr)
pohled modelka =
    [ nav modelka.page
    , body modelka
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
                    (Route.fromAdminRoute <| navItemToRoute navItem)
                |> Button.when (navItem == pageToNavItem page) Button.active
                |> Button.toCell
                |> Cell.withExactWidth width
                |> Row.fromCell
    in
    navItems
        |> List.map navItemView
        |> Row.toCell
        |> Cell.withExactWidth width


body : Modelka -> Cell Zpr
body modelka =
    let
        titleRows : List (Row Zpr)
        titleRows =
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

        navItemRows : List (Row Zpr)
        navItemRows =
            case modelka.page of
                Page__Blog subModelka ->
                    Blog.pohled subModelka
                        |> List.map (Row.map BlogZpr)

                Page__Loading _ ->
                    [ Row.fromString "Loading.." ]
    in
    [ titleRows
    , navItemRows
    ]
        |> List.concat
        |> Row.withSpaceBetween Size.medium
        |> Row.toCell



--------------------------------------------------------------------------------
-- PORTS --
--------------------------------------------------------------------------------


incomingPortsListener : FromJs.Listener Zpr
incomingPortsListener =
    FromJs.none
