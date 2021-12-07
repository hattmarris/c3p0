defmodule C3p0.Slack do
  alias C3p0.Logger
  alias Jason
  alias HTTPoison

  def send_message("" <> message) do
    Logger.debug(message, label: "Matched send_message/1<string>")

    token = System.get_env("SLACK_TOKEN")

    HTTPoison.post(
      "https://slack.com/api/chat.postMessage",
      Jason.encode!(%{
        channel: "DDUQVP62H",
        text: message
      }),
      [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"}
      ]
    )
  end

  def send_message(_message), do: {:error, "Can only send string messages"}
end
