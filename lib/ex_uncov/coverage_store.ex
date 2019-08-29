defmodule ExUncov.CoverageStore do
  @moduledoc false

  import ExUncov.Printer

  def validate do
    if File.dir?(dir()) do
      :ok
    else
      dir = b(dir())
      cmd = b("mix test --cover")

      info([dir, " directory not found, please run ", cmd, " first"])
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)

      :error
    end
  end

  defp dir do
    Mix.Project.config()
    |> Keyword.get(:test_coverage, [])
    |> Keyword.get(:output, "cover")
  end

  def mods do
    Enum.map(files(), &file_to_mod/1)
  end

  defp files do
    dir()
    |> Path.join("*.html")
    |> Path.wildcard()
  end

  # sobelow_skip ["DOS.StringToAtom"]
  def file_to_mod(file) do
    file
    |> Path.basename()
    |> Path.rootname()
    |> String.to_atom()
  end

  def load do
    Enum.map(files(), fn file ->
      mod = file_to_mod(file)
      mod_coverage = load_file(file)

      {mod, mod_coverage}
    end)
  end

  def load_mod(mod) do
    mod
    |> mod_to_file()
    |> load_file()
  end

  defp mod_to_file(mod) do
    Path.join(dir(), "Elixir.#{inspect(mod)}.html")
  end

  @coverage_line_regex ~r"""
  <tr( class="(\w+)")?>
  <td class="line" id="L(\d+)">.*?</td>
  <td class="hits">.*</td>
  <td class="source"><code>(.*?)</code></td>
  </tr>
  """

  # sobelow_skip ["Traversal.FileModule"]
  defp load_file(file) do
    html = File.read!(file)

    lines =
      @coverage_line_regex
      |> Regex.scan(html, capture: :all_but_first)
      |> Enum.map(fn [_, type, line, code] ->
        type = parse_coverage_type(type)
        line = String.to_integer(line)

        {type, line, code}
      end)

    hit = Enum.count(lines, &match?({:hit, _, _}, &1))
    miss = Enum.count(lines, &match?({:miss, _, _}, &1))

    {hit, miss, lines}
  end

  defp parse_coverage_type("hit"), do: :hit
  defp parse_coverage_type("miss"), do: :miss
  defp parse_coverage_type(""), do: :noop
end
