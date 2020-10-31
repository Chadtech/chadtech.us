module Style.Padding exposing
    ( Padding
    , all
    , toCss
    )

import Css
import Style.Size as Size exposing (Size)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Padding =
    { left : Maybe Size
    , top : Maybe Size
    , right : Maybe Size
    , bottom : Maybe Size
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


toCss : Padding -> Css.Style
toCss padding =
    [ Maybe.map (Css.paddingLeft << Size.toPx) padding.left
    , Maybe.map (Css.paddingTop << Size.toPx) padding.top
    , Maybe.map (Css.paddingRight << Size.toPx) padding.right
    , Maybe.map (Css.paddingBottom << Size.toPx) padding.bottom
    ]
        |> List.filterMap identity
        |> Css.batch


all : Size -> Padding
all size =
    let
        justSize : Maybe Size
        justSize =
            Just size
    in
    { left = justSize
    , top = justSize
    , right = justSize
    , bottom = justSize
    }
