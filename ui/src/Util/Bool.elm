module Util.Bool exposing (all)


all : Bool -> List Bool -> Bool
all first rest =
    case rest of
        [] ->
            first

        second :: remaining ->
            if first then
                all second remaining

            else
                False
