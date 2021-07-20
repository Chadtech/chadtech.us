module Analytics exposing
    ( Event
    , Modelka
    , Zpr
    , name
    , none
    , poca
    , record
    , subscriptions
    , toCmd
    , withProp
    , zmodernizovat
    )

import Json.Encode as Encode
import Ports.ToJs as ToJs
import Time



-------------------------------------------------------------------------------
-- TYPY --
-------------------------------------------------------------------------------


type alias Modelka =
    { events : List EventModelka }


type Event
    = Event EventModelka
    | None


type alias EventModelka =
    { name : String
    , props : List ( String, Encode.Value )
    }


type Zpr
    = WaitTimeExpired Time.Posix



-------------------------------------------------------------------------------
-- POCA --
-------------------------------------------------------------------------------


poca : Modelka
poca =
    { events = [] }



-------------------------------------------------------------------------------
-- API --
-------------------------------------------------------------------------------


record : Event -> Modelka -> Modelka
record event modelka =
    case event of
        Event eventModelka ->
            { modelka | events = eventModelka :: modelka.events }

        None ->
            modelka


name : String -> Event
name str =
    Event { name = str, props = [] }


none : Event
none =
    None


withProp : String -> Encode.Value -> Event -> Event
withProp propName propVal event =
    case event of
        None ->
            None

        Event e ->
            Event { name = e.name, props = ( propName, propVal ) :: e.props }


toCmd : Event -> Cmd msg
toCmd event =
    case event of
        Event payload ->
            ToJs.type_ "analytics_event"
                |> ToJs.fieldsBody
                    [ Tuple.pair "eventName" <| Encode.string payload.name
                    , Tuple.pair "props" <| Encode.object payload.props
                    ]
                |> ToJs.send

        None ->
            Cmd.none



---------------------------------------------------------------
-- ZMODERNIZOVAT --
---------------------------------------------------------------


zmodernizovat : { zasedaniId : String } -> Zpr -> Modelka -> ( Modelka, Cmd Zpr )
zmodernizovat args zpr modelka =
    case zpr of
        WaitTimeExpired _ ->
            Debug.todo "WAIT TIME EXPIRED"



---------------------------------------------------------------
-- SUBSCRIPTION --
---------------------------------------------------------------


subscriptions : Sub Zpr
subscriptions =
    Time.every (10 * 1000) WaitTimeExpired
