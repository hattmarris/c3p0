defmodule C3p0.GithubTest do
  use ExUnit.Case, async: true

  alias C3p0.Github

  test "issue_number_from_branch" do
    assert "4" = Github.issue_number_from_branch("issue-4")
    assert "938475" = Github.issue_number_from_branch("issue-938475")
  end

  test "local_branch" do
    {branches, _exit_status} = System.cmd("git", ["branch"])
    "* " <> orig_branch = String.split(branches, "\n") |> Enum.find(fn x -> x =~ "* " end)

    repo = File.cwd!() |> Git.new()

    Git.checkout(repo, "main")

    assert "main" = Github.cwd_local_branch()

    Git.checkout(repo, orig_branch)
  end
end
