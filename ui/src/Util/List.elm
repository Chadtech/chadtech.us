module Util.List exposing (maybeCons)


maybeCons : Maybe elem -> List elem -> List elem
maybeCons maybeElem list =
    case maybeElem of
        Just elem ->
            elem :: list

        Nothing ->
            list
