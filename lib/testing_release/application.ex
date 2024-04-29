defmodule TestingRelease.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TestingReleaseWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:testing_release, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TestingRelease.PubSub},
      # Start a worker by calling: TestingRelease.Worker.start_link(arg)
      # {TestingRelease.Worker, arg},
      # Start to serve requests, typically the last entry
      TestingReleaseWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TestingRelease.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TestingReleaseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
