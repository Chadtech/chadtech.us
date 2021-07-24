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
    | Menu
    | Textarea
    | Textfield



---------------------------------------------------------------
-- IMPLEMENTATION --
---------------------------------------------------------------


buttonPath : String
buttonPath =
    "button"


menuPath : String
menuPath =
    "menu"


textareaPath : String
textareaPath =
    "textarea"


textefieldPath : String
textefieldPath =
    "texteField"



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
    , P.map Menu <| P.s menuPath
    , P.map Textarea <| P.s textareaPath
    , P.map Textfield <| P.s textefieldPath
    ]
        |> P.oneOf


toPath : Route -> List String
toPath route =
    case route of
        Button ->
            [ buttonPath ]

        Menu ->
            [ menuPath ]

        Textarea ->
            [ textareaPath ]

        Textfield ->
            [ textefieldPath ]


toName : Route -> String
toName route =
    case route of
        Button ->
            "Button"

        Menu ->
            "Menu"

        Textarea ->
            "Textarea"

        Textfield ->
            "Textfield"
