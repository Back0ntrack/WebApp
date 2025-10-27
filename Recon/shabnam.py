#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import time
import re
from pathlib import Path

# ANSI color codes for status updates
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_status(message, color=Colors.GREEN):
    print(f"{color}{message}{Colors.ENDC}")

def print_error(message):
    print(f"{Colors.RED}{Colors.BOLD}ERROR: {message}{Colors.ENDC}")
    sys.exit(1)

def validate_domain(domain):
    """Validate that the domain is an apex (root) domain, e.g., example.com, not www.example.com or api.example.com."""
    domain_lower = domain.lower().strip()
    if not re.match(r'^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$', domain_lower):
        print_error("Invalid domain format. Please provide a valid apex domain (e.g., example.com).")
    
    # Check for common subdomain prefixes
    common_subs = {'www', 'mail', 'ftp', 'api', 'dev', 'test', 'staging', 'blog', 'shop', 'admin'}
    first_part = domain_lower.split('.')[0]
    if first_part in common_subs:
        print_error(f"Domain appears to be a subdomain (starts with '{first_part}'). Please provide the apex domain only.")
    
    return domain_lower

def create_directories(base_path, domain):
    """Create the directory structure if it doesn't exist."""
    recon_dir = Path(base_path) / "recon_framework" / domain
    recon_dir.mkdir(parents=True, exist_ok=True)
    
    (recon_dir / "fast_approach").mkdir(exist_ok=True)
    (recon_dir / "slow_approach").mkdir(exist_ok=True)
    (recon_dir / "results").mkdir(exist_ok=True)
    
    return recon_dir

def run_command(cmd, cwd, description):
    """Run a shell command sequentially, time it, and print status."""
    print_status(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Starting: {description}", Colors.BLUE)
    start_time = time.time()
    try:
        result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True, check=True)
        end_time = time.time()
        duration = end_time - start_time
        print_status(f"✓ Completed: {description} in {duration:.2f}s", Colors.GREEN)
        if result.stdout.strip():
            print(f"  Output preview: {result.stdout.strip()[:100]}...")
        return result
    except subprocess.CalledProcessError as e:
        end_time = time.time()
        duration = end_time - start_time
        print_error(f"✗ Failed: {description} after {duration:.2f}s\n  Error: {e.stderr}")
    except Exception as e:
        print_error(f"✗ Exception in: {description}\n  Error: {str(e)}")

def main():
    parser = argparse.ArgumentParser(description="Shabnam: Subdomain Enumeration Tool")
    parser.add_argument("domain", help="Apex domain to enumerate (e.g., example.com)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-f", "--fast", action="store_true", help="Run fast approach")
    group.add_argument("-s", "--slow", action="store_true", help="Run slow approach")
    args = parser.parse_args()
    
    domain = validate_domain(args.domain)
    recon_base = "/root"
    recon_dir = create_directories(recon_base, domain)
    fast_dir = recon_dir / "fast_approach"
    slow_dir = recon_dir / "slow_approach"
    results_dir = recon_dir / "results"
    
    print_status(f"{Colors.BOLD}Starting Shabnam for {domain} ({'Fast' if args.fast else 'Slow'} approach){Colors.ENDC}")
    
    if args.fast:
        approach_dir = fast_dir
        print_status("Running FAST approach", Colors.YELLOW)
        
        # 1. findomain
        cmd1 = f"findomain -t {domain} -u {fast_dir}/findomain_results.txt"
        run_command(cmd1, recon_dir, "findomain scan")
        
        # 2. subfinder
        cmd2 = f"subfinder -d {domain} -o {fast_dir}/subfinder_results.txt"
        run_command(cmd2, recon_dir, "subfinder scan")
        
        # 3. Combine unique subdomains
        cmd3 = f"cat {fast_dir}/findomain_results.txt {fast_dir}/subfinder_results.txt | anew > {fast_dir}/all_subs.txt"
        run_command(cmd3, fast_dir, "Combine unique subdomains (anew)")
        
        # 4. httpx for alive (200)
        cmd4 = f"httpx-toolkit -l {fast_dir}/all_subs.txt -mc 200 -ports 80,443,8080,8000,8888,8443,3000 -o {fast_dir}/alive_subs_url.txt -random-agent"
        run_command(cmd4, fast_dir, "httpx alive check (200)")
        
        # 5. httpx for redirects (301,302)
        cmd5 = f"httpx-toolkit -l {fast_dir}/all_subs.txt -mc 301,302 -ports 80,443,8080,8000,8888,8443,3000 -o {fast_dir}/redirecting_subs_url.txt -random-agent"
        run_command(cmd5, fast_dir, "httpx redirect check (301/302)")
        
        # 6. httpx for forbidden (403)
        cmd6 = f"httpx-toolkit -l {fast_dir}/all_subs.txt -mc 403 -ports 80,443,8080,8000,8888,8443,3000 -o {fast_dir}/forbidden_subs_url.txt -random-agent"
        run_command(cmd6, fast_dir, "httpx forbidden check (403)")
        
        # 7. Append stripped results to results dir using anew
        cmd7a = f"sed -E 's|https?://||g' {fast_dir}/alive_subs_url.txt | anew {results_dir}/alive_subs.txt"
        run_command(cmd7a, fast_dir, "Append alive subs to results (anew)")
        
        cmd7b = f"sed -E 's|https?://||g' {fast_dir}/redirecting_subs_url.txt | anew {results_dir}/redirecting_subs.txt"
        run_command(cmd7b, fast_dir, "Append redirecting subs to results (anew)")
        
        cmd7c = f"sed -E 's|https?://||g' {fast_dir}/forbidden_subs_url.txt | anew {results_dir}/forbidden_subs.txt"
        run_command(cmd7c, fast_dir, "Append forbidden subs to results (anew)")
        
    elif args.slow:
        approach_dir = slow_dir
        print_status("Running SLOW approach", Colors.YELLOW)
        
        # Prompt for API keys
        github_key = input("Enter GitHub API key: ").strip()
        if not github_key:
            print_error("GitHub API key is required for slow approach.")
        shodan_key = input("Enter Shodan API key: ").strip()
        if not shodan_key:
            print_error("Shodan API key is required for slow approach.")
        
        # 1. shosubgo
        cmd1 = f"shosubgo -d {domain} -s {shodan_key} -o {slow_dir}/shodan_subs.txt"
        run_command(cmd1, recon_dir, "shosubgo (Shodan subdomains)")
        
        # 2. github-subdomains
        cmd2 = f"github-subdomains -d {domain} -t {github_key} -o {slow_dir}/github_subs.txt"
        run_command(cmd2, recon_dir, "github-subdomains scan")
        
        # 3. Combine unique subdomains
        cmd3 = f"cat {slow_dir}/shodan_subs.txt {slow_dir}/github_subs.txt | anew > {slow_dir}/all_subs.txt"
        run_command(cmd3, slow_dir, "Combine unique subdomains (anew)")
        
        # 4. httpx for alive (200)
        cmd4 = f"httpx-toolkit -l {slow_dir}/all_subs.txt -mc 200 -ports 80,443,8080,8000,8888,8443,3000 -o {slow_dir}/alive_subs_url.txt -random-agent"
        run_command(cmd4, slow_dir, "httpx alive check (200)")
        
        # 5. Append stripped alive results to results dir using anew
        cmd5 = f"sed -E 's|https?://||g' {slow_dir}/alive_subs_url.txt | anew {results_dir}/alive_subs.txt"
        run_command(cmd5, slow_dir, "Append alive subs to results (anew)")
        
        # 6. ffuf with n0kovo wordlist
        cmd6 = f"ffuf -u 'https://FUZZ.{domain}' -w /opt/wordlists/n0kovo_subdomains/n0kovo_subdomains_medium.txt -o {slow_dir}/list1.json -ic -c -mc 200"
        run_command(cmd6, recon_dir, "ffuf brute-force (n0kovo medium)")
        
        # 7. ffuf with shubs-subdomains
        cmd7 = f"ffuf -u 'https://FUZZ.{domain}' -w /usr/share/seclists/Discovery/DNS/shubs-subdomains.txt -o {slow_dir}/list2.json -ic -c -mc 200"
        run_command(cmd7, recon_dir, "ffuf brute-force (shubs-subdomains)")
        
        # 8. ffuf with top1million-20000
        cmd8 = f"ffuf -u 'https://FUZZ.{domain}' -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt -o {slow_dir}/list3.json -ic -c -mc 200"
        run_command(cmd8, recon_dir, "ffuf brute-force (top1million-20000)")
        
        # 9. Combine ffuf JSON outputs
        cmd9 = f"cat {slow_dir}/list1.json {slow_dir}/list2.json {slow_dir}/list3.json > {slow_dir}/combined.json"
        run_command(cmd9, slow_dir, "Combine ffuf JSON results")
        
        # 10. Extract unique hosts with jq and append to results using anew
        cmd10 = f"jq -r '.results[].host' {slow_dir}/combined.json | sort -u | anew {results_dir}/alive_subs.txt"
        run_command(cmd10, slow_dir, "Extract and append unique ffuf hosts to results (anew)")
    
    print_status(f"{Colors.BOLD}Shabnam completed for {domain}! Check {recon_dir} for outputs.{Colors.ENDC}")

if __name__ == "__main__":
    main()