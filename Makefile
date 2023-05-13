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
	rm -rf _build deps priv/static/assets/*
format:
	mix format --check-formatted
credo:
	mix credo --all
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
release: check-working-dir-clean check-version-up-to-date
	rm -f connect4-*.gz
	docker build --tag=connect4-release -f docker/builder/Dockerfile .
	docker rm -f connect4-release
	docker create --name connect4-release connect4-release
	docker cp connect4-release:/app/_build/prod/connect4-`cat VERSION`.tar.gz .
check-working-dir-clean:
	[[ -z "`git status --porcelain`" ]] || (echo "There are uncommitted changes" >&2 ; exit 1)
check-version-up-to-date:
	[[ `git log -1 --pretty=format:'%h'` == `git log -1 --pretty=format:'%h' VERSION` ]] \
	  || (echo "There have been changes since VERSION was updated" >&2 ; exit 1)
deploy:
	scp connect4-`cat VERSION`.tar.gz connect4@connect4.nat.bt.com:
	ssh connect4@connect4.nat.bt.com "bash -lc './deploy-release.sh connect4-`cat VERSION`.tar.gz && rm connect4-`cat VERSION`.tar.gz'"	
