defmodule C3p0 do
  alias C3p0.{Github, Logger, Lxc, Slack}

  def interpret({_opts, ["start"], []}) do
    Logger.debug("Starting C3p0")

    []
  end

  def interpret({opts, ["slack"], []}) do
    message = Keyword.get(opts, :message)

    Logger.debug(message, label: "Interpreted as send a message to slack")

    slack(message)
  end

  def interpret({opts, ["pr"], []}) do
    Logger.debug("Interpreted as a create pr")

    base = Keyword.get(opts, :base, "main")
    message = Keyword.get(opts, :message)

    Github.create_pr(base, message)
  end

  def interpret({opts, ["lxc", "list"], []}) do
    Logger.debug("Interpreted as list lxc instances")

    Lxc.list()
  end

  def interpret({_opts, _args, _invalid}), do: "Invalid options args or subcommands"

  def slack(message) do
    case Slack.send_message(message) do
      {:ok, _response} -> {:done, "Message sent."}
      {:error, reason} -> {:error, "Something went wrong... #{reason}"}
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
