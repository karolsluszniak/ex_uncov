defmodule Mix.Tasks.Uncov do
  @moduledoc """
  Identifies lines uncovered by tests and tracks them via code.

  ## Usage

  Display modules with changes of uncovered lines (after `mix test --cover`):

      mix uncov

  Commit changes of uncovered lines for module, group of modules or all modules:

      mix uncov MyApp.MyMod
      mix uncov MyApp.OneMod MyApp.AnotherMod
      mix uncov MyApp.MyContext.*
      mix uncov cover/*
      mix uncov --all
      mix uncov -a

  Ensure that all changes of uncovered lines are committed (e.g. on CI):

      mix uncov --verify
      mix uncov -v

  """

  use Mix.Task

  @recursive true

  @switches [
    all: :boolean,
    verify: :boolean
  ]

  @aliases [
    a: :all,
    v: :verify
  ]

  @impl Mix.Task
  def run(argv) do
    {opts, args} = OptionParser.parse!(argv, strict: @switches, aliases: @aliases)
    mods = if opts[:all], do: :all, else: args
    opts = Keyword.delete(opts, :all)

    ExUncov.Track.run(mods, opts)
  end
end
