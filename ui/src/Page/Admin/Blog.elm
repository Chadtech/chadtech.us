module Page.Admin.Blog exposing
    ( Flags
    , Modelka
    , Zpr
    , load
    , pendingRequests
    , poca
    , pohled
    , zmodernizovat
    )

import Api
import View.Row exposing (Row)



---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type alias Modelka =
    { api : Api.Modelka }


type Zpr
    = Zpr



--------------------------------------------------------------------------------
-- POCA --
--------------------------------------------------------------------------------


type alias Flags =
    {}


poca : Flags -> Modelka
poca flags =
    { api = Api.init }


load : (Api.Response Flags -> msg) -> Cmd msg
load toMsg =
    Cmd.none



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


pendingRequests : Modelka -> Api.PendingRequestCount
pendingRequests modelka =
    Api.pendingRequests modelka.api



--------------------------------------------------------------------------------
-- ZMODERNIZOVAT --
--------------------------------------------------------------------------------


zmodernizovat : Zpr -> Modelka -> ( Modelka, Cmd Zpr )
zmodernizovat zpr modelka =
    case zpr of
        Zpr ->
            ( modelka, Cmd.none )



--------------------------------------------------------------------------------
-- POHLED --
--------------------------------------------------------------------------------


pohled : Modelka -> List (Row Zpr)
pohled modelka =
    []
