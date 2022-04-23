defmodule RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawn buckets", %{registry: registry} do
    IO.inspect(registry)
    assert KV.Registry.lookup(registry, "shopping") == :error
    assert _pid = KV.Registry.create(registry, "shopping")
    assert {:ok, pid} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(pid, "milk", 3)
    assert KV.Bucket.get(pid, "milk") == 3
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)

    # ets operations are async
    # so the after Agent.stop, ets might not finished hence race condition
    # Do a call (blocking the next line) to ensure the registry processed the DOWN message
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "removes bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Stop the bucket with msg other than :normal to crash all linked processes
    Agent.stop(bucket, :shutdown)

    # Do a call (blocking the next line) to ensure the registry processed the DOWN message
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "bucket can crash at any time", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Simulate a bucket crash by explicitly and synchronously shutting it down
    Agent.stop(bucket, :shutdown)

    catch_exit(KV.Bucket.put(bucket, "milk", 3))
  end
end
