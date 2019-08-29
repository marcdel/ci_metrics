defmodule AmadeusChoWeb.PageController do
  use AmadeusChoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
