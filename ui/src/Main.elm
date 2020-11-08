module Main exposing (main)

import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Document exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Layout exposing (Layout)
import Page.Blog as Blog
import Ports.Incoming
import Route exposing (Route)
import Session exposing (Session)
import Url exposing (Url)
import Util.Cmd as CmdUtil
import View.Cell as Cell exposing (Cell)
import View.Row as Row exposing (Row)



--------------------------------------------------------------------------------
-- MAIN --
--------------------------------------------------------------------------------


main : Program Decode.Value Model Msg
main =
    { init = init
    , view = Document.toBrowserDocument << view
    , update = update
    , subscriptions = subscriptions
    , onUrlRequest = UrlRequested
    , onUrlChange = RouteChanged << Route.fromUrl
    }
        |> Browser.application



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type Model
    = PageNotFound Session Layout
    | Blog Blog.Model


type Msg
    = MsgDecodeFailed Ports.Incoming.Error
    | UrlRequested UrlRequest
    | RouteChanged (Maybe Route)
    | BlogMsg Blog.Msg



--------------------------------------------------------------------------------
-- INIT --
--------------------------------------------------------------------------------


init : Decode.Value -> Url -> Nav.Key -> ( Model, Cmd Msg )
init json url navKey =
    let
        session : Session
        session =
            Session.init navKey

        route : Maybe Route
        route =
            Route.fromUrl url
    in
    PageNotFound session (Layout.init route)
        |> superHandleRouteChange route



--------------------------------------------------------------------------------
-- INTERNAL HELPERS --
--------------------------------------------------------------------------------


getSession : Model -> Session
getSession model =
    case model of
        PageNotFound session _ ->
            session

        Blog subModel ->
            Blog.getSession subModel


getLayout : Model -> Layout
getLayout model =
    case model of
        PageNotFound _ layout ->
            layout

        Blog subModel ->
            Blog.getLayout subModel


setLayout : Layout -> Model -> Model
setLayout layout model =
    case model of
        PageNotFound session _ ->
            PageNotFound session layout

        Blog subModel ->
            Blog <| Blog.setLayout layout subModel


mapLayout : (Layout -> Layout) -> Model -> Model
mapLayout f model =
    setLayout (f <| getLayout model) model



--------------------------------------------------------------------------------
-- UPDATE --
--------------------------------------------------------------------------------


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session : Session
        session =
            getSession model
    in
    case msg of
        MsgDecodeFailed _ ->
            model
                |> CmdUtil.withNoCmd

        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    case Route.fromUrl url of
                        Just route ->
                            ( model
                            , Session.goTo session route
                            )

                        Nothing ->
                            model
                                |> CmdUtil.withNoCmd

                Browser.External url ->
                    ( model
                    , Nav.load url
                    )

        RouteChanged maybeRoute ->
            superHandleRouteChange maybeRoute model

        BlogMsg subMsg ->
            case model of
                Blog subModel ->
                    Blog.update subMsg subModel
                        |> CmdUtil.mapBoth Blog BlogMsg

                _ ->
                    model
                        |> CmdUtil.withNoCmd


superHandleRouteChange : Maybe Route -> Model -> ( Model, Cmd Msg )
superHandleRouteChange maybeRoute model =
    model
        |> mapLayout (Layout.handleRouteChange maybeRoute)
        |> handleRouteChange maybeRoute


handleRouteChange : Maybe Route -> Model -> ( Model, Cmd Msg )
handleRouteChange maybeRoute model =
    let
        session : Session
        session =
            getSession model

        layout : Layout
        layout =
            getLayout model
    in
    case maybeRoute of
        Nothing ->
            PageNotFound session layout
                |> CmdUtil.withNoCmd

        Just route ->
            let
                initBlog : () -> ( Model, Cmd Msg )
                initBlog _ =
                    ( Blog <| Blog.init session layout
                    , Cmd.none
                    )
            in
            case route of
                Route.Landing ->
                    initBlog ()

                Route.Blog ->
                    initBlog ()



--------------------------------------------------------------------------------
-- VIEW --
--------------------------------------------------------------------------------


view : Model -> Document Msg
view model =
    let
        body : List (Cell Msg)
        body =
            case model of
                PageNotFound _ _ ->
                    [ Cell.fromString "Page not found!" ]

                Blog subModel ->
                    Blog.view subModel
                        |> List.map (Cell.map BlogMsg)

        layout : Layout
        layout =
            getLayout model
    in
    body
        |> Layout.view layout



--------------------------------------------------------------------------------
-- SUBSCRIPTIONS --
--------------------------------------------------------------------------------


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.Incoming.subscription
        MsgDecodeFailed
        (incomingPortsListeners model)


incomingPortsListeners : Model -> Ports.Incoming.Listener Msg
incomingPortsListeners model =
    case model of
        PageNotFound _ _ ->
            Ports.Incoming.none

        Blog _ ->
            Ports.Incoming.map BlogMsg Blog.incomingPortsListener
