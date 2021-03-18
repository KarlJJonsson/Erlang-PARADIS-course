-module(allocator).
-export([start/1, request/2, release/2]).

start(ResourceMap) ->
    spawn_link(fun() -> allocator(ResourceMap) end).

request(Pid, ResourceList) ->
    Ref = make_ref(),
    Pid ! {request, {self(), Ref, ResourceList}},
    receive
        {granted, Ref, Granted} ->
            {Granted}
    end.

release(Pid, ResourceMap) ->
    Ref = make_ref(),
    Pid ! {release, {self(), Ref, ResourceMap}},
    receive
        {released, Ref} ->
            ok
    end.

allocator(ResourceMap) ->
    receive
        {request, {Pid, Ref, ResourceList}} ->
            case map_contains_elements(ResourceMap, ResourceList) of
                true ->
                    Granted = [{Resource, maps:get(Resource, ResourceMap)} || Resource <- ResourceList],
                    Remaining = remove_keys(ResourceList, ResourceMap),
                    Pid ! {granted, Ref, maps:from_list(Granted)},
                    allocator(Remaining);
                false ->
                    self() ! {request, {Pid, Ref, ResourceList}}
            end;

        {release, {Pid, Ref, Released}} ->
            NewResourceMap = maps:merge(ResourceMap, Released),
            Pid ! {released, Ref},
            allocator(NewResourceMap)
    end.

map_contains_elements(_Map, []) ->
    true;

map_contains_elements(Map, [H | T]) ->
    case maps:find(H, Map) of
        {ok, _Value} ->
            map_contains_elements(maps:remove(H, Map), T);
        error ->
            false
    end.

remove_keys([], Map) ->
    Map;

remove_keys([Key | Keys], Map) ->
    remove_keys(Keys, maps:remove(Key, Map)).