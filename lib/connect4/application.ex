defmodule Connect4.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @env Application.compile_env(:connect4, :env)

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Connect4.Supervisor]
    Supervisor.start_link(children(@env), opts)
  end

  defp children(:test), do: default_children()
  defp children(_), do: default_children() ++ non_test_children()

  defp default_children do
    [
      Connect4Web.Telemetry,
      Connect4.Repo,
      {Phoenix.PubSub, name: Connect4.PubSub},
      {Finch, name: Connect4.Finch},
      Connect4Web.Endpoint,
      {Registry, keys: :unique, name: Connect4.GameRegistry}
    ]
  end

  defp non_test_children do
    [Connect4.Game.Runner]
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Connect4Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
