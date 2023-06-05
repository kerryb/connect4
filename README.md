# Connect 4 Tournament Server

A server to run a coding contest based around the game of [Connect
4](https://en.wikipedia.org/wiki/Connect_Four).

The idea is that developers/pairs/teams sign up on the site, are given a unique
URL, then compete in a tournament against each other by writing programs that
interface with a simple HTTP API.

## Getting Started

  * Install appropriate versions of Erlang and Elixir (if you use
    [ASDF](https://github.com/asdf-vm/asdf) you can just run `asdf install`)
  * Install [PostgreSQL](https://www.postgresql.org/), eg `brew install
    postgresql`
  * Run `make setup`

## Running the Build

Just run `make`.

## Setup and Deployment

### Server Setup

There’s a setup script to get things installed on a CentOS/OEL 7 server.
Temporarily check the project out on the server (or just copy the `setup`
directory) and run `setup/setup-server.sh`, then follow the manual steps
printed out at the end.

### Building and Deploying Releases

Update the `VERSION` file and commit it, then run `make release`.

To deploy to the server, run `make deploy` (this assumes ssh access to the
`connect4` user on the server).

## Standard Phoenix Stuff

To start your Phoenix server locally:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

### Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
