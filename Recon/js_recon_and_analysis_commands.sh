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

# Get domain input
read -p $'\e[33;1mEnter target domain (e.g., simplilearn.com): \e[0m' DOMAIN
BASE=$(echo "$DOMAIN" | cut -d '.' -f1)

# Create required folder structure
mkdir -p "${BASE}/recon/js_enum/dump"

# Check for combined.txt in sub_enum
COMBINED_PATH="${BASE}/recon/sub_enum/combined.txt"
if [[ ! -f "$COMBINED_PATH" ]]; then
  echo -e "${RED}❌ ${COMBINED_PATH} not found.${NC}"
  read -p $'\e[33;1mEnter full path to domains.txt (combined subdomains): \e[0m' COMBINED_PATH
  if [[ ! -f "$COMBINED_PATH" ]]; then
    echo -e "${RED}❌ Still not found. Exiting.${NC}"
    exit 1
  fi
fi

# Output file
COMMANDS_FILE="js_commands.txt"

{
  toilet -f digital 'JS Recon & Analysis' | lolcat --force -p 1

  toilet -F border -f term "URL Collection" | lolcat --force -p 0.2

  echo -e "${CYAN}▶ echo 'https://www.${DOMAIN}' | hakrawler -d 3 --subs -t 30 | grep '^https://[^/]*\\.${BASE}\\.com' | anew ${BASE}/recon/js_enum/dump/all_urls.txt${NC}"
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ katana -list ${COMBINED_PATH} -d 5 -jc -jsl -c 30 | grep '^https://[^/]*\\.${BASE}\\.com' | anew ${BASE}/recon/js_enum/dump/all_urls.txt${NC}"
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ waybackurls '${DOMAIN}' | grep '^https://[^/]*\\.${BASE}\\.com' | anew ${BASE}/recon/js_enum/dump/all_urls.txt${NC}"

  toilet -F border -f term "Filter JS & Alive URLs" | lolcat --force -p 0.2

  echo -e "${CYAN}▶ cat ${BASE}/recon/js_enum/dump/all_urls.txt | grep '\\.js\$' | uro | sort -u | httpx-toolkit -mc 200 -t 150 -o ${BASE}/recon/js_enum/target_js_urls.txt${NC}"
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ cat ${BASE}/recon/js_enum/dump/all_urls.txt | uro | sort -u | httpx-toolkit -mc 200,302 -t 150 -o ${BASE}/recon/js_enum/target_url_list.txt${NC}"

  toilet -F border -f term "Sensitive Info & Leaks" | lolcat --force -p 0.2

  echo -e "${CYAN}▶ cat ${BASE}/recon/js_enum/target_js_urls.txt | jsleak -s -k${NC}"
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ nuclei -l ${BASE}/recon/js_enum/target_js_urls.txt -t ~/.local/nuclei-templates/http/exposures -c 30${NC}"
  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ cat ${BASE}/recon/js_enum/target_js_urls.txt | nuclei -t ~/.local/nuclei-templates/coffinxp_nuclei_templates/credentials-disclosure-all.yaml -c 30${NC}"

  toilet -F border -f term "Optional Extra Tools" | lolcat --force -p 0.2

  echo -e "${CYAN}▶ echo '${DOMAIN}' | gau | grep '^https://[^/]*\\.${BASE}\\.com' | anew ${BASE}/recon/js_enum/dump/urls.txt${NC}"
  echo -e "${CYAN}▶ cat ${BASE}/recon/js_enum/dump/urls.txt | anew ${BASE}/recon/js_enum/target_url_list.txt${NC}"
  echo -e "${YELLOW}💡 If any new JS URLs are found, restart the JS analysis phase for them.${NC}"

  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"
  echo -e "${CYAN}▶ cat ${BASE}/recon/js_enum/target_js_urls.txt | xargs -I{} bash -c 'echo -e \"\\ntarget : {}\\n\" && lazyegg \"{}\" --js_urls --domains --ips --leaked_creds --local_storage'${NC}"
  echo -e "${YELLOW}⚠️ This command is powerful but messy. Use only when ready for deep analysis.${NC}"

  echo -e "\n${GREEN}${BOLD}✅ JS Recon & Analysis completed.${NC}"
  echo -e "${YELLOW}You now have filtered URLs and JS files. You can start hunting or analyze leaks manually.${NC}"

    toilet -F border -f term "Crawling Juicy Endpoints" | lolcat --force -p 0.2

  echo -e "${CYAN}▶ grep -Ei '/(admin|config|dashboard|login|auth|debug|test|staging|upload|backup|server-status|monitor|manage|dev|portal|private|panel|root|internal|console|cgi-bin|shell|setup|editor|password|credentials|db|database|env|hidden|system|account|superuser|core|includes|wp-admin|webadmin|cpanel|git|svn|api|v1|v2|token|key|secret|jwt|session|logs|error|secure|restricted|flag)(/|$)' ${BASE}/recon/js_enum/target_url_list.txt | sort -u > ${BASE}/recon/js_enum/juicy_urls.txt${NC}"

  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"

  echo -e "${CYAN}▶ katana -u https://www.${DOMAIN} -d 5 -mdc 'contains(endpoint,\"api\")' -jc -jsl -kf all -o ${BASE}/recon/js_enum/dump/api_endpoints.txt${NC}"

  echo -e "${MAGENTA}────────────────────────────────────────────────────────────────────${NC}"

  echo -e "${CYAN}▶ cat ${BASE}/recon/js_enum/dump/api_endpoints.txt | uro | sort -u | httpx-toolkit -mc 200 -t 150 -o ${BASE}/recon/js_enum/juicy_api_endpoints.txt${NC}"


} | tee "$COMMANDS_FILE"

