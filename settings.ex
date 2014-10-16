defmodule Config do
  def get(:dev) do
    [
      listen_on: 8080,
      db_url: "ecto://auth_stralia:superpassword@localhost/auth_stralia_dev",
      jwt_secret: "56972e4ddccbab39a5966e79ec2ddcc556a6775d89ad9478c5bfd5ec012618e6703ec98ab29eeb0b9105f6050246b1885a2849fb3fc30c8ee276581b49f6e712",
      expires_in: 600 # 10 minutes
    ]
  end
  def get(:test) do
    [
      listen_on: 3000,
      db_url: "ecto://auth_stralia:superpassword@localhost/auth_stralia_test?size=1&max_overflow=0",
      jwt_secret: "secret",
      expires_in: 10 # seconds
    ]
  end
  def get(:prod) do
    [
      listen_on: System.get_env("PORT") |> String.to_integer,
      db_url: System.get_env("DATABASE_URL"),
      jwt_secret: System.get_env("JWT_SECRET"),
      expires_in: (7*24*60*60) # 1 week
    ]
  end
end

defmodule Settings do
  def jwt_secret do
    {:ok, jwt_secret} = :application.get_env(:auth_stralia, :jwt_secret)
    jwt_secret
  end
  def expiresIn do
    {:ok, expiresIn} = :application.get_env(:auth_stralia, :expires_in)
    expiresIn
  end
  def port do
    {:ok, port} = :application.get_env(:auth_stralia, :listen_on)
    port
  end
  def db_url do
    {:ok, db_url} = :application.get_env(:auth_stralia, :db_url)
    db_url
  end
end