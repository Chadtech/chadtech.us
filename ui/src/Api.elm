module Api exposing
    ( Error
    , Handler
    , HasApi
    , Modelka
    , PendingRequestCount
    , Request
    , Response
    , customHandle
    , errorToString
    , handle
    , init
    , pendingRequests
    , query
    , send
    , sendCustom
    , simpleHandler
    , zero
    )

import CodeGen.Api.Root as ApiRoot
import Graphql.Http
import Graphql.Http.GraphqlError exposing (GraphqlError)
import Graphql.Operation exposing (RootQuery)
import Graphql.SelectionSet exposing (SelectionSet)



---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type Error
    = Error__Graphql
        { sensitiveError : String
        , rawError : String
        }


type Response value key
    = Response__Value value
    | Response__Error Error


type Request value
    = Request (Graphql.Http.Request value)


type PendingRequestCount
    = Count Int


type alias Modelka key =
    { pendingRequestCount : PendingRequestCount
    , key : Maybe key
    }


type alias HasApi modelka key =
    { modelka | api : Modelka key }


type alias Handler modelka key =
    { ziskatApi : modelka -> Modelka key
    , datApi : Modelka key -> modelka -> modelka
    }



--------------------------------------------------------------------------------
-- HELPERS --
--------------------------------------------------------------------------------


decrementRequests : Modelka key -> Modelka key
decrementRequests =
    mapRequestCount (\i -> i - 1)


incrementRequests : Modelka key -> Modelka key
incrementRequests =
    mapRequestCount (\i -> i + 1)


mapRequestCount : (Int -> Int) -> Modelka key -> Modelka key
mapRequestCount fn modelka =
    let
        (Count c) =
            modelka.pendingRequestCount
    in
    { modelka
        | pendingRequestCount = Count (max 0 (fn c))
    }


responseToResult : Response value key -> Result Error value
responseToResult response =
    case response of
        Response__Value value ->
            Ok value

        Response__Error error ->
            Err error


graphqlRawErrorToString : { sensitive : Bool } -> Graphql.Http.RawError parsedData Graphql.Http.HttpError -> String
graphqlRawErrorToString args graphqlError =
    case graphqlError of
        Graphql.Http.GraphqlError _ graphqlErrors ->
            let
                graphqlErrorToString : GraphqlError -> String
                graphqlErrorToString err =
                    err.message
            in
            [ [ "Graphql Errors : " ]
            , List.map graphqlErrorToString graphqlErrors
            ]
                |> List.concat
                |> String.join "\n"

        Graphql.Http.HttpError httpError ->
            case httpError of
                Graphql.Http.BadUrl badUrl ->
                    if args.sensitive then
                        "Bad Url"

                    else
                        "Bad Url : " ++ badUrl

                Graphql.Http.Timeout ->
                    "Timeout"

                Graphql.Http.NetworkError ->
                    "Network Error"

                Graphql.Http.BadStatus metadata message ->
                    [ "Bad Status :"
                    , String.fromInt metadata.statusCode
                    , message
                    ]
                        |> String.join " "

                Graphql.Http.BadPayload _ ->
                    "Bad payload"



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


query : SelectionSet value RootQuery -> Request value
query =
    Request << Graphql.Http.queryRequest (ApiRoot.asString ++ "/graphql")


send :
    { toZpr : Response value key -> zpr
    , req : Request value
    , modelka : HasApi modelka key
    }
    -> ( HasApi modelka key, Cmd zpr )
send =
    sendCustom simpleHandler


sendCustom :
    Handler modelka key
    ->
        { toZpr : Response value key -> zpr
        , req : Request value
        , modelka : modelka
        }
    -> ( modelka, Cmd zpr )
sendCustom handler args =
    let
        newModelka : modelka
        newModelka =
            handler.datApi
                (handler.ziskatApi args.modelka
                    |> incrementRequests
                )
                args.modelka

        graphqlToMsg : Result (Graphql.Http.Error value) value -> zpr
        graphqlToMsg result =
            case result of
                Ok value ->
                    args.toZpr <| Response__Value value

                Err error ->
                    { rawError =
                        graphqlRawErrorToString
                            { sensitive = False }
                            error
                    , sensitiveError =
                        graphqlRawErrorToString
                            { sensitive = True }
                            error
                    }
                        |> Error__Graphql
                        |> Response__Error
                        |> args.toZpr

        (Request graphqlReq) =
            args.req
    in
    ( newModelka
    , Graphql.Http.send
        graphqlToMsg
        graphqlReq
    )


zero : PendingRequestCount
zero =
    Count 0


errorToString : { sensitive : Bool } -> Error -> String
errorToString args error =
    case error of
        Error__Graphql graphqlError ->
            if args.sensitive then
                graphqlError.sensitiveError

            else
                graphqlError.rawError


pendingRequests : Modelka key -> PendingRequestCount
pendingRequests modelka =
    modelka.pendingRequestCount


init : Modelka key
init =
    { pendingRequestCount = Count 0
    , key = Nothing
    }


simpleHandler : Handler (HasApi modelka key) key
simpleHandler =
    { ziskatApi = .api
    , datApi =
        \api modelka ->
            { modelka | api = api }
    }


handle :
    Response value key
    -> (Result Error value -> HasApi modelka key -> HasApi modelka key)
    -> HasApi modelka key
    -> HasApi modelka key
handle =
    customHandle simpleHandler


customHandle :
    Handler modelka key
    -> Response value key
    -> (Result Error value -> modelka -> modelka)
    -> modelka
    -> modelka
customHandle handler response fn modelka =
    let
        result : Result Error value
        result =
            responseToResult response

        novaModelka : modelka
        novaModelka =
            fn result modelka
    in
    novaModelka
        |> handler.datApi
            (handler.ziskatApi novaModelka
                |> decrementRequests
            )
