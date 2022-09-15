defmodule ProbuildEx.Repo do
  use Ecto.Repo,
    otp_app: :probuild_ex,
    adapter: Ecto.Adapters.Postgres
end
