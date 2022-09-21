defmodule ProbuildEx.Repo do
  use Ecto.Repo,
    otp_app: :probuild_ex,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 20
end
