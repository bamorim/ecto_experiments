defmodule MapCodec do
  @moduledoc """
  MapCodec defines a behaviour for encoding and decoding elixir types to something that is similar
  to a JSON, but not a serialized version of that. Instead, it is just a subset of elixir types. It
  is either a list, a map with string keys, numbers, booleans and nil, combined.

  The idea is that the wire-serialization is up to each application. One may choose to encode as
  JSON, other may want to encode with MsgPack or maybe you want to output YAML. That is up to other
  libraries.

  The problem with most JSON serialization Protocols is that they require a Struct and focus on the
  encode side of things, mostly because the protocol is only present in the decoded form (it uses
  the __struct__ metadata on the map). That is why we use a Behaviour here. The idea is that you
  always need to provide the type for encoding and decoding. The type is just an annotation and is
  up to the Codec to know what to do with that.

  This lib provides a bunch of simple codecs and codec combinators, in order to enable people to
  build their own Encoding/Decoding solution.
  """
  @type encoded_map ::
          %{required(String.t()) => encoded_map()}
          | [encoded_map()]
          | String.t()
          | number()
          | boolean()
          | nil

  defmodule Encoder do
    @callback encode(value :: any()) :: {:ok, MapCodec.encoded_map()} | :error
  end

  defmodule Decoder do
    @callback decode(type :: any(), MapCodec.encoded_map()) :: {:ok, any()} | :error
  end
end
