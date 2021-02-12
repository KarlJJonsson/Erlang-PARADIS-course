-module(monitor).
-export([start/0, init/1]).
-behaviour(supervisor).

%Same as Week 2/monitor.erl but implemented using supervisor instead

start() ->
    supervisor:start_link(?MODULE, []).

init(_Args) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 1000,
        period => 60},

    ChildSpec = [
        #{
            id => double_id,
            start => {double, start_link, []}
        }
    ],
    {ok, {SupFlags, ChildSpec}}.