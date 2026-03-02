# Dotfiles Makefile

.PHONY: help install vm vm-full local local-full backup check clean update generations rollback

# Colors
GREEN := \033[0;32m
BLUE := \033[0;34m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# Variables
USERNAME := $(shell whoami)
BACKUP_DIR := $(HOME)/.dotfiles-backup-$(shell date +%Y%m%d-%H%M%S)

help: ## Show this help message
	@echo "$(BLUE)Dotfiles Makefile$(NC)"
	@echo "=================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-14s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)First time setup:$(NC)"
	@echo "  1. Run 'make install' to install Nix"
	@echo "  2. Restart your terminal"
	@echo "  3. Run 'make vm' (lightweight) or 'make vm-full' (full dev env)"

install: ## Install Nix using official installer
	@echo "$(BLUE)==> Installing Nix...$(NC)"
	@if ! command -v nix &> /dev/null; then \
		curl -L https://nixos.org/nix/install | sh -s -- --daemon; \
		echo "$(GREEN)✓ Nix installed$(NC)"; \
		echo "$(YELLOW)! Restart your terminal, then run 'make vm' or 'make vm-full'$(NC)"; \
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

# --- Lightweight profiles (core only) ---

local: backup ## Apply lightweight config (aflowers@workstation)
	@echo "$(BLUE)==> Applying lightweight local configuration...$(NC)"
	@nix run home-manager/master -- switch --flake ./home-manager#local -b backup
	@echo "$(GREEN)✓ Lightweight local config applied$(NC)"
	@echo "$(YELLOW)Run 'source ~/.zshrc' or restart your terminal$(NC)"

vm: backup ## Apply lightweight VM config (auto-detects user)
	@echo "$(BLUE)==> Applying lightweight VM configuration...$(NC)"
	@if [ "$(USERNAME)" = "nvidia" ]; then \
		nix run home-manager/master -- switch --flake ./home-manager#brev-vm-gpu -b backup; \
	elif [ "$(USERNAME)" = "root" ]; then \
		nix run home-manager/master -- switch --flake ./home-manager#brev-vm-root -b backup; \
	else \
		nix run home-manager/master -- switch --flake ./home-manager#brev-vm -b backup; \
	fi
	@echo "$(GREEN)✓ Lightweight VM config applied$(NC)"
	@echo "$(YELLOW)Run 'source ~/.zshrc' or restart your terminal$(NC)"

# --- Full profiles (core + extras) ---

local-full: backup ## Apply full config (aflowers@workstation)
	@echo "$(BLUE)==> Applying full local configuration...$(NC)"
	@nix run home-manager/master -- switch --flake ./home-manager#local-full -b backup
	@echo "$(GREEN)✓ Full local config applied$(NC)"
	@echo "$(YELLOW)Run 'source ~/.zshrc' or restart your terminal$(NC)"

vm-full: backup ## Apply full VM config (auto-detects user)
	@echo "$(BLUE)==> Applying full VM configuration...$(NC)"
	@nix run home-manager/master -- switch --flake ./home-manager#brev-vm-full -b backup
	@echo "$(GREEN)✓ Full VM config applied$(NC)"
	@echo "$(YELLOW)Run 'source ~/.zshrc' or restart your terminal$(NC)"

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
