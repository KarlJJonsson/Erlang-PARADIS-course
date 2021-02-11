-module(pmap).
-export([unordered/2]).

master(Fun, L) ->
    Pids = [spawn_work(Element, Fun) || Element <- L],
    gather(Pids).

spawn_work(Element, Fun) ->
    Pid = spawn(fun worker/0),
    Pid ! {self(), {work, Element, Fun}},
    Pid.

worker() ->
    receive
        {Master, {work, Element, Fun}} ->
            Master ! {self(), {result, Fun(Element)}}
    end.

gather([]) ->
    [];
gather([Pid | Pids]) ->
    receive
        {Pid, {result, Result}} ->
            [Result | gather(Pids)]
    end.

unordered(Fun, L) ->
    Results = master(Fun, L),
    Results.

