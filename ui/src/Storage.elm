module Storage exposing (Storage, decoder, get, listener, set)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports.Incoming
import Ports.Outgoing



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type Storage
    = Storage (Dict String Decode.Value)



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


empty : Storage
empty =
    Storage Dict.empty



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


get : String -> Decoder a -> Storage -> Result Decode.Error (Maybe a)
get key valueDecoder (Storage storage) =
    case Dict.get key storage of
        Just json ->
            Result.map Just <|
                Decode.decodeValue valueDecoder json

        Nothing ->
            Ok Nothing


set : String -> Encode.Value -> Cmd msg
set key value =
    Ports.Outgoing.fromType_ "setStorage"
        |> Ports.Outgoing.fieldsBody
            [ Tuple.pair "value" value
            , Tuple.pair "key" <| Encode.string key
            ]
        |> Ports.Outgoing.send


decoder : Decoder Storage
decoder =
    [ Decode.dict Decode.value
        |> Decode.map Storage
    , Decode.null empty
    ]
        |> Decode.oneOf



--------------------------------------------------------------------------------
-- PORTS INCOMING --
--------------------------------------------------------------------------------


listener : (Storage -> msg) -> Ports.Incoming.Listener msg
listener toMsg =
    Ports.Incoming.listen "storage updated"
        (Decode.map toMsg decoder)
