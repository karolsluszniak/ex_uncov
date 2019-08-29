defmodule ExUncov.List do
  @moduledoc false

  import ExUncov.Printer
  alias ExUncov.CoverageStore

  def run do
    with :ok <- CoverageStore.validate() do
      do_run()
    end
  end

  defp do_run do
    coverage = CoverageStore.load()
    info([:cyan, "  UNCOV  ", "  ", "MODULE"])
    Enum.each(coverage, &print_module/1)
  end

  defp print_module({mod, {_, 0, _}}) do
    print_module_status(:green, mod, "0")
  end

  defp print_module({mod, {_, miss, _}}) do
    print_module_status(:red, mod, to_string(miss))
  end

  defp print_module_status(color, mod, status) do
    diff_string = String.pad_trailing(status, 7, " ")

    info([color, "  #{diff_string}", "  ", b(inspect(mod))])
  end
end
