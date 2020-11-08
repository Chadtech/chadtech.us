module Util.Maybe exposing
    ( lazyWithDefault
    , orLazy
    )


lazyWithDefault : (() -> a) -> Maybe a -> a
lazyWithDefault default maybe =
    case maybe of
        Just a ->
            a

        Nothing ->
            default ()


orLazy : (() -> Maybe v) -> Maybe v -> Maybe v
orLazy default maybe =
    case maybe of
        Just a ->
            Just a

        Nothing ->
            default ()
