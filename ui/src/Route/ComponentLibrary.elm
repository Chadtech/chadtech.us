module Route.ComponentLibrary exposing
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
    = Button



---------------------------------------------------------------
-- IMPLEMENTATION --
---------------------------------------------------------------


buttonPath : String
buttonPath =
    "button"



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


landing : Route
landing =
    Button


parser : Parser (Route -> a) a
parser =
    [ P.map landing <| P.top
    , P.map Button <| P.s buttonPath
    ]
        |> P.oneOf


toPath : Route -> List String
toPath route =
    case route of
        Button ->
            [ buttonPath ]


toName : Route -> String
toName route =
    case route of
        Button ->
            "Button"
