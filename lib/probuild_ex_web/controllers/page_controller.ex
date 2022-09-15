defmodule ProbuildExWeb.PageController do
  use ProbuildExWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
