# Dotfiles Makefile

.PHONY: help install apply backup check clean update generations rollback bootstrap test

# Colors
GREEN := \033[0;32m
BLUE := \033[0;34m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# Variables
USER ?= $(shell whoami)
PROFILE ?= core
BACKUP_DIR := $(HOME)/.dotfiles-backup-$(shell date +%Y%m%d-%H%M%S)

help: ## Show this help message
	@echo "$(BLUE)Dotfiles Makefile$(NC)"
	@echo "=================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-14s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  make apply                          # $(USER)-core"
	@echo "  make apply PROFILE=full             # $(USER)-full"
	@echo "  make apply USER=root PROFILE=core   # root-core"
	@echo ""
	@echo "$(YELLOW)First time Brev setup (run from local machine):$(NC)"
	@echo "  make bootstrap INSTANCE=my-instance"
	@echo "  make bootstrap INSTANCE=my-instance PROFILE=full"

install: ## Install Nix using official installer
	@echo "$(BLUE)==> Installing Nix...$(NC)"
	@if ! command -v nix &> /dev/null; then \
		curl -L https://nixos.org/nix/install | sh -s -- --daemon; \
		echo "$(GREEN)✓ Nix installed$(NC)"; \
		echo "$(YELLOW)! Restart your terminal, then run 'make apply'$(NC)"; \
	else \
		echo "$(GREEN)✓ Nix is already installed$(NC)"; \
	fi
	@echo "$(BLUE)==> Enabling flakes...$(NC)"
	@sudo mkdir -p /etc/nix
	@if ! grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then \
		echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf > /dev/null; \
		echo "$(GREEN)✓ Flakes enabled$(NC)"; \
	else \
		echo "$(GREEN)✓ Flakes already enabled$(NC)"; \
	fi

check: ## Check if configuration builds without applying
	@echo "$(BLUE)==> Checking configuration...$(NC)"
	@cd home-manager && nix flake check --show-trace
	@echo "$(GREEN)✓ Configuration check passed$(NC)"

backup: ## Backup existing dotfiles
	@echo "$(BLUE)==> Backing up existing dotfiles...$(NC)"
	@mkdir -p "$(BACKUP_DIR)"
	@for file in .zshrc .bashrc .vimrc .gitconfig .tmux.conf; do \
		if [ -f "$(HOME)/$$file" ]; then \
			cp "$(HOME)/$$file" "$(BACKUP_DIR)/"; \
			echo "$(GREEN)✓ Backed up $$file$(NC)"; \
		fi; \
	done
	@echo "$(YELLOW)Backup location: $(BACKUP_DIR)$(NC)"

apply: backup ## Apply config: make apply [USER=x] [PROFILE=core|full]
	@echo "$(BLUE)==> Applying $(USER)-$(PROFILE) configuration...$(NC)"
	@nix run home-manager/master -- switch --flake ./home-manager#$(USER)-$(PROFILE) -b backup
	@echo "$(GREEN)✓ $(USER)-$(PROFILE) config applied$(NC)"
	@echo "$(YELLOW)Run 'source ~/.zshrc' or restart your terminal$(NC)"

# --- Bootstrap (run from LOCAL machine) ---

INSTANCE ?=
REMOTE_USER = $(shell ssh -G $(INSTANCE) 2>/dev/null | awk '/^user /{print $$2}')
REMOTE_HOME = $(shell if [ "$(REMOTE_USER)" = "root" ]; then echo "/root"; else echo "/home/$(REMOTE_USER)"; fi)

bootstrap: ## Bootstrap a Brev instance: make bootstrap INSTANCE=name [PROFILE=full]
	@if [ -z "$(INSTANCE)" ]; then \
		echo "$(RED)Error: INSTANCE is required$(NC)"; \
		echo "Usage: make bootstrap INSTANCE=my-gpu-box [PROFILE=full]"; \
		exit 1; \
	fi
	@echo "$(BLUE)==> Bootstrapping $(INSTANCE) (profile: $(PROFILE))$(NC)"
	@echo ""
	@echo "$(BLUE)==> Step 1: Copying SSH key + secrets...$(NC)"
	@ssh $(INSTANCE) "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
	@scp ~/.ssh/gitlab_2026_01 $(INSTANCE):~/.ssh/gitlab_2026_01
	@scp ~/.ssh/gitlab_2026_01.pub $(INSTANCE):~/.ssh/gitlab_2026_01.pub
	@ssh $(INSTANCE) "chmod 600 ~/.ssh/gitlab_2026_01"
	@if [ -f ~/.secrets ]; then \
		scp ~/.secrets $(INSTANCE):~/.secrets; \
		ssh $(INSTANCE) "chmod 600 ~/.secrets"; \
		echo "$(GREEN)✓ Secrets copied$(NC)"; \
	fi
	@if [ -f ~/.ssh/config.local ]; then \
		scp ~/.ssh/config.local $(INSTANCE):~/.ssh/config.local; \
		echo "$(GREEN)✓ SSH config.local copied$(NC)"; \
	fi
	@echo "$(GREEN)✓ Key + secrets copied$(NC)"
	@echo ""
	@echo "$(BLUE)==> Step 2: Cloning dotfiles + installing Nix + applying config...$(NC)"
	@ssh $(INSTANCE) '\
		set -e; \
		if [ ! -d ~/dotfiles/.git ]; then \
			git clone https://github.com/alec-flowers/dotfiles.git ~/dotfiles; \
		fi; \
		cd ~/dotfiles; \
		if ! command -v nix >/dev/null 2>&1; then \
			curl -L https://nixos.org/nix/install | sh -s -- --daemon; \
			sudo mkdir -p /etc/nix; \
			grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null || \
				echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null; \
		fi; \
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; \
		make apply PROFILE=$(PROFILE); \
		echo ""; \
		echo "Done! SSH in and restart your shell: ssh $(INSTANCE)"; \
	'
	@echo ""
	@echo "$(GREEN)✓ Bootstrap complete!$(NC)"
	@echo "$(YELLOW)SSH in: ssh $(INSTANCE)$(NC)"

test: ## Run setup verification tests
	@bash tests/test-setup.sh

# --- Maintenance ---

clean: ## Clean up Nix store and old generations
	@echo "$(BLUE)==> Cleaning up...$(NC)"
	@nix-collect-garbage -d
	@home-manager expire-generations "-30 days"
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

update: ## Update flake inputs
	@echo "$(BLUE)==> Updating flake inputs...$(NC)"
	@cd home-manager && nix flake update
	@echo "$(GREEN)✓ Flake inputs updated$(NC)"

generations: ## Show home-manager generations
	@echo "$(BLUE)==> Home Manager generations:$(NC)"
	@home-manager generations

rollback: ## Rollback to previous generation
	@echo "$(BLUE)==> Rolling back...$(NC)"
	@home-manager rollback
	@echo "$(GREEN)✓ Rolled back$(NC)"
