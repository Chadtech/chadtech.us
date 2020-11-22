module View.Row exposing
    ( Row
    , fillVerticalSpace
    , fromCell
    , fromCells
    , fromString
    , map
    , toCell
    , toHtml
    , withBackgroundColor
    , withSpaceBetween
    , withTagName
    )

import Css
import Html.Styled as H exposing (Attribute, Html)
import Html.Styled.Attributes as A
import Style.Color as Color exposing (Color)
import Style.Margin as Margin
import Style.Size exposing (Size)
import Util.Css as CssUtil
import View.Cell as Cell exposing (Cell)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Row msg =
    { cells : List (Cell msg)
    , backgroundColor : Maybe Color
    , semantics : Maybe String
    , topMargin : Maybe Size
    , fillVerticalSpace : Bool
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


fromCells : List (Cell msg) -> Row msg
fromCells cells =
    { cells = cells
    , backgroundColor = Nothing
    , semantics = Nothing
    , topMargin = Nothing
    , fillVerticalSpace = False
    }


fromCell : Cell msg -> Row msg
fromCell cell =
    fromCells [ cell ]


toCell : List (Row msg) -> Cell msg
toCell rows =
    rows
        |> List.map toHtml
        |> Cell.fromHtml


fromString : String -> Row msg
fromString str =
    fromCell <| Cell.fromString str


map : (a -> msg) -> Row a -> Row msg
map toMsg row =
    { cells = List.map (Cell.map toMsg) row.cells
    , backgroundColor = row.backgroundColor
    , semantics = row.semantics
    , topMargin = row.topMargin
    , fillVerticalSpace = row.fillVerticalSpace
    }


fillVerticalSpace : Row msg -> Row msg
fillVerticalSpace row =
    { row | fillVerticalSpace = True }


withSpaceBetween : Size -> List (Row msg) -> List (Row msg)
withSpaceBetween size rows =
    let
        withMargin : Row msg -> Row msg
        withMargin row =
            { row | topMargin = Just size }
    in
    case rows of
        first :: rest ->
            first :: List.map withMargin rest

        [] ->
            []


withBackgroundColor : Color -> Row msg -> Row msg
withBackgroundColor color row =
    { row | backgroundColor = Just color }


withTagName : String -> Row msg -> Row msg
withTagName name row =
    { row | semantics = Just name }


toHtml : Row msg -> Html msg
toHtml row =
    let
        conditionalStyling : List Css.Style
        conditionalStyling =
            [ Maybe.map
                (Css.backgroundColor << Color.toCss)
                row.backgroundColor
            , Maybe.map (Margin.toCss << Margin.top) row.topMargin
            ]
                |> List.filterMap identity

        styles : List Css.Style
        styles =
            [ Css.displayFlex
            , Css.batch conditionalStyling
            , CssUtil.when row.fillVerticalSpace (Css.flex <| Css.int 1)
            ]
    in
    H.node (Maybe.withDefault "row" row.semantics)
        [ A.css styles
        ]
        (List.map Cell.toHtml row.cells)
