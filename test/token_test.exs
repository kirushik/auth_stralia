defmodule TokenTest do
  use Amrita.Sweet
  import TokenOperations

  describe "Token" do
    it "parses correct token" do
      token = generate_token(%{})
      correct_timestamp = epoch()+86400
      Token.parse(token).exp |> correct_timestamp
    end
    it "correctly composes the token" do
      timestamp = 22786400
      generate_token(%{}, timestamp) |> equals Token.compose(%{}, timestamp)
    end
    it "gets field from token" do
      value = "aaa"
      token = generate_token(%{data: value})
      Token.extract(token, :data) |> value
    end
    it "returns :invalid when token is invalid" do
      token = "adfkasjfdhlkajdshflakj"
      Token.parse(token) |> :invalid
    end
    it "returns :expired when token is expired" do
      token = generate_token(%{},0)
      Token.parse(token) |> :expired
    end

    it "correctly parses the expired token in forced mode" do
      now = epoch()
      token = generate_token(%{},0)
      %{exp: now} |> equals Token.parse(token, :force)
      #TODO This test would fail from time to time, only due to changed timestamp
      Token.parse(token) |> :expired
    end

    it "correctly issues user verification tokens" do
      token = Token.generate_verification_token("username", "session_id")
      %{sub: "username", jti: "session_id", typ: "user_verification_token"} |> match?(Token.parse(token)) |> truthy
    end

    it "issues user verification tokens with proper time correction" do
      now = epoch()
      token = Token.generate_verification_token("username", "", 100)
      Token.parse(token).exp |> equals now + 100
    end

    it "updates token's expiration time" do
      old_time = epoch() + 10
      new_time = old_time + 990
      token = generate_token(%{}, old_time) |> Token.update_expiration_time(1000)
      Token.parse(token).exp |> new_time
    end

    it "correctly updates expired tokens" do
      now = epoch()
      token = generate_token(%{},0) |> Token.update_expiration_time
      Token.parse(token).exp |> equals now + Settings.expiresIn
    end
  end
end
