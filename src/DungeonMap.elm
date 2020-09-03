module DungeonMap exposing (..)

--elm Packages
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Svg
import Svg.Attributes as SvgAtt
import Svg.Events
import Json.Decode
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Table as Table
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Radio as Radio
import Bootstrap.Form.Textarea as Textarea
import Array
import File
import ColorPicker
import Color

--our Modules
import Model exposing (..)

dungeonMapView : Model -> Html Msg
dungeonMapView model =
    Html.section [ class "content-box is-widescreen" ]
            [ div [ class "section" ]
                [ Grid.row [ Row.attrs <| [style "margin-bottom" "2%"] ]
                    [ Grid.col [ Col.xs8 ]
                        [ Textarea.textarea
                            [ Textarea.rows 1
                            , Textarea.disabled
                            , Textarea.value model.activeTooltip
                            , Textarea.attrs [ class "text-area" ]
                            ]
                        ]
                    , Grid.col [ ]
                        [ Button.button
                            [ Button.attrs [ class "metalButton", style "height" "52px", style "margin-right" "2%" ]
                            , Button.onClick Pick ]
                            [ text "Karte hochladen" ]
                        , Button.button
                            [ Button.attrs [ class "metalButton", style "height" "52px" ]
                            , Button.onClick ClearCharacterList ] 
                            [ text "Karte leeren" ]
                        ]
                    ]
                , Grid.row [ ]
                    [ Grid.col [ Col.xs8 ] [ dungeonMap_Svg model ]
                    , Grid.col [] [ dungeonMap_MonsterList model]
                    ]
                ]
                , newObjectIconModal model
            ]

dungeonMap_MonsterList : Model -> Html Msg
dungeonMap_MonsterList model =
    div [ ]
        [ Table.table { options = [ Table.hover, Table.bordered ]
                      , thead =  Table.simpleThead
                          [ Table.th [Table.cellAttr <| class "mediumCopper"] [ Html.text "ID" ]
                          , Table.th [Table.cellAttr <| class "mediumCopper"] [ Html.text "Name" ]
                          , Table.th [Table.cellAttr <| class "mediumCopper"] [ Html.text "LeP" ]
                          ]
                      , tbody =
                          Table.tbody []
                            <| characters2rows model.enemy model.highlightedTableRow
                      }

        ]

characters2rows : Array.Array Character -> Int -> List (Table.Row Msg)
characters2rows chars highlighted =
    List.indexedMap
        (\i c ->
            case c of
                Enemy name health _ _ _ ->
                    Table.tr ([ Table.rowAttr (stopBubbling (AddCharacterIcon (MouseDraw (MonsterIcon (i+1) "-100" "-100" name)))) ]
                             ++ if highlighted==i+1 then [ Table.rowSecondary ] else [])
                        [ Table.td [] [Html.text <| String.fromInt (i+1)]
                        , Table.td [] [Html.text name]
                        , Table.td [] [Html.text <| String.fromInt health]
                        ]

                Hero name health ->
                    Table.tr ([ Table.rowAttr (stopBubbling (AddCharacterIcon (MouseDraw (PlayerIcon (i+1) "-100" "-100" name)))) ]
                             ++ if highlighted==i+1 then [ Table.rowSecondary ] else [])
                        [ Table.td [] [Html.text <| String.fromInt (i+1)]
                        , Table.td [] [Html.text name]
                        , Table.td [] [Html.text <| String.fromInt health]
                        ]
        )
        <| Array.toList chars



dungeonMap_Svg : Model -> Html Msg
dungeonMap_Svg model =
    div [ style "border" (if model.hover then "6px dashed #b87333" else "6px dashed #bfbfbf")
        , hijackOn "dragenter" (Json.Decode.succeed DragEnter)
        , hijackOn "dragover" (Json.Decode.succeed DragEnter)
        , hijackOn "dragleave" (Json.Decode.succeed DragLeave)
        , hijackOn "drop" dropDecoder
        ]
        [ Html.figure [ ]
           [ Svg.svg
                ([ SvgAtt.width "100%", SvgAtt.viewBox "0 0 800 550", SvgAtt.version "1.1" ]
                    ++ mouseDrawEvents model.addCharacterIcon
                )
                ([ Svg.image
                    [ SvgAtt.width "800"
                    , SvgAtt.height "550"
                    , SvgAtt.title "DungeonMap"
                    , SvgAtt.xlinkHref (Maybe.withDefault "" (List.head model.previews))
                    ] []
                ]
                    ++ svgIconList model
                    ++ newIconsView model.addCharacterIcon
                )
           ]
        ]

newObjectIconModal : Model -> Html Msg
newObjectIconModal model =
    Modal.config (CloseModal ObjectIconModal)
        |> Modal.hideOnBackdropClick True
        |> Modal.header [class "mediumCopper"]
                [ Html.h3 [][text "Neues Icon"]
                ]
        |> Modal.body [class "body"]
            [ div []
                [ div []
                    ( Radio.radioList "customradiogroup"
                        [ Radio.createCustom [ Radio.id "rdi1", Radio.inline, Radio.onClick (ChangeIcon 1), Radio.checked (1 == model.radioCheckedID) ] "Kiste"
                        , Radio.createCustom [ Radio.id "rdi2", Radio.inline, Radio.onClick (ChangeIcon 2), Radio.checked (2 == model.radioCheckedID) ] "Schlüssel"
                        , Radio.createCustom [ Radio.id "rdi3", Radio.inline, Radio.onClick (ChangeIcon 3), Radio.checked (3 == model.radioCheckedID) ] "Benutzerdefiniert"
                        ]
                    )
                , div []
                    ( [ Html.br [] []
                      , Input.text
                          [ Input.value model.iconText
                          , Input.placeholder "Beschreibung"
                          , Input.onInput ChangeIconText
                          ]
                      ]
                      ++  case model.radioCheckedID of
                              3 -> [ Html.br [] []
                                   , ColorPicker.view model.colour model.colorPicker
                                      |> Html.map ColorPickerMsg
                                   ]
                              _ -> []
                    )
                ]
            ]
            |> Modal.footer [class "mediumCopper"]
                [ Button.button
                    [ Button.attrs [onClick <| AddCharacterIcon (MouseClick (getCharIcon model.addCharacterIcon)), class "metalButton", style "margin-top" "5px" ]
                    , Button.disabled (model.radioCheckedID==0)
                    ]
                    [ text "Icon hinzufügen" ]
                ]
            |> Modal.view model.showObjectIconModal

getCharIcon : AddCharacterIconState -> CharacterIcon
getCharIcon state =
    case state of
        DrawIcon charIcon ->
            charIcon

        _ -> ObjectIcon 0 "" "" "" Nothing 0

stopBubbling : msg -> Svg.Attribute msg
stopBubbling msg =
    Html.Events.stopPropagationOn "click" (Json.Decode.map (\m -> ( m, True )) (Json.Decode.succeed msg))



svgIconList : Model -> List (Svg.Svg Msg)
svgIconList model =
    List.foldl (++) [] (List.map placeIcon (model.characterList ++ model.objectIconList))

placeIcon : CharacterIcon -> List (Svg.Svg Msg)
placeIcon s =
    let
      x = Maybe.withDefault "0" (List.head (String.split "," (getCoord s)))
      y = Maybe.withDefault "0" (List.head (List.drop 1 (String.split "," (getCoord s))))
      id = getID s
      text = getObjectText s        --Text of an ObjectIcon, for other Icons empty
      color = getColor s            --Color of a custom ObjectIcon, for others Nothing
      iconType = getIconType s
      typeID = getTypeID s
    in
    case iconType of
        "monster" ->
            [ Svg.text_ [ SvgAtt.textAnchor "middle"
                , SvgAtt.x (String.fromFloat (Maybe.withDefault 0 (String.toFloat x)))
                , SvgAtt.y (String.fromFloat (Maybe.withDefault 0 (String.toFloat y)))
                , SvgAtt.dominantBaseline "middle"
                ]
                [ Svg.text (String.fromInt id) ]
            , Svg.image
                [ SvgAtt.width "50"
                , SvgAtt.height "50"
                , SvgAtt.x (String.fromFloat (Maybe.withDefault 0 (String.toFloat x) - 25.5))
                , SvgAtt.y (String.fromFloat (Maybe.withDefault 0 (String.toFloat y) - 24.5))
                , SvgAtt.title "MonsterIcon"
                , SvgAtt.xlinkHref "src/res/icons/Enemy.svg"
                , Svg.Events.onMouseOver (HighlightTableRow id text)
                , Svg.Events.onMouseOut (HighlightTableRow 0 "")
                , Svg.Events.onClick (DeleteIcon iconType id)
                , SvgAtt.class "MonsterIcon"
                ] []
            ]

        "player" ->
            [ Svg.text_ [ SvgAtt.textAnchor "middle"
                , SvgAtt.x (String.fromFloat (Maybe.withDefault 0 (String.toFloat x)))
                , SvgAtt.y (String.fromFloat (Maybe.withDefault 0 (String.toFloat y)))
                , SvgAtt.dominantBaseline "middle"
                ]
                [ Svg.text (String.fromInt id) ]
            , Svg.image
                [ SvgAtt.width "45"
                , SvgAtt.height "45"
                , SvgAtt.x (String.fromFloat (Maybe.withDefault 0 (String.toFloat x) - 22.5))
                , SvgAtt.y (String.fromFloat (Maybe.withDefault 0 (String.toFloat y) - 22))
                , SvgAtt.title "ObjectIcon"
                , SvgAtt.xlinkHref "src/res/icons/Hero.svg"
                , Svg.Events.onMouseOver (HighlightTableRow id text)
                , Svg.Events.onMouseOut (HighlightTableRow 0 "")
                , Svg.Events.onClick (DeleteIcon iconType id)
                , SvgAtt.class "PlayerIcon"
                ] []
            ]

        "object" ->
            case getIconPath typeID of
                "custom" -> [ Svg.circle
                                [ SvgAtt.id (String.fromInt id)
                                , SvgAtt.cx x
                                , SvgAtt.cy y
                                , SvgAtt.r "10"
                                , SvgAtt.style (buildCustomObjectIconStyle color)
                                , Svg.Events.onMouseOver (ToolTipMsg text True)
                                , Svg.Events.onMouseOut (ToolTipMsg "" False)
                                , SvgAtt.class "ObjectIcon"
                                , Svg.Events.onClick (DeleteIcon iconType id)
                                ]
                                []
                            ]


                _ -> [ Svg.image
                         [ SvgAtt.style "width:25px;height:25px;"
                         , SvgAtt.x (String.fromFloat (Maybe.withDefault 0 (String.toFloat x) - 11.5))
                         , SvgAtt.y (String.fromFloat (Maybe.withDefault 0 (String.toFloat y) - 11.5))
                         , SvgAtt.xlinkHref (getIconPath typeID)
                         , Svg.Events.onMouseOver (ToolTipMsg text True)
                         , Svg.Events.onMouseOut (ToolTipMsg "" False)
                         , SvgAtt.class "ObjectIcon"
                         , Svg.Events.onClick (DeleteIcon iconType id)
                         ] []
                     ]

        _ ->
            []

getColor : CharacterIcon -> (Maybe Color.Color)
getColor object = 
    case object of
        MonsterIcon _ _ _ _ ->
            Nothing

        PlayerIcon _ _ _ _ ->
            Nothing

        ObjectIcon _ _ _ _ c _ ->
            c

getIconPath : Int -> String
getIconPath id =
    case id of
        1 -> "src/res/icons/chest.png"
        2 -> "src/res/icons/key.png"
        3 -> "custom"   --a svg-shape rather than an .png file, see placeIcon function
        _ -> ""

getIconType : CharacterIcon -> String
getIconType object =
    case object of
        MonsterIcon _ _ _ _ ->
            "monster"

        PlayerIcon _ _ _ _ ->
            "player"

        ObjectIcon _ _ _ _ _ _ ->
            "object"

getCoord : CharacterIcon -> String
getCoord object =
    case object of
        MonsterIcon _ x y _ ->
            x ++ "," ++ y

        PlayerIcon _ x y _ ->
            x ++ "," ++ y

        ObjectIcon _ x y _ _ _ ->
            x ++ "," ++ y

getID : CharacterIcon -> Int
getID object =
    case object of
        MonsterIcon i _ _ _ -> 
            i

        PlayerIcon i _ _ _ ->
            i

        ObjectIcon _ _ _ _ _ ident ->
            ident

getTypeID : CharacterIcon -> Int
getTypeID object =
    case object of
        ObjectIcon i _ _ _ _ _ ->
            i

        _ ->
            0

getObjectText : CharacterIcon -> String
getObjectText object =
    case object of
        MonsterIcon _ _ _ name ->
            name

        PlayerIcon _ _ _ name ->
            name
        ObjectIcon _ _ _ t _ _ ->
            t

buildCustomObjectIconStyle : Maybe Color.Color -> String
buildCustomObjectIconStyle color =
    "stroke:black;stroke-width:4;fill:" ++ Color.toCssString (Maybe.withDefault Color.black color)

mouseDrawEvents : AddCharacterIconState -> List (Svg.Attribute Msg)
mouseDrawEvents addCharacterIcon =
    case addCharacterIcon of
        DrawIcon characterIcon ->
            case characterIcon of
                PlayerIcon i _ _ n ->
                    [ Svg.Events.onClick (AddCharacterIcon (MouseClick characterIcon))
                    , onMouseMove (positionToIconCenter "player" n i)
                    ]

                MonsterIcon i _ _ n ->
                    [ Svg.Events.onClick (AddCharacterIcon (MouseClick characterIcon))
                    , onMouseMove (positionToIconCenter "monster" n i)
                    ]

                ObjectIcon i _ _ _ _ _ ->
                    [ Svg.Events.onClick (ShowModal ObjectIconModal)
                    , onMouseMove (positionToIconCenter "object" "" i)
                    ]

        DrawingInactive ->
                [ onMouseMove (positionToIconCenter "object" "" 0)
                ]


onMouseMove : (MousePosition -> msg) -> Svg.Attribute msg
onMouseMove mapMousePositionToMsg =
    Svg.Events.on "mousemoveWithCoordinates" (Json.Decode.map mapMousePositionToMsg mousePosition)


mousePosition : Json.Decode.Decoder MousePosition
mousePosition =
    Json.Decode.map2 MousePosition
        (Json.Decode.at [ "detail", "x" ] Json.Decode.float)
        (Json.Decode.at [ "detail", "y" ] Json.Decode.float)

positionToIconCenter : String -> String -> Int -> MousePosition -> Msg
positionToIconCenter icon name i position =
    case icon of
        "player" ->
            AddCharacterIcon (MouseDraw (PlayerIcon i (String.fromFloat position.x) (String.fromFloat position.y) name))

        "monster" ->
            AddCharacterIcon (MouseDraw (MonsterIcon i (String.fromFloat position.x) (String.fromFloat position.y) name))

        "object" ->
            AddCharacterIcon (MouseDraw (ObjectIcon i (String.fromFloat position.x) (String.fromFloat position.y) "" Nothing 0 ))

        _ ->
            DoNothing

newIconsView : AddCharacterIconState -> List (Svg.Svg Msg)
newIconsView addCharacterIcon =
    case addCharacterIcon of
        DrawIcon characterIcon ->
            case characterIcon of
                ObjectIcon _ _ _ _ _ _ ->
                    []

                PlayerIcon _ x y _ ->
                    placeIcon characterIcon
                        ++  [ Svg.rect
                                [ SvgAtt.width "800"
                                , SvgAtt.height "600"
                                , SvgAtt.x "0"
                                , SvgAtt.y "0"
                                , SvgAtt.style "fill:blue;stroke:pink;stroke-width:5;fill-opacity:0.1;stroke-opacity:0.9"
                                ]
                                []
                            ]

                MonsterIcon _ x y _ ->
                    placeIcon characterIcon
                        ++  [ Svg.rect
                                [ SvgAtt.width "800"
                                , SvgAtt.height "600"
                                , SvgAtt.x "0"
                                , SvgAtt.y "0"
                                , SvgAtt.style "fill:blue;stroke:pink;stroke-width:5;fill-opacity:0.1;stroke-opacity:0.9"
                                ]
                                []
                            ]
        _ ->
            []

dropDecoder : Json.Decode.Decoder Msg
dropDecoder =
  Json.Decode.at ["dataTransfer","files"] (Json.Decode.oneOrMore GotFiles File.decoder)


hijackOn : String -> Json.Decode.Decoder msg -> Html.Attribute msg
hijackOn event decoder =
  Html.Events.preventDefaultOn event (Json.Decode.map hijack decoder)


hijack : msg -> (msg, Bool)
hijack msg =
  (msg, True)
