# Makefile for bm - Bookmark Manager

.DEFAULT_GOAL := help

# Colors
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
BLUE   := \033[0;34m
NC     := \033[0m

# Installation paths
SERVER_PATH := /ffp/etc/profile.d
TERMUX_PATH := /data/data/com.termux/files/usr/etc/profile.d
DEFAULT_PATH := $(PREFIX)/etc/profile.d

.PHONY: help server termux default

help:
	@echo -e "${BLUE}bm - Bookmark Manager Makefile${NC}"
	@echo -e "Usage: ${GREEN}make${NC} [${YELLOW}target${NC}]"
	@echo ""
	@echo -e "Available targets:"
	@echo -e "  ${YELLOW}help${NC}    - Show this colored help message (default)"
	@echo -e "  ${YELLOW}server${NC}  - Install to ${BLUE}$(SERVER_PATH)/bm.bash${NC}"
	@echo -e "  ${YELLOW}termux${NC}  - Install to ${BLUE}$(TERMUX_PATH)/bm.bash${NC}"
	@echo -e "  ${YELLOW}default${NC} - Install to ${BLUE}$(DEFAULT_PATH)/bm.bash${NC} (Uses \$$PREFIX)"

server:
	@echo -e "${YELLOW}Installing to server path...${NC}"
	@mkdir -p $(SERVER_PATH)
	@cp bm.bash $(SERVER_PATH)/bm.bash
	@chmod 755 $(SERVER_PATH)/bm.bash
	@echo -e "${GREEN}Success!${NC} Please run: ${YELLOW}source $(SERVER_PATH)/bm.bash${NC}"

termux:
	@echo -e "${YELLOW}Installing to Termux path...${NC}"
	@mkdir -p $(TERMUX_PATH)
	@cp bm.bash $(TERMUX_PATH)/bm.bash
	@chmod 755 $(TERMUX_PATH)/bm.bash
	@echo -e "${GREEN}Success!${NC} Please run: ${YELLOW}source $(TERMUX_PATH)/bm.bash${NC}"

default:
	@if [ -z "$(PREFIX)" ]; then \
		echo -e "${RED}Error: \$$PREFIX is not defined.${NC}"; \
		exit 1; \
	fi
	@echo -e "${YELLOW}Installing to default path ($(PREFIX))...${NC}"
	@mkdir -p $(DEFAULT_PATH)
	@cp bm.bash $(DEFAULT_PATH)/bm.bash
	@chmod 755 $(DEFAULT_PATH)/bm.bash
	@echo -e "${GREEN}Success!${NC} Please run: ${YELLOW}source $(DEFAULT_PATH)/bm.bash${NC}"
