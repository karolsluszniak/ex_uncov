defmodule ExUncov.Printer do
  @moduledoc false

  def info(info \\ []) do
    Mix.shell().info(info)
  end

  def b(inner) do
    [:bright, to_string(inner), :normal]
  end
end
