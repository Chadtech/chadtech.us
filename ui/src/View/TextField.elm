module View.TextField exposing
    ( TextField
    , simple
    , toCell
    )

import Html.Styled as H exposing (Html)
import Html.Styled.Events as Ev
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
    H.input
        [ Ev.onInput textField.onInput ]
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
