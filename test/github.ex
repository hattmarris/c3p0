defmodule C3p0.GithubTest do
  use ExUnit.Case, async: true

  alias C3p0.Github

  test "issue_id_from_branch" do
    assert "4" = Github.issue_id_from_branch("issue-4")
    assert "938475" = Github.issue_id_from_branch("issue-938475")
  end
end
