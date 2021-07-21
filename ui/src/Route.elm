module Route exposing
    ( Route(..)
    , admin
    , blog
    , componentLibrary
    , fromAdminRoute
    , fromComponentLibraryRoute
    , fromUrl
    , href
    , toName
    , toString
    )

import Html.Styled exposing (Attribute)
import Html.Styled.Attributes as A
import Route.Admin as Admin
import Route.ComponentLibrary as ComponentLibrary
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
    | ComponentLibrary ComponentLibrary.Route



---------------------------------------------------------------
-- IMPLEMENTATION --
---------------------------------------------------------------


parser : Parser (Route -> a) a
parser =
    [ P.map Landing P.top
    , hashAndNonHash Blog blogPath
    , P.map Admin <| P.s adminPath </> Admin.parser
    ]
        |> P.oneOf


hashAndNonHash : Route -> String -> Parser (Route -> a) a
hashAndNonHash route path =
    [ P.map route <| P.s path
    , P.map route <| P.s "#" </> P.s path
    ]
        |> P.oneOf


blogPath : String
blogPath =
    "blog"


adminPath : String
adminPath =
    "admin"


componentLibraryPath : String
componentLibraryPath =
    "componentlibrary"



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


toName : Route -> String
toName route =
    case route of
        Landing ->
            "Landing"

        Blog ->
            "Blog"

        Admin subRoute ->
            "Admin/" ++ Admin.toName subRoute

        ComponentLibrary subRoute ->
            "Component Library/" ++ ComponentLibrary.toName subRoute


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

                ComponentLibrary subRoute ->
                    componentLibraryPath :: ComponentLibrary.toPath subRoute
    in
    UrlBuilder.absolute path []


blog : Route
blog =
    Blog


admin : Route
admin =
    fromAdminRoute Admin.landing


componentLibrary : Route
componentLibrary =
    fromComponentLibraryRoute ComponentLibrary.landing


fromAdminRoute : Admin.Route -> Route
fromAdminRoute =
    Admin


fromComponentLibraryRoute : ComponentLibrary.Route -> Route
fromComponentLibraryRoute =
    ComponentLibrary


fromUrl : Url -> Maybe Route
fromUrl =
    P.parse parser


href : Route -> Attribute msg
href route =
    A.href <| toString route
