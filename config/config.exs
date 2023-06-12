# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :probuild_ex,
  ecto_repos: [ProbuildEx.Repo]

# Configures the endpoint
config :probuild_ex, ProbuildExWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: ProbuildExWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: :pbx_pubsub,
  live_view: [signing_salt: "0VmmhuEM"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tesla, :adapter, Tesla.Adapter.Hackney

config :probuild_ex, :canon,
games: [platform_ids: ["euw1", "jp1", "kr", "na1", "br1"], delay: 10_000],
pros: [platform_ids: ["euw1", "jp1", "kr", "na1", "br1"], delay: 1_000 * 60 * 60 * 24]

config :tailwind,
  version: "3.1.8",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
