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
      token = generate_token(%{},0)
      %{exp: epoch()} |> equals Token.parse(token, :force)
      Token.parse(token) |> :expired
    end

    it "updates token's expiration time" do
      old_time = epoch() + 10
      new_time = epoch() + 1000
      token = generate_token(%{}, old_time)
      token |> Token.update_expiration_time(1000) |> Token.parse |> Map.get(:exp) |> new_time
    end
  end
end
