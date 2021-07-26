module View.TextField exposing
    ( Textfield
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


type alias Textfield zpr =
    { onInput : String -> zpr
    , value : String
    }



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


toHtml : Textfield zpr -> Html zpr
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
        , A.value textField.value
        , A.css styles
        , A.spellcheck False
        ]
        []



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


simple : String -> (String -> zpr) -> Textfield zpr
simple value onInput =
    { value = value
    , onInput = onInput
    }


toCell : Textfield zpr -> Cell zpr
toCell textField =
    Cell.fromHtml [ toHtml textField ]
