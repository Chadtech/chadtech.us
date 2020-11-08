module View.Dialog.Header exposing
    ( Header
    , map
    , toRow
    )

import View.Row as Row exposing (Row)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Header msg =
    { title : String
    , closeButton : Maybe msg
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


map : (a -> msg) -> Header a -> Header msg
map toMsg header =
    { title = header.title
    , closeButton = Maybe.map toMsg header.closeButton
    }


toRow : Header msg -> Row msg
toRow header =
    Row.fromCells []
