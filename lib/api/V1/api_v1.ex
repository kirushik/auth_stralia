defmodule AuthStralia.API.V1 do
  defmodule Handler do
    use Elli.Handler

    get "/" do
      http_ok "This is AuthStralia!"
    end
  end
end