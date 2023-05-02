defmodule Connect4.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      Connect4Web.Telemetry,
      # Start the Ecto repository
      Connect4.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Connect4.PubSub},
      # Start Finch
      {Finch, name: Connect4.Finch},
      # Start the Endpoint (http/https)
      Connect4Web.Endpoint,
      {Registry, keys: :unique, name: Connect4.GameRegistry}
      # Start a worker by calling: Connect4.Worker.start_link(arg)
      # {Connect4.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Connect4.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Connect4Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
