module Main exposing (main)

import Browser
import Html exposing (Html, button, div, text, br, h1, h2, ul, li, b, a)
import Html.Events exposing (onClick)
import Html.Attributes as Attr exposing (href, class)
import Json.Decode

type alias Model =
    { count : Int }


initialModel : Model
initialModel =
    { count = 0 }

init : () -> (Model, Cmd Msg)
init _ = 
    (initialModel
    , Cmd.none
    )

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


type Msg
    = Increment
    | Decrement


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        _ -> (model, Cmd.none)


view : Model -> Html Msg
view model =
    div []
        [ header
        , body
        , footer
        ]

body : Html Msg
body =
    div []
        [text "Hier kommt Inhalt rein :)"
        ]

header : Html Msg
header =
    Html.section [class "hero is-primary is-bold animate__animated animate__fadeInDown"]
            [ div [class "hero-body"]
                [ div [class "container"]
                    [ h1 [class "title"] [text "Pen & Paper Manager"]
                    , h2 [class "subtitle"] [text "Für \"Das schwarze Auge\" Version 5"]
                    ]
                ]
            ]

footer : Html Msg
footer =
    Html.footer [class "footer animate__animated animate__fadeInUp"]
            [ div [class "content has-text-centered"]
                [ Html.p [] [ text "Entwickelt von Laura Spilling und Stefan Kranz" ]
                , Html.p [] [ text "Einführung in das World Wide Web" ]
                ]
            ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
