module Style.Color exposing
    ( background0, background1, background2, background3, background4
    , content0, content1, content2, content3, content4, content5
    , important0, important1
    , decoration0, decoration1
    , problem0, problem1
    , success0, success1
    , Color, toCss
    )

{-| Colors in the Chadtech design standard v2.0


# Background

@docs background0, background1, background2, background3, background4


# Content

@docs content0, content1, content2, content3, content4, content5


# Important

@docs important0, important1


# Decoration

@docs decoration0, decoration1


# Problem

@docs problem0, problem1


# Success

@docs success0, success1

-}

import Css


type Color
    = Background Degree__5
    | Content Degree__6
    | Important Degree__2
    | Decoration Degree__2
    | Problem Degree__2
    | Success Degree__2


type Degree__2
    = D2__Low
    | D2__High


type Degree__5
    = D5__0
    | D5__1
    | D5__2
    | D5__3
    | D5__4


type Degree__6
    = D6__0
    | D6__1
    | D6__2
    | D6__3
    | D6__4
    | D6__5


toCss : Color -> Css.Color
toCss color =
    case color of
        Background degree ->
            case degree of
                D5__0 ->
                    Css.hex "#030907"

                D5__1 ->
                    Css.hex "#071D10"

                D5__2 ->
                    Css.hex "#082208"

                D5__3 ->
                    Css.hex "#142909"

                D5__4 ->
                    Css.hex "#30371A"

        Content degree ->
            case degree of
                D6__0 ->
                    Css.hex "#131610"

                D6__1 ->
                    Css.hex "#2C2826"

                D6__2 ->
                    Css.hex "#57524F"

                D6__3 ->
                    Css.hex "#807672"

                D6__4 ->
                    Css.hex "#B0A69A"

                D6__5 ->
                    Css.hex "#E0D6CA"

        Important degree ->
            case degree of
                D2__Low ->
                    Css.hex "#B39F4B"

                D2__High ->
                    Css.hex "#E3D34B"

        Decoration degree ->
            case degree of
                D2__Low ->
                    Css.hex "#175CFE"

                D2__High ->
                    Css.hex "#0ABAB5"

        Problem degree ->
            case degree of
                D2__Low ->
                    Css.hex "#651A20"

                D2__High ->
                    Css.hex "#F21D23"

        Success degree ->
            case degree of
                D2__Low ->
                    Css.hex "#366317"

                D2__High ->
                    Css.hex "#0ACA1A"


background : Degree__5 -> Color
background =
    Background


{-| #030907
-}
background0 : Color
background0 =
    background D5__0


{-| #071D10
-}
background1 : Color
background1 =
    background D5__1


{-| #082208
-}
background2 : Color
background2 =
    background D5__2


{-| #142909
-}
background3 : Color
background3 =
    background D5__3


{-| #30371A
-}
background4 : Color
background4 =
    background D5__4


content : Degree__6 -> Color
content =
    Content


{-| #131610
-}
content0 : Color
content0 =
    content D6__0


{-| #2C2826
-}
content1 : Color
content1 =
    content D6__1


{-| #57524F
-}
content2 : Color
content2 =
    content D6__2


{-| #807672
-}
content3 : Color
content3 =
    content D6__3


{-| #B0A69A
-}
content4 : Color
content4 =
    content D6__4


{-| #E0D6CA
-}
content5 : Color
content5 =
    content D6__5


important : Degree__2 -> Color
important =
    Important


{-| #B39F4B
-}
important0 : Color
important0 =
    important D2__Low


{-| #E3D34B
-}
important1 : Color
important1 =
    important D2__High


decoration : Degree__2 -> Color
decoration =
    Decoration


{-| #175CFE
-}
decoration0 : Color
decoration0 =
    decoration D2__Low


{-| #0ABAB5
-}
decoration1 : Color
decoration1 =
    decoration D2__High


problem : Degree__2 -> Color
problem =
    Problem


{-| #651A20
-}
problem0 : Color
problem0 =
    problem D2__Low


{-| #F21D23
-}
problem1 : Color
problem1 =
    problem D2__High


success : Degree__2 -> Color
success =
    Success


{-| #366317
-}
success0 : Color
success0 =
    success D2__Low


{-| #0ACA1A
-}
success1 : Color
success1 =
    success D2__High
