module Style.Margin exposing
    ( Margin
    , all
    , right
    , toCss
    , top
    )

import Css
import Style.Size as Size exposing (Size)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Margin =
    { left : Maybe Size
    , top : Maybe Size
    , right : Maybe Size
    , bottom : Maybe Size
    }



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


none : Margin
none =
    { top = Nothing
    , left = Nothing
    , right = Nothing
    , bottom = Nothing
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


toCss : Margin -> Css.Style
toCss margin =
    [ Maybe.map (Css.marginLeft << Size.toPx) margin.left
    , Maybe.map (Css.marginTop << Size.toPx) margin.top
    , Maybe.map (Css.marginRight << Size.toPx) margin.right
    , Maybe.map (Css.marginBottom << Size.toPx) margin.bottom
    ]
        |> List.filterMap identity
        |> Css.batch


right : Size -> Margin
right size =
    { none | right = Just size }


top : Size -> Margin
top size =
    { none | top = Just size }


all : Size -> Margin
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
