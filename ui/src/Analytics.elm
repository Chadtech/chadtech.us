module Analytics exposing
    ( Event
    , Modelka
    , Zpr
    , name
    , none
    , poca
    , record
    , subscriptions
    , withProp
    , zmodernizovat
    )

import Api
import Api.InputObject
import Api.Mutation as Mutation
import Graphql.SelectionSet as SS
import Json.Encode as Encode
import Time



-------------------------------------------------------------------------------
-- TYPY --
-------------------------------------------------------------------------------


type alias Modelka =
    { events : List EventModelka
    , api : Api.Modelka AnalyticsApiKey
    }


type Event
    = Event ({ pageName : String, currentTime : Time.Posix } -> EventModelka)
    | None


type alias EventModelka =
    { name : String
    , pageName : String
    , currentTime : Time.Posix
    , props : List ( String, Encode.Value )
    }


type Zpr
    = WaitTimeExpired Time.Posix
    | RecordResponse { tryCount : Int } (Response ())


type alias Response value =
    Api.CustomResponse RecordError value AnalyticsApiKey


type RecordError
    = ApiError (List EventModelka) Api.Error


type AnalyticsApiKey
    = AnalyticsApiKey



-------------------------------------------------------------------------------
-- POCA --
-------------------------------------------------------------------------------


poca : Modelka
poca =
    { events = []
    , api = Api.init
    }



-------------------------------------------------------------------------------
-- HELPERS --
-------------------------------------------------------------------------------


threshold : Int
threshold =
    25


datEvents : List EventModelka -> Modelka -> Modelka
datEvents eventModelkas modelka =
    { modelka | events = eventModelkas }


clearEvents : Modelka -> Modelka
clearEvents =
    datEvents []


sendEvents : { zasedaniId : String, tryCount : Int } -> List EventModelka -> Modelka -> ( Modelka, Cmd Zpr )
sendEvents args events modelka =
    let
        toGraphqlEvent : EventModelka -> Api.InputObject.NovaEvent
        toGraphqlEvent event =
            { name = event.name
            , eventTime = toFloat <| Time.posixToMillis event.currentTime
            , zasedaniId = args.zasedaniId
            , pageName = event.pageName
            , propsJson = Encode.encode 0 (Encode.object event.props)
            }

        customResponseToZpr : Api.Response () AnalyticsApiKey -> Zpr
        customResponseToZpr res =
            res
                |> Api.mapResponseError (ApiError events)
                |> RecordResponse { tryCount = args.tryCount + 1 }
    in
    Api.send
        { req =
            Mutation.recordAnalytics
                { events = List.map toGraphqlEvent events }
                |> SS.map (\_ -> ())
                |> Api.mutation
        , toZpr = customResponseToZpr
        , modelka = modelka
        }



-------------------------------------------------------------------------------
-- API --
-------------------------------------------------------------------------------


record :
    { zasedaniId : String
    , pageName : String
    , currentTime : Time.Posix
    }
    -> Event
    -> Modelka
    -> ( Modelka, Cmd Zpr )
record args event modelka =
    case event of
        Event eventModelkaFn ->
            let
                novaEvents : List EventModelka
                novaEvents =
                    eventModelkaFn
                        { pageName = args.pageName
                        , currentTime = args.currentTime
                        }
                        :: modelka.events
            in
            if List.length novaEvents > threshold then
                modelka
                    |> clearEvents
                    |> sendEvents
                        { zasedaniId = args.zasedaniId
                        , tryCount = 0
                        }
                        novaEvents

            else
                ( datEvents novaEvents modelka
                , Cmd.none
                )

        None ->
            ( modelka
            , Cmd.none
            )


name : String -> Event
name str =
    Event
        (\{ pageName, currentTime } ->
            { name = str
            , pageName = pageName
            , currentTime = currentTime
            , props = []
            }
        )


none : Event
none =
    None


withProp : String -> Encode.Value -> Event -> Event
withProp propName propVal event =
    case event of
        None ->
            None

        Event fn ->
            let
                modelkaFn : { pageName : String, currentTime : Time.Posix } -> EventModelka
                modelkaFn args =
                    let
                        eventModelka : EventModelka
                        eventModelka =
                            fn
                                { pageName = args.pageName
                                , currentTime = args.currentTime
                                }
                    in
                    { eventModelka | props = ( propName, propVal ) :: eventModelka.props }
            in
            Event modelkaFn



---------------------------------------------------------------
-- ZMODERNIZOVAT --
---------------------------------------------------------------


zmodernizovat : { zasedaniId : String } -> Zpr -> Modelka -> ( Modelka, Cmd Zpr )
zmodernizovat args zpr modelka =
    case zpr of
        WaitTimeExpired _ ->
            modelka
                |> clearEvents
                |> sendEvents
                    { zasedaniId = args.zasedaniId
                    , tryCount = 0
                    }
                    modelka.events

        RecordResponse { tryCount } res ->
            Api.handleEffectful
                res
                (handleRecordResponse
                    { tryCount = tryCount
                    , zasedaniId = args.zasedaniId
                    }
                )
                modelka


handleRecordResponse :
    { tryCount : Int
    , zasedaniId : String
    }
    -> Result RecordError ()
    -> Modelka
    -> ( Modelka, Cmd Zpr )
handleRecordResponse args result modelka =
    case result of
        Ok () ->
            ( modelka
            , Cmd.none
            )

        Err (ApiError events _) ->
            if args.tryCount > 4 then
                ( modelka, Cmd.none )

            else
                modelka
                    |> sendEvents
                        { zasedaniId = args.zasedaniId
                        , tryCount = args.tryCount
                        }
                        events



---------------------------------------------------------------
-- SUBSCRIPTION --
---------------------------------------------------------------


subscriptions : Sub Zpr
subscriptions =
    Time.every (10 * 1000) WaitTimeExpired
