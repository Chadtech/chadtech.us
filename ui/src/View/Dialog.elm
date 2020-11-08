module View.Dialog exposing
    ( Dialog
    , map
    , toHtml
    )

import Html.Styled as H exposing (Html)
import Html.Styled.Attributes as A
import Style.Border as Border
import Util.List as ListUtil
import View.Dialog.Header as Header exposing (Header)
import View.Row as Row exposing (Row)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Dialog msg =
    { header : Maybe (Header msg)
    , body : List (Row msg)
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


map : (a -> msg) -> Dialog a -> Dialog msg
map toMsg dialog =
    { header = Maybe.map (Header.map toMsg) dialog.header
    , body = List.map (Row.map toMsg) dialog.body
    }


toHtml : Dialog msg -> Html msg
toHtml dialog =
    H.div
        [ A.css
            [ Border.toCss Border.outdent ]
        ]
        (ListUtil.maybeCons
            (Maybe.map Header.toRow dialog.header)
            dialog.body
            |> List.map Row.toHtml
        )
