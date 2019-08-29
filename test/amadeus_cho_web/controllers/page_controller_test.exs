defmodule AmadeusChoWeb.PageControllerTest do
  use AmadeusChoWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Coming soon!"
  end
end
