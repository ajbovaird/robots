import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List exposing (..)
import String exposing (toList)

main : Program Never Model Msg
main = 
    Html.program 
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
    }

type alias World = List PlaceInWorld 
type alias PlaceInWorld = (House, List Robot, Presents)

type alias House = 
    { x : Int
    , y : Int
}

type alias Robots = List Robot
type alias Robot = 
    { id : Int 
    }

type alias Moves = List Move
type alias Move = 
    { changeX : Int
    , changeY : Int
}

type alias Presents = Int
type alias RobotMove = (Robot, Move)
type alias RobotMoves = List RobotMove
type alias RobotHouse = (Robot, House)
type alias RobotHouses = List RobotHouse

origin : House
origin = { x = 0, y = 0 }

initialWorld : List Robot -> World
initialWorld robots = [ (origin, robots, 1) ]

moveUp : Move
moveUp = { changeX = 0, changeY = 1  }

moveRight : Move
moveRight = { changeX = 1, changeY = 0 }

moveDown : Move
moveDown = { changeX = 0, changeY = -1  }

moveLeft : Move
moveLeft = { changeX = -1, changeY = 0  }

undefinedMove : Move
undefinedMove = { changeX = 0, changeY = 0 }

-- MODEL
type alias Model = 
    { world : World
    , moves : Moves
    , robots : Robots
    , inputtedMoves : String
    , numberOfRobots : Int
    , currentRobotPositions : RobotHouses
    , remainingRobotMoves : RobotMoves
    , housesWithPresentsAboveThreshold : String
    , numberOfPresentsThreshold : Presents
    , totalPresentsDelivered : Presents
}

infinity : String
infinity = "∞"

initialModel : Model
initialModel =
    { world = []
    , moves = []
    , robots = []
    , inputtedMoves = ""
    , numberOfRobots = 1
    , currentRobotPositions = []
    , remainingRobotMoves = [] 
    , housesWithPresentsAboveThreshold = infinity
    , numberOfPresentsThreshold = 0
    , totalPresentsDelivered = 0
    }

init : (Model, Cmd Msg)
init =
    let
        model = initialModel 
    in
        (model, Cmd.none)

-- Update
type Msg 
    = Robots String
    | Moves String
    | RunSimulation
    | Step
    | Threshold String

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Robots input ->
            let 
                numberOfRobots = 
                    if parseIntFromString input > 0 then
                        parseIntFromString input
                    else
                        1
            in
                ({ initialModel | numberOfRobots = numberOfRobots, inputtedMoves = model.inputtedMoves }, Cmd.none)
        Moves input ->
            ({ initialModel | inputtedMoves = input, numberOfRobots = model.numberOfRobots }, Cmd.none)
        RunSimulation ->
            let 
                (robots, moves, updatedWorld, currentRobotPositions, updatedRemainingMoves, totalPresents) = runSimulation model
            in 
                ( { model | world = updatedWorld, robots = robots, moves = moves, currentRobotPositions = currentRobotPositions, remainingRobotMoves = updatedRemainingMoves, totalPresentsDelivered = totalPresents, numberOfPresentsThreshold = 0, housesWithPresentsAboveThreshold = infinity }, Cmd.none)
        Step ->
            let
                (robots, moves, updatedWorld, currentRobotPositions, updatedRemainingMoves, totalPresents) = runStep model
            in
                ( { model | world = updatedWorld, robots = robots, moves = moves, currentRobotPositions = currentRobotPositions, remainingRobotMoves = updatedRemainingMoves, totalPresentsDelivered = totalPresents, numberOfPresentsThreshold = 0, housesWithPresentsAboveThreshold = infinity }, Cmd.none)
        Threshold input ->
            let 
                n = parseIntFromString input
                housesWithPresents = 
                    if n == 0 then
                        infinity
                    else
                        List.filter (\(h, rs, p) -> p >= n) model.world
                        |> List.length
                        |> toString
            in
                ({ model | numberOfPresentsThreshold = n, housesWithPresentsAboveThreshold = housesWithPresents }, Cmd.none)

-- SUBSCRIPTIONS
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- VIEW
view : Model -> Html Msg
view model = 
    div [] 
        [ div [style [("padding", "10px")]]
            [ label [ for "numRobots" ] [text "# Robots: "] 
            , input [ id "numRobots", type_ "number", Html.Attributes.min "1", onInput Robots, value (toString model.numberOfRobots) ] []
            ] 
        , div [style [("padding", "10px")]]
            [ label [for "moves" ] [text "Moves: "] 
            , input [ id "moves", type_ "text", onInput Moves, value model.inputtedMoves ] []
            ]
        , div [style [("padding", "10px")]]
            [ button [ onClick RunSimulation ] [ text "Run Full Simulation" ] 
            , button [ onClick Step ] [ text "Step Into Single Turn" ] 
            ]
        , div [style [("padding", "10px")]]
            [ label [ for "threshold" ] [text "Houses With At Least "] 
            , input [ id "threshold", type_ "number", Html.Attributes.min "0", onInput Threshold, value (toString model.numberOfPresentsThreshold), style [("width", "50px")] ] []
            , span [] [ text (" Presents = " ++ model.housesWithPresentsAboveThreshold) ]
            ] 
        , div [style [("padding", "10px")]]
            [ span [] [ text ("Total Presents Delivered = " ++ (toString model.totalPresentsDelivered)) ]
            ] 
        , div [ style [("padding", "10px"), ("display", "flex")] ]
            [ div [ style [("padding", "10px")] ]
                [ table [ style [("border", "1px solid black"), ("min-width", "200px")] ] 
                    [ caption [] [ text "Robot Positions" ] 
                    , thead [] 
                        [ tr [] 
                            [ th [] [ text "Id" ]
                            , th [] [ text "Location" ]
                        ]
                    ]
                    , tbody [] (List.map robotRow model.currentRobotPositions)
                    ]   
                ]
            ]
        ]

robotRow : RobotHouse -> Html Msg
robotRow (robot, house) =
    tr [] [
        td [ align "center" ] [ text (toString(robot.id)) ]
        , td [ align "center" ] [ text (currentHouseToString house) ]
    ]

currentHouseToString : House -> String
currentHouseToString house =
    let 
        x = toString house.x
        y = toString house.y
    in 
        String.concat ["( ", x, ", ", y, " )"]


-- DOMAIN
parseMoves : String -> Moves
parseMoves input =
    let 
        chars = toList input
        getMove char = 
            case char of
                '^' -> moveUp
                '>' -> moveRight
                'V' -> moveDown
                'v' -> moveDown
                '<' -> moveLeft
                _ -> undefinedMove
    in
        List.map getMove chars

takeTurn : World -> Robots -> Robot -> Move -> RobotMoves -> (World, RobotHouses, Presents)
takeTurn world robots robot move remainingRobotMoves =
    let 
        houseToMoveTo : World -> Robot -> Move -> House
        houseToMoveTo w r m = 
            let 
                places = List.filter(\(h, rs, ps) -> List.member r rs) w
            in
                case List.head places of
                    Just (h, rs, ps) -> 
                        {h | x = h.x + m.changeX, y = h.y + m.changeY}
                    Nothing -> 
                        origin

        leaveHouse : Int -> PlaceInWorld -> PlaceInWorld
        leaveHouse id (h, rs, ps) =
            let 
                robots = List.filter(\r -> r.id /= id) rs
            in
                (h, robots, ps)

        addHouseToWorld : World -> House -> World
        addHouseToWorld w newHouse =
            let
                places = List.filter(\(h, rs, ps) -> h == newHouse) world
            in
                case List.head places of
                    Just (h, rs, ps) -> 
                        w
                    Nothing -> 
                        List.append [(newHouse, [], 0)] w

        enterHouse : House -> Robot -> PlaceInWorld -> PlaceInWorld
        enterHouse houseToEnter r (h, rs, ps) =
            let 
                updatedRobots =
                    if h == houseToEnter then
                        List.append [r] rs
                    else
                        rs
            in
                (h, updatedRobots, ps)

        deliverPresent : House -> PlaceInWorld -> PlaceInWorld
        deliverPresent nh (h, rs, ps) =
            if h == nh && List.length rs == 1 then
                (h, rs, ps + 1) 
            else
                (h, rs, ps)

        newHouse : House
        newHouse = houseToMoveTo world robot move

        updatedWorld : World
        updatedWorld =
            newHouse
            |> addHouseToWorld world 
            |> List.map (leaveHouse robot.id)
            |> List.map (enterHouse newHouse robot)
            |> List.map (deliverPresent newHouse)

        getRobotHouse : Robot -> RobotHouse
        getRobotHouse robot = 
            let
                places = List.filter (\(h, rs, ps) -> List.member robot rs) updatedWorld                        
            in
                case List.head places of
                    Just (h, rs, ps) -> 
                        (robot, h)
                    Nothing -> 
                        (robot, origin)

        robotHouses : RobotHouses
        robotHouses = List.map getRobotHouse robots

        totalPresentsDelivered : Presents
        totalPresentsDelivered = 
            updatedWorld 
            |> List.map(\(h, rs, ps) -> ps)
            |> List.sum
    in
        case remainingRobotMoves of
            [] ->
                (updatedWorld, robotHouses, totalPresentsDelivered)
            (robot, move) :: rms ->
                takeTurn updatedWorld robots robot move rms

parseIntFromString : String -> Int
parseIntFromString s = 
    case String.toInt s of
        Err _ -> 0
        Ok val -> val

initializeSimulation : Int -> String -> (Robots, Moves, World, RobotMoves)    
initializeSimulation numberOfRobots inputtedMoves =
    let
        robots : Robots
        robots =
            let 
                indexes = if numberOfRobots > 0 then List.range 0 (numberOfRobots - 1) else []
            in 
                List.map (\i -> { id = i}) indexes
        
        moves : Moves
        moves = parseMoves inputtedMoves

        world : World
        world = initialWorld robots

        mkRobotsSequence : Robots -> Moves -> Robots -> Robots
        mkRobotsSequence originalRobots moves robotsSequence = 
            let
                robotsLength = List.length robotsSequence
                movesLength = List.length moves
            in
                if movesLength > robotsLength then
                    List.append originalRobots robotsSequence  
                    |> mkRobotsSequence originalRobots moves
                else
                    robotsSequence

        robotsSequence : Robots
        robotsSequence = mkRobotsSequence robots moves []
        
        robotMoves : RobotMoves
        robotMoves = List.map2 (,) robotsSequence moves    
    in
        (robots, moves, world, robotMoves)

runStep : Model -> (Robots, Moves, World, RobotHouses, RobotMoves, Presents)
runStep model =
    let
        (robots, moves, world, remainingMoves) = 
            if List.isEmpty model.remainingRobotMoves then
                initializeSimulation model.numberOfRobots model.inputtedMoves
            else
                (model.robots, model.moves, model.world, model.remainingRobotMoves)
        
        (updatedWorld, currentRobotPositions, updatedRemainingMoves, totalPresents) = 
            case remainingMoves of
                    [] ->
                        (world, model.currentRobotPositions, [], model.totalPresentsDelivered)
                    ((currentRobot, currentMove) :: nextRobotMove :: rms) ->
                        let
                            (uw, crps, tps) = takeTurn world robots currentRobot currentMove []
                        in
                            (uw, crps, nextRobotMove :: rms, tps)
                    [(currentRobot, currentMove)] ->
                        let
                            (uw, crps, tps) = takeTurn world robots currentRobot currentMove []
                        in
                            (uw, crps, [], tps)
    in
        (robots, moves, updatedWorld, currentRobotPositions, updatedRemainingMoves, totalPresents)

runSimulation : Model -> (Robots, Moves, World, RobotHouses, RobotMoves, Presents)
runSimulation model =
    let
        (robots, moves, world, robotMoves) = 
            initializeSimulation model.numberOfRobots model.inputtedMoves
        
        (updatedWorld, currentRobotPositions, totalPresents) = 
            case robotMoves of
                [] ->
                    (world, model.currentRobotPositions, model.totalPresentsDelivered)
                ((robot, move) :: rms) ->
                    takeTurn world robots robot move rms
    in
        (robots, moves, updatedWorld, currentRobotPositions, [], totalPresents)