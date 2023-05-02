import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :connect4, Connect4.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "connect4_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :connect4, Connect4Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "D8wYT9UktsuG81iBTIetIUiT1wVWYiHcGIeavyQvRYEOsFPPyNHXAcTf1UCjP78h",
  server: false

# In test we don't send emails.
config :connect4, Connect4.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
