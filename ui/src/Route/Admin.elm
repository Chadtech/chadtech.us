module Route.Admin exposing
    ( Route(..)
    , landing
    , parser
    , toName
    , toPath
    )

import Url.Parser as P exposing (Parser)



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type Route
    = Blog
    | Analytics



---------------------------------------------------------------
-- IMPLEMENTATION --
---------------------------------------------------------------


blogPath : String
blogPath =
    "blog"


analyticsPath : String
analyticsPath =
    "analytics"



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
    , P.map Analytics <| P.s analyticsPath
    ]
        |> P.oneOf


toPath : Route -> List String
toPath route =
    case route of
        Blog ->
            [ blogPath ]

        Analytics ->
            [ analyticsPath ]


toName : Route -> String
toName route =
    case route of
        Blog ->
            "Blog"

        Analytics ->
            "Analytics"
