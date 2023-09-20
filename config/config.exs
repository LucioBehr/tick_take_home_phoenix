# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :tick_take_home, TickTakeHomeWeb.Repo,
  database: "tick_take_home_repo",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :tick_take_home,
  ecto_repos: [TickTakeHome.Repo]

# Configures the endpoint
config :tick_take_home, TickTakeHomeWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: TickTakeHomeWeb.ErrorHTML, json: TickTakeHomeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TickTakeHome.PubSub,
  live_view: [signing_salt: "J0shOlI3"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :tick_take_home, TickTakeHome.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :brod,
  clients: [
    kafka_client: [
      endpoints: [{"localhost", 9092}],
      auto_start_producers: true
    ]
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
