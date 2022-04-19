defmodule KV.Registry do
  use GenServer

  # Client API

  def start_link(defaults, opts) do
    GenServer.start_link(__MODULE__, defaults, opts)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  # Call backs

  @impl true
  def init(state \\ %{}) do
    {:ok, state}
  end

  @impl true
  def handle_call({:lookup, name}, _from, names_state) do
    {:reply, Map.fetch(names_state, name), names_state}
  end

  @impl true
  def handle_call({:create, name}, _from, names_state) do
    if Map.has_key?(names_state, name) do
      {:reply, :duplicate, names_state}
    else
      {:ok, bucket} = KV.Bucket.start_link([])
      names_state = Map.put(names_state, name, bucket)
      {:reply, :created, names_state}
    end
  end
end
