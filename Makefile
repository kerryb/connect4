.PHONY: clean credo dialyzer format setup test update-deps
all: clean format credo compile dialyzer test
setup:
	mix deps.get
	mix ecto.setup
clean:
	mix clean
	MIX_ENV=test mix clean
	rm -rf priv/static/assets/*
deep-clean:
	rm -rf _build deps priv/static/assets
format:
	mix format --check-formatted
credo:
	mix credo --strict
compile:
	mix compile --warnings-as-errors
dialyzer:
	mix dialyzer --format dialyxir
test:
	MIX_ENV=test mix ecto.reset
	mix coveralls.html
outdated:
	mix hex.outdated
update-deps:
	mix deps.update --all
