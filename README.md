# ex_uncov

**Tracks lines uncovered by tests as a code and forces developers to commit coverage regressions.**

## Installation

Add `ex_uncov` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_uncov, ">= 0.0.0", only: [:dev, :test]}
  ]
end
```

## Usage

Now you can:

- run `mix uncov` after collecting coverage via `mix test --cover` to display and commit changes

- run `mix uncov.list` and `mix uncov.show` to learn more about uncovered lines

- run `mix uncov --verify` on CI to ensure that all changes are committed

- run `mix help uncov` for more information (or [read docs on HexDocs](https://hexdocs.pm/ex_uncov))
