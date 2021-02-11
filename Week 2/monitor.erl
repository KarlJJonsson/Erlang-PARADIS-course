-module(monitor).
-export([start/0]).

start() ->
    spawn(fun process_booter/0).

process_booter() ->
    Pid = spawn(fun double:double/0),
    register(double, Pid),
    MRef = monitor(process, Pid),
    receive
        {'DOWN', MRef, _, _, _} ->
            process_booter()
    end.