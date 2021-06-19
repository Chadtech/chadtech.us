module Admin exposing
    ( fromStorage
    , poca
    , save
    )

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
    case Storage.ziskat key Decode.string storage of
        Ok maybePassword ->
            ( maybePassword, Nothing )

        Err error ->
            ( Nothing, Just error )


poca : ( String, Cmd zpr )
poca =
    let
        initValue : String
        initValue =
            ""
    in
    ( initValue, save initValue )


save : String -> Cmd zpr
save value =
    Storage.dat key <| Encode.string value
