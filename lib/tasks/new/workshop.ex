defmodule Mix.Tasks.New.Workshop do
  use Mix.Task
  import Mix.Generator
  import Mix.Utils, only: [camelize: 1]

  @shortdoc "Create a new workshop"
  @moduledoc """
  Creates a new workshop.

  It expects a path for the workshop

      mix new.workshop PATH

  The path will be named after the given PATH. Given `my_workshop` will
  result in a workshop named *My Workshop*.
  """

  @spec run(OptionParser.argv) :: :ok
  def run(argv) do
    {opts, argv, _} = OptionParser.parse(argv, switches: [])

    case argv do
      [] -> Mix.raise "Expected PATH to be given. Please use `mix new.workshop PATH`"
      [path|_] ->
        name = Path.basename(Path.expand(path))
        check_workshop_name!(name)
        mod = "Workshop"
        title = opts[:title] || snake_case_to_headline(name)

        case File.mkdir_p(path) do
          :ok ->
            File.cd!(path, fn ->
              do_generate_workshop(path, title, mod, opts)
            end)
        end
    end
  end

  defp check_workshop_name!(name) do
    # taken from the `mix new` source code
    unless name =~ ~r/^[a-z][\w_]*$/ do
      Mix.raise "Workshop name must start with a letter and have only lowercase " <>
                "letters, numbers and underscore, got: #{inspect name}"
    end
  end

  defp do_generate_workshop(name, title, mod, _opts) do
    assigns = [name: name, title: title, module: mod]

    create_file "README.md", readme_template(assigns)
    create_directory ".workshop"
    create_file ".workshop/prerequisite.exs", prerequisite_template(assigns)
    create_file ".workshop/workshop.exs", workshop_template(assigns)
    create_directory ".workshop/exercises"
    create_file ".workshop/exercises/.gitkeep", ""
  end

  defp snake_case_to_headline(name) do
    name
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  embed_template :readme, """
  <%= @title %>
  <%= String.replace(@title, ~r/./, "=") %>
  **TODO: add a short description of the workshop**

  What's next?
  ------------
  Type `mix workshop.start` in the terminal to start the workshop, and
  have fun!
  """

  embed_template :workshop, """
  defmodule Workshop.Meta do
    use Workshop.Info

    # The human readable title of the workshop.
    @title "<%= @title %>"

    # The version number is used to verify what version of the workshop the user
    # is running.
    @version "0.0.1"

    # An optional short description of the workshop. Will get shown at places
    # where the long description would not fit, such as the `mix workshop` screen.
    # Set this to `false` if you want to suppress the missing shortdesc warning.
    @shortdesc nil

    # The description should state what the user will learn from this workshop.
    # Perhaps mention the intended audience.
    @description \"""
    Describe the workshop here.
    \"""

    # The introduction should welcome the user to the workshop, set the
    # expectations, and inform the user to execute the next-command to get to the
    # first exercise.
    @introduction \"""
    This is the introduction and it will get displayed when the workshop has been
    started.

    Don't forget to inform the user to write `mix workshop.next` to get to the
    first exercise.
    \"""

    # The debriefing message will get shown when the workshop is over.
    # This would be a good opportunity to congratulate the user; perhaps thank the
    # user and; and ask for feedback.
    @debriefing \"""
    You have completed the last exercise. Congratulations!
    \"""
  end
  """

  embed_template :prerequisite, """
  defmodule Workshop.Prerequisite do
    @type result :: :ok | {:error, String.t} | {:warning, String.t}
    @type test_function :: (() -> result)

    @spec run :: [test_function]
    def run do
      # register all the checks in this list
      [&should_check_the_truth/0]
    end

    @spec should_check_the_truth :: result
    defp should_check_the_truth do
      # just remove and replace this example check
      case 1 + 1 do
        2 ->
          :ok
        3 ->
          {:warning, "Math doesn't seem to work, but we'll work with it"}
        :otherwise ->
          {:error, "Something is seriously wrong with the universe"}
      end
    end
  end
  """
end
