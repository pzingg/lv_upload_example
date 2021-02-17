defmodule LvUploadExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      LvUploadExample.Repo,
      # Start the Telemetry supervisor
      LvUploadExampleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LvUploadExample.PubSub},
      # Start the Endpoint (http/https)
      LvUploadExampleWeb.Endpoint
      # Start a worker by calling: LvUploadExample.Worker.start_link(arg)
      # {LvUploadExample.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LvUploadExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LvUploadExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
