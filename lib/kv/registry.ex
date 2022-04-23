defmodule KV.Registry do
  use GenServer

  # Client API

  # def start_link(defaults, opts) do
  #   GenServer.start_link(__MODULE__, defaults, opts)
  # end

  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  def lookup(server, name) do
    # Using ETS
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end

    # GenServer.call(server, {:lookup, name})
  end

  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  # Call backs

  @impl true
  def init(table) do
    # names = %{}
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}

    {:ok, {names, refs}}
  end

  # @impl true
  # def handle_call({:lookup, name}, _from, state) do
  #   {names, _} = state
  #   {:reply, Map.fetch(names, name), state}
  # end

  @impl true
  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} ->
        {:reply, pid, {names, refs}}

      :error ->
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)

        ref = Process.monitor(pid)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, pid})
        {:reply, pid, {names, refs}}
    end

    # if Map.has_key?(names, name) do
    #   {:reply, :duplicate, {names, refs}}
    # else
    #   {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)

    #   ref = Process.monitor(bucket)
    #   refs = Map.put(refs, ref, name)
    #   names = Map.put(names, name, bucket)

    #   {:reply, :created, {names, refs}}
    # end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    # names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected KV msg in KV.Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
