defmodule C3p0.Github do
  alias Jason
  alias C3p0.{Logger}
  alias Tentacat.{Client, Issues}

  def create_pr(owner, repo) do
    # Logger.debug({owner, repo}, label: "create_pr/2")

    token = System.get_env("GITHUB_API_TOKEN")
    client = Client.new(%{access_token: token})

    local_branch = cwd_local_branch()

    issue_number = issue_number_from_branch(local_branch)

    {200, issue, _resp} = Issues.find(client, owner, repo, issue_number)

    create_pr_title(issue)

    # TODO
    # Get issue title from github
    # Create PR with correct title and body on github for current branch
  end

  def create_pr_title(%{"number" => number, "title" => title} = _issue) do
    "[gh-#{number}] #{title}"
  end

  def create_pr_body(%{number: number} = _issue) do
    """
    Resolves #{number}
    """
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

  def issue_number_from_branch(branch) do
    "issue-" <> number = branch

    number
  end
end
