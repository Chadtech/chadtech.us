module View.DevPanel exposing
    ( Modelka
    , poca
    , pohled
    )

import View.Dialog as Dialog exposing (Dialog)
import View.Dialog.Header as DialogHeader
import View.Row as Row



---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type alias Modelka =
    {}



---------------------------------------------------------------
-- POCA --
---------------------------------------------------------------


poca : Modelka
poca =
    {}



---------------------------------------------------------------
-- POHLED --
---------------------------------------------------------------


pohled : { errors : List String } -> Modelka -> Dialog zpr
pohled args modelka =
    List.map Row.fromString args.errors
        |> Dialog.fromBody
        |> Dialog.withHeader
            (DialogHeader.fromTitle "Dev Panel")
