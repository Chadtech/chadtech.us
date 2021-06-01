module View.Cell exposing
    ( Cell
    , fromHtml
    , fromString
    , indent
    , map
    , none
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


type Cell zpr
    = Visible (Modelka zpr)
    | None


type alias Modelka zpr =
    { html : List (Html zpr)
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
-- INTERNAL HELPERS --
--------------------------------------------------------------------------------


mapModelka : (Modelka a -> Modelka zpr) -> Cell a -> Cell zpr
mapModelka fn cell =
    case cell of
        Visible modelka ->
            Visible <| fn modelka

        None ->
            None



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


none : Cell zpr
none =
    None


verticallyCenterContent : Cell zpr -> Cell zpr
verticallyCenterContent =
    mapModelka (\cell -> { cell | verticallyCenterContent = True })


fromString : String -> Cell zpr
fromString str =
    fromHtml [ H.text str ]


fromHtml : List (Html zpr) -> Cell zpr
fromHtml html =
    Visible
        { html = html
        , fontColor = Nothing
        , padding = Nothing
        , width = Grow
        , indent = False
        , leftMargin = Nothing
        , backgroundColor = Nothing
        , verticallyCenterContent = False
        }


map : (a -> zpr) -> Cell a -> Cell zpr
map toMsg cell =
    case cell of
        Visible modelka ->
            Visible
                { html = List.map (H.map toMsg) modelka.html
                , fontColor = modelka.fontColor
                , padding = modelka.padding
                , width = modelka.width
                , indent = modelka.indent
                , leftMargin = modelka.leftMargin
                , backgroundColor = modelka.backgroundColor
                , verticallyCenterContent = modelka.verticallyCenterContent
                }

        None ->
            None


withBackgroundColor : Color -> Cell zpr -> Cell zpr
withBackgroundColor color =
    mapModelka (\cell -> { cell | backgroundColor = Just color })


withSpaceBetween : Size -> List (Cell zpr) -> List (Cell zpr)
withSpaceBetween size cells =
    let
        withMargin : Cell zpr -> Cell zpr
        withMargin =
            mapModelka (\cell -> { cell | leftMargin = Just size })
    in
    case cells of
        first :: rest ->
            first :: List.map withMargin rest

        [] ->
            []


withExactWidth : Size -> Cell zpr -> Cell zpr
withExactWidth size =
    mapModelka (\cell -> { cell | width = ExactWidth size })


pad : Padding -> Cell zpr -> Cell zpr
pad padding =
    mapModelka (\cell -> { cell | padding = Just padding })


withFontColor : Color -> Cell zpr -> Cell zpr
withFontColor color =
    mapModelka (\cell -> { cell | fontColor = Just color })


indent : Cell zpr -> Cell zpr
indent =
    mapModelka (\cell -> { cell | indent = True })


toHtml : Cell zpr -> Html zpr
toHtml cell =
    case cell of
        Visible modelka ->
            let
                conditionalStyling : List Css.Style
                conditionalStyling =
                    [ Maybe.map
                        (Css.color << Color.toCss)
                        modelka.fontColor
                    , Maybe.map Padding.toCss modelka.padding
                    ]
                        |> List.filterMap identity

                widthStyle : Css.Style
                widthStyle =
                    case modelka.width of
                        Grow ->
                            Css.flex (Css.int 1)

                        ExactWidth size ->
                            Css.width <| Size.toPx size

                styles : List Css.Style
                styles =
                    [ widthStyle
                    , Css.batch conditionalStyling
                    , CssUtil.when modelka.indent <|
                        Border.toCss Border.indent
                    , CssUtil.fromMaybe
                        (Margin.left >> Margin.toCss)
                        modelka.leftMargin
                    , CssUtil.fromMaybe
                        (Color.toCss >> Css.backgroundColor)
                        modelka.backgroundColor
                    , CssUtil.when modelka.verticallyCenterContent <|
                        Css.batch
                            [ Css.justifyContent Css.center
                            , Css.flexDirection Css.column
                            , Css.displayFlex
                            ]
                    ]
            in
            H.node "cell"
                [ A.css styles ]
                modelka.html

        None ->
            H.text ""
