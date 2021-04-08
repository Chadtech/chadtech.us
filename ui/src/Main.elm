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
import Url exposing (Url)
import Util.Cmd as CmdUtil
import View.Cell as Cell exposing (Cell)
import Zasedani exposing (Zasedani)



--------------------------------------------------------------------------------
-- MAIN --
--------------------------------------------------------------------------------


main : Program Decode.Value (Result Error Modelka) Zpr
main =
    { init = poca
    , view = Document.toBrowserDocument << superView
    , update = superZmodernizovat
    , subscriptions = superSubscriptions
    , onUrlRequest = UrlRequested
    , onUrlChange = RouteChanged << Route.fromUrl
    }
        |> Browser.application


superSubscriptions : Result Error Modelka -> Sub Zpr
superSubscriptions result =
    case result of
        Ok model ->
            subscriptions model

        Err _ ->
            Sub.none


superView : Result Error Modelka -> Document Zpr
superView result =
    case result of
        Ok modelka ->
            view modelka

        Err error ->
            Document.fromBody
                []


superZmodernizovat : Zpr -> Result Error Modelka -> ( Result Error Modelka, Cmd Zpr )
superZmodernizovat msg result =
    case result of
        Ok model ->
            zmodernizovat msg model
                |> Tuple.mapFirst Ok

        Err error ->
            ( Err error, Cmd.none )



--------------------------------------------------------------------------------
-- TYPY --
--------------------------------------------------------------------------------


type Modelka
    = PageNotFound Zasedani Layout
    | Blog Blog.Modelka
    | Admin Admin.Modelka


{-| zpráva
-}
type Zpr
    = MsgDecodeFailed FromJs.Error
    | UrlRequested UrlRequest
    | RouteChanged (Maybe Route)
    | BlogZpr Blog.Zpr
    | AdminZpr Admin.Zpr
    | OpenAdminPanelPressed
    | ZasedaniZpr Zasedani.Zpr


type Error
    = SessionFailedToInit Decode.Error



--------------------------------------------------------------------------------
-- POCA --
--------------------------------------------------------------------------------


poca : Decode.Value -> Url -> Nav.Key -> ( Result Error Modelka, Cmd Zpr )
poca json url navKey =
    case Zasedani.poca json navKey of
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


ziskatZasedani : Modelka -> Zasedani
ziskatZasedani model =
    case model of
        PageNotFound zasedani _ ->
            zasedani

        Blog subModelka ->
            Blog.ziskatZasedani subModelka

        Admin subModelka ->
            Admin.ziskatSession subModelka


datZasedani : Zasedani -> Modelka -> Modelka
datZasedani zasedani model =
    case model of
        PageNotFound _ layout ->
            PageNotFound zasedani layout

        Blog subModel ->
            Blog <| Blog.datZasedani zasedani subModel

        Admin subModel ->
            Admin <| Admin.datSession zasedani subModel


mapZasedani : (Zasedani -> Zasedani) -> Modelka -> Modelka
mapZasedani f model =
    datZasedani (f <| ziskatZasedani model) model


getLayout : Modelka -> Layout
getLayout model =
    case model of
        PageNotFound _ layout ->
            layout

        Blog subModel ->
            Blog.getLayout subModel

        Admin subModel ->
            Admin.getLayout subModel


setLayout : Layout -> Modelka -> Modelka
setLayout layout model =
    case model of
        PageNotFound session _ ->
            PageNotFound session layout

        Blog subModel ->
            Blog <| Blog.setLayout layout subModel

        Admin subModel ->
            Admin <| Admin.setLayout layout subModel


mapLayout : (Layout -> Layout) -> Modelka -> Modelka
mapLayout f modelka =
    setLayout (f <| getLayout modelka) modelka



--------------------------------------------------------------------------------
-- ZMODERNIZOVAT --
--------------------------------------------------------------------------------


zmodernizovat : Zpr -> Modelka -> ( Modelka, Cmd Zpr )
zmodernizovat zpr modelka =
    let
        zasedani : Zasedani
        zasedani =
            ziskatZasedani modelka

        layout : Layout
        layout =
            getLayout modelka
    in
    case zpr of
        MsgDecodeFailed _ ->
            modelka
                |> CmdUtil.withNoCmd

        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    case Route.fromUrl url of
                        Just route ->
                            ( modelka
                            , Zasedani.goTo zasedani route
                            )

                        Nothing ->
                            modelka
                                |> CmdUtil.withNoCmd

                Browser.External url ->
                    ( modelka
                    , Nav.load url
                    )

        RouteChanged maybeRoute ->
            superHandleRouteChange maybeRoute modelka

        BlogZpr subZpr ->
            case modelka of
                Blog subModelka ->
                    Blog.zmodernizovat subZpr subModelka
                        |> CmdUtil.mapBoth Blog BlogZpr

                _ ->
                    modelka
                        |> CmdUtil.withNoCmd

        OpenAdminPanelPressed ->
            let
                ( newSession, cmd ) =
                    Zasedani.turnOnAdminMode zasedani
            in
            ( datZasedani newSession modelka
            , Cmd.batch
                [ cmd
                , Zasedani.goTo zasedani Route.admin
                ]
            )

        AdminZpr subZpr ->
            case modelka of
                Admin subModelka ->
                    Admin.zmodernizovat subZpr subModelka
                        |> CmdUtil.mapBoth Admin AdminZpr

                _ ->
                    modelka |> CmdUtil.withNoCmd

        ZasedaniZpr subZpr ->
            ( mapZasedani (Zasedani.update subZpr) modelka
            , Cmd.none
            )


superHandleRouteChange : Maybe Route -> Modelka -> ( Modelka, Cmd Zpr )
superHandleRouteChange maybeRoute modelka =
    modelka
        |> mapLayout (Layout.handleRouteChange maybeRoute)
        |> handleRouteChange maybeRoute


handleRouteChange : Maybe Route -> Modelka -> ( Modelka, Cmd Zpr )
handleRouteChange maybeRoute modelka =
    let
        session : Zasedani
        session =
            ziskatZasedani modelka

        layout : Layout
        layout =
            getLayout modelka

        pageNotFound : () -> ( Modelka, Cmd msg )
        pageNotFound _ =
            PageNotFound session layout
                |> CmdUtil.withNoCmd
    in
    case maybeRoute of
        Nothing ->
            pageNotFound ()

        Just route ->
            let
                initBlog : () -> ( Modelka, Cmd Zpr )
                initBlog _ =
                    ( Blog <| Blog.poca session layout
                    , Cmd.none
                    )
            in
            case route of
                Route.Landing ->
                    initBlog ()

                Route.Blog ->
                    initBlog ()

                Route.Admin subRoute ->
                    case modelka of
                        Admin subModelka ->
                            ( Admin.handleRouteChange
                                subRoute
                                subModelka
                                |> Admin
                            , Cmd.none
                            )

                        _ ->
                            if Zasedani.adminMode session /= Nothing then
                                Admin.poca session layout subRoute
                                    |> Admin
                                    |> CmdUtil.withNoCmd

                            else
                                pageNotFound ()



--------------------------------------------------------------------------------
-- VIEW --
--------------------------------------------------------------------------------


view : Modelka -> Document Zpr
view model =
    let
        body : List (Cell Zpr)
        body =
            case model of
                PageNotFound _ _ ->
                    [ Cell.fromString "Page not found!" ]

                Blog subModel ->
                    Blog.view subModel
                        |> List.map (Cell.map BlogZpr)

                Admin subModel ->
                    Admin.view subModel
                        |> List.map (Cell.map AdminZpr)

        layout : Layout
        layout =
            getLayout model

        session : Zasedani
        session =
            ziskatZasedani model
    in
    body
        |> Layout.view session layout



--------------------------------------------------------------------------------
-- SUBSCRIPTIONS --
--------------------------------------------------------------------------------


subscriptions : Modelka -> Sub Zpr
subscriptions model =
    [ FromJs.subscription
        MsgDecodeFailed
        (incomingPortsListeners model)
    , KeyCmd.subscriptions
        keyCmds
    ]
        |> Sub.batch


keyCmds : List (KeyCmd Zpr)
keyCmds =
    [ KeyCmd.a OpenAdminPanelPressed
        |> KeyCmd.shift
        |> KeyCmd.cmd
    ]


incomingPortsListeners : Modelka -> FromJs.Listener Zpr
incomingPortsListeners model =
    let
        pageListener : FromJs.Listener Zpr
        pageListener =
            case model of
                PageNotFound _ _ ->
                    FromJs.none

                Blog _ ->
                    FromJs.map BlogZpr Blog.incomingPortsListener

                Admin _ ->
                    FromJs.map AdminZpr Admin.incomingPortsListener
    in
    [ Zasedani.listener
        |> FromJs.map ZasedaniZpr
    , pageListener
    ]
        |> FromJs.batch
