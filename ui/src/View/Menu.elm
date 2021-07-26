module View.Menu exposing (Item, itemFromLabel, itemIsActive, itemOnClick, itemsToCell)

import Style.Color as Color exposing (Color)
import Style.Padding as Padding
import Style.Size as Size
import View.Cell as Cell exposing (Cell)
import View.Row as Row exposing (Row)



--------------------------------------------------------------------------------
-- TYPY --
--------------------------------------------------------------------------------


type alias Item zpr =
    { label : String
    , active : Bool
    , onClick : Maybe zpr
    }



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


itemToRow : Item zpr -> Row zpr
itemToRow item =
    let
        backgroundColor : Color
        backgroundColor =
            if item.active then
                Color.background2

            else
                Color.background0

        fontColor : Color
        fontColor =
            if item.active then
                Color.content5

            else
                Color.content4
    in
    Row.fromString item.label
        |> Row.withFontColor fontColor
        |> Row.withBackgroundColor backgroundColor
        |> Row.withBackgroundColorOnHover Color.background4
        |> Row.when (item.onClick /= Nothing) (Row.withFontColorOnHover Color.content5)
        |> Row.pad (Padding.all Size.small)
        |> Row.maybe item.onClick Row.onClick



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


itemFromLabel : String -> Item zpr
itemFromLabel label =
    { label = label
    , active = False
    , onClick = Nothing
    }


itemIsActive : Bool -> Item zpr -> Item zpr
itemIsActive active item =
    { item | active = active }


itemOnClick : zpr -> Item zpr -> Item zpr
itemOnClick zpr item =
    { item | onClick = Just zpr }


itemsToCell : List (Item zpr) -> Cell zpr
itemsToCell items =
    items
        |> List.map itemToRow
        |> Row.toCell
        |> Cell.indent
        |> Cell.withBackgroundColor Color.background0
