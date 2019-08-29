defmodule ExUncov.ModResolve do
  @moduledoc false

  alias ExUncov.CoverageStore

  def run(:all) do
    CoverageStore.mods()
  end

  def run(matches) when is_list(matches) do
    all_mods = CoverageStore.mods()
    matches = map_file_matches(matches)

    Enum.filter(all_mods, &mod_match?(&1, matches))
  end

  defp map_file_matches(matches) do
    Enum.map(matches, fn match ->
      if Path.extname(match) == ".html" do
        match
        |> Path.basename()
        |> Path.rootname()
        |> String.replace("Elixir.", "")
      else
        match
      end
    end)
  end

  defp mod_match?(mod, matches) do
    Enum.any?(matches, fn match ->
      match_escaped =
        match
        |> Regex.escape()
        |> String.replace("\\*", ".*")

      String.match?(inspect(mod), ~r/^#{match_escaped}$/)
    end)
  end
end
