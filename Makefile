.PHONY: clean credo dialyzer format setup test update-deps
all: clean credo compile format dialyzer test
setup:
	mix deps.get
	mix ecto.setup
clean:
	mix clean
	MIX_ENV=test mix clean
	rm -rf priv/static/assets/*
deep-clean:
	rm -rf _build deps priv/static/assets
credo:
	mix credo --strict
format:
	mix format --check-formatted
compile:
	mix compile --warnings-as-errors
dialyzer:
	mix dialyzer --format dialyxir
test:
	mix coveralls.html
outdated:
	mix hex.outdated
update-deps:
	mix deps.update --all
