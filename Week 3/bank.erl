-module(bank).
-export([init/1, start/0, balance/2, deposit/3, withdraw/3, lend/4, handle_call/3]).
-behavior(gen_server).

%Same as Week 2/bank.erl but implemented using gen_server instead

start()->
    {ok, Pid} = gen_server:start(?MODULE, [], []),
    Pid.

init(_Args) ->
    ets:new(bank_server, [set, private, named_table]), %assignment didn't specify if multiple people with same name could all have accounts; set was used and ex. only 1 bob can have an account.
    {ok, no_state}.

handle_call({balance, Who}, _From, State) ->
    Response =  
        case has_account(Who) of
            false ->
                no_account;
            true ->
                {ok, account_balance(Who)}
        end,
    {reply, Response, State};

handle_call({deposit, Who, Amount}, _From, State) ->
    Response =
        case has_account(Who) of
            true ->
                New_balance = account_balance(Who) + Amount,
                account_update_balance(Who, New_balance), %should instead use a add_balance_to_account function
                {ok, account_balance(Who)};
            false ->
                create_new_account(Who, Amount),
                {ok, account_balance(Who)}
        end,
    {reply, Response, State};

handle_call({withdraw, Who, Amount}, _From, State) ->
    Response = 
        case has_account(Who) and account_has_sufficient_funds(Who, Amount) of
            true ->
                New_balance = account_balance(Who) - Amount,
                account_update_balance(Who, New_balance), %should instead use a remove_balance_from_account function
                {ok, account_balance(Who)};
            false ->
                insufficient_funds
        end,
    {reply, Response, State};

handle_call({lend, Receiver, Sender, Amount}, _From, State) ->
    Response = 
        case which_account_doesnt_exist(Sender, Receiver) of
            Sender ->
                {no_account, Sender};
            Receiver ->
                {no_account, Receiver};
            both ->
                {no_account, both};
            both_exists ->
                case account_has_sufficient_funds(Sender, Amount) of
                    false ->
                        insufficient_funds;
                    true ->
                        account_update_balance(Sender, account_balance(Sender)-Amount), %should instead use a remove_balance_from_account function
                        account_update_balance(Receiver, account_balance(Receiver)+Amount),  %should instead use a add_balance_to_account function
                        ok
                end
        end,
    {reply, Response, State}.

balance(Pid, Who) when is_pid(Pid)->
    gen_server:call(Pid, {balance, Who}).

deposit(Pid, Who, X) when is_pid(Pid)->
    gen_server:call(Pid, {deposit, Who, X}).

withdraw(Pid, Who, X) when is_pid(Pid)->
    gen_server:call(Pid, {withdraw, Who, X}).

lend(Pid, From, To, X) when is_pid(Pid)->
    gen_server:call(Pid, {lend, To, From, X}).

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