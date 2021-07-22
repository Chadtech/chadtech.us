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
    | List



---------------------------------------------------------------
-- IMPLEMENTATION --
---------------------------------------------------------------


buttonPath : String
buttonPath =
    "button"


listPath : String
listPath =
    "list"



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
    , P.map List <| P.s listPath
    ]
        |> P.oneOf


toPath : Route -> List String
toPath route =
    case route of
        Button ->
            [ buttonPath ]

        List ->
            [ listPath ]


toName : Route -> String
toName route =
    case route of
        Button ->
            "Button"

        List ->
            "List"
