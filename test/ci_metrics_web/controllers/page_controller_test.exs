defmodule CiMetricsWeb.PageControllerTest do
  use CiMetricsWeb.ConnCase, async: true

  test "GET / links to the new repository page", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ Routes.repository_path(conn, :new)
  end
end
