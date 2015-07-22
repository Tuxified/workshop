defmodule Mix.Tasks.Workshop.New.Exercise do
  use Mix.Task
  import Mix.Generator
  import Mix.Utils, only: [camelize: 1]

  @shortdoc "Create a new exercise for a workshop"
  @moduledoc """
  Creates a new exercise for a workshop.

  It expects a name for the new exercise

      mix workshop.new NAME

  The path will be named after the given NAME. Given `my_exercise` it will
  result in a workshop named *My Exercise*. The generated files will be
  stored in folder prefixed with a number, like "010", incrementing by 10
  for every exercise that is created.
  """
  @spec run(OptionParser.argv) :: :ok
  def run(argv) do
    {opts, argv, _} = OptionParser.parse(argv, switches: [])

    # current working dir should be `.workshop` and it should have an `exercises`-folder
    path = find_workshop_root_dir(File.cwd!)
           |> Path.join(".workshop")
           |> Path.join("exercises")
    unless File.exists?(path),
      do: Mix.raise "This command should be executed within a workshop folder"
    # update current working dir
    File.cd!(path)

    case argv do
      [] -> Mix.raise "Expected NAME to be given. Please use `mix workshop.new.exercise NAME`"
      [name|_] ->
        name = Path.basename(Path.expand(name))
        check_workshop_name!(name)
        mod = camelize(name)
        title = snake_case_to_headline(name)
        exercise_folder = Path.join(path, get_next_exercise_weight <> "_" <> name)

        case File.mkdir_p(exercise_folder) do
          :ok ->
            File.cd!(exercise_folder, fn ->
              do_generate_exercise(path, title, mod, opts)
            end)
        end
    end
  end

  # todo, should traverse the file structure until it find the root of the workshop
  defp find_workshop_root_dir(_path) do
    Path.expand("sandbox")
  end

  # workshops should get prefixed with a weight
  defp get_exercises_by_weight do
    File.ls!(File.cwd!)
    |> Enum.reject(&(String.starts_with?(&1, ".")))
    |> Enum.map(fn item ->
                  [number, name] = String.split(item, "_", parts: 2)
                  {String.to_integer(number), name}
               end)
    |> Enum.sort
  end

  # calculate the next weight value for the next exercise
  defp get_next_exercise_weight do
    case Enum.reverse(get_exercises_by_weight) do
      [{weight, _} | _] ->
        weight + 10 |> Integer.to_string |> String.rjust(3, ?0)

      [] ->
        "010"
    end
  end

  defp check_workshop_name!(name) do
    # taken from the `mix new` source code
    unless name =~ ~r/^[a-z][\w_]*$/ do
      Mix.raise "Exercise name must start with a letter and have only lowercase " <>
                "letters, numbers and underscore, got: #{inspect name}"
    end
  end

  defp snake_case_to_headline(name) do
    name
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp do_generate_exercise(name, title, mod, opts) do
    assigns = [name: name, title: title, module: mod]
    IO.inspect {assigns, opts}
    create_file "README.md", readme_template(assigns)
    create_directory "files"
    create_directory "test"
    create_file "test/test_helper.exs", ""
  end

  embed_template :readme, """
  <%= @title %>
  <%= String.replace(@title, ~r/./, "=") %>
  **TODO: add a short description of the exercise**

  What's next?
  ------------
  Type `mix workshop.check` to check your solution. If you pass you can proceed
  to the next exercise by typing `mix workshop.next`. This is all done in the
  terminal.

  If you are confused you could try `mix workshop.hint`. Otherwise ask your
  instructor or follow the directions on `mix workshop.help`.
  """
end
