defmodule Mix.Tasks.Workshop.Validate do
  use Mix.Task
  alias Workshop.ValidationResult, as: Result

  @spec run(OptionParser.argv) :: :ok
  def run(argv) do
    Workshop.start([], [])
    {_opts, _, _} = OptionParser.parse(argv, switches: [system: :boolean])

    Workshop.validate
    |> handle_validation_result
  end

  defp handle_validation_result(%Result{runs: x, passed: x}) do
    Mix.shell.info "Everything seems to be in order (#{x}/#{x} passed)"
  end
  defp handle_validation_result(%Result{errors: errors}) do
    Mix.shell.error """
    This does not seem to be a valid workshop. Please fix the following errors:

    #{errors |> Enum.map(&("  * #{&1}")) |> Enum.join("\n")}
    """
    System.at_exit fn _ ->
      exit({:shutdown, 1})
    end
  end
end
