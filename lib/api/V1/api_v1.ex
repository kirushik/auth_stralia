defmodule AuthStralia.API.V1 do
  defmodule Handler do
    use Elli.Handler

    get "/token/new" do
      http_ok "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhbGljZUBleGFtcGxlLmNvbSIsImlzcyI6ImF1dGguZXhhbXBsZS5jb20iLCJleHAiOjEzOTk3Mzg1NzgsImp0aSI6IjEyODI0MjNFLUQ1RUUtMTFFMy1CMzY4LTRGN0Q3NEVCMEE1NCJ9.a0f-ey8hsmHjAHHg4RCoUHjaI8cHX8U5-FkwsmFiCv0"
    end
  end
end