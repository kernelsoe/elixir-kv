defmodule RegistryTest do
  use ExUnit.Case, async: true

  setup do
    registry = start_supervised!(KV.Registry)
    %{registry: registry}
  end

  test "return an initial empty list", %{registry: registry} do
    assert KV.Registry.push(registry, :kernel) == :ok
    assert KV.Registry.pop(registry) == :kernel
  end
end
