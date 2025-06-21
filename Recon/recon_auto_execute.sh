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
mkdir -p "${BASE}/recon/sub_enum/dump"
echo "$DOMAIN" > "${BASE}/scope.txt"

# Output file
COMMANDS_FILE="commands.txt"

# Save colored commands to file
{
  printf "${BLUE}${BOLD}# Wide Recon${NC}\n"
  printf "${GREEN}## Subdomain Enumeration${NC}\n"

  printf "${YELLOW}### Using Subfinder${NC}\n"
  printf "subfinder -d $DOMAIN -all -recursive -silent -o ${BASE}/recon/sub_enum/dump/subs.txt\n\n"

  printf "${YELLOW}### Using github-subdomains${NC}\n"
  printf "github-subdomains -d $DOMAIN -o ${BASE}/recon/sub_enum/dump/git_subs.txt -t $GH_API\n\n"

  printf "${YELLOW}### Using Shosubgo${NC}\n"
  printf "shosubgo -s $SHODAN_API -d $DOMAIN -o ${BASE}/recon/sub_enum/dump/shosubgo_subs.txt\n\n"

  printf "${GREEN}## Gather Unique Subdomains${NC}\n"
  printf "cat ${BASE}/recon/sub_enum/dump/subs.txt "
  printf "${BASE}/recon/sub_enum/dump/git_subs.txt "
  printf "${BASE}/recon/sub_enum/dump/shosubgo_subs.txt | anew > ${BASE}/recon/sub_enum/dump/all_uniq_subs.txt\n\n"

  printf "${GREEN}## Check Alive Subdomains${NC}\n"
  printf "cat ${BASE}/recon/sub_enum/dump/all_uniq_subs.txt | httpx-toolkit -ports 80,443,8080,8000,8888,8443,3000 -o ${BASE}/recon/sub_enum/dump/alive_subs.txt -mc 200 -t 150\n"
  printf "cat ${BASE}/recon/sub_enum/dump/all_uniq_subs.txt | httpx-toolkit -ports 80,443,8080,8000,8888,8443,3000 -o ${BASE}/recon/sub_enum/dump/redir_subs.txt -mc 302 -t 150\n\n"

  printf "${GREEN}## Clean Output (remove protocols, deduplicate)${NC}\n"
  printf "cat ${BASE}/recon/sub_enum/dump/alive_subs.txt | sed 's|http[s]*://||' | sort -u > ${BASE}/recon/sub_enum/alive_subs.txt\n"
  printf "cat ${BASE}/recon/sub_enum/dump/redir_subs.txt | sed 's|http[s]*://||' | sort -u > ${BASE}/recon/sub_enum/redir_subs.txt\n"
  printf "cat ${BASE}/recon/sub_enum/alive_subs.txt ${BASE}/recon/sub_enum/redir_subs.txt | anew > ${BASE}/recon/sub_enum/combined.txt\n\n"

  printf "${BLUE}bbot -t $DOMAIN -p subdomain-enum -o . -n bbot_results -om txt${NC}\n\n"

  printf "${GREEN}${BOLD}✅ Subdomain enumeration is done.${NC}\n"
  printf "${YELLOW}You can go with these results for hunting but don't forget to use bbot for more results and findings.${NC}\n"
} > "$COMMANDS_FILE"

# Show output to terminal
cat "$COMMANDS_FILE"
