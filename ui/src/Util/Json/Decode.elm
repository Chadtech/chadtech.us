module Util.Json.Decode exposing (errorToSensitiveString)

import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode


errorToSensitiveString : { sensitive : Bool } -> Error -> String
errorToSensitiveString args error =
    errorToSensitiveStringHelp args error []


errorToSensitiveStringHelp : { sensitive : Bool } -> Error -> List String -> String
errorToSensitiveStringHelp args error context =
    let
        indent : String -> String
        indent str =
            String.join "\n    " (String.split "\n" str)
    in
    case error of
        Decode.Field f err ->
            let
                isSimple =
                    case String.uncons f of
                        Nothing ->
                            False

                        Just ( char, rest ) ->
                            Char.isAlpha char && String.all Char.isAlphaNum rest

                fieldName =
                    if isSimple then
                        "." ++ f

                    else
                        "['" ++ f ++ "']"
            in
            errorToSensitiveStringHelp args err (fieldName :: context)

        Decode.Index i err ->
            let
                indexName =
                    "[" ++ String.fromInt i ++ "]"
            in
            errorToSensitiveStringHelp args err (indexName :: context)

        Decode.OneOf errors ->
            case errors of
                [] ->
                    "Ran into a Json.Decode.oneOf with no possibilities"
                        ++ (case context of
                                [] ->
                                    "!"

                                _ ->
                                    " at json" ++ String.join "" (List.reverse context)
                           )

                [ err ] ->
                    errorToSensitiveStringHelp args err context

                _ ->
                    let
                        errorOneOf : Int -> Error -> String
                        errorOneOf i e =
                            "\n\n(" ++ String.fromInt (i + 1) ++ ") " ++ indent (errorToSensitiveString args e)

                        starter =
                            case context of
                                [] ->
                                    "Json.Decode.oneOf"

                                _ ->
                                    "The Json.Decode.oneOf at json" ++ String.join "" (List.reverse context)

                        introduction =
                            starter ++ " failed in the following " ++ String.fromInt (List.length errors) ++ " ways:"
                    in
                    String.join "\n\n" (introduction :: List.indexedMap errorOneOf errors)

        Decode.Failure msg _ ->
            let
                introduction =
                    case context of
                        [] ->
                            "Problem with the given value:\n\n"

                        _ ->
                            "Problem with the value at json" ++ String.join "" (List.reverse context) ++ ":\n\n    "
            in
            introduction ++ "\n\n" ++ msg
