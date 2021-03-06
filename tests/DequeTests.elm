module DequeTests exposing (suite)

import Deque
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Test exposing (..)


smallInt : Fuzzer Int
smallInt =
    Fuzz.intRange 0 9999


suite : Test
suite =
    describe "Deque"
        [ describe "empty"
            [ test "isEmpty" <|
                \_ ->
                    Expect.true "isEmpty fails" (Deque.isEmpty Deque.empty)
            , test "fromList of empty list create the empty deque" <|
                \_ ->
                    Expect.equal Deque.empty (Deque.fromList [])
            ]
        , describe "singleton"
            [ test "Creates deque of single element" <|
                \_ ->
                    let
                        useOfSingleton =
                            Deque.singleton 1

                        useOfPush =
                            Deque.pushFront 1 Deque.empty
                    in
                    Expect.equal useOfSingleton useOfPush
            ]
        , fuzz2 smallInt smallInt "range" <|
            \from to ->
                Deque.range from to
                    |> Deque.toList
                    |> Expect.equalLists (List.range from to)
        , fuzz2 smallInt smallInt "repeat" <|
            \size val ->
                Deque.repeat size val
                    |> Deque.toList
                    |> Expect.equalLists (List.repeat size val)
        , fuzz (Fuzz.list Fuzz.int) "fromList works as the inverse of toList" <|
            \list ->
                Deque.fromList list
                    |> Deque.toList
                    |> Expect.equalLists list
        , describe "Push"
            [ fuzz (Fuzz.list Fuzz.int) "pushFront is the same as List :: operator" <|
                \list ->
                    List.foldl Deque.pushFront Deque.empty list
                        |> Deque.toList
                        |> Expect.equalLists (List.reverse list)
            , fuzz (Fuzz.list Fuzz.int) "pushBack should result in the same List" <|
                \list ->
                    List.foldl Deque.pushBack Deque.empty list
                        |> Deque.toList
                        |> Expect.equalLists list
            ]
        , describe "Pop" <|
            let
                fromListAlt ls =
                    List.foldr Deque.pushFront Deque.empty ls
            in
            [ fuzz (Fuzz.list Fuzz.int) "popFront" <|
                \list ->
                    let
                        listPopper ( vals, ls ) =
                            case ls of
                                [] ->
                                    ( vals, [] )

                                x :: xs ->
                                    listPopper ( x :: vals, xs )

                        popper ( vals, deque ) =
                            case Deque.popFront deque of
                                ( Nothing, newDeque ) ->
                                    ( vals, newDeque )

                                ( Just val, newDeque ) ->
                                    popper ( val :: vals, newDeque )

                        expected =
                            listPopper ( [], list )

                        answer =
                            ( [], Deque.fromList list )
                                |> popper
                                |> Tuple.mapSecond Deque.toList

                        altAnswer =
                            ( [], fromListAlt list )
                                |> popper
                                |> Tuple.mapSecond Deque.toList
                    in
                    Expect.all
                        [ Expect.true "Not the same result when deque is built in reverse"
                            << (==) altAnswer
                        , Expect.equal expected
                        ]
                        answer
            , fuzz (Fuzz.list Fuzz.int) "popBack" <|
                \list ->
                    let
                        listPopper ( vals, ls ) =
                            case List.reverse ls of
                                [] ->
                                    ( vals, [] )

                                x :: xs ->
                                    listPopper ( x :: vals, List.reverse xs )

                        popper ( vals, deque ) =
                            case Deque.popBack deque of
                                ( Nothing, newDeque ) ->
                                    ( vals, newDeque )

                                ( Just val, newDeque ) ->
                                    popper ( val :: vals, newDeque )

                        expected =
                            listPopper ( [], list )

                        answer =
                            ( [], Deque.fromList list )
                                |> popper
                                |> Tuple.mapSecond Deque.toList

                        altAnswer =
                            ( [], fromListAlt list )
                                |> popper
                                |> Tuple.mapSecond Deque.toList
                    in
                    Expect.all
                        [ Expect.true "Not the same result when deque is built in reverse"
                            << (==) altAnswer
                        , Expect.equal expected
                        ]
                        answer
            , test "Stack safe popFront" <|
                \_ ->
                    let
                        _ =
                            List.repeat 10000 1
                                |> Deque.fromList
                                |> Deque.popFront
                    in
                    Expect.true "" True
            , test "Stack safe popBack" <|
                \_ ->
                    let
                        _ =
                            List.repeat 10000 1
                                |> List.foldl Deque.pushFront Deque.empty
                                |> Deque.popBack
                    in
                    Expect.true "" True
            ]
        , describe "Equality"
            [ fuzz2 (Fuzz.list Fuzz.string) (Fuzz.list Fuzz.string) "Same as List (==)" <|
                \list1 list2 ->
                    Expect.equal
                        (list1 == list2)
                        (Deque.equals (Deque.fromList list1) (Deque.fromList list2))
            ]
        , describe "Slice variants" <|
            [ fuzz2 Fuzz.int (Fuzz.list Fuzz.string) "left" <|
                \n list ->
                    Expect.equalLists
                        (List.take n list)
                        (Deque.toList (Deque.left n (Deque.fromList list)))
            , fuzz2 Fuzz.int (Fuzz.list Fuzz.string) "right" <|
                \n list ->
                    Expect.equalLists
                        (List.reverse (List.take n (List.reverse list)))
                        (Deque.toList (Deque.right n (Deque.fromList list)))
            , fuzz2 Fuzz.int (Fuzz.list Fuzz.string) "dropLeft" <|
                \n list ->
                    Expect.equalLists
                        (List.drop n list)
                        (Deque.toList (Deque.dropLeft n (Deque.fromList list)))
            , fuzz2 Fuzz.int (Fuzz.list Fuzz.string) "dropRight" <|
                \n list ->
                    Expect.equalLists
                        (List.reverse (List.drop n (List.reverse list)))
                        (Deque.toList (Deque.dropRight n (Deque.fromList list)))
            ]
        , describe "Conversions"
            [ fuzz (Fuzz.list Fuzz.string) "foldl works like List.foldl" <|
                \list ->
                    let
                        listResult =
                            List.foldl (++) "" list

                        dequeResult =
                            Deque.foldl (++) "" (Deque.fromList list)
                    in
                    Expect.equal listResult dequeResult
            , fuzz (Fuzz.list Fuzz.string) "foldr works like List.foldr" <|
                \list ->
                    let
                        listResult =
                            List.foldr (++) "" list

                        dequeResult =
                            Deque.foldr (++) "" (Deque.fromList list)
                    in
                    Expect.equal listResult dequeResult
            , test "Stack safe foldl" <|
                \_ ->
                    let
                        _ =
                            List.repeat 10000 1
                                |> Deque.fromList
                                |> Deque.foldl (+) 0
                    in
                    Expect.true "" True
            , test "Stack safe foldr" <|
                \_ ->
                    let
                        _ =
                            List.repeat 10000 1
                                |> Deque.fromList
                                |> Deque.foldr (+) 0
                    in
                    Expect.true "" True
            , fuzz (Fuzz.list Fuzz.int) "map works like List.map" <|
                \list ->
                    let
                        listResult =
                            List.map ((+) 1) list

                        dequeResult =
                            Deque.map ((+) 1) (Deque.fromList list)
                    in
                    Expect.equalLists listResult (Deque.toList dequeResult)
            , fuzz (Fuzz.list Fuzz.int) "filter works like List.filter" <|
                \list ->
                    let
                        listResult =
                            List.filter (\n -> modBy 2 n == 0) list

                        dequeResult =
                            Deque.filter (\n -> modBy 2 n == 0) (Deque.fromList list)
                    in
                    Expect.equalLists listResult (Deque.toList dequeResult)
            , fuzz (Fuzz.list Fuzz.int) "filterMap works like List.filterMap" <|
                \list ->
                    let
                        fn n =
                            if modBy 2 n == 0 then
                                Just 1

                            else
                                Nothing

                        listResult =
                            List.filterMap fn list

                        dequeResult =
                            Deque.filterMap fn (Deque.fromList list)
                    in
                    Expect.equalLists listResult (Deque.toList dequeResult)
            , describe "append"
                [ fuzz2 (Fuzz.list Fuzz.int) (Fuzz.list Fuzz.int) "works like List.append" <|
                    \list1 list2 ->
                        Deque.fromList list2
                            |> Deque.append (Deque.fromList list1)
                            |> Deque.toList
                            |> Expect.equalLists (list1 ++ list2)
                , fuzz2 (Fuzz.list Fuzz.int) (Fuzz.list Fuzz.int) "doesn't mess up slice operations" <|
                    \list1 list2 ->
                        let
                            deque1 =
                                Deque.fromList list1

                            deque2 =
                                Deque.fromList list2

                            resultList =
                                list1
                                    ++ list2
                                    |> List.reverse
                                    |> List.drop 13
                                    |> List.reverse
                        in
                        Deque.append deque1 deque2
                            |> Deque.dropRight 13
                            |> Deque.toList
                            |> Expect.equalLists resultList
                ]
            , fuzz (Fuzz.list Fuzz.int) "length" <|
                \list ->
                    Deque.fromList list
                        |> Deque.length
                        |> Expect.equal (List.length list)
            , fuzz2 (Fuzz.list Fuzz.int) Fuzz.int "member" <|
                \list item ->
                    list
                        |> Deque.fromList
                        |> Deque.member item
                        |> Expect.equal (List.member item list)
            , fuzz (Fuzz.list Fuzz.int) "partition" <|
                \list ->
                    list
                        |> Deque.fromList
                        |> Deque.partition (\i -> modBy 2 i == 0)
                        |> Tuple.mapBoth Deque.toList Deque.toList
                        |> Expect.equal (List.partition (\i -> modBy 2 i == 0) list)
            ]
        ]
