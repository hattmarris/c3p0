defmodule C3p0.Logger do
  use Agent

  def start(level \\ :warn) do
    Agent.start_link(fn -> level end, name: __MODULE__)
  end

  def change(level) do
    Agent.get_and_update(__MODULE__, &{&1, level})
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def stop do
    Agent.stop(__MODULE__)
  end

  def debug(input, opts \\ []) do
    if value() == :debug do
      case Keyword.get(opts, :label) do
        "" <> _label ->
          IO.inspect(input, prepend_label(opts, "DEBUG: "))

        nil ->
          debug_no_opts(input)
      end
    end
  end

  defp debug_no_opts("" <> str), do: IO.inspect(str, label: "DEBUG: " <> str)
  defp debug_no_opts(input), do: IO.inspect(input)

  defp prepend_label(opts, label) do
    Keyword.put(opts, :label, label <> Keyword.get(opts, :label))
  end
end
