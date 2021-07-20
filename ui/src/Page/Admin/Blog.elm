module Page.Admin.Blog exposing
    ( Flags
    , Modelka
    , Zpr
    , load
    , pendingRequests
    , poca
    , pohled
    , track
    , zmodernizovat
    )

import Analytics
import Api exposing (HasApi)
import Api.Object.Post as PostSS
import Api.Query as Query
import Graphql.Http
import Graphql.SelectionSet as SS
import View.Row as Row exposing (Row)



---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type alias Modelka =
    { api : Api.Modelka AdminBlogApiKey
    , posts : List Post
    }


type AdminBlogApiKey
    = AdminBlogApiKey


type Post
    = Post__V2 PostV2


type alias PostV2 =
    { id : Int
    , title : String
    }


type Zpr
    = Zpr



--------------------------------------------------------------------------------
-- POCA --
--------------------------------------------------------------------------------


type alias Flags =
    { posts : List Post }


poca : Flags -> Modelka
poca flags =
    { api = Api.init
    , posts = flags.posts
    }


load :
    (Api.Response Flags key -> zpr)
    -> HasApi modelka key
    -> ( HasApi modelka key, Cmd zpr )
load toZpr modelka =
    let
        flagsRequest : Api.Request Flags
        flagsRequest =
            Query.blogpostsV2
                (SS.map2 PostV2
                    PostSS.id
                    PostSS.title
                    |> SS.map Post__V2
                )
                |> SS.map Flags
                |> Api.query
    in
    Api.send
        { toZpr = toZpr
        , modelka = modelka
        , req = flagsRequest
        }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


pendingRequests : Modelka -> Api.PendingRequestCount
pendingRequests modelka =
    Api.pendingRequests modelka.api



--------------------------------------------------------------------------------
-- ZMODERNIZOVAT --
--------------------------------------------------------------------------------


zmodernizovat : Zpr -> Modelka -> ( Modelka, Cmd Zpr )
zmodernizovat zpr modelka =
    case zpr of
        Zpr ->
            ( modelka, Cmd.none )



--------------------------------------------------------------------------------
-- TRACK --
--------------------------------------------------------------------------------


track : Zpr -> Analytics.Event
track zpr =
    case zpr of
        Zpr ->
            Analytics.none



--------------------------------------------------------------------------------
-- POHLED --
--------------------------------------------------------------------------------


pohled : Modelka -> List (Row Zpr)
pohled modelka =
    [ Row.fromString "Posts V2"
    , Row.fromCells []
    ]
