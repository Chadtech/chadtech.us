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
    , simpleHandler
    , zero
    )

---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type Error
    = Error


type Response value
    = Response__Value value
    | Response__Error Error


type Request value
    = Request value


type PendingRequestCount
    = Count Int


type alias Modelka =
    { pendingRequestCount : PendingRequestCount }


type alias HasApi modelka =
    { modelka | api : Modelka }


type alias Handler modelka =
    { ziskatApi : modelka -> Modelka
    , datApi : Modelka -> modelka -> modelka
    }



--------------------------------------------------------------------------------
-- HELPERS --
--------------------------------------------------------------------------------


decrementRequests : Modelka -> Modelka
decrementRequests =
    mapRequestCount (\i -> i - 1)


incrementRequests : Modelka -> Modelka
incrementRequests =
    mapRequestCount (\i -> i + 1)


mapRequestCount : (Int -> Int) -> Modelka -> Modelka
mapRequestCount fn modelka =
    let
        (Count c) =
            modelka.pendingRequestCount
    in
    { modelka
        | pendingRequestCount = Count (max 0 (fn c))
    }


responseToResult : Response value -> Result Error value
responseToResult response =
    case response of
        Response__Value value ->
            Ok value

        Response__Error error ->
            Err error



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


zero : PendingRequestCount
zero =
    Count 0


errorToString : Error -> String
errorToString error =
    case error of
        Error ->
            "ERROR"


pendingRequests : Modelka -> PendingRequestCount
pendingRequests modelka =
    modelka.pendingRequestCount


init : Modelka
init =
    { pendingRequestCount = Count 0 }


simpleHandler : Handler (HasApi modelka)
simpleHandler =
    { ziskatApi = .api
    , datApi =
        \api modelka ->
            { modelka | api = api }
    }


handle :
    Response value
    -> (Result Error value -> HasApi modelka -> HasApi modelka)
    -> HasApi modelka
    -> HasApi modelka
handle =
    customHandle simpleHandler


customHandle :
    Handler modelka
    -> Response value
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
