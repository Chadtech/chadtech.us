module Style.Cursor exposing
    ( Cursor
    , pointer
    , toCss
    )

--------------------------------------------------------------------------------
-- TYPY --
--------------------------------------------------------------------------------

import Css


type Cursor
    = Pointer



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


pointer : Cursor
pointer =
    Pointer


toCss : Cursor -> Css.Style
toCss cursor =
    case cursor of
        Pointer ->
            Css.batch
                [ Css.cursor Css.pointer
                , Css.property "user-select" "none"
                ]
