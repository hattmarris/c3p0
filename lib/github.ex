defmodule C3p0.Github do
  alias Jason
  alias C3p0.{Logger, Slack}
  alias Tentacat.{Client, Issues, Pulls}

  def create_pr(base, message) do
    Logger.debug(base, label: "create_pr/2")

    token = System.get_env("GITHUB_API_TOKEN")
    client = Client.new(%{access_token: token})
    local_repo = cwd_repo()
    {owner, repo} = parse_remote_push(local_repo)
    branch = local_branch(local_repo)

    git_data = {client, owner, repo, branch, base}

    case branch |> attempt_push() |> issue_number_from_branch do
      :no_issue -> no_issue_pipeline(git_data, message)
      number -> issue_pipeline(number, git_data)
    end
  end

  def issue_pipeline(issue_number, {client, owner, repo, branch, base}) do
    {:ok, _response} =
      issue_number
      |> find_issue({client, owner, repo})
      |> create_pr_title()
      |> create_pr_body()
      |> submit_pr({client, owner, repo, branch, base})

    IO.puts("PR created, slack notified")
  end

  def no_issue_pipeline({client, owner, repo, branch, base}, message) do
    Logger.debug(branch, label: "no_issue_pipeline/1")

    body = %{
      title: "[deploy] #{message}",
      body: "[deploy] #{message}",
      head: branch,
      base: base
    }

    Logger.debug(body, label: "PR body")

    case Pulls.create(client, owner, repo, body) do
      {201, pr, _resp} ->
        no_issue_notify_slack(pr)

      other ->
        brexit(other, "Could not create pull request, exiting.")
    end

    IO.puts("PR created, slack notified")
  end

  def submit_pr({issue, title, body}, {client, owner, repo, branch, base}) do
    body = %{
      "title" => title,
      "body" => body,
      "head" => branch,
      "base" => base
    }

    case Pulls.create(client, owner, repo, body) do
      {201, pr, _resp} ->
        notify_slack(issue, pr)

      other ->
        brexit(other, "Could not create pull request, exiting.")
    end
  end

  def find_issue(issue_number, {client, owner, repo}) do
    case Issues.find(client, owner, repo, issue_number) do
      {200, issue, _resp} ->
        issue

      error ->
        brexit(error, "Could not find issue, exiting.")
    end
  end

  def parse_remote_push(local_repo) do
    remote_str =
      local_repo
      |> Git.remote!(["-v"])
      |> String.split("\n")
      |> Enum.find(fn x -> x =~ " (push)" end)

    case Regex.named_captures(
           ~r/git@github.com:(?<owner>.*)\/(?<repo>.*).git\s\(push\)$/,
           remote_str
         ) do
      %{"owner" => owner, "repo" => repo} ->
        {owner, repo}

      nil ->
        IO.puts("Could not parse a remote push url, exiting.")
        System.halt(0)
    end
  end

  def notify_slack(issue, %{"title" => title, "html_url" => html_url}) do
    message = ~s"""
    Issue: <#{issue["html_url"]}|#{issue["title"]} ##{issue["number"]}> is ready for code review -
    PR ==> <#{html_url}|#{title}> <==
    """

    slack_or_bust(message)
  end

  def no_issue_notify_slack(%{"title" => title, "html_url" => html_url}) do
    message = ~s"""
    Deploy (no issue): ready for code review -
    PR ==> <#{html_url}|#{title}> <==
    """

    slack_or_bust(message)
  end

  def slack_or_bust(message) do
    case Slack.send_message(message) do
      {:ok, response} ->
        {:ok, response}

      {:error, reason} ->
        brexit(reason, "PR was created, but could not notify slack, exiting.")
    end
  end

  def attempt_push(local_branch) do
    case cwd_repo() |> Git.push() do
      {:ok, _out} ->
        local_branch

      {:error, _err} ->
        Logger.debug("push failed, setting upstream first")
        set_upstream(local_branch)
    end
  end

  def set_upstream(local_branch) do
    cwd_repo()
    |> Git.push!(["--set-upstream", "origin", local_branch])

    local_branch
  end

  def create_pr_title(%{"number" => number, "title" => title} = issue) do
    {issue, "[gh-#{number}] #{title}"}
  end

  def create_pr_body({%{"body" => issue_body, "number" => number} = issue, title}) do
    body = ~s"""
    #{title}

    #{issue_body}

    Resolves ##{number}
    """

    {issue, title, body}
  end

  def cwd_repo do
    File.cwd!()
    |> Git.new()
  end

  def cwd_local_branch do
    cwd_repo() |> local_branch
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
    case branch do
      "issue-" <> number -> number
      "deploy-" <> _rest -> :no_issue
      other -> brexit(other, "Local branch name doesn't match format issue-<number>, exiting.")
    end
  end

  defp brexit(obj, message) do
    IO.puts(message)

    Logger.debug(obj, label: message)

    System.halt(0)
  end
end
