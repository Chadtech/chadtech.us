module Admin exposing (fromStorage, init, save)

import Json.Decode as Decode
import Json.Encode as Encode
import Storage exposing (Storage)



---------------------------------------------------------------
-- IMPLEMENTATION --
---------------------------------------------------------------


key : String
key =
    "admin_mode"



---------------------------------------------------------------
-- API --
---------------------------------------------------------------


fromStorage : Storage -> ( Maybe String, Maybe Decode.Error )
fromStorage storage =
    case Storage.get key Decode.string storage of
        Ok maybePassword ->
            ( maybePassword, Nothing )

        Err error ->
            ( Nothing, Just error )


init : ( String, Cmd msg )
init =
    let
        initValue : String
        initValue =
            ""
    in
    ( initValue, save initValue )


save : String -> Cmd msg
save value =
    Storage.set key <| Encode.string value
