defmodule ProbuildEx.UGG do
  @moduledoc false

  @url "https://stats2.u.gg/pro/pro-list.json"
  # If they change the endpoint in the future you can use the url below instead
  # it's a snapshot of the pro-list.json endpoint the 13 August 2022
  # @url "https://gist.githubusercontent.com/mrdotb/0d11ce00445de1f2573b8e74a9fcc5f7/raw/a0ff759bb1b794611f8c7a60b2a68bdc7d5eba80/pro-list.json"

  def pro_list do
    %{body: body} = Tesla.get!(@url)
    Jason.decode!(body)
  end
end
