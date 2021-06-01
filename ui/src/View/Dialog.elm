module View.Dialog exposing
    ( Dialog
    , first
    , fromBody
    , map
    , none
    , toHtml
    , withHeader
    )

import Css
import Html.Styled as H exposing (Html)
import Html.Styled.Attributes as A
import Style.Border as Border
import Util.List as ListUtil
import View.Dialog.Header as Header exposing (Header)
import View.Row as Row exposing (Row)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type Dialog zpr
    = Open (Modelka zpr)
    | None


type alias Modelka zpr =
    { header : Maybe (Header zpr)
    , body : List (Row zpr)
    }



--------------------------------------------------------------------------------
-- INTERNAL HELPERS --
--------------------------------------------------------------------------------


mapModelka : (Modelka zpr -> Modelka zpr) -> Dialog zpr -> Dialog zpr
mapModelka fn dialog =
    case dialog of
        Open modelka ->
            Open <| fn modelka

        None ->
            None


setHeader : Header zpr -> Modelka zpr -> Modelka zpr
setHeader header modelka =
    { modelka | header = Just header }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


none : Dialog zpr
none =
    None


withHeader : Header zpr -> Dialog zpr -> Dialog zpr
withHeader header =
    mapModelka (setHeader header)


fromBody : List (Row zpr) -> Dialog zpr
fromBody rows =
    Open
        { header = Nothing
        , body = rows
        }


map : (a -> zpr) -> Dialog a -> Dialog zpr
map toZpr dialog =
    case dialog of
        Open modelka ->
            Open
                { header = Maybe.map (Header.map toZpr) modelka.header
                , body = List.map (Row.map toZpr) modelka.body
                }

        None ->
            None


first : List (() -> Dialog zpr) -> Dialog zpr
first dialogFns =
    case dialogFns of
        dialogFn :: rest ->
            case dialogFn () of
                None ->
                    first rest

                dialog ->
                    dialog

        [] ->
            None


toHtml : Dialog zpr -> Html zpr
toHtml dialog =
    case dialog of
        Open modelka ->
            H.div
                [ A.css
                    [ Border.toCss Border.outdent
                    , Css.position Css.absolute
                    , Css.left (Css.pct 50)
                    , Css.top (Css.pct 50)
                    , Css.transform (Css.translate2 (Css.pct -50) (Css.pct -50))
                    ]
                ]
                (ListUtil.maybeCons
                    (Maybe.map Header.toRow modelka.header)
                    modelka.body
                    |> List.map Row.toHtml
                )

        None ->
            H.text ""
