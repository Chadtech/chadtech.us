module View.Menu exposing (Item, itemsToCell)

import View.Cell exposing (Cell)
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
-- API --
--------------------------------------------------------------------------------


itemsToCell : List (Item zpr) -> Cell zpr
itemsToCell items =
    []
        |> Row.toCell
