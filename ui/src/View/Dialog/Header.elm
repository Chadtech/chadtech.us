module View.Dialog.Header exposing
    ( Header
    , fromTitle
    , map
    , toRow
    )

import Style.Color as Color
import Style.Padding as Padding
import Style.Size as Size
import View.Button as Button
import View.Cell as Cell exposing (Cell)
import View.Row as Row exposing (Row)



--------------------------------------------------------------------------------
-- TYPY --
--------------------------------------------------------------------------------


type alias Header zpr =
    { title : String
    , closeButton : Maybe zpr
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


map : (a -> zpr) -> Header a -> Header zpr
map toZpr header =
    { title = header.title
    , closeButton = Maybe.map toZpr header.closeButton
    }


fromTitle : String -> Header zpr
fromTitle title =
    { title = title
    , closeButton = Nothing
    }


toRow : Header zpr -> Row zpr
toRow header =
    let
        closeButton : Cell zpr
        closeButton =
            case header.closeButton of
                Just zpr ->
                    Button.simple "X" zpr
                        |> Button.toCell

                Nothing ->
                    Cell.none
    in
    [ Cell.fromString header.title
        |> Cell.withFontColor Color.content1
    , closeButton
    ]
        |> Row.fromCells
        |> Row.withBackgroundColor Color.content4
        |> Row.pad (Padding.all Size.medium)
