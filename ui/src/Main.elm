module Main exposing (main)

import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Document exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import KeyCmd exposing (KeyCmd)
import Layout exposing (Layout)
import Page.Admin as Admin
import Page.Blog as Blog
import Ports.FromJs as FromJs
import Route exposing (Route)
import Session exposing (Session)
import Url exposing (Url)
import Util.Cmd as CmdUtil
import View.Cell as Cell exposing (Cell)



--------------------------------------------------------------------------------
-- MAIN --
--------------------------------------------------------------------------------


main : Program Decode.Value (Result Error Model) Msg
main =
    { init = init
    , view = Document.toBrowserDocument << superView
    , update = superUpdate
    , subscriptions = superSubscriptions
    , onUrlRequest = UrlRequested
    , onUrlChange = RouteChanged << Route.fromUrl
    }
        |> Browser.application


superSubscriptions : Result Error Model -> Sub Msg
superSubscriptions result =
    case result of
        Ok model ->
            subscriptions model

        Err _ ->
            Sub.none


superView : Result Error Model -> Document Msg
superView result =
    case result of
        Ok model ->
            view model

        Err error ->
            Document.fromBody
                []


superUpdate : Msg -> Result Error Model -> ( Result Error Model, Cmd Msg )
superUpdate msg result =
    case result of
        Ok model ->
            update msg model
                |> Tuple.mapFirst Ok

        Err error ->
            ( Err error, Cmd.none )



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type Model
    = PageNotFound Session Layout
    | Blog Blog.Model
    | Admin Admin.Model


type Msg
    = MsgDecodeFailed FromJs.Error
    | UrlRequested UrlRequest
    | RouteChanged (Maybe Route)
    | BlogMsg Blog.Msg
    | AdminMsg Admin.Msg
    | OpenAdminPanelPressed
    | SessionMsg Session.Msg


type Error
    = SessionFailedToInit Decode.Error



--------------------------------------------------------------------------------
-- INIT --
--------------------------------------------------------------------------------


init : Decode.Value -> Url -> Nav.Key -> ( Result Error Model, Cmd Msg )
init json url navKey =
    case Session.init json navKey of
        Ok session ->
            let
                route : Maybe Route
                route =
                    Route.fromUrl url
            in
            PageNotFound session (Layout.init route)
                |> superHandleRouteChange route
                |> Tuple.mapFirst Ok

        Err error ->
            ( Err <| SessionFailedToInit error, Cmd.none )



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

        Admin subModel ->
            Admin.getSession subModel


setSession : Session -> Model -> Model
setSession session model =
    case model of
        PageNotFound _ layout ->
            PageNotFound session layout

        Blog subModel ->
            Blog <| Blog.setSession session subModel

        Admin subModel ->
            Admin <| Admin.setSession session subModel


mapSession : (Session -> Session) -> Model -> Model
mapSession f model =
    setSession (f <| getSession model) model


getLayout : Model -> Layout
getLayout model =
    case model of
        PageNotFound _ layout ->
            layout

        Blog subModel ->
            Blog.getLayout subModel

        Admin subModel ->
            Admin.getLayout subModel


setLayout : Layout -> Model -> Model
setLayout layout model =
    case model of
        PageNotFound session _ ->
            PageNotFound session layout

        Blog subModel ->
            Blog <| Blog.setLayout layout subModel

        Admin subModel ->
            Admin <| Admin.setLayout layout subModel


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

        layout : Layout
        layout =
            getLayout model
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

        OpenAdminPanelPressed ->
            let
                ( newSession, cmd ) =
                    Session.turnOnAdminMode session
            in
            ( setSession newSession model
            , Cmd.batch
                [ cmd
                , Session.goTo session Route.admin
                ]
            )

        AdminMsg subMsg ->
            case model of
                Admin subModel ->
                    Admin.update subMsg subModel
                        |> CmdUtil.mapBoth Admin AdminMsg

                _ ->
                    model |> CmdUtil.withNoCmd

        SessionMsg subMsg ->
            ( mapSession (Session.update subMsg) model
            , Cmd.none
            )


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

        pageNotFound : () -> ( Model, Cmd msg )
        pageNotFound _ =
            PageNotFound session layout
                |> CmdUtil.withNoCmd
    in
    case maybeRoute of
        Nothing ->
            pageNotFound ()

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

                Route.Admin ->
                    case model of
                        Admin _ ->
                            ( model, Cmd.none )

                        _ ->
                            if Session.adminIsOn session then
                                Admin.init session layout
                                    |> Admin
                                    |> CmdUtil.withNoCmd

                            else
                                pageNotFound ()



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

                Admin subModel ->
                    Admin.view subModel
                        |> List.map (Cell.map AdminMsg)

        layout : Layout
        layout =
            getLayout model

        session : Session
        session =
            getSession model
    in
    body
        |> Layout.view session layout



--------------------------------------------------------------------------------
-- SUBSCRIPTIONS --
--------------------------------------------------------------------------------


subscriptions : Model -> Sub Msg
subscriptions model =
    [ FromJs.subscription
        MsgDecodeFailed
        (incomingPortsListeners model)
    , KeyCmd.subscriptions
        keyCmds
    ]
        |> Sub.batch


keyCmds : List (KeyCmd Msg)
keyCmds =
    [ KeyCmd.a OpenAdminPanelPressed
        |> KeyCmd.shift
        |> KeyCmd.cmd
    ]


incomingPortsListeners : Model -> FromJs.Listener Msg
incomingPortsListeners model =
    let
        pageListener : FromJs.Listener Msg
        pageListener =
            case model of
                PageNotFound _ _ ->
                    FromJs.none

                Blog _ ->
                    FromJs.map BlogMsg Blog.incomingPortsListener

                Admin _ ->
                    FromJs.map AdminMsg Admin.incomingPortsListener
    in
    [ Session.listener
        |> FromJs.map SessionMsg
    , pageListener
    ]
        |> FromJs.batch
