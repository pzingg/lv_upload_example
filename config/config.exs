# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :lv_upload_example,
  ecto_repos: [LvUploadExample.Repo]

# Configures the endpoint
config :lv_upload_example, LvUploadExampleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4tFb+4nM3yc+CPgJ59TjybkAfzqjqSahCZxpL8xHz/H9yeJjiawBnPqBnhcl1Lce",
  render_errors: [view: LvUploadExampleWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LvUploadExample.PubSub,
  live_view: [signing_salt: "XZ3u1VGM"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
