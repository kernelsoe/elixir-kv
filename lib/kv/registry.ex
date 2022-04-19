defmodule KV.Registry do
  use GenServer

  # Client API

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def pop(server) do
    GenServer.call(server, :pop)
  end

  def push(server, element) do
    GenServer.cast(server, {:push, element})
  end

  # Call backs

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end
end
