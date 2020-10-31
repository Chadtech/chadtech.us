module Layout exposing
    ( Layout
    , init
    , view
    )

import Document exposing (Document)
import Route
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
    {}


type NavItem
    = Blog
    | Twitter
    | Github



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


allNavItems : List NavItem
allNavItems =
    [ Blog
    , Twitter
    , Github
    ]


navigation : Cell msg
navigation =
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

        navItemView : NavItem -> Row msg
        navItemView navItem =
            Button.fromLabel (toLabel navItem)
                |> withClickHandling navItem
                |> Button.toCell
                |> Row.fromCell
    in
    allNavItems
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



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


init : Layout
init =
    {}


view : Layout -> List (Row msg) -> Document msg
view layout body =
    [ headerRow
    , Row.fromCells
        [ navigation
        , Row.toCell body
        ]
    ]
        |> Row.withSpaceBetween gapSize
        |> Document.fromBody
