module Document exposing
    ( Document
    , fromBody
    , map
    , toBrowserDocument
    , withTitle
    )

import Browser
import Css
import Css.Global
import Html.Styled as Html exposing (Html)
import Style.Color as Color
import Style.Margin as Margin
import Style.Padding as Padding
import Style.Size as Size
import View.Dialog as Dialog exposing (Dialog)
import View.Row as Row exposing (Row)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Document msg =
    { title : Maybe String
    , body : List (Row msg)
    , dialog : Maybe (Dialog msg)
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


fromBody : List (Row msg) -> Document msg
fromBody body =
    { title = Nothing
    , body = body
    , dialog = Nothing
    }


withTitle : String -> Document msg -> Document msg
withTitle title document =
    { document | title = Just title }


map : (a -> msg) -> Document a -> Document msg
map toMsg doc =
    { title = doc.title
    , body = List.map (Row.map toMsg) doc.body
    , dialog = Maybe.map (Dialog.map toMsg) doc.dialog
    }


toBrowserDocument : Document msg -> Browser.Document msg
toBrowserDocument doc =
    let
        globalStyling : Html msg
        globalStyling =
            [ Css.Global.everything
                [ Css.fontFamilies [ "HFNSS" ]
                , Css.color <| Color.toCss Color.content4
                , Css.fontSize <| Size.toPx Size.text
                , Css.property "-webkit-font-smoothing" "none"
                , Css.boxSizing Css.borderBox
                ]
            , Css.Global.body
                [ Css.backgroundColor <| Color.toCss Color.content1
                , Padding.toCss <| Padding.all Size.small
                , Margin.toCss <| Margin.all Size.zero
                , Css.flexDirection Css.column
                , Css.displayFlex
                , Css.height <| Css.pct 100
                ]
            ]
                |> Css.Global.global

        nonPageHtml : List (Html msg)
        nonPageHtml =
            [ Just globalStyling
            , Maybe.map Dialog.toHtml doc.dialog
            ]
                |> List.filterMap identity

        html : List (Html msg)
        html =
            nonPageHtml ++ List.map Row.toHtml doc.body
    in
    { title =
        doc.title
            |> Maybe.withDefault "Chadtech"
    , body = List.map Html.toUnstyled html
    }
