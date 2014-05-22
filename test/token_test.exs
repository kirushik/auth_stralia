defmodule TokenTest do
  use Amrita.Sweet
  import TokenOperations

  describe "Token" do
    it "parses correct token" do
      token = generate_token({[]})
      correct_timestamp = epoch()+86400
      :proplists.get_value("exp", Token.parse(token)) |> correct_timestamp
    end
    it "gets field from token" do
      value = "aaa"
      token = generate_token({[data: value]})
      Token.extract(token, "data") |> value
    end
    it "gets field from parsed token" do
      value = "qqq"
      parsed_token = [{"data", value}]
      Token.get(parsed_token, "data") |> value
    end
    it "returns :invalid when token is invalid" do
      token = "adfkasjfdhlkajdshflakj"
      Token.parse(token) |> :invalid
    end
  end
end