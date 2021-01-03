module Route.Admin exposing
    ( Route(..)
    , landing
    , parser
    , toPath
    )

import Url.Parser as P exposing (Parser)



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type Route
    = NewYearsCards



---------------------------------------------------------------
-- IMPLEMENTATION --
---------------------------------------------------------------


newYeardsCardPath : String
newYeardsCardPath =
    "new-years-cards"



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


landing : Route
landing =
    NewYearsCards


parser : Parser (Route -> a) a
parser =
    [ P.map landing <| P.top
    , P.map NewYearsCards <| P.s newYeardsCardPath
    ]
        |> P.oneOf


toPath : Route -> List String
toPath route =
    case route of
        NewYearsCards ->
            [ newYeardsCardPath ]
