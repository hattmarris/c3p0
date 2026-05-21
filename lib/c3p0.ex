defmodule C3p0 do
  alias C3p0.{Github, Logger, Slack}

  def interpret({_opts, ["start"], []}) do
    Logger.debug("Starting C3p0")

    []
  end

  def interpret({opts, ["slack"], []}) do
    Logger.debug(label: "Interpreted as send a message to slack")

    slack(opts)
  end

  def interpret({opts, ["pr"], []}) do
    Logger.debug("Interpreted as a create pr")

    base = Keyword.get(opts, :base, "main")
    message = Keyword.get(opts, :message)

    Github.create_pr(base, message)
  end

  def interpret({_opts, _args, _invalid}), do: "Invalid options args or subcommands"

  def slack(opts \\ []) do
    message = Keyword.fetch!(opts, :message)

    case Slack.send_message(message, opts) do
      {:ok, _resp} -> {:done, "Message sent."}
      {:error, code} -> {:error, "Something went wrong... #{code}"}
    end
  end

  def start_logger({opts, args, invalid} = parsed) do
    case Keyword.get(opts, :debug) do
      true ->
        Logger.start(:debug)
        Logger.debug(opts, label: "Parsed options")
        Logger.debug(args, label: "Remaining args")
        Logger.debug(invalid, label: "Invalid")

      false ->
        Logger.start(:warn)

      nil ->
        Logger.start(:warn)
    end

    parsed
  end
end
