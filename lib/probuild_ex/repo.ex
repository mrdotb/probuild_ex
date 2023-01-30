defmodule ProbuildEx.Repo do
  use Ecto.Repo,
    otp_app: :probuild_ex,
    adapter: Ecto.Adapters.Postgres

  use Paginator,
    limit: 20,
    include_total_count: false
end
