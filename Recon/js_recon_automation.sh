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

# Prompt for domain
read -p $'\e[33;1mEnter target domain (e.g., simplilearn.com): \e[0m' DOMAIN
BASE=$(echo "$DOMAIN" | cut -d '.' -f1)

# Create folder structure
mkdir -p "${BASE}/recon/js_enum/dump"

# Check for combined.txt
COMBINED_PATH="${BASE}/recon/sub_enum/combined.txt"
if [[ ! -f "$COMBINED_PATH" ]]; then
  echo -e "${RED}❌ ${COMBINED_PATH} not found.${NC}"
  read -p $'\e[33;1mEnter full path to domains.txt (combined subdomains): \e[0m' COMBINED_PATH
  if [[ ! -f "$COMBINED_PATH" ]]; then
    echo -e "${RED}❌ Still not found. Exiting.${NC}"
    exit 1
  fi
fi

echo -e "${BLUE}${BOLD}📦 Collecting JS-related URLs...${NC}"

# Tools
echo "$DOMAIN" | gau | grep "^https://[^/]*\.${BASE}\.com" > "${BASE}/recon/js_enum/dump/gau_urls.txt"
echo "https://www.$DOMAIN" | hakrawler -d 3 --subs -t 30 | grep "^https://[^/]*\.${BASE}\.com" > "${BASE}/recon/js_enum/dump/hakrawler_urls.txt"
katana -list "$COMBINED_PATH" -d 5 -jc -jsl -c 30 | grep "^https://[^/]*\.${BASE}\.com" > "${BASE}/recon/js_enum/dump/katana_urls.txt"
paramspider -d "$DOMAIN" -p -s > "${BASE}/recon/js_enum/dump/paramspider_urls.txt"
waybackurls "$DOMAIN" | grep "^https://[^/]*\.${BASE}\.com" > "${BASE}/recon/js_enum/dump/wayback_urls.txt"

echo -e "${GREEN}${BOLD}✅ URL collection done. Filtering JS and alive URLs...${NC}"

# Combine and filter
cat "${BASE}"/recon/js_enum/dump/*.txt | sort | anew > "${BASE}/recon/js_enum/dump/all_urls.txt"
cat "${BASE}/recon/js_enum/dump/all_urls.txt" | grep "\.js$" | uro | sort -u | httpx-toolkit -mc 200 -t 150 -o "${BASE}/recon/js_enum/target_js_urls.txt"
cat "${BASE}/recon/js_enum/dump/all_urls.txt" | uro | sort -u | httpx-toolkit -mc 200,302 -t 150 -o "${BASE}/recon/js_enum/target_url_list.txt"

echo -e "${BLUE}${BOLD}🔍 Running Sensitive Info and Credential Leaks Scan...${NC}"

# JS Leak Analysis
cat "${BASE}/recon/js_enum/target_js_urls.txt" | jsleak -s -k
nuclei -l "${BASE}/recon/js_enum/target_js_urls.txt" -t ~/.local/nuclei-templates/http/exposures -c 30
cat "${BASE}/recon/js_enum/target_js_urls.txt" | nuclei -t ~/.local/nuclei-templates/coffinxp_nuclei_templates/credentials-disclosure-all.yaml -c 30

# LazyEgg Deep Scan (optional, messy output)
cat "${BASE}/recon/js_enum/target_js_urls.txt" | xargs -I{} bash -c 'echo -e "\n[+] Target: {}" && lazyegg "{}" --js_urls --domains --ips --leaked_creds --local_storage'

echo -e "${GREEN}${BOLD}🎯 Sensitive data scan complete.${NC}"

echo -e "${BLUE}${BOLD}🔍 Crawling for Juicy Endpoints...${NC}"

# Crawl for juicy endpoints
grep -Ei '/(admin|config|dashboard|login|auth|debug|test|staging|upload|backup|server-status|monitor|manage|dev|portal|private|panel|root|internal|console|cgi-bin|shell|setup|editor|password|credentials|db|database|env|hidden|system|account|superuser|core|includes|wp-admin|webadmin|cpanel|git|svn|api|v1|v2|token|key|secret|jwt|session|logs|error|secure|restricted|flag)(/|$)' "${BASE}/recon/js_enum/target_url_list.txt" | sort -u > "${BASE}/recon/js_enum/juicy_urls.txt"

katana -u "https://www.${DOMAIN}" -d 5 -mdc 'contains(endpoint,"api")' -jc -jsl -kf all -o "${BASE}/recon/js_enum/dump/api_endpoints.txt"
cat "${BASE}/recon/js_enum/dump/api_endpoints.txt" | uro | sort -u | httpx-toolkit -mc 200 -t 150 -o "${BASE}/recon/js_enum/juicy_api_endpoints.txt"

echo -e "${GREEN}${BOLD}✅ JS Recon & Crawling Completed. Results saved in ${BASE}/recon/js_enum/${NC}"
