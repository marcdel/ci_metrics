defmodule CiMetricsWeb.PageController do
  use CiMetricsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
