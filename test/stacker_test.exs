defmodule StackerTest do
  use ExUnit.Case, async: true

  setup do
    stacker = start_supervised!(KV.Stacker)
    %{stacker: stacker}
  end

  test "return an initial empty list", %{stacker: stacker} do
    assert KV.Registry.push(stacker, :kernel) == :ok
    assert KV.Registry.pop(stacker) == :kernel
  end
end
