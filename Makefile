BINARY_NAME=bm
GO_VERSION=1.19

.PHONY: all build redmi server

all: build redmi server

build:
	CGO_ENABLED=0 GOTOOLCHAIN=go1.19 go build -x -trimpath -ldflags="-s -w" -o ./bin/bm_codespace ./cmd/bm

redmi:
	CGO_ENABLED=0 GOTOOLCHAIN=go1.19 GOOS=android GOARCH=arm64 go build -x -trimpath -ldflags="-s -w" -o ./bin/bm_redmi ./cmd/bm

server:
	CGO_ENABLED=0 GOTOOLCHAIN=go1.19 GOOS=linux GOARCH=arm GOARM=5 go build -x -trimpath -ldflags="-s -w" -o ./bin/bm_server ./cmd/bm
