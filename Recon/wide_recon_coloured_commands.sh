#!/bin/bash

# ANSI Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
BOLD="\e[1m"
NC="\e[0m"

# Take inputs
read -p $'\e[33;1mEnter domain (e.g., example.com): \e[0m' DOMAIN
read -p $'\e[33;1mEnter GitHub API key: \e[0m' GH_API
read -p $'\e[33;1mEnter Shodan API key: \e[0m' SHODAN_API

# Extract base
BASE=$(echo "$DOMAIN" | cut -d '.' -f1)

# Create folder structure
mkdir -p "${BASE}/recon/sub_enum/dump"
echo "$DOMAIN" > "${BASE}/scope.txt"

# Output file
COMMANDS_FILE="commands.txt"

# Save colored commands to file and terminal
{
  toilet -f digital 'JS recon & Analysis' | lolcat --force -p 1

  toilet -F border -f term "Subdomain Enumeration" | lolcat --force -p 0.2

  echo -e "${CYAN}▶ subfinder -d $DOMAIN -all -recursive -silent -o ${BASE}/recon/sub_enum/dump/subs.txt${NC}"
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ github-subdomains -d $DOMAIN -o ${BASE}/recon/sub_enum/dump/git_subs.txt -t $GH_API${NC}"
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ shosubgo -s $SHODAN_API -d $DOMAIN -o ${BASE}/recon/sub_enum/dump/shosubgo_subs.txt${NC}"

  toilet -F border -f term "Gather Unique Subdomains" | lolcat --force -p 0.2
  echo -e "${CYAN}▶ cat ${BASE}/recon/sub_enum/dump/subs.txt ${BASE}/recon/sub_enum/dump/git_subs.txt ${BASE}/recon/sub_enum/dump/shosubgo_subs.txt | anew > ${BASE}/recon/sub_enum/dump/all_uniq_subs.txt${NC}"

  toilet -F border -f term "Check Alive Subdomains" | lolcat --force -p 0.2
  echo -e "${CYAN}▶ cat ${BASE}/recon/sub_enum/dump/all_uniq_subs.txt | httpx-toolkit -ports 80,443,8080,8000,8888,8443,3000 -o ${BASE}/recon/sub_enum/dump/alive_subs.txt -mc 200 -t 150${NC}"
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ cat ${BASE}/recon/sub_enum/dump/all_uniq_subs.txt | httpx-toolkit -ports 80,443,8080,8000,8888,8443,3000 -o ${BASE}/recon/sub_enum/dump/redir_subs.txt -mc 302 -t 150${NC}"

  toilet -F border -f term "Clean Output" | lolcat --force -p 0.2
  echo -e "${CYAN}▶ cat ${BASE}/recon/sub_enum/dump/alive_subs.txt | sed 's|http[s]*://||' | sort -u > ${BASE}/recon/sub_enum/alive_subs.txt${NC}"
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ cat ${BASE}/recon/sub_enum/dump/redir_subs.txt | sed 's|http[s]*://||' | sort -u > ${BASE}/recon/sub_enum/redir_subs.txt${NC}"
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ cat ${BASE}/recon/sub_enum/alive_subs.txt ${BASE}/recon/sub_enum/redir_subs.txt | anew > ${BASE}/recon/sub_enum/combined.txt${NC}"

  toilet -F border -f term "Extra Enumeration" | lolcat --force -p 0.2
  echo -e "${CYAN}▶ bbot -t $DOMAIN -p subdomain-enum -o . -n bbot_results -om txt${NC}"

  echo -e "\n${GREEN}${BOLD}✅ Subdomain enumeration is done.${NC}"
  echo -e "${YELLOW}You can go with these results for hunting but don't forget to use bbot for more results and findings.${NC}"

} | tee "$COMMANDS_FILE"
