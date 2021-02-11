-module(task1).
-export([eval/1, eval/2, map/2, map/3, filter/2, filter/3, split/2, split/3, groupby/2, groupby/4]).


% eval/1 below
eval({Op, E1, E2}) when is_tuple(E1)-> % used when E1 is tuple, and calls eval on E1
    NewE1 = element(2, eval(E1)),
    eval({Op, NewE1, E2});

eval({Op, E1, E2}) when is_tuple(E2)-> % used when E2 is tuple, and call eval on E2
    NewE2 = element(2, eval(E2)),
    eval({Op, E1, NewE2});

eval({Op, E1, E2}) -> % used when both E1 and E2 are numbers, and is always called in the top of the iteration
    case {Op, E1, E2} of
        {add, _, _} -> 
            {ok, E1 + E2};

        {sub, _, _} ->
            {ok, E1 - E2};

        {'div', _, _} ->
            {ok, E1 / E2};

        {mul, _, _} ->
            {ok, E1 * E2};
        _ ->
            error
    end;

eval(_)->
    {error, unkown_error}.


%-----------------------------------------------------------------------------------------------------------------


% lägg till unknown error
% eval/2 below
eval({Op, E1, E2}, L) when is_map(L) and not is_number(E1) -> % used when E1 is not a number and a map is given
    case maps:is_key(E1, L) of
        true ->
            eval({Op, maps:get(E1, L), E2}, L); % map is sent again in case E2 is still a variable
        false ->
            {error, variable_not_found}
    end;

eval({Op, E1, E2}, L) when is_map(L) and not is_number(E2) -> % used when E2 is not a number and a map is given
    case maps:is_key(E2, L) of
        true ->
            eval({Op, E1, maps:get(E2, L)}, L); % map is sent again in case E1 is still a variable
        false ->
            {error, variable_not_found}
    end;

eval({Op, E1, E2}, L) when is_map(L)-> % used when E1 and E2 are both number and a map is given
    eval({Op, E1, E2});

eval(_,_) ->
    {error, unkown_error}.


%-----------------------------------------------------------------------------------------------------------------


map(F, L) ->
    map(F, L, []).

map(_, [], R) ->
    lists:reverse(R); % reverse R since Head of L appends to head of R 

map(F, [H|T], R) ->
    map(F, T, [F(H)|R]). %appends head to head in list R


%-----------------------------------------------------------------------------------------------------------------


filter(P, L) ->
    filter(P, L, []).

filter(_, [], R) ->
    lists:reverse(R);

filter(P, [H|T], R) ->
    case P(H) of
        true ->
            Temp = [H|R];
        false ->
            Temp = R
    end,
    filter(P, T, Temp).


%-----------------------------------------------------------------------------------------------------------------


split(P, L) ->
    split(P, L, {[], []}).

split(_, [], {True, False}) ->
    {lists:reverse(True), lists:reverse(False)};

split(P, [H|T] , {True, False}) ->
    case P(H) of
        true ->
            Temp = {[H | True],False};
        false ->
            Temp = {True,[ H | False]}
    end,
    split(P, T, Temp).


%-----------------------------------------------------------------------------------------------------------------


groupby(F, L) ->
    groupby(F, L, #{},1).

groupby(F, [H|T], M, Index) when is_map(M) ->
    case maps:find(F(H), M) of
        {ok, ListToUpdate} ->
            NewMap = maps:put(F(H), lists:reverse([Index | ListToUpdate]), M);
        error ->
            NewMap = maps:put(F(H), [Index], M)
    end,
    groupby(F, T, NewMap, Index+1);

groupby(_,[], M, _) ->
    M.



% groupby(_, [], Neg, Pos, Zero, _) ->
%     #{negative => lists:reverse(Neg), positive => lists:reverse(Pos), zero => lists:reverse(Zero)};

% groupby(F,[H|T], Neg, Pos, Zer, Index) ->
%     case F(H) of
%         positive -> 
%             Positive = [Index | Pos],
%             Negative = Neg,
%             Zero = Zer;

%         negative -> 
%             Negative = [Index | Neg],
%             Positive = Pos,
%             Zero = Zer;

%         zero ->
%             Zero = [Index | Zer],
%             Positive = Pos,
%             Negative = Neg
%     end,
%     groupby(F, T, Negative, Positive, Zero, Index+1).