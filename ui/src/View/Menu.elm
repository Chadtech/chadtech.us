module View.Menu exposing (Item, itemFromLabel, itemIsActive, itemsToCell)

import Style.Color as Color
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


itemToRow : Int -> Item zpr -> Row zpr
itemToRow index item =
    Row.fromString item.label
        |> Row.when (modBy 2 index == 0) (Row.withBackgroundColor Color.background2)
        |> Row.when item.active (Row.withBackgroundColor Color.background4)
        |> Row.pad (Padding.all Size.small)



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


itemsToCell : List (Item zpr) -> Cell zpr
itemsToCell items =
    List.indexedMap itemToRow items
        |> Row.toCell
        |> Cell.indent
        |> Cell.withBackgroundColor Color.background0
