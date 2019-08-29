defmodule ExUncov.Show do
  @moduledoc false

  import ExUncov.Printer
  alias ExUncov.{CoverageStore, ModResolve}

  @default_lines_around 3

  def run(mods, opts) do
    with :ok <- CoverageStore.validate() do
      do_run(mods, opts)
    end
  end

  defp do_run(mods, opts) do
    mods = ModResolve.run(mods)

    Enum.each(mods, fn mod ->
      show_mod_uncovered(mod, opts)
    end)
  end

  defp show_mod_uncovered(mod, opts) do
    lines_around = Keyword.get(opts, :lines_around, @default_lines_around)
    {_, _, lines} = CoverageStore.load_mod(mod)
    line_count = length(lines)

    uncovered_line_groups =
      lines
      |> Enum.filter(&match?({:miss, _, _}, &1))
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&((&1 - lines_around)..(&1 + lines_around)))
      |> Enum.reduce([], fn
        range, [] ->
          [range]

        _..new_to = range, [last_from.._ = last_range | rem_ranges] = ranges ->
          if Range.disjoint?(range, last_range),
            do: [range | ranges],
            else: [last_from..new_to | rem_ranges]
      end)
      |> Enum.reverse()
      |> Enum.map(fn from..to -> max(1, from)..min(line_count, to) end)
      |> Enum.map(fn range -> Enum.map(range, &Enum.at(lines, &1 - 1)) end)

    with groups when groups != [] <- uncovered_line_groups do
      info([:cyan, "#{inspect(mod)}"])
      print_line_groups(groups)
    end
  end

  defp print_line_groups([]) do
    info("  (no uncovered lines)")
    info()
  end

  defp print_line_groups(line_groups) do
    {_, max_ln, _} =
      line_groups
      |> List.last()
      |> List.last()

    ln_width =
      max_ln
      |> to_string()
      |> String.length()

    separator = String.pad_leading("", ln_width, "-")

    Enum.each(Enum.with_index(line_groups), fn
      {lines, 0} ->
        Enum.each(lines, &print_line(&1, ln_width))

      {lines, _} ->
        info([:cyan, separator])
        Enum.each(lines, &print_line(&1, ln_width))
    end)

    info()
  end

  defp print_line({type, line, code}, max_width) do
    line_num = String.pad_leading(to_string(line), max_width, " ")
    decoded_code = HtmlEntities.decode(code)

    if IO.ANSI.enabled?() do
      color =
        case type do
          :hit -> :green
          :miss -> :red
          :noop -> :normal
        end

      info([:faint, :cyan, line_num, :reset, " ", color, decoded_code])
    else
      indicator =
        case type do
          :hit -> "  "
          :miss -> "> "
          :noop -> "  "
        end

      info([line_num, " ", indicator, decoded_code])
    end
  end
end
