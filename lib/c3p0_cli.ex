defmodule C3p0.Cli do
  alias C3p0

  def main(args) do
    options = [
      switches: [
        debug: :boolean,
        message: :string,
        base: :string,
        channel: :string
      ],
      aliases: [
        b: :base,
        c: :channel,
        d: :debug,
        m: :message
      ]
    ]

    OptionParser.parse(args, options)
    |> C3p0.start_logger()
    |> C3p0.interpret()
    |> IO.inspect()
  end
end
