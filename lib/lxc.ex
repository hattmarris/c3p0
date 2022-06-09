defmodule C3p0.Lxc do
  alias C3p0.Logger
  alias HTTPoison

  @scheme "http+unix"
  @socket "/var/snap/lxd/common/lxd/unix.socket"

  defmodule __MODULE__.Response.Body do
    defstruct error: "",
              error_code: 0,
              metadata: [],
              operation: "",
              status: "",
              status_code: 0,
              type: ""
  end

  alias __MODULE__.Response

  def list() do
    Logger.debug("List instances")

    get!("/1.0/instances")
    |> decode_body!()
    |> to_struct()
    |> get_data()
    |> Enum.map(fn s -> String.split(s, "/") |> List.last() end)
  end

  def get!(path) do
    url = @scheme <> "://" <> URI.encode_www_form(@socket)

    [url, path]
    |> Path.join()
    |> HTTPoison.get!()
    |> handle_response()
  end

  def handle_response(%HTTPoison.Response{status_code: 200} = response), do: response

  def decode_body!(%HTTPoison.Response{body: body}), do: Jason.decode!(body)

  def to_struct(map) do
    %Response.Body{
      error: map["error"],
      error_code: map["error_code"],
      metadata: map["metadata"],
      operation: map["operation"],
      status: map["status"],
      status_code: map["status_code"],
      type: map["type"]
    }
  end

  def get_data(%Response.Body{metadata: data}), do: data
end
