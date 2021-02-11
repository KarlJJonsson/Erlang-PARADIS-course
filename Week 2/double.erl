-module(double).
-export([start/0, double/0, double/1]).

start() ->
    Pid = spawn(fun double/0),
    register(double, Pid).

double() ->
    receive 
        {Pid, Ref, N} -> 
           Pid ! {Ref, N*2}
    end,
    double().

double(N) ->
    Ref = make_ref(),
    Mref = monitor(process, double),
    double ! {self(), Ref, N},
    receive
        {Ref, Result} ->
            Result;
        {'DOWN', Mref, _, _, _} ->
            demonitor(Mref),
            double(N)
    end.

