module View.Textarea exposing
    ( Textarea
    , readOnly
    , simple
    , toCell
    )

import Css
import Html.Styled as H exposing (Attribute, Html)
import Html.Styled.Attributes as A
import Html.Styled.Events as Ev
import Style.Border as Border
import Style.Color as Color
import Style.Size as Size
import View.Cell as Cell exposing (Cell)



--------------------------------------------------------------------------------
-- TYPY --
--------------------------------------------------------------------------------


type alias Textarea zpr =
    { onInput : Maybe (String -> zpr)
    , value : String
    }



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


toHtml : Textarea zpr -> Html zpr
toHtml textarea =
    let
        styles : List Css.Style
        styles =
            [ Border.toCss Border.indent
            , Css.backgroundColor <| Color.toCss Color.background1
            , Css.height <| Size.toPx <| Size.extraLarge 4
            , Css.outline Css.none
            , Css.width <| Css.pct 100
            , Css.whiteSpace Css.pre
            , Css.color <| Color.toCss Color.content4
            ]

        conditionalAttrs : List (Attribute zpr)
        conditionalAttrs =
            [ Maybe.map Ev.onInput textarea.onInput ]
                |> List.filterMap identity

        baseAttrs : List (Attribute zpr)
        baseAttrs =
            [ A.value textarea.value
            , A.css styles
            , A.spellcheck False
            ]
    in
    H.textarea
        (baseAttrs ++ conditionalAttrs)
        []



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


simple : String -> (String -> zpr) -> Textarea zpr
simple value onInput =
    { value = value
    , onInput = Just onInput
    }


readOnly : String -> Textarea zpr
readOnly value =
    { value = value
    , onInput = Nothing
    }


toCell : Textarea zpr -> Cell zpr
toCell textField =
    Cell.fromHtml [ toHtml textField ]
