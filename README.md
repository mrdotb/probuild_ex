# ProbuildEx

Companion code for the [series](https://mrdotb.com/posts/probuild-ex-part-one/)

To start probuild ex:
- Install dependencies with `mix deps.get`
- You need to get a token from https://developer.riotgames.com/ and put it in `config/dev.local.exs`
```elixir
import Config

# Setup the riot token
config :probuild_ex, ProbuildEx.RiotApi, token: ""
```
- You need postgres you can use [docker](https://www.docker.com/)
```shell
docker compose -f docker-compose.dev.yml up -d 
```
- Create and migrate your database with `mix ecto.setup`
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
