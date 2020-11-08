module KeyCmd exposing
    ( KeyCmd
    , a
    , batch
    , cmd
    , map
    , none
    , shift
    , subscriptions
    )

import Browser.Events
import Json.Decode as Decode exposing (Decoder)
import Util.Bool as BoolUtil
import Util.Maybe as MaybeUtil



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type KeyCmd msg
    = Single (Model msg)
    | Batch (List (KeyCmd msg))


type alias Model msg =
    { msg : msg
    , command : Command
    , shift : Shift
    , keys : List String
    }


type Command
    = Command Bool


type Shift
    = Shift Bool



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


mapModels : (Model a -> Model msg) -> KeyCmd a -> KeyCmd msg
mapModels f keyCmd =
    case keyCmd of
        Single model ->
            Single (f model)

        Batch keyCmds ->
            Batch <| List.map (mapModels f) keyCmds


fromKeys : List String -> msg -> KeyCmd msg
fromKeys keys msg =
    Single
        { keys = keys
        , msg = msg
        , command = Command False
        , shift = Shift False
        }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


none : KeyCmd msg
none =
    batch []


batch : List (KeyCmd msg) -> KeyCmd msg
batch =
    Batch


map : (a -> msg) -> KeyCmd a -> KeyCmd msg
map toMsg keyCmd =
    case keyCmd of
        Single model ->
            Single
                { msg = toMsg model.msg
                , command = model.command
                , shift = model.shift
                , keys = model.keys
                }

        Batch keyCmds ->
            Batch <| List.map (map toMsg) keyCmds


cmd : KeyCmd msg -> KeyCmd msg
cmd =
    mapModels (\model -> { model | command = Command True })


shift : KeyCmd msg -> KeyCmd msg
shift =
    mapModels (\model -> { model | shift = Shift True })


a : msg -> KeyCmd msg
a =
    fromKeys [ "a" ]


subscriptions : List (KeyCmd msg) -> Sub msg
subscriptions keyCmds =
    let
        fromEvent : KeyCmd msg -> Command -> Shift -> String -> Maybe msg
        fromEvent remaining eventCmdKey eventShiftKey eventKey =
            case remaining of
                Single model ->
                    if
                        BoolUtil.all
                            (List.member eventKey model.keys)
                            [ model.command == eventCmdKey
                            , model.shift == eventShiftKey
                            ]
                    then
                        Just model.msg

                    else
                        Nothing

                Batch [] ->
                    Nothing

                Batch (first :: rest) ->
                    fromEvent first eventCmdKey eventShiftKey eventKey
                        |> MaybeUtil.orLazy
                            (\() ->
                                fromEvent (Batch rest) eventCmdKey eventShiftKey eventKey
                            )

        fromMaybe : Maybe msg -> Decoder msg
        fromMaybe maybeMsg =
            case maybeMsg of
                Just msg ->
                    Decode.succeed msg

                Nothing ->
                    Decode.fail "Key Down event did not match any I was listening for"
    in
    Decode.map3
        (fromEvent <| batch keyCmds)
        (Decode.field "metaKey" Decode.bool
            |> Decode.map Command
        )
        (Decode.field "shift" Decode.bool
            |> Decode.map Shift
        )
        (Decode.field "key" Decode.string)
        |> Decode.andThen fromMaybe
        |> Browser.Events.onMouseDown
