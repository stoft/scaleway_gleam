.PHONY: run-watch
run-watch:
	watchexec -v -e gleam--restart --stop-signal=SIGKILL --wrap-process=session --debounce 2s --stop-timeout=5s gleam run

.PHONY: run-with-litestream
run-with-litestream:
	litestream replicate -config litestream.yml &
	gleam run

.PHONY: restore-db
restore-db:
	litestream restore -config litestream.yml -o app.db app.db

.PHONY: replicate-db
replicate-db:
	litestream replicate -config litestream.yml

.PHONY: stop-litestream
stop-litestream:
	pkill litestream

.PHONY: build
build:
	docker build -t web .