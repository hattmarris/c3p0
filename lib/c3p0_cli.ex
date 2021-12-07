defmodule C3p0.Cli do
  alias C3p0

  def main(args) do
    options = [
      switches: [
        debug: :boolean,
        message: :string,
        repo: :string,
        owner: :string
      ],
      aliases: [
        d: :debug,
        m: :message,
        r: :repo,
        o: :owner
      ]
    ]

    OptionParser.parse(args, options)
    |> C3p0.start_logger()
    |> C3p0.interpret()
    |> IO.inspect()
  end
end
