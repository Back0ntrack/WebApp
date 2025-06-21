#!/bin/bash

# ANSI Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
BOLD="\e[1m"
NC="\e[0m"

# Take inputs
read -p $'\e[33;1mEnter domain (e.g., example.com): \e[0m' DOMAIN
read -p $'\e[33;1mEnter GitHub API key: \e[0m' GH_API
read -p $'\e[33;1mEnter Shodan API key: \e[0m' SHODAN_API

# Extract base
BASE=$(echo "$DOMAIN" | cut -d '.' -f1)

# Create folder structure
RECON_DIR="${BASE}/recon/sub_enum"
DUMP_DIR="${RECON_DIR}/dump"
mkdir -p "$DUMP_DIR"
echo "$DOMAIN" > "${BASE}/scope.txt"

echo -e "${BLUE}${BOLD}[*] Starting Recon Automation...${NC}"

# Subfinder
echo -e "${YELLOW}[+] Running Subfinder...${NC}"
subfinder -d "$DOMAIN" -all -recursive -silent -o "$DUMP_DIR/subs.txt"

# github-subdomains
echo -e "${YELLOW}[+] Running github-subdomains...${NC}"
github-subdomains -d "$DOMAIN" -o "$DUMP_DIR/git_subs.txt" -t "$GH_API"

# Shosubgo
echo -e "${YELLOW}[+] Running shosubgo...${NC}"
shosubgo -s "$SHODAN_API" -d "$DOMAIN" -o "$DUMP_DIR/shosubgo_subs.txt"

# Gather unique
echo -e "${GREEN}[+] Gathering unique subdomains...${NC}"
cat "$DUMP_DIR/subs.txt" "$DUMP_DIR/git_subs.txt" "$DUMP_DIR/shosubgo_subs.txt" | anew > "$DUMP_DIR/all_uniq_subs.txt"

# Alive check
echo -e "${BLUE}[+] Probing for live subdomains... (200 OK)${NC}"
cat "$DUMP_DIR/all_uniq_subs.txt" | httpx-toolkit -ports 80,443,8080,8000,8888,8443,3000 -o "$DUMP_DIR/alive_subs.txt" -mc 200 -t 150

echo -e "${BLUE}[+] Probing for redirected subdomains... (302)${NC}"
cat "$DUMP_DIR/all_uniq_subs.txt" | httpx-toolkit -ports 80,443,8080,8000,8888,8443,3000 -o "$DUMP_DIR/redir_subs.txt" -mc 302 -t 150

# Clean and deduplicate
echo -e "${YELLOW}[+] Cleaning and removing protocols...${NC}"
cat "$DUMP_DIR/alive_subs.txt" | sed 's|http[s]*://||' | sort -u > "$RECON_DIR/alive_subs.txt"
cat "$DUMP_DIR/redir_subs.txt" | sed 's|http[s]*://||' | sort -u > "$RECON_DIR/redir_subs.txt"

# Combined output
cat "$RECON_DIR/alive_subs.txt" "$RECON_DIR/redir_subs.txt" | anew > "$RECON_DIR/combined.txt"

# Done
echo -e "\n${GREEN}${BOLD}✅ Subdomain enumeration is done.${NC}"
echo -e "${YELLOW}You can go with these results for hunting but don't forget to use bbot for more results and findings.${NC}"
echo -e "${BLUE}Hint: bbot -t $DOMAIN -p subdomain-enum -o . -n bbot_results -om txt${NC}"
