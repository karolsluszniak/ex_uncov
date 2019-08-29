defmodule Mix.Tasks.Uncov.List do
  @moduledoc """
  Lists all modules along with information about uncovered lines.

  ## Usage

  Display list of all modules:

      mix uncov.list

  """

  use Mix.Task

  @recursive true

  @switches []

  @aliases []

  @impl Mix.Task
  def run(argv) do
    _ = OptionParser.parse!(argv, strict: @switches, aliases: @aliases)

    ExUncov.List.run()
  end
end
