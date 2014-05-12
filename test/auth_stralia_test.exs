defmodule AuthStraliaTest do
  use Amrita.Sweet
  use Localhost

  test "Correct JSON web token is returned from /token/new endpoint" do
    response = post('/token/new', %{:user_id => "alice@example.com", :password => "Correct password"})
    {:ok, key} = :application.get_env(:auth_stralia, :jwt_secret)
    {_claims} = :ejwt.parse_jwt(response, key)
  end
end
