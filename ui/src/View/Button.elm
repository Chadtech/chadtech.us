module View.Button exposing
    ( Button
    , fromLabel
    , simple
    , toCell
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

        activeStyle : Css.Style
        activeStyle =
            Css.active
                [ Border.toCss Border.indent ]

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


withLink : Route -> Button msg -> Button msg
withLink route button =
    { button | onClick = Link route }


withLinkToNewWindow : String -> Button msg -> Button msg
withLinkToNewWindow url button =
    { button | onClick = NewWindow url }


fromLabel : String -> Button msg
fromLabel label =
    fromOnClick label NoClick


simple : String -> msg -> Button msg
simple label msg =
    fromOnClick label (Event msg)


toCell : Button msg -> Cell msg
toCell button =
    Cell.fromHtml [ toHtml button ]
