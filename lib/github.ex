defmodule C3p0.Github do
  alias Jason
  alias C3p0.{Logger, Slack}
  alias Tentacat.{Client, Pulls}

  @linear_workspace "levelall"

  def create_pr(base, message, opts \\ []) do
    Logger.debug(base, label: "create_pr/3")

    token = System.fetch_env!("GH_TOKEN")
    client = Client.new(%{access_token: token})
    local_repo = cwd_repo()
    {owner, repo} = parse_remote_push(local_repo)
    branch = local_branch(local_repo)

    git_data = {client, owner, repo, branch, base}

    case branch |> attempt_push() |> issue_id_from_branch() do
      :no_issue -> no_issue_pipeline(git_data, message, opts)
      identifier -> issue_pipeline(identifier, git_data, message, opts)
    end
  end

  def slack_pr(opts \\ []) do
    Logger.debug(opts, label: "slack_pr/1")

    token = System.fetch_env!("GH_TOKEN")
    client = Client.new(%{access_token: token})
    local_repo = cwd_repo()
    {owner, repo} = parse_remote_push(local_repo)
    branch = local_branch(local_repo)

    pr = find_pr_for_branch(client, owner, repo, branch)

    case issue_id_from_branch(branch) do
      :no_issue -> no_issue_notify_slack(pr, opts)
      identifier -> notify_slack(identifier, linear_issue_url(identifier), pr, opts)
    end

    IO.puts("Slack notified")
  end

  def issue_pipeline(identifier, {client, owner, repo, branch, base}, message, opts \\ []) do
    title = pr_title(identifier, message)
    issue_url = linear_issue_url(identifier)

    body = ~s"""
    #{title}

    Linear: #{issue_url}
    """

    pr_body = %{
      "title" => title,
      "body" => body,
      "head" => branch,
      "base" => base
    }

    Logger.debug(pr_body, label: "PR body")

    case Pulls.create(client, owner, repo, pr_body) do
      {201, pr, _resp} ->
        notify_slack(identifier, issue_url, pr, opts)

      other ->
        brexit(other, "Could not create pull request, exiting.")
    end

    IO.puts("PR created, slack notified")
  end

  def no_issue_pipeline({client, owner, repo, branch, base}, message, opts \\ []) do
    Logger.debug(branch, label: "no_issue_pipeline/3")

    body = %{
      title: "[deploy] #{message}",
      body: "[deploy] #{message}",
      head: branch,
      base: base
    }

    Logger.debug(body, label: "PR body")

    case Pulls.create(client, owner, repo, body) do
      {201, pr, _resp} ->
        no_issue_notify_slack(pr, opts)

      other ->
        brexit(other, "Could not create pull request, exiting.")
    end

    IO.puts("PR created, slack notified")
  end

  defp find_pr_for_branch(client, owner, repo, branch) do
    case Pulls.filter(client, owner, repo, %{head: "#{owner}:#{branch}", state: "open"}) do
      {200, [pr | _], _resp} ->
        pr

      {200, [], _resp} ->
        brexit(branch, "No open PR found for branch #{branch}, exiting.")

      other ->
        brexit(other, "Could not list pull requests, exiting.")
    end
  end

  defp pr_title(identifier, nil), do: "[#{identifier}]"
  defp pr_title(identifier, ""), do: "[#{identifier}]"
  defp pr_title(identifier, message), do: "[#{identifier}] #{message}"

  def linear_issue_url(identifier) do
    "https://linear.app/#{@linear_workspace}/issue/#{identifier}"
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

  def notify_slack(identifier, issue_url, %{"title" => title, "html_url" => html_url}, opts \\ []) do
    message = ~s"""
    Issue: <#{issue_url}|#{identifier}> is ready for code review -
    PR ==> <#{html_url}|#{title}> <==
    """

    slack_or_bust(message, opts)
  end

  def no_issue_notify_slack(%{"title" => title, "html_url" => html_url}, opts \\ []) do
    message = ~s"""
    Deploy (no issue): ready for code review -
    PR ==> <#{html_url}|#{title}> <==
    """

    slack_or_bust(message, opts)
  end

  def slack_or_bust(message, opts \\ []) do
    case Slack.send_message(message, opts) do
      {:ok, response} ->
        {:ok, response}

      {:error, reason} ->
        brexit(reason, "Could not notify slack, exiting.")
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

  def issue_id_from_branch(branch) do
    case branch do
      "deploy-" <> _rest ->
        :no_issue

      _ ->
        case Regex.run(~r{^[^/]+/([a-zA-Z]+-\d+)(?:-.*)?$}, branch) do
          [_, id] ->
            String.upcase(id)

          nil ->
            brexit(
              branch,
              "Local branch name doesn't match format <user>/<team>-<number>(-<slug>), exiting."
            )
        end
    end
  end

  defp brexit(obj, message) do
    IO.puts(message)

    Logger.debug(obj, label: message)

    System.halt(0)
  end
end
