Code.require_file "test/test_helper.exs"

defmodule AuthStraliaTest do
  use ExUnit.Case
  use Localhost

  test "server starts" do
    get('/')
  end
end
