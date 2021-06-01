module View.Button exposing
    ( Button
    , active
    , fromLabel
    , onClick
    , simple
    , toCell
    , toRow
    , when
    , withLink
    , withLinkToNewWindow
    )

import Css
import Html.Styled as H exposing (Attribute, Html)
import Html.Styled.Attributes as A
import Html.Styled.Events as Ev
import Route exposing (Route)
import Style.Border as Border exposing (Border)
import Style.Color as Color exposing (Color)
import Style.Padding as Padding
import Style.Size as Size
import View.Cell as Cell exposing (Cell)
import View.Row as Row exposing (Row)



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type alias Button msg =
    { onClick : Click msg
    , label : String
    , active : Bool
    }


type Click msg
    = Event msg
    | Link Route
    | NewWindow String
    | NoClick



--------------------------------------------------------------------------------
-- IMPLEMENTATION --
--------------------------------------------------------------------------------


toHtml : Button msg -> Html msg
toHtml button =
    let
        tag : List (Attribute msg) -> List (Html msg) -> Html msg
        tag =
            case button.onClick of
                Event _ ->
                    H.button

                Link _ ->
                    H.a

                NewWindow _ ->
                    H.a

                NoClick ->
                    H.button

        backgroundColor : Color
        backgroundColor =
            Color.content1

        border : Border
        border =
            if button.active then
                Border.indent

            else
                Border.outdent

        textHighlight : Css.Style
        textHighlight =
            Css.color <| Color.toCss Color.content5

        activeStyle : Css.Style
        activeStyle =
            let
                baseActiveStyle : Css.Style
                baseActiveStyle =
                    [ Border.toCss Border.indent
                    , textHighlight
                    ]
                        |> Css.batch
            in
            if button.active then
                baseActiveStyle

            else
                Css.active
                    [ baseActiveStyle ]

        hoverStyle : Css.Style
        hoverStyle =
            Css.hover
                [ textHighlight ]

        styles : List Css.Style
        styles =
            [ Css.backgroundColor <| Color.toCss backgroundColor
            , Css.outline Css.none
            , Padding.toCss <| Padding.all Size.medium
            , Border.toCss border
            , Css.width <| Css.pct 100
            , Css.display Css.inlineBlock
            , Css.textDecoration Css.none
            , Css.textAlign Css.center
            , activeStyle
            , hoverStyle
            ]

        clickAttrs : List (Attribute msg)
        clickAttrs =
            case button.onClick of
                Event msg ->
                    [ Ev.onClick msg ]

                Link route ->
                    [ Route.href route ]

                NewWindow url ->
                    [ A.href url
                    , A.target "_blank"
                    ]

                NoClick ->
                    []

        baseAttrs : List (Attribute msg)
        baseAttrs =
            [ A.css styles
            ]

        attrs : List (Attribute msg)
        attrs =
            baseAttrs ++ clickAttrs
    in
    tag attrs
        [ H.text button.label ]


fromOnClick : String -> Click msg -> Button msg
fromOnClick label click =
    { onClick = click
    , label = label
    , active = False
    }



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


when : Bool -> (Button zpr -> Button zpr) -> Button zpr -> Button zpr
when cond f button =
    if cond then
        f button

    else
        button


active : Button zpr -> Button zpr
active button =
    { button | active = True }


onClick : zpr -> Button zpr -> Button zpr
onClick zpr button =
    { button | onClick = Event zpr }


withLink : Route -> Button zpr -> Button zpr
withLink route button =
    { button | onClick = Link route }


withLinkToNewWindow : String -> Button zpr -> Button zpr
withLinkToNewWindow url button =
    { button | onClick = NewWindow url }


fromLabel : String -> Button zpr
fromLabel label =
    fromOnClick label NoClick


simple : String -> zpr -> Button zpr
simple label zpr =
    fromOnClick label (Event zpr)


toCell : Button zpr -> Cell zpr
toCell button =
    Cell.fromHtml [ toHtml button ]


toRow : Button zpr -> Row zpr
toRow =
    toCell >> Row.fromCell
