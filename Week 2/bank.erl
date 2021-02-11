-module(bank).
-export([start/0, loop/0, balance/2, deposit/3, withdraw/3, lend/4]).

start() ->
    spawn(fun bank_server/0).

bank_server() ->
    ets:new(bank_server, [set, private, named_table]), %assignment didn't specify if multiple people with same name could all have accounts; set was used and ex. only 1 bob can have an account.
    loop().

loop() ->
    receive
        {Pid, Ref, Who, balance} ->
            case has_account(Who) of
                false ->
                    Pid ! {no_account, Ref};
                true ->
                    Pid ! {ok, Ref, account_balance(Who)}
            end,
            loop(); % bara en behövs ?

        {Pid, Ref, Who, X, deposit} ->
            case has_account(Who) of
                true ->
                    New_balance = account_balance(Who) + X,
                    account_update_balance(Who, New_balance), %should instead use a add_balance_to_account function
                    Pid ! {ok, Ref, account_balance(Who)}; 
                false ->
                    create_new_account(Who, X),
                    Pid ! {ok, Ref, account_balance(Who)}
            end,
            loop();

        {Pid, Ref, Who, X, withdraw} ->
            case has_account(Who) and account_has_sufficient_funds(Who, X) of
                true ->
                    New_balance = account_balance(Who) - X,
                    account_update_balance(Who, New_balance), %should instead use a remove_balance_from_account function
                    Pid ! {ok, Ref, account_balance(Who)};
                false ->
                    Pid ! {insufficient_funds, Ref}
            end,
            loop();
        {Pid, Ref, From, To, X, lend} ->
            case which_account_doesnt_exist(From, To) of
                From ->
                    Pid ! {no_account, Ref, From};
                To ->
                    Pid ! {no_account, Ref, To};
                both ->
                    Pid ! {no_account, Ref, both};
                both_exists ->
                    case account_has_sufficient_funds(From, X) of
                        false ->
                            Pid ! {insufficient_funds, Ref};
                        true ->
                            account_update_balance(From, account_balance(From)-X), %should instead use a remove_balance_from_account function
                            account_update_balance(To, account_balance(To)+X),  %should instead use a add_balance_to_account function
                            Pid ! {ok, Ref}
                    end
            end,
            loop()
    end.


balance(Pid, Who) when is_pid(Pid)->
    Ref = make_ref(),
    Mref = monitor(process, Pid),
    Pid ! {self(), Ref, Who, balance},
    receive
        {no_account, Ref} ->
            no_account;
        {ok, Ref, Balance} ->
            {ok, Balance};
        {'DOWN', Mref, _, _, _} ->
            demonitor(Mref),
            no_bank
    after 1000 ->
        timeout
    end.

deposit(Pid, Who, X) when is_pid(Pid)->
    Ref = make_ref(),
    Mref = monitor(process, Pid),
    Pid ! {self(), Ref, Who, X, deposit},
    receive
        {ok, Ref, Balance} ->
            {ok, Balance};
        {'DOWN', Mref, _, _, _} ->
            demonitor(Mref),
            no_bank
    after 1000 ->
        timeout
    end.

withdraw(Pid, Who, X) when is_pid(Pid)->
    Ref = make_ref(),
    Mref = monitor(process, Pid),
    Pid ! {self(), Ref, Who, X, withdraw},
    receive
        {ok, Ref, Balance} ->
            {ok, Balance};
        {insufficient_funds, Ref} ->
            insufficient_funds;
        {'DOWN', Mref, _, _, _} ->
            demonitor(Mref),
            no_bank
    after 1000 ->
        timeout
    end.

lend(Pid, From, To, X) when is_pid(Pid)->
    Ref = make_ref(),
    Mref = monitor(process, Pid),
    Pid ! {self(), Ref, From, To, X, lend},
    receive
        {no_account, Ref, Account} ->
            {no_account, Account};
        {insufficient_funds, Ref} ->
            insufficient_funds;
        {ok, Ref} ->
            ok;
        {'DOWN', Mref, _, _, _} ->
            demonitor(Mref),
            no_bank
    after 1000 ->
        timeout
    end.

which_account_doesnt_exist(First_account, Second_account) ->
    case {has_account(First_account), has_account(Second_account)} of
        {false, false} ->
            both;
        {false, true} ->
            First_account;
        {true, false} ->
            Second_account;
        {true, true} ->
            both_exists
    end.
has_account(Name) ->
    ets:member(bank_server, Name).

account_balance(Name) ->
    Account_info_list = ets:lookup(bank_server, Name),
    Account_info_tuple = lists:nth(1, Account_info_list),
    Balance = element(2, Account_info_tuple),
    Balance.

account_update_balance(Name, New_balance) ->
    ets:insert(bank_server, {Name, New_balance}).

create_new_account(Name, Balance) ->
    ets:insert(bank_server, {Name, Balance}).

account_has_sufficient_funds(Name, Withdraw_amount) ->
    case account_balance(Name) of %case only here to allow the use of this function during a loan and withdrawal, since it would else cause an error if called on an account which doesnt exist
        X when is_number(X) ->
            Balance = account_balance(Name),
            Balance-Withdraw_amount > 0;
        _ ->
            false
    end.