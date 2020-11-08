module Util.Css exposing
    ( fromMaybe
    , when
    )

import Css


when : Bool -> Css.Style -> Css.Style
when cond styles =
    if cond then
        styles

    else
        Css.batch []


fromMaybe : (a -> Css.Style) -> Maybe a -> Css.Style
fromMaybe f value =
    Maybe.map f value
        |> Maybe.withDefault (Css.batch [])
