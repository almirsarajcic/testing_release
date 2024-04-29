defmodule TestingReleaseWeb.HomeController do
  use TestingReleaseWeb, :controller

  def index(conn, _params) do
    ExUnit.__info__(:functions) |> IO.inspect(label: "ExUnit functions")

    json(conn, %{status: "ok"})
  end
end
