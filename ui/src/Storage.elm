module Storage exposing
    ( Storage
    , decoder
    , get
    , listener
    , set
    )

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Ports.FromJs as FromJs
import Ports.ToJs as ToJs



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type Storage
    = Storage (Dict String Decode.Value)



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
    ToJs.type_ "setStorage"
        |> ToJs.fieldsBody
            [ Tuple.pair "value" value
            , Tuple.pair "key" <| Encode.string key
            ]
        |> ToJs.send


decoder : Decoder Storage
decoder =
    Decode.dict Decode.value
        |> Decode.map Storage


listener : (Storage -> msg) -> FromJs.Listener msg
listener toMsg =
    FromJs.listen "storage updated"
        (Decode.map toMsg decoder)
