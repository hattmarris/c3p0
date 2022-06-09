defmodule C3p0.Lxc do
  alias C3p0.Logger
  alias HTTPoison

  @scheme "http+unix"
  @socket "/var/snap/lxd/common/lxd/unix.socket"

  def list() do
    Logger.debug("List instances")
    get("/1.0/instances")
  end

  def get(path) do
    url = @scheme <> "://" <> URI.encode_www_form(@socket)

    [url, path]
    |> Path.join()
    |> HTTPoison.get()
    # |> then(fn {:ok, r} -> Jason.decode(r.body) end)
    |> IO.inspect()
  end
end
