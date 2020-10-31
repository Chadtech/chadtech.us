module View.Cell exposing
    ( Cell
    , fromHtml
    , fromString
    , map
    , pad
    , toHtml
    , withExactWidth
    , withFontColor
    )

import Css
import Html.Styled as H exposing (Html)
import Html.Styled.Attributes as A
import Style.Color as Color exposing (Color)
import Style.Padding as Padding exposing (Padding)
import Style.Size as Size exposing (Size)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Cell msg =
    { html : List (Html msg)
    , fontColor : Maybe Color
    , padding : Maybe Padding
    , width : Width
    }


type Width
    = Grow
    | ExactWidth Size



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


fromString : String -> Cell msg
fromString str =
    fromHtml [ H.text str ]


fromHtml : List (Html msg) -> Cell msg
fromHtml html =
    { html = html
    , fontColor = Nothing
    , padding = Nothing
    , width = Grow
    }


map : (a -> msg) -> Cell a -> Cell msg
map toMsg cell =
    { html = List.map (H.map toMsg) cell.html
    , fontColor = cell.fontColor
    , padding = cell.padding
    , width = cell.width
    }


withExactWidth : Size -> Cell msg -> Cell msg
withExactWidth size cell =
    { cell | width = ExactWidth size }


pad : Padding -> Cell msg -> Cell msg
pad padding cell =
    { cell | padding = Just padding }


withFontColor : Color -> Cell msg -> Cell msg
withFontColor color cell =
    { cell | fontColor = Just color }


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
            ]
    in
    H.node "cell"
        [ A.css styles
        ]
        cell.html
