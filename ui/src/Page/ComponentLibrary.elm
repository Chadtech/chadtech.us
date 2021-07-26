module Page.ComponentLibrary exposing
    ( Modelka
    , Zpr
    , datZasedani
    , getLayout
    , handleRouteChange
    , poca
    , pohled
    , setLayout
    , ziskatZasedani
    , zmodernizovat
    )

import Html.Styled as H exposing (Html)
import Layout exposing (Layout)
import Route
import Route.ComponentLibrary as ComponentLibraryRoute exposing (Route)
import Style.Size as Size exposing (Size)
import SyntaxHighlight
import View.Button as Button
import View.Cell as Cell exposing (Cell)
import View.Menu as Menu
import View.Row as Row exposing (Row)
import View.TextField as Textfield
import View.Textarea as Textarea
import Zasedani exposing (Zasedani)



---------------------------------------------------------------
-- TYPY --
---------------------------------------------------------------


type alias Modelka =
    { layout : Layout
    , zasedani : Zasedani
    , page : Page
    , textareaField : String
    , textfield : String
    , activeOption : Int
    }


type alias Example zpr =
    { title : Maybe String
    , code : String
    , pohled : Cell zpr
    }


type Page
    = Page__Button
    | Page__Menu
    | Page__Textarea
    | Page__Textfield


type NavItem
    = NavItem__Button
    | NavItem__Menu
    | NavItem__Textarea
    | NavItem__Textfield


type Zpr
    = TextareaUpdated String
    | TextfieldUpdated String
    | OptionClicked Int



--------------------------------------------------------------------------------
-- POCA --
--------------------------------------------------------------------------------


poca : Zasedani -> Layout -> Route -> Modelka
poca zasedani layout route =
    { layout = layout
    , zasedani = zasedani
    , page = routeToPage route
    , textareaField = "This is a text area"
    , textfield = "This is a text field"
    , activeOption = 2
    }



--------------------------------------------------------------------------------
-- ROUTE HANDLING --
--------------------------------------------------------------------------------


handleRouteChange : Route -> Modelka -> Modelka
handleRouteChange route =
    datPage (routeToPage route)



--------------------------------------------------------------------------------
-- API --
--------------------------------------------------------------------------------


datZasedani : Zasedani -> Modelka -> Modelka
datZasedani zasedani modelka =
    { modelka | zasedani = zasedani }


ziskatZasedani : Modelka -> Zasedani
ziskatZasedani modelka =
    modelka.zasedani


getLayout : Modelka -> Layout
getLayout model =
    model.layout


setLayout : Layout -> Modelka -> Modelka
setLayout layout model =
    { model | layout = layout }



--------------------------------------------------------------------------------
-- HELPERS --
--------------------------------------------------------------------------------


datPage : Page -> Modelka -> Modelka
datPage page modelka =
    { modelka | page = page }


routeToPage : Route -> Page
routeToPage route =
    case route of
        ComponentLibraryRoute.Button ->
            Page__Button

        ComponentLibraryRoute.Menu ->
            Page__Menu

        ComponentLibraryRoute.Textarea ->
            Page__Textarea

        ComponentLibraryRoute.Textfield ->
            Page__Textfield


navItemToLabel : NavItem -> String
navItemToLabel navItem =
    case navItem of
        NavItem__Button ->
            "Button"

        NavItem__Menu ->
            "Menu"

        NavItem__Textarea ->
            "Textarea"

        NavItem__Textfield ->
            "Textfield"


navItemToRoute : NavItem -> Route
navItemToRoute navItem =
    case navItem of
        NavItem__Button ->
            ComponentLibraryRoute.Button

        NavItem__Menu ->
            ComponentLibraryRoute.Menu

        NavItem__Textarea ->
            ComponentLibraryRoute.Textarea

        NavItem__Textfield ->
            ComponentLibraryRoute.Textfield


pageToNavItem : Page -> NavItem
pageToNavItem page =
    case page of
        Page__Button ->
            NavItem__Button

        Page__Menu ->
            NavItem__Menu

        Page__Textarea ->
            NavItem__Textarea

        Page__Textfield ->
            NavItem__Textfield


navItems : List NavItem
navItems =
    let
        _ =
            case NavItem__Button of
                NavItem__Button ->
                    ()

                NavItem__Menu ->
                    ()

                NavItem__Textarea ->
                    ()

                NavItem__Textfield ->
                    ()
    in
    [ NavItem__Button
    , NavItem__Menu
    , NavItem__Textarea
    , NavItem__Textfield
    ]



--------------------------------------------------------------------------------
-- POHLED --
--------------------------------------------------------------------------------


pohled : Modelka -> List (Cell Zpr)
pohled modelka =
    [ nav modelka.page
    , body modelka
    ]


nav : Page -> Cell Zpr
nav page =
    let
        width : Size
        width =
            Size.extraLarge 4

        navItemView : NavItem -> Row Zpr
        navItemView navItem =
            Button.fromLabel
                (navItemToLabel navItem)
                |> Button.withLink
                    (Route.fromComponentLibraryRoute <|
                        navItemToRoute navItem
                    )
                |> Button.when (navItem == pageToNavItem page) Button.active
                |> Button.toCell
                |> Cell.withExactWidth width
                |> Row.fromCell
    in
    navItems
        |> List.map navItemView
        |> Row.withSpaceBetween Size.small
        |> Row.toCell
        |> Cell.withExactWidth width


body : Modelka -> Cell Zpr
body modelka =
    case modelka.page of
        Page__Button ->
            buttonPage

        Page__Menu ->
            menuPage modelka

        Page__Textarea ->
            textareaPage modelka

        Page__Textfield ->
            textfieldPage modelka


menuPage : Modelka -> Cell Zpr
menuPage modelka =
    let
        simpleExample : Example Zpr
        simpleExample =
            let
                optionFromInt :
                    { activeOption : Int }
                    -> Int
                    -> Menu.Item Zpr
                optionFromInt args int =
                    Menu.itemFromLabel
                        ("Option " ++ String.fromInt int)
                        |> Menu.itemIsActive (args.activeOption == int)
                        |> Menu.itemOnClick (OptionClicked int)

                menu : Cell Zpr
                menu =
                    List.map
                        (optionFromInt
                            { activeOption = modelka.activeOption }
                        )
                        (List.range 0 5)
                        |> Menu.itemsToCell
            in
            { title = Nothing
            , code =
                """
optionFromInt :
    { activeOption : Int }
    -> Int
    -> Menu.Item Zpr
optionFromInt args int =
    Menu.itemFromLabel
        ("Option " ++ String.fromInt int)
        |> Menu.itemIsActive (args.activeOption == int)
        |> Menu.itemOnClick (OptionClicked int)

menu : Cell Zpr
menu =
    List.map
        (optionFromInt
            { activeOption = modelka.activeOption }
        )
        (List.range 0 5)
        |> Menu.itemsToCell
            """
            , pohled =
                [ menu ]
                    |> List.map Row.fromCell
                    |> Row.toCell
            }
    in
    [ simpleExample ]
        |> List.map exampleToRow
        |> Row.toCell


textfieldPage : Modelka -> Cell Zpr
textfieldPage modelka =
    let
        simpleExample : Example Zpr
        simpleExample =
            let
                textfield : Cell Zpr
                textfield =
                    Textfield.simple
                        modelka.textfield
                        TextfieldUpdated
                        |> Textfield.toCell
            in
            { title = Nothing
            , code =
                """
textfield : Cell Zpr
textfield =
    Textfield.simple
        "${value}"
        TextfieldUpdated
        |> Textfield.toCell
            """
                    |> String.replace "${value}" modelka.textfield
            , pohled =
                [ textfield ]
                    |> List.map Row.fromCell
                    |> Row.toCell
            }
    in
    [ simpleExample ]
        |> List.map exampleToRow
        |> Row.toCell


textareaPage : Modelka -> Cell Zpr
textareaPage modelka =
    let
        simpleExample : Example Zpr
        simpleExample =
            let
                textarea : Cell Zpr
                textarea =
                    Textarea.simple
                        modelka.textareaField
                        TextareaUpdated
                        |> Textarea.toCell
            in
            { title = Nothing
            , code =
                """
textarea : Cell Zpr
textarea =
    Textarea.simple
        "${value}"
        TextareaUpdated
        |> Textarea.toCell
            """
                    |> String.replace "${value}" modelka.textfield
            , pohled =
                [ textarea ]
                    |> List.map Row.fromCell
                    |> Row.toCell
            }
    in
    [ simpleExample ]
        |> List.map exampleToRow
        |> Row.toCell


buttonPage : Cell Zpr
buttonPage =
    let
        simpleExample : Example Zpr
        simpleExample =
            let
                button : Cell zpr
                button =
                    Button.fromLabel "Button"
                        |> Button.toCell
            in
            { title = Nothing
            , code = """
button : Cell zpr
button =
    Button.fromLabel "Button"
        |> Button.toCell
            """
            , pohled =
                [ button ]
                    |> List.map Row.fromCell
                    |> Row.toCell
            }
    in
    [ simpleExample ]
        |> List.map exampleToRow
        |> Row.toCell


exampleToRow : Example zpr -> Row zpr
exampleToRow example =
    let
        codeHtml : List (Html zpr)
        codeHtml =
            case SyntaxHighlight.elm example.code of
                Ok code ->
                    [ SyntaxHighlight.useTheme SyntaxHighlight.monokai
                    , SyntaxHighlight.toBlockHtml Nothing code
                    ]
                        |> List.map H.fromUnstyled

                Err _ ->
                    [ H.text "ERROR PARSING CODE" ]
    in
    [ Cell.fromHtml codeHtml
        |> Cell.indent
    , example.pohled
    ]
        |> Cell.withSpaceBetween Size.medium
        |> Row.fromCells



---------------------------------------------------------------
-- ZMODERNIZOVAT --
---------------------------------------------------------------


zmodernizovat : Zpr -> Modelka -> Modelka
zmodernizovat zpr modelka =
    case zpr of
        TextareaUpdated str ->
            { modelka | textareaField = str }

        TextfieldUpdated str ->
            { modelka | textfield = str }

        OptionClicked index ->
            { modelka | activeOption = index }
