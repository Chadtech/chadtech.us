module Style.Border exposing
    ( Border
    , indent
    , outdent
    , toCss
    )

import Css
import Style.Color as Color exposing (Color)
import Style.Size as Size



--------------------------------------------------------------------------------
-- TYPES --
--------------------------------------------------------------------------------


type Border
    = Outdent
    | Indent



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


toCss : Border -> Css.Style
toCss border =
    let
        borderSize : Css.Px
        borderSize =
            Size.toPx Size.extraSmall

        upperLeft : Color -> Css.Style
        upperLeft color =
            [ Css.borderTop3 borderSize Css.solid (Color.toCss color)
            , Css.borderLeft3 borderSize Css.solid (Color.toCss color)
            ]
                |> Css.batch

        lowerRight : Color -> Css.Style
        lowerRight color =
            [ Css.borderRight3 borderSize Css.solid (Color.toCss color)
            , Css.borderBottom3 borderSize Css.solid (Color.toCss color)
            ]
                |> Css.batch
    in
    case border of
        Outdent ->
            [ upperLeft Color.content3
            , lowerRight Color.content0
            ]
                |> Css.batch

        Indent ->
            [ upperLeft Color.content0
            , lowerRight Color.content3
            ]
                |> Css.batch


outdent : Border
outdent =
    Outdent


indent : Border
indent =
    Indent
