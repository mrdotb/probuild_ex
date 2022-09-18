import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :probuild_ex, ProbuildEx.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "probuild_ex_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :probuild_ex, ProbuildExWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "eDZ3CLJ9osB7AAJCk7o3mZrQEaYwhjzL2vKWd8t/E70HYvH67XAq5UEldTMfpGOk",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Disable canon during tests
config :probuild_ex, :canon,
  games: [platform_ids: []],
  pros: [platform_ids: []]

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
