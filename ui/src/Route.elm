module Route exposing
    ( Route(..)
    , admin
    , blog
    , fromAdminRoute
    , fromUrl
    , href
    , toString
    )

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes as A
import Route.Admin as Admin
import Url exposing (Url)
import Url.Builder as UrlBuilder
import Url.Parser as P exposing ((</>), Parser)



---------------------------------------------------------------
-- TYPES --
---------------------------------------------------------------


type Route
    = Landing
    | Blog
    | Admin Admin.Route



---------------------------------------------------------------
-- IMPLEMENTATION --
---------------------------------------------------------------


parser : Parser (Route -> a) a
parser =
    [ P.map Landing P.top
    , P.map Blog <| P.s blogPath
    , P.map Blog <| P.s "#" </> P.s blogPath
    , P.map Admin <| P.s adminPath </> Admin.parser
    ]
        |> P.oneOf


blogPath : String
blogPath =
    "blog"


adminPath : String
adminPath =
    "admin"



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

                Admin subRoute ->
                    adminPath :: Admin.toPath subRoute
    in
    UrlBuilder.relative path []


blog : Route
blog =
    Blog


admin : Route
admin =
    fromAdminRoute Admin.landing


fromAdminRoute : Admin.Route -> Route
fromAdminRoute =
    Admin


fromUrl : Url -> Maybe Route
fromUrl =
    P.parse parser


href : Route -> Attribute msg
href route =
    A.href <| toString route
