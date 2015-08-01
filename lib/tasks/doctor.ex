defmodule Mix.Tasks.Workshop.Doctor do
  use Mix.Task

  @spec run(OptionParser.argv) :: :ok
  def run(argv) do
    Workshop.start([], [])
    {_, _, _} = OptionParser.parse(argv, switches: [system: :boolean])

    result = Workshop.Session.get(:data_folder)
             |> prerequisite_file
             |> execute_prerequisite_check

    System.at_exit fn _ ->
      if result != :ok do
        exit({:shutdown, 1})
      end
    end
  end

  @prerequisite_file_name "prerequisite.exs"
  defp prerequisite_file(folder),
    do: Path.join(folder, @prerequisite_file_name)

  defp execute_prerequisite_check(path) do
    if File.exists? path do
      # compile and execute the run function on the first found module
      Code.require_file(path)
      apply(Workshop.Prerequisite, :run, [])
    else
      {:ok, "no prerequisites defined"}
    end
  end
end
