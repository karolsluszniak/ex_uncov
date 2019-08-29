defmodule ExUncov.Track do
  @moduledoc false

  import ExUncov.Printer
  alias ExUncov.{CoverageStore, ModResolve, UncoveredStore}

  def run(mods, opts) do
    with :ok <- CoverageStore.validate() do
      do_run(mods, opts)
    end
  end

  defp do_run(mods, opts) do
    coverage = CoverageStore.load()
    old_uncovered = UncoveredStore.load()
    mods = ModResolve.run(mods)

    uncovered = map_coverage_uncovered(coverage)
    changes = calculate_changes(uncovered, old_uncovered)

    print_totals(coverage)

    if Keyword.get(opts, :verify, false) do
      verify(changes)
    else
      mutate(mods, uncovered, old_uncovered, changes)
    end
  end

  defp map_coverage_uncovered(coverage) do
    Enum.map(coverage, fn {mod, {_, miss, _}} -> {mod, miss} end)
  end

  defp calculate_changes(uncovered, old_uncovered) do
    Enum.map(uncovered, fn {mod, miss} ->
      case Keyword.fetch(old_uncovered, mod) do
        {:ok, old_miss} when miss < old_miss ->
          {mod, :improvement, old_miss - miss}

        {:ok, old_miss} when miss > old_miss ->
          {mod, :regression, miss - old_miss}

        :error when miss > 0 ->
          {mod, :regression, miss}

        :error when miss == 0 ->
          {mod, :new}

        {:ok, _} ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  defp print_totals(coverage) do
    {hit_mod, miss_mod, hit, miss} = get_totals(coverage)

    percent =
      hit
      |> get_hit_percent(miss)
      |> format_percent()
      |> b()

    mod = hit_mod + miss_mod
    all = hit + miss

    info(["Total coverage of #{mod} modules: ", b(hit), " / ", b(all), " LLOC (", percent, ")"])

    if miss_mod > 0 do
      info(["Total uncovered lines in #{miss_mod} non-green modules: ", b(miss), " LLOC"])
      info(["  (use ", b("mix uncov.list"), " to list non-green modules)"])

      info(["  (use ", b("mix uncov.show <MOD>"), " to see uncovered lines for ", b("<MOD>"), ")"])
    end

    info()
  end

  defp get_totals(coverage) do
    Enum.reduce(coverage, {0, 0, 0, 0}, fn {_, {hit, miss, _}},
                                           {hit_mod_acc, miss_mod_acc, hit_acc, miss_acc} ->
      if miss > 0 do
        {hit_mod_acc, miss_mod_acc + 1, hit + hit_acc, miss + miss_acc}
      else
        {hit_mod_acc + 1, miss_mod_acc, hit + hit_acc, miss + miss_acc}
      end
    end)
  end

  defp get_hit_percent(0, 0), do: 100.0
  defp get_hit_percent(hit, miss), do: hit * 100 / (hit + miss)

  defp format_percent(percent) do
    "#{Float.floor(percent * 1.0, 2)}%"
  end

  defp verify(changes) do
    if Enum.any?(changes) do
      print_changes(changes)
      info([:red, "Verification failed: uncommitted changes of uncovered lines"])
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)
    else
      info(["Verification passed: no uncommitted changes of uncovered lines"])
    end
  end

  defp print_changes(changes) do
    if Enum.any?(changes) do
      info(["Modules with changes of uncovered lines:"])
      info(["  (use ", b("mix uncov <MOD>"), " to commit changes for ", b("<MOD>"), ")"])
      info(["  (use ", b("mix uncov --all"), " to commit all changes)"])
      info()

      Enum.each(changes, fn
        {mod, :new} ->
          print_module_status(:green, mod, " 0")

        {mod, :improvement, diff} ->
          print_module_diff(:green, mod, diff)

        {mod, :regression, diff} ->
          print_module_diff(:red, mod, diff)
      end)

      info()
    else
      info(["No changes of uncovered lines"])
    end
  end

  defp print_module_diff(color, mod, diff) do
    diff_string = to_string(abs(diff))
    diff_sign = if diff >= 0, do: "+", else: "-"

    print_module_status(color, mod, diff_sign <> diff_string)
  end

  defp print_module_status(color, mod, status) do
    diff_string = String.pad_trailing(status, 7, " ")

    info([color, "        ", "#{diff_string} ", b(inspect(mod))])
  end

  defp mutate(mods, uncovered, old_uncovered, changes) do
    new_uncovered = calculate_new_uncovered(mods, uncovered, old_uncovered, changes)
    rem_changes = calculate_changes(uncovered, new_uncovered)

    print_changes(rem_changes)

    if Enum.count(rem_changes) < Enum.count(changes) do
      UncoveredStore.save(new_uncovered)
    end
  end

  defp calculate_new_uncovered(mods, uncovered, old_uncovered, changes) do
    Enum.map(uncovered, fn {mod, miss} ->
      old_miss = Keyword.get(old_uncovered, mod)
      change = List.keyfind(changes, mod, 0)

      cond do
        change && Enum.member?(mods, mod) ->
          {mod, miss}

        old_miss ->
          {mod, old_miss}

        true ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end
end
