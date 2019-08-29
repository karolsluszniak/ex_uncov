defmodule Mix.Tasks.Uncov.Show do
  @moduledoc """
  Displays uncovered lines in specified modules.

  ## Usage

  Display uncovered lines in module, group of modules or all modules:

      mix uncov.show MyApp.MyMod
      mix uncov.show MyApp.OneMod MyApp.AnotherMod
      mix uncov.show MyApp.MyContext.*
      mix uncov.show cover/*
      mix uncov.show --all
      mix uncov.show -a

  """

  use Mix.Task

  @recursive true

  @switches [
    all: :boolean,
    lines_around: :integer
  ]

  @aliases [
    a: :all
  ]

  @impl Mix.Task
  def run(argv) do
    {opts, args} = OptionParser.parse!(argv, strict: @switches, aliases: @aliases)
    mods = if opts[:all], do: :all, else: args
    opts = Keyword.delete(opts, :all)

    ExUncov.Show.run(mods, opts)
  end
end
