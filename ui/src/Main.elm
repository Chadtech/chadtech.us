module Main exposing (main)

import Analytics
import Api
import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Document exposing (Document)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import KeyCmd exposing (KeyCmd)
import Layout exposing (Layout)
import Page.Admin as Admin
import Page.Blog as Blog
import Page.ComponentLibrary as ComponentLibrary
import Ports.FromJs as FromJs
import Route exposing (Route)
import Url exposing (Url)
import Util.Cmd as CmdUtil
import View.Cell as Cell exposing (Cell)
import View.DevPanel as DevPanel
import View.Dialog as Dialog exposing (Dialog)
import View.Row as Row
import Zasedani exposing (Zasedani)



--------------------------------------------------------------------------------
-- MAIN --
--------------------------------------------------------------------------------


main : Program Decode.Value (Result Error Modelka) Zpr
main =
    { init = poca
    , view = Document.toBrowserDocument << superPohled
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


superPohled : Result Error Modelka -> Document Zpr
superPohled result =
    case result of
        Ok modelka ->
            pohled modelka

        Err error ->
            [ "Error"
            , "Chadtech.us failed to start, sorry about that"
            ]
                |> List.map Row.fromString
                |> Document.fromBody


superZmodernizovat : Zpr -> Result Error Modelka -> ( Result Error Modelka, Cmd Zpr )
superZmodernizovat zpr result =
    case result of
        Ok modelka ->
            let
                ( novaModelka, cmd ) =
                    zmodernizovat zpr modelka

                analyticsEvent =
                    track zpr

                ( novaZasedani, analyticsCmd ) =
                    Zasedani.recordAnalytics
                        { pageName = pageName modelka }
                        analyticsEvent
                        (ziskatZasedani novaModelka)
            in
            ( Ok <| datZasedani novaZasedani novaModelka
            , Cmd.batch
                [ cmd
                , Cmd.map AnalyticsZpr analyticsCmd
                ]
            )

        Err error ->
            ( Err error, Cmd.none )



--------------------------------------------------------------------------------
-- TYPY --
--------------------------------------------------------------------------------


type Modelka
    = PageNotFound Zasedani Layout
    | Blog Blog.Modelka
    | Admin Admin.Modelka
    | ComponentLibrary ComponentLibrary.Modelka


{-| zpráva
-}
type Zpr
    = MsgDecodeFailed FromJs.Error
    | UrlRequested UrlRequest
    | RouteChanged (Maybe Route)
    | BlogZpr Blog.Zpr
    | AdminZpr Admin.Zpr
    | OpenAdminPanelPressed
    | OpenDevPanelPressed
    | ZasedaniZpr Zasedani.Zpr
    | AnalyticsZpr Analytics.Zpr
    | ComponentLibraryZpr ComponentLibrary.Zpr


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


pageName : Modelka -> String
pageName modelka =
    case modelka of
        PageNotFound _ _ ->
            "Not Found"

        Blog _ ->
            "Blog"

        Admin _ ->
            "Admin"

        ComponentLibrary _ ->
            "Component Library"


pendingApiRequests : Modelka -> Api.PendingRequestCount
pendingApiRequests modelka =
    case modelka of
        PageNotFound _ _ ->
            Api.zero

        Blog subModelka ->
            Blog.pendingRequests subModelka

        Admin subModelka ->
            Admin.pendingRequests subModelka

        ComponentLibrary _ ->
            Api.zero


datAnalytics : Analytics.Modelka -> Modelka -> Modelka
datAnalytics analyticsModelka modelka =
    datZasedani
        (Zasedani.datAnalytics analyticsModelka <| ziskatZasedani modelka)
        modelka


ziskatAnalytics : Modelka -> Analytics.Modelka
ziskatAnalytics =
    ziskatZasedani >> Zasedani.ziskatAnalytics


ziskatZasedani : Modelka -> Zasedani
ziskatZasedani modelka =
    case modelka of
        PageNotFound zasedani _ ->
            zasedani

        Blog subModelka ->
            Blog.ziskatZasedani subModelka

        Admin subModelka ->
            Admin.ziskatZasedani subModelka

        ComponentLibrary subModelka ->
            ComponentLibrary.ziskatZasedani subModelka


datZasedani : Zasedani -> Modelka -> Modelka
datZasedani zasedani model =
    case model of
        PageNotFound _ layout ->
            PageNotFound zasedani layout

        Blog subModel ->
            Blog <| Blog.datZasedani zasedani subModel

        Admin subModel ->
            Admin <| Admin.datZasedani zasedani subModel

        ComponentLibrary subModelka ->
            ComponentLibrary <| ComponentLibrary.datZasedani zasedani subModelka


mapZasedani : (Zasedani -> Zasedani) -> Modelka -> Modelka
mapZasedani f model =
    datZasedani (f <| ziskatZasedani model) model


getLayout : Modelka -> Layout
getLayout model =
    case model of
        PageNotFound _ layout ->
            layout

        Blog subModelka ->
            Blog.getLayout subModelka

        Admin subModelka ->
            Admin.getLayout subModelka

        ComponentLibrary subModelka ->
            ComponentLibrary.getLayout subModelka


setLayout : Layout -> Modelka -> Modelka
setLayout layout model =
    case model of
        PageNotFound session _ ->
            PageNotFound session layout

        Blog subModel ->
            Blog <| Blog.setLayout layout subModel

        Admin subModel ->
            Admin <| Admin.setLayout layout subModel

        ComponentLibrary subModelka ->
            ComponentLibrary <| ComponentLibrary.setLayout layout subModelka


mapLayout : (Layout -> Layout) -> Modelka -> Modelka
mapLayout fn modelka =
    setLayout (fn <| getLayout modelka) modelka



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
    case Debug.log "Zpr" zpr of
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
                ( newZasedani, cmd ) =
                    Zasedani.turnOnAdminMode zasedani
            in
            ( datZasedani newZasedani modelka
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
            ( mapZasedani (Zasedani.zmodernizovat subZpr) modelka
            , Cmd.none
            )

        OpenDevPanelPressed ->
            ( mapZasedani
                Zasedani.openDevPanel
                modelka
            , Cmd.none
            )

        AnalyticsZpr subZpr ->
            let
                ( novaAnalyticsModelka, cmd ) =
                    Analytics.zmodernizovat
                        { zasedaniId = Zasedani.id <| ziskatZasedani modelka }
                        subZpr
                        (ziskatAnalytics modelka)
            in
            ( datAnalytics novaAnalyticsModelka modelka
            , Cmd.map AnalyticsZpr cmd
            )

        ComponentLibraryZpr subZpr ->
            case modelka of
                ComponentLibrary subModelka ->
                    ( ComponentLibrary.zmodernizovat subZpr subModelka
                        |> ComponentLibrary
                    , Cmd.none
                    )

                _ ->
                    modelka |> CmdUtil.withNoCmd


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
                            Admin.handleRouteChange
                                subRoute
                                subModelka
                                |> Tuple.mapFirst Admin
                                |> Tuple.mapSecond (Cmd.map AdminZpr)

                        _ ->
                            if Zasedani.adminMode session /= Nothing then
                                Admin.poca session layout subRoute
                                    |> Tuple.mapFirst Admin
                                    |> Tuple.mapSecond (Cmd.map AdminZpr)

                            else
                                pageNotFound ()

                Route.ComponentLibrary subRoute ->
                    case modelka of
                        ComponentLibrary subModelka ->
                            ( ComponentLibrary.handleRouteChange
                                subRoute
                                subModelka
                                |> ComponentLibrary
                            , Cmd.none
                            )

                        _ ->
                            if Zasedani.adminMode session /= Nothing then
                                ( ComponentLibrary.poca session layout subRoute
                                    |> ComponentLibrary
                                , Cmd.none
                                )

                            else
                                pageNotFound ()



--------------------------------------------------------------------------------
-- TRACK --
--------------------------------------------------------------------------------


track : Zpr -> Analytics.Event
track zpr =
    case zpr of
        MsgDecodeFailed error ->
            FromJs.track error

        UrlRequested _ ->
            Analytics.none

        RouteChanged maybeRoute ->
            Analytics.name "route changed"
                |> Analytics.withProp
                    "route"
                    (Maybe.map Route.toName maybeRoute
                        |> Maybe.withDefault "Unknown Route"
                        |> Encode.string
                    )

        BlogZpr subZpr ->
            Blog.track subZpr

        AdminZpr subZpr ->
            Admin.track subZpr

        OpenAdminPanelPressed ->
            Analytics.name "Admin Panel Pressed"

        OpenDevPanelPressed ->
            Analytics.name "Dev Panel Pressed"

        ZasedaniZpr subZpr ->
            Zasedani.track subZpr

        AnalyticsZpr _ ->
            Analytics.none

        ComponentLibraryZpr subZpr ->
            ComponentLibrary.track subZpr



--------------------------------------------------------------------------------
-- POHLED --
--------------------------------------------------------------------------------


pohled : Modelka -> Document Zpr
pohled modelka =
    let
        body : List (Cell Zpr)
        body =
            case modelka of
                PageNotFound _ _ ->
                    [ Cell.fromString "Page not found!" ]

                Blog subModelka ->
                    Blog.pohled subModelka
                        |> List.map (Cell.map BlogZpr)

                Admin subModelka ->
                    Admin.pohled subModelka
                        |> List.map (Cell.map AdminZpr)

                ComponentLibrary subModelka ->
                    ComponentLibrary.pohled subModelka
                        |> List.map (Cell.map ComponentLibraryZpr)

        layout : Layout
        layout =
            getLayout modelka

        zasedani : Zasedani
        zasedani =
            ziskatZasedani modelka

        dialogs : List (() -> Dialog zpr)
        dialogs =
            [ \() ->
                case Zasedani.devPanel zasedani of
                    Just devPanel ->
                        DevPanel.pohled
                            { errors =
                                Zasedani.errorsAsStrs
                                    { sensitive = False }
                                    zasedani
                            }
                            devPanel

                    Nothing ->
                        Dialog.none
            ]
    in
    Layout.pohled
        { pendingApiRequests = pendingApiRequests modelka }
        zasedani
        layout
        body
        |> Document.withDialog (Dialog.first dialogs)



--------------------------------------------------------------------------------
-- SUBSCRIPTIONS --
--------------------------------------------------------------------------------


subscriptions : Modelka -> Sub Zpr
subscriptions model =
    [ FromJs.subscription
        MsgDecodeFailed
        (incomingPortsListeners model)
    , KeyCmd.subscriptions keyCmds
    , Zasedani.subscriptions
        |> Sub.map ZasedaniZpr
    ]
        |> Sub.batch


keyCmds : List (KeyCmd Zpr)
keyCmds =
    [ KeyCmd.a OpenAdminPanelPressed
        |> KeyCmd.shift
        |> KeyCmd.cmd
    , KeyCmd.period OpenDevPanelPressed
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

                ComponentLibrary _ ->
                    FromJs.none
    in
    [ Zasedani.listener
        |> FromJs.map ZasedaniZpr
    , pageListener
    ]
        |> FromJs.batch
