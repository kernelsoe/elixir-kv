defmodule KV.Registry do
  use GenServer

  # Client API

  # def start_link(defaults, opts) do
  #   GenServer.start_link(__MODULE__, defaults, opts)
  # end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  # Call backs

  @impl true
  def init(:ok) do
    names = %{}
    refs = %{}

    {:ok, {names, refs}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, state) do
    {names, _} = state
    {:reply, Map.fetch(names, name), state}
  end

  @impl true
  def handle_call({:create, name}, _from, {names, refs}) do
    if Map.has_key?(names, name) do
      {:reply, :duplicate, {names, refs}}
    else
      {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)

      ref = Process.monitor(bucket)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, bucket)

      {:reply, :created, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected KV msg in KV.Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
