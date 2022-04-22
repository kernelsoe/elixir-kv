defmodule KV do
  use Application

  @moduledoc """
  Documentation for `KV`.
  """

  @impl true
  def start(_type, _args) do
    KV.SuperVisor.start_link(name: KV.SuperVisor)
  end

  @doc """
  Hello world.

  ## Examples

      iex> KV.hello()
      :world

  """
  def hello do
    :world
  end
end
