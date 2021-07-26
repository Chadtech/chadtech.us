module View.Row exposing
    ( Row
    , fillVerticalSpace
    , fromCell
    , fromCells
    , fromString
    , grow
    , horizontallyCenterContent
    , map
    , maybe
    , onClick
    , pad
    , toCell
    , toHtml
    , when
    , withBackgroundColor
    , withBackgroundColorOnHover
    , withCursor
    , withFontColor
    , withFontColorOnHover
    , withSpaceBetween
    , withTagName
    )

import Css
import Html.Styled as H exposing (Attribute, Html)
import Html.Styled.Attributes as A
import Html.Styled.Events as Ev
import Style.Color as Color exposing (Color)
import Style.Cursor as Cursor exposing (Cursor)
import Style.Margin as Margin
import Style.Padding as Padding exposing (Padding)
import Style.Size exposing (Size)
import Util.Css as CssUtil
import View.Cell as Cell exposing (Cell)



--------------------------------------------------------------------------------
-- TYPY --
--------------------------------------------------------------------------------


type Row zpr
    = Visible (Modelka zpr)
    | None


type alias Modelka zpr =
    { cells : List (Cell zpr)
    , backgroundColor : Maybe Color
    , semantics : Maybe String
    , topMargin : Maybe Size
    , fillVerticalSpace : Bool
    , padding : Maybe Padding
    , height : Height
    , horizontallyCenterContent : Bool
    , fontColor : Maybe Color
    , cursor : Maybe Cursor
    , clickZpr : Maybe zpr
    , backgroundColorOnHover : Maybe Color
    , fontColorOnHover : Maybe Color
    }


type Height
    = Grow
    | Shrink



--------------------------------------------------------------------------------
-- INTERNAL HELPERS --
--------------------------------------------------------------------------------


mapModelka : (Modelka a -> Modelka zpr) -> Row a -> Row zpr
mapModelka fn cell =
    case cell of
        Visible modelka ->
            Visible <| fn modelka

        None ->
            None



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


withBackgroundColorOnHover : Color -> Row zpr -> Row zpr
withBackgroundColorOnHover color =
    mapModelka (\row -> { row | backgroundColorOnHover = Just color })


withFontColorOnHover : Color -> Row zpr -> Row zpr
withFontColorOnHover color =
    mapModelka
        (\row ->
            { row
                | fontColorOnHover = Just color
                , cells = List.map (Cell.withFontColorOnHover color) row.cells
            }
        )


onClick : zpr -> Row zpr -> Row zpr
onClick zpr =
    mapModelka (\row -> { row | clickZpr = Just zpr })
        >> withCursor Cursor.pointer


withCursor : Cursor -> Row zpr -> Row zpr
withCursor cursor =
    mapModelka (\row -> { row | cursor = Just cursor })


when : Bool -> (Row zpr -> Row zpr) -> Row zpr -> Row zpr
when cond fn row =
    if cond then
        fn row

    else
        row


maybe : Maybe v -> (v -> Row zpr -> Row zpr) -> Row zpr -> Row zpr
maybe mb fn row =
    case mb of
        Just v ->
            fn v row

        Nothing ->
            row


horizontallyCenterContent : Row zpr -> Row zpr
horizontallyCenterContent =
    mapModelka (\row -> { row | horizontallyCenterContent = True })


grow : Row zpr -> Row zpr
grow =
    mapModelka (\row -> { row | height = Grow })


pad : Padding -> Row zpr -> Row zpr
pad padding =
    mapModelka (\row -> { row | padding = Just padding })


fromCells : List (Cell zpr) -> Row zpr
fromCells cells =
    Visible
        { cells = cells
        , backgroundColor = Nothing
        , semantics = Nothing
        , topMargin = Nothing
        , fillVerticalSpace = False
        , padding = Nothing
        , height = Shrink
        , horizontallyCenterContent = False
        , fontColor = Nothing
        , cursor = Nothing
        , clickZpr = Nothing
        , backgroundColorOnHover = Nothing
        , fontColorOnHover = Nothing
        }


fromCell : Cell zpr -> Row zpr
fromCell cell =
    fromCells [ cell ]


toCell : List (Row zpr) -> Cell zpr
toCell rows =
    rows
        |> List.map toHtml
        |> Cell.fromHtml


fromString : String -> Row zpr
fromString str =
    fromCell <| Cell.fromString str


map : (a -> zpr) -> Row a -> Row zpr
map toMsg =
    mapModelka
        (\row ->
            { cells = List.map (Cell.map toMsg) row.cells
            , backgroundColor = row.backgroundColor
            , semantics = row.semantics
            , topMargin = row.topMargin
            , fillVerticalSpace = row.fillVerticalSpace
            , padding = row.padding
            , height = row.height
            , horizontallyCenterContent = row.horizontallyCenterContent
            , fontColor = row.fontColor
            , cursor = row.cursor
            , clickZpr = Maybe.map toMsg row.clickZpr
            , backgroundColorOnHover = row.backgroundColorOnHover
            , fontColorOnHover = row.fontColorOnHover
            }
        )


withFontColor : Color -> Row zpr -> Row zpr
withFontColor color =
    mapModelka
        (\row ->
            { row
                | fontColor = Just color
                , cells = List.map (Cell.withFontColor color) row.cells
            }
        )


fillVerticalSpace : Row zpr -> Row zpr
fillVerticalSpace =
    mapModelka (\row -> { row | fillVerticalSpace = True })


withSpaceBetween : Size -> List (Row zpr) -> List (Row zpr)
withSpaceBetween size rows =
    let
        withMargin : Row zpr -> Row zpr
        withMargin =
            mapModelka (\row -> { row | topMargin = Just size })
    in
    case rows of
        first :: rest ->
            first :: List.map withMargin rest

        [] ->
            []


withBackgroundColor : Color -> Row zpr -> Row zpr
withBackgroundColor color =
    mapModelka (\row -> { row | backgroundColor = Just color })


withTagName : String -> Row zpr -> Row zpr
withTagName name =
    mapModelka (\row -> { row | semantics = Just name })


toHtml : Row zpr -> Html zpr
toHtml row =
    case row of
        None ->
            H.text ""

        Visible modelka ->
            let
                conditionalStyling : List Css.Style
                conditionalStyling =
                    [ Maybe.map
                        (Css.color << Color.toCss)
                        modelka.fontColor
                    , Maybe.map
                        (Css.backgroundColor << Color.toCss)
                        modelka.backgroundColor
                    , Maybe.map (Margin.toCss << Margin.top) modelka.topMargin
                    , Maybe.map Padding.toCss modelka.padding
                    , Maybe.map Cursor.toCss modelka.cursor
                    ]
                        |> List.filterMap identity

                heightStyle : Css.Style
                heightStyle =
                    case modelka.height of
                        Grow ->
                            Css.flex <| Css.int 1

                        Shrink ->
                            Css.batch []

                horizontallyCenterContentStyle : Css.Style
                horizontallyCenterContentStyle =
                    if modelka.horizontallyCenterContent then
                        Css.justifyContent Css.center

                    else
                        Css.batch []

                backgroundColorOnHover : Css.Style
                backgroundColorOnHover =
                    case modelka.backgroundColorOnHover of
                        Just color ->
                            Css.hover
                                [ Css.backgroundColor <| Color.toCss color ]

                        Nothing ->
                            Css.batch []

                fontColorOnHover : Css.Style
                fontColorOnHover =
                    case modelka.fontColorOnHover of
                        Just color ->
                            Css.hover
                                [ Css.color <| Color.toCss color ]

                        Nothing ->
                            Css.batch []

                styles : List Css.Style
                styles =
                    [ Css.displayFlex
                    , Css.batch conditionalStyling
                    , CssUtil.when
                        modelka.fillVerticalSpace
                        (Css.flex <| Css.int 1)
                    , heightStyle
                    , horizontallyCenterContentStyle
                    , backgroundColorOnHover
                    , fontColorOnHover
                    ]

                conditionalAttrs : List (Attribute zpr)
                conditionalAttrs =
                    [ Maybe.map Ev.onClick modelka.clickZpr ]
                        |> List.filterMap identity

                baseAttrs : List (Attribute msg)
                baseAttrs =
                    [ A.css styles ]
            in
            H.node (Maybe.withDefault "row" modelka.semantics)
                (baseAttrs ++ conditionalAttrs)
                (List.map Cell.toHtml modelka.cells)
