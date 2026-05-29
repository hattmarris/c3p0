defmodule C3p0.GithubTest do
  use ExUnit.Case, async: true

  alias C3p0.Github

  test "issue_id_from_branch" do
    assert "LVL-4" = Github.issue_id_from_branch("matt/lvl-4-some-description")
    assert "LVL-938475" = Github.issue_id_from_branch("matt/lvl-938475-fix-the-thing")
    assert "LVL-123" = Github.issue_id_from_branch("matt/lvl-123")
    assert "ENG-7" = Github.issue_id_from_branch("someone/ENG-7-already-upper")
    assert :no_issue = Github.issue_id_from_branch("deploy-2026-05-29")
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
