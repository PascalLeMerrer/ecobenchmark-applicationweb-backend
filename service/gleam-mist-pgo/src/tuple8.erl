-module(tuple8).

-export([decode_tuple8/1]).

-import(gleam_stdlib, [decode_error_msg/2]).


decode_tuple8({_,_,_,_,_,_,_,_} = A) -> {ok, A};
decode_tuple8([A,B,C,D,E,F,G,H]) -> {ok, {A,B,C,D,E,F,G,H}};
decode_tuple8(Data) -> decode_error_msg(<<"Tuple of 8 elements">>, Data).