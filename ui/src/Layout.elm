module Layout exposing
    ( Layout
    , handleRouteChange
    , init
    , view
    )

import Document exposing (Document)
import Route exposing (Route)
import Session exposing (Session)
import Style.Color as Color
import Style.Padding as Padding
import Style.Size as Size exposing (Size)
import View.Button as Button exposing (Button)
import View.Cell as Cell exposing (Cell)
import View.Row as Row exposing (Row)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Layout =
    { activeNav : Maybe NavItem
    }


type NavItem
    = Blog
    | Twitter
    | Github
    | Admin



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


allNavItems : List NavItem
allNavItems =
    [ Blog
    , Twitter
    , Github
    , Admin
    ]


navigation : Session -> Maybe NavItem -> Cell msg
navigation session activeNavItem =
    let
        toLabel : NavItem -> String
        toLabel navItem =
            case navItem of
                Blog ->
                    "Blog"

                Twitter ->
                    "Twitter"

                Github ->
                    "Github"

                Admin ->
                    "Admin"

        withClickHandling : NavItem -> Button msg -> Button msg
        withClickHandling navItem =
            case navItem of
                Blog ->
                    Button.withLink Route.blog

                Twitter ->
                    Button.withLinkToNewWindow
                        "https://www.twitter.com/TheRealChadtech"

                Github ->
                    Button.withLinkToNewWindow
                        "https://www.github.com/chadtech"

                Admin ->
                    Button.withLink Route.admin

        navItemView : NavItem -> Row msg
        navItemView navItem =
            Button.fromLabel (toLabel navItem)
                |> withClickHandling navItem
                |> Button.when
                    (Just navItem == activeNavItem)
                    Button.active
                |> Button.toCell
                |> Row.fromCell

        showNavItem : NavItem -> Bool
        showNavItem navItem =
            case navItem of
                Blog ->
                    True

                Twitter ->
                    True

                Github ->
                    True

                Admin ->
                    Session.adminIsOn session
    in
    allNavItems
        |> List.filter showNavItem
        |> List.map navItemView
        |> Row.withSpaceBetween gapSize
        |> Row.toCell
        |> Cell.withExactWidth (Size.extraLarge 3)


headerRow : Row msg
headerRow =
    "Chadtech Online"
        |> Cell.fromString
        |> Cell.withFontColor Color.content1
        |> Cell.pad (Padding.all Size.medium)
        |> Row.fromCell
        |> Row.withBackgroundColor Color.content4
        |> Row.withTagName "header"


gapSize : Size
gapSize =
    Size.small


routeToNavItem : Route -> NavItem
routeToNavItem route =
    case route of
        Route.Landing ->
            Blog

        Route.Blog ->
            Blog

        Route.Admin ->
            Admin


setActiveRoute : Maybe NavItem -> Layout -> Layout
setActiveRoute maybeNavItem layout =
    { layout | activeNav = maybeNavItem }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


handleRouteChange : Maybe Route -> Layout -> Layout
handleRouteChange maybeRoute =
    setActiveRoute
        (Maybe.map routeToNavItem maybeRoute)


init : Maybe Route -> Layout
init route =
    { activeNav = Maybe.map routeToNavItem route }


view : Session -> Layout -> List (Cell msg) -> Document msg
view session layout body =
    [ headerRow
    , (navigation session layout.activeNav :: body)
        |> Cell.withSpaceBetween gapSize
        |> Row.fromCells
        |> Row.fillVerticalSpace
    ]
        |> Row.withSpaceBetween gapSize
        |> Document.fromBody
