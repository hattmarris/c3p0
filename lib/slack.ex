defmodule C3p0.Slack do
  alias C3p0.Logger
  alias Jason
  alias HTTPoison

  def send_message("" <> message) do
    Logger.debug(message, label: "Matched send_message/1<string>")

    token = System.get_env("SLACK_TOKEN")
    channel = System.get_env("SLACK_CHANNEL_NAME") |> get_channel()

    Logger.debug(channel, label: "The slack channel ID")

    HTTPoison.post(
      "https://slack.com/api/chat.postMessage",
      Jason.encode!(%{
        channel: channel,
        text: message
      }),
      [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ]
    )
  end

  def send_message(_message), do: {:error, "Can only send string messages"}

  defp get_channel(name) do
    case name do
      "matt" ->
        "DDUQVP62H"

      "product" ->
        "C013BAL8292"

      "" ->
        Logger.debug("get_channel/1 given empty string channel name, using default")
        "DDUQVP62H"

      nil ->
        Logger.debug("get_channel/1 given nil channel name, using default")
        "DDUQVP62H"
    end
  end
end
