module Style.Size exposing
    ( Size
    , extraLarge
    , extraSmall
    , large
    , medium
    , small
    , text
    , toPx
    , zero
    )

import Css



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type Size
    = Zero
    | ExtraSmall
    | Small
    | Medium
    | Large Int



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


toInt : Size -> Int
toInt size =
    case size of
        Zero ->
            0

        ExtraSmall ->
            2

        Small ->
            4

        Medium ->
            8

        Large i ->
            2 ^ (4 + i)



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


text : Size
text =
    extraLarge 1


extraLarge : Int -> Size
extraLarge =
    Large


large : Size
large =
    Large 0


small : Size
small =
    Small


extraSmall : Size
extraSmall =
    ExtraSmall


medium : Size
medium =
    Medium


zero : Size
zero =
    Zero


toPx : Size -> Css.Px
toPx size =
    Css.px <| toFloat <| toInt size
