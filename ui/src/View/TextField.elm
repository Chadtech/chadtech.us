module View.TextField exposing
    ( TextField
    , simple
    , toCell
    )

import Css
import Html.Styled as H exposing (Html)
import Html.Styled.Attributes as A
import Html.Styled.Events as Ev
import Style.Border as Border
import Style.Color as Color
import Style.Size as Size
import View.Cell as Cell exposing (Cell)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias TextField msg =
    { onInput : String -> msg
    , value : String
    }



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


toHtml : TextField msg -> Html msg
toHtml textField =
    let
        styles : List Css.Style
        styles =
            [ Border.toCss Border.indent
            , Css.backgroundColor <| Color.toCss Color.background1
            , Css.height <| Size.toPx <| Size.extraLarge 1
            , Css.outline Css.none
            , Css.width <| Css.pct 100
            ]
    in
    H.input
        [ Ev.onInput textField.onInput
        , A.css styles
        ]
        []



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


simple : String -> (String -> msg) -> TextField msg
simple value onInput =
    { value = value
    , onInput = onInput
    }


toCell : TextField msg -> Cell msg
toCell textField =
    Cell.fromHtml [ toHtml textField ]
