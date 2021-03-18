-module(barrier).
-export([start/1, loop/2, wait/2]).

start(Refs) when is_list(Refs) ->
    spawn_link(fun () -> loop(Refs, []) end).

loop(Refs, Arrived) when Refs =:= [] ->
    [Pid ! {continue, Ref} || {Pid, Ref} <- Arrived],
    RefilledRefs = [[Ref] || {_Pid, Ref} <- Arrived],
    loop(RefilledRefs, []);

loop(Refs, Arrived) ->
    receive
        {arrive, {Pid, Ref}} ->
            case lists:member(Ref, Refs) of
                true ->
                    loop(lists:delete(Ref, Refs), [{Pid, Ref} | Arrived]);
                false ->
                    Pid ! {continue, Ref},
                    loop(Refs, Arrived)
            end
    end.

wait(Barrier, Ref) ->
    Barrier ! {arrive, {self(), Ref}},
    receive
	    {continue, Ref} ->
	        ok
    end.