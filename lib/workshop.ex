defmodule Workshop do
  def find_exercise_folders(folder) do
    folder
    |> File.ls!
    |> Enum.filter(&(String.starts_with? &1, "exercise"))
    |> Enum.filter(&(File.dir?(Path.join(folder, &1))))
  end

  def info(folder) do
    path = Path.join(folder, "manifest.exs")
    Code.load_file(path) |> hd |> elem(0)
  end
end
