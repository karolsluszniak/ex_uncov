defmodule ExUncov.UncoveredStore do
  @moduledoc false

  @uncovered_file ".uncov.lock"

  # sobelow_skip ["Traversal.FileModule"]
  def load do
    if File.exists?(@uncovered_file) do
      @uncovered_file
      |> File.read!()
      |> String.split("\n")
      |> Enum.reduce([], fn line, uncovered ->
        with [[_, mod_string, miss_string]] <- Regex.scan(~r/^  {([\w.]+), (\d+)},$/, line),
             mod = Module.concat("Elixir", mod_string),
             {miss, ""} <- Integer.parse(miss_string),
             existing_miss = Keyword.get(uncovered, mod),
             true <- is_nil(existing_miss) or existing_miss < miss do
          uncovered ++ [{mod, miss}]
        else
          _ -> uncovered
        end
      end)
    else
      []
    end
  end

  def save(new_uncovered) do
    content =
      Enum.map(new_uncovered, fn {mod, miss} ->
        "  {#{inspect(mod)}, #{miss}},"
      end)
      |> Enum.join("\n")

    content = "[\n" <> content <> "\n]\n"

    File.write!(@uncovered_file, content)
  end
end
