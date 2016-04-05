defmodule Airbrakex.Utils do
  @moduledoc """
  Assorted helper functions used through out the Airbrakex package
  """

  @doc """
  Internally all modules are prefixed with Elixir. This function removes the
  Elixir prefix from the module when it is converted to a string.
  """
  def strip_elixir_prefix(module) when is_atom(module) do
    module
    |> Atom.to_string
    |> String.split(".")
    |> strip_elixir_prefix
  end
  def strip_elixir_prefix(["Elixir"|tl]) do
    tl
    |> Enum.join(".")
  end
  def strip_elixir_prefix(list) when is_list(list) do
    list
    |> Enum.join(".")
  end
end
