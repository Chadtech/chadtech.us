port module Ports.ToJs exposing
    ( Msg
    , fieldsBody
    , intBody
    , send
    , stringBody
    , type_
    )

import Json.Encode as Encode



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Msg =
    { type_ : String
    , body : Encode.Value
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


type_ : String -> Msg
type_ t =
    { type_ = t
    , body = Encode.null
    }


fieldsBody : List ( String, Encode.Value ) -> Msg -> Msg
fieldsBody fields =
    setBody <| Encode.object fields


stringBody : String -> Msg -> Msg
stringBody string =
    setBody <| Encode.string string


intBody : Int -> Msg -> Msg
intBody int =
    setBody <| Encode.int int


send : Msg -> Cmd msg
send msg =
    [ ( "type", Encode.string msg.type_ )
    , ( "body", msg.body )
    ]
        |> Encode.object
        |> toJs



--------------------------------------------------------------------------------
-- INTERNAL HELPERS --
--------------------------------------------------------------------------------


setBody : Encode.Value -> Msg -> Msg
setBody json msg =
    { msg | body = json }


port toJs : Encode.Value -> Cmd msg
