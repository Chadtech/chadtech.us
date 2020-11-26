module View.Cell exposing
    ( Cell
    , fromHtml
    , fromString
    , indent
    , map
    , pad
    , toHtml
    , verticallyCenterContent
    , withBackgroundColor
    , withExactWidth
    , withFontColor
    , withSpaceBetween
    )

import Css
import Html.Styled as H exposing (Html)
import Html.Styled.Attributes as A
import Style.Border as Border
import Style.Color as Color exposing (Color)
import Style.Margin as Margin
import Style.Padding as Padding exposing (Padding)
import Style.Size as Size exposing (Size)
import Util.Css as CssUtil



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Cell msg =
    { html : List (Html msg)
    , fontColor : Maybe Color
    , padding : Maybe Padding
    , width : Width
    , indent : Bool
    , leftMargin : Maybe Size
    , backgroundColor : Maybe Color
    , verticallyCenterContent : Bool
    }


type Width
    = Grow
    | ExactWidth Size



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


verticallyCenterContent : Cell msg -> Cell msg
verticallyCenterContent cell =
    { cell | verticallyCenterContent = True }


fromString : String -> Cell msg
fromString str =
    fromHtml [ H.text str ]


fromHtml : List (Html msg) -> Cell msg
fromHtml html =
    { html = html
    , fontColor = Nothing
    , padding = Nothing
    , width = Grow
    , indent = False
    , leftMargin = Nothing
    , backgroundColor = Nothing
    , verticallyCenterContent = False
    }


map : (a -> msg) -> Cell a -> Cell msg
map toMsg cell =
    { html = List.map (H.map toMsg) cell.html
    , fontColor = cell.fontColor
    , padding = cell.padding
    , width = cell.width
    , indent = cell.indent
    , leftMargin = cell.leftMargin
    , backgroundColor = cell.backgroundColor
    , verticallyCenterContent = cell.verticallyCenterContent
    }


withBackgroundColor : Color -> Cell msg -> Cell msg
withBackgroundColor color cell =
    { cell | backgroundColor = Just color }


withSpaceBetween : Size -> List (Cell msg) -> List (Cell msg)
withSpaceBetween size cells =
    let
        withMargin : Cell msg -> Cell msg
        withMargin cell =
            { cell | leftMargin = Just size }
    in
    case cells of
        first :: rest ->
            first :: List.map withMargin rest

        [] ->
            []


withExactWidth : Size -> Cell msg -> Cell msg
withExactWidth size cell =
    { cell | width = ExactWidth size }


pad : Padding -> Cell msg -> Cell msg
pad padding cell =
    { cell | padding = Just padding }


withFontColor : Color -> Cell msg -> Cell msg
withFontColor color cell =
    { cell | fontColor = Just color }


indent : Cell msg -> Cell msg
indent cell =
    { cell | indent = True }


toHtml : Cell msg -> Html msg
toHtml cell =
    let
        conditionalStyling : List Css.Style
        conditionalStyling =
            [ Maybe.map
                (Css.color << Color.toCss)
                cell.fontColor
            , Maybe.map Padding.toCss cell.padding
            ]
                |> List.filterMap identity

        widthStyle : Css.Style
        widthStyle =
            case cell.width of
                Grow ->
                    Css.flex (Css.int 1)

                ExactWidth size ->
                    Css.width <| Size.toPx size

        styles : List Css.Style
        styles =
            [ widthStyle
            , Css.batch conditionalStyling
            , CssUtil.when cell.indent <|
                Border.toCss Border.indent
            , CssUtil.fromMaybe
                (Margin.left >> Margin.toCss)
                cell.leftMargin
            , CssUtil.fromMaybe
                (Color.toCss >> Css.backgroundColor)
                cell.backgroundColor
            , CssUtil.when cell.verticallyCenterContent <|
                Css.batch
                    [ Css.justifyContent Css.center
                    , Css.flexDirection Css.column
                    , Css.displayFlex
                    ]
            ]
    in
    H.node "cell"
        [ A.css styles ]
        cell.html
