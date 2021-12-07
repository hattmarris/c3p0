defmodule C3p0.Github do
  alias Jason
  alias C3p0.{Logger}
  alias Tentacat.{Client, Pulls}

  def create_pr(owner, repo) do
    Logger.debug({owner, repo}, label: "create_pr/2")

    token = System.get_env("GITHUB_API_TOKEN")
    client = Client.new(%{access_token: token})

    {status, term, _response} = Pulls.list(client, owner, repo)

    IO.inspect(cwd_local_branch())

    {status, List.first(term)["title"]}
  end

  def cwd_local_branch do
    File.cwd!()
    |> Git.new()
    |> local_branch
  end

  def local_branch(repo) do
    "* " <> branch =
      repo
      |> Git.branch!()
      |> String.split("\n")
      |> Enum.find(fn x -> x =~ "* " end)

    branch
  end

  def issue_id_from_branch(branch) do
    "issue-" <> id = branch

    id
  end
end
