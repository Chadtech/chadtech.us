module Route exposing
    ( Route(..)
    , blog
    , fromUrl
    , href
    , toString
    )

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes as A
import Url exposing (Url)
import Url.Builder as UrlBuilder
import Url.Parser as P exposing ((</>), Parser)



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type Route
    = Landing
    | Blog



---------------------------------------------------------------
-- IMPLEMENTATION --
---------------------------------------------------------------


parser : Parser (Route -> a) a
parser =
    [ P.map Landing P.top
    , P.map Blog <| P.s blogPath
    , P.map Blog <| P.s "#" </> P.s blogPath
    ]
        |> P.oneOf


blogPath : String
blogPath =
    "blog"



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


toString : Route -> String
toString route =
    let
        path : List String
        path =
            case route of
                Landing ->
                    []

                Blog ->
                    [ blogPath ]
    in
    UrlBuilder.relative path []


blog : Route
blog =
    Blog


fromUrl : Url -> Maybe Route
fromUrl =
    P.parse parser


href : Route -> Attribute msg
href route =
    A.href <| toString route
