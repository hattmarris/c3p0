defmodule C3p0.Slack do
  alias C3p0.Logger
  alias Jason
  alias HTTPoison
  alias HTTPoison.Response

  def send_message("" <> message, opts \\ []) do
    Logger.debug({message, opts}, label: "send_message/1")

    token = System.fetch_env!("SLACK_USER_TOKEN")
    channel_default = System.get_env("SLACK_CHANNEL", "matt")
    channel_name = Keyword.get(opts, :channel, channel_default)
    channel = get_channel(channel_name)

    Logger.debug(channel, label: "The slack channel ID")

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    body =
      Jason.encode!(%{
        channel: channel,
        text: message
      })

    "https://slack.com/api/chat.postMessage"
    |> HTTPoison.post(body, headers)
    |> case do
      {:ok, %Response{status_code: 200, body: "{\"ok" <> _} = resp} -> {:ok, resp}
      {_, %Response{status_code: code}} -> {:error, code}
    end
  end

  defp get_channel(name) do
    case Map.fetch(channel_map(), name) do
      {:ok, id} -> id
      :error -> name
    end
  end

  defp channel_map do
    with json when is_binary(json) and json != "" <- System.get_env("SLACK_CHANNELS"),
         {:ok, map} when is_map(map) <- Jason.decode(json) do
      map
    else
      _ -> %{}
    end
  end
end
