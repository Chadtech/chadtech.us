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
    = Blog



---------------------------------------------------------------
-- IMPLEMENTATION --
---------------------------------------------------------------


blogPath : String
blogPath =
    "blog"



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


landing : Route
landing =
    Blog


parser : Parser (Route -> a) a
parser =
    [ P.map landing <| P.top
    , P.map Blog <| P.s blogPath
    ]
        |> P.oneOf


toPath : Route -> List String
toPath route =
    case route of
        Blog ->
            [ blogPath ]
