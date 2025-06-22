#!/bin/bash

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"  # No color

# Check root
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}❌ Please run this script as root!${NC}"
  exit 1
fi

# Function to install tool
check_and_install() {
  tool=$1
  if ! command -v "$tool" &>/dev/null; then
    echo -e "${YELLOW}🔧 Installing $tool...${NC}"
    sudo apt install -y "$tool" &>/dev/null
    if command -v "$tool" &>/dev/null; then
      echo -e "${GREEN}✅ $tool installed!${NC}"
    else
      echo -e "${RED}❌ Failed to install $tool!${NC}"
    fi
  else
    echo -e "${GREEN}✅ $tool already installed!${NC}"
  fi
}

# Tools list
tools=(
  golang-go
  dnsrecon
  theHarvester
  subfinder
  dnsenum
  ffuf
  gobuster
  whatweb
  nuclei
  paramspider
  arjun
  finalrecon
  httpx-toolkit
  toilet
  figlet
)

# Install all tools
for tool in "${tools[@]}"; do
  check_and_install "$tool"
done

# Check nuclei-templates folder
if [[ ! -d "/usr/local/nuclei-templates" ]]; then
  echo -e "${YELLOW}📁 /usr/local/nuclei-templates not found. Running nuclei -update-templates...${NC}"
  nuclei -update-templates &>/dev/null
  if [[ -d "$HOME/nuclei-templates" ]]; then
    mv "$HOME/nuclei-templates" /usr/local/nuclei-templates
    echo -e "${GREEN}✅ nuclei templates updated and moved to /usr/local/nuclei-templates${NC}"
  fi
else
  echo -e "${GREEN}✅ /usr/local/nuclei-templates already exists!${NC}"
fi

# Clone coffinxp templates if not already present
if [[ ! -d "/usr/local/nuclei-templates/coffinxp_templates" ]]; then
  echo -e "${YELLOW}📥 Cloning coffinxp nuclei templates...${NC}"
  git clone https://github.com/coffinxp/nuclei-templates.git /usr/local/nuclei-templates/coffinxp_templates &>/dev/null
  echo -e "${GREEN}✅ coffinxp_templates added!${NC}"
else
  echo -e "${GREEN}✅ coffinxp_templates already exists!${NC}"
fi

# Function to install Go tools
install_go_tool() {
  toolname=$1
  installcmd=$2
  gobin="/root/go/bin/$toolname"

  if [[ ! -d "/root/go/bin" ]]; then
    echo -e "${RED}❌ /root/go/bin does not exist. Is Go properly installed for root user?${NC}"
    return
  fi

  if [[ -f "$gobin" ]]; then
    echo -e "${GREEN}✅ $toolname already installed in /root/go/bin${NC}"
  else
    echo -e "${YELLOW}🔧 Installing $toolname using Go...${NC}"
    go install $installcmd
    if [[ -f "$gobin" ]]; then
      echo -e "${GREEN}✅ $toolname installed successfully!${NC}"
    else
      echo -e "${RED}❌ Failed to install $toolname!${NC}"
    fi
  fi

  if [[ -f "$gobin" && ! -f "/usr/bin/$toolname" ]]; then
    ln -sf "$gobin" "/usr/bin/$toolname"
    echo -e "${GREEN}🔗 Symlinked $toolname to /usr/bin/$toolname${NC}"
  fi
}

# Install all Go tools
install_go_tool "tlsx" "github.com/projectdiscovery/tlsx/cmd/tlsx@latest"
install_go_tool "github-subdomains" "github.com/gwen001/github-subdomains@latest"
install_go_tool "shosubgo" "github.com/incogbyte/shosubgo@latest"
install_go_tool "katana" "github.com/projectdiscovery/katana/cmd/katana@latest"
install_go_tool "hakrawler" "github.com/hakluke/hakrawler@latest"
install_go_tool "gau" "github.com/lc/gau/v2/cmd/gau@latest"
install_go_tool "waybackurls" "github.com/tomnomnom/waybackurls@latest"
install_go_tool "jsleak" "github.com/channyein1337/jsleak@latest"
install_go_tool "anew" "github.com/tomnomnom/anew@latest"
install_go_tool "qsreplace" "github.com/tomnomnom/qsreplace@latest"

# Clone coffinxp scripts
if [[ ! -d "/opt/coffinxp_scripts" ]]; then
  echo -e "${YELLOW}📥 Cloning coffinxp scripts to /opt...${NC}"
  git clone https://github.com/coffinxp/scripts /opt/coffinxp_scripts &>/dev/null
  echo -e "${GREEN}✅ coffinxp_scripts downloaded to /opt/coffinxp_scripts${NC}"
else
  echo -e "${GREEN}✅ coffinxp_scripts already exists in /opt${NC}"
fi

# Setup directory
mkdir -p /opt/github_recon

# Install trufflehog to /usr/local/bin
if ! command -v trufflehog &>/dev/null; then
  echo -e "${YELLOW}📦 Installing trufflehog...${NC}"
  curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
  echo -e "${GREEN}✅ trufflehog installed to /usr/local/bin${NC}"
else
  echo -e "${GREEN}✅ trufflehog already installed.${NC}"
fi

# Clone lazyegg if not already present
if [[ ! -d "/opt/lazyegg" ]]; then
  echo -e "${YELLOW}📥 Cloning lazyegg to /opt...${NC}"
  git clone https://github.com/schooldropout1337/lazyegg.git /opt/lazyegg
  echo -e "${GREEN}✅ lazyegg cloned to /opt/lazyegg${NC}"
else
  echo -e "${GREEN}✅ lazyegg already exists in /opt.${NC}"
fi

# Create main.sh launcher
cat << 'EOF' > /opt/lazyegg/main.sh
#!/bin/bash
cd /opt/lazyegg
python3 lazyegg.py "$@"
EOF

chmod +x /opt/lazyegg/main.sh

# Symlink to /usr/bin/lazyegg
ln -sf /opt/lazyegg/main.sh /usr/bin/lazyegg
echo -e "${GREEN}🔗 Symlinked lazyegg launcher to /usr/bin/lazyegg${NC}"


# Check and create directory
if [[ ! -d "/opt/github_recon" ]]; then
  echo -e "${YELLOW}📁 Creating /opt/github_recon directory...${NC}"
  mkdir -p /opt/github_recon
else
  echo -e "${GREEN}✅ /opt/github_recon already exists.${NC}"
fi

# Check and download Gdorlinks.sh
if [[ ! -f "/opt/github_recon/Gdorlinks.sh" ]]; then
  echo -e "${YELLOW}📥 Downloading Gdorlinks.sh...${NC}"
  wget -q -O /opt/github_recon/Gdorlinks.sh "https://gist.githubusercontent.com/jhaddix/1fb7ab2409ab579178d2a79959909b33/raw/e9fea4c0f6982546d90d241bc3e19627a7083e5e/Gdorklinks.sh"
  chmod +x /opt/github_recon/Gdorlinks.sh
  echo -e "${GREEN}✅ Gdorlinks.sh downloaded and made executable.${NC}"
else
  echo -e "${GREEN}✅ Gdorlinks.sh already exists in /opt/github_recon.${NC}"
fi

# Symlink to /usr/bin/github_recon
ln -sf /opt/github_recon/Gdorlinks.sh /usr/bin/github_recon
echo -e "${GREEN}🔗 Symlinked Gdorlinks.sh to /usr/bin/github_recon${NC}"

# Clone SecretFinder into /opt if not already present
if [[ ! -d "/opt/secretfinder" ]]; then
  echo -e "${YELLOW}📥 Cloning SecretFinder...${NC}"
  git clone https://github.com/m4ll0k/SecretFinder.git /opt/secretfinder
  echo -e "${GREEN}✅ SecretFinder cloned to /opt/secretfinder${NC}"
else
  echo -e "${GREEN}✅ SecretFinder already exists in /opt${NC}"
fi

# Create a Python venv inside the directory
if [[ ! -d "/opt/secretfinder/venv" ]]; then
  echo -e "${YELLOW}🐍 Creating virtual environment...${NC}"
  python3 -m venv /opt/secretfinder/venv
  echo -e "${GREEN}✅ Virtual environment created at /opt/secretfinder/venv${NC}"
else
  echo -e "${GREEN}✅ Virtual environment already exists.${NC}"
fi

# Activate venv and install requirements with --break-system-packages
echo -e "${YELLOW}📦 Installing Python requirements in venv...${NC}"
/opt/secretfinder/venv/bin/pip install --upgrade pip &> /dev/null
/opt/secretfinder/venv/bin/pip install -r /opt/secretfinder/requirements.txt --break-system-packages

# Create launcher script
cat << 'EOF' > /opt/secretfinder/main.sh
#!/bin/bash
cd /opt/secretfinder
source venv/bin/activate
python3 SecretFinder.py "$@"
EOF

chmod +x /opt/secretfinder/main.sh

# Symlink to /usr/bin
ln -sf /opt/secretfinder/main.sh /usr/bin/secretfinder
echo -e "${GREEN}🔗 Symlinked SecretFinder launcher to /usr/bin/secretfinder${NC}"

# Clone LinkFinder if not already present
if [[ ! -d "/opt/linkfinder" ]]; then
  echo -e "${YELLOW}📥 Cloning LinkFinder...${NC}"
  git clone https://github.com/GerbenJavado/LinkFinder.git /opt/linkfinder
  echo -e "${GREEN}✅ LinkFinder cloned to /opt/linkfinder${NC}"
else
  echo -e "${GREEN}✅ LinkFinder already exists in /opt${NC}"
fi

# Create Python virtual environment
if [[ ! -d "/opt/linkfinder/venv" ]]; then
  echo -e "${YELLOW}🐍 Creating virtual environment...${NC}"
  python3 -m venv /opt/linkfinder/venv
  echo -e "${GREEN}✅ Virtual environment created at /opt/linkfinder/venv${NC}"
else
  echo -e "${GREEN}✅ Virtual environment already exists.${NC}"
fi

# Activate venv and install requirements
echo -e "${YELLOW}📦 Installing requirements.txt into venv...${NC}"
/opt/linkfinder/venv/bin/pip install --upgrade pip &> /dev/null
/opt/linkfinder/venv/bin/pip install -r /opt/linkfinder/requirements.txt --break-system-packages

# Install LinkFinder using setup.py inside venv
echo -e "${YELLOW}⚙️  Installing LinkFinder with setup.py...${NC}"
cd /opt/linkfinder
/opt/linkfinder/venv/bin/python setup.py install

# Create launcher script
cat << 'EOF' > /opt/linkfinder/main.sh
#!/bin/bash
cd /opt/linkfinder
source venv/bin/activate
python3 linkfinder.py "$@"
EOF

chmod +x /opt/linkfinder/main.sh

# Symlink to /usr/bin
ln -sf /opt/linkfinder/main.sh /usr/bin/linkfinder
echo -e "${GREEN}🔗 Symlinked LinkFinder launcher to /usr/bin/linkfinder${NC}"

# Clone the repo if not already present
if [[ ! -d "/opt/4-ZERO-3" ]]; then
  echo -e "${YELLOW}📥 Cloning 4-ZERO-3 repository...${NC}"
  git clone https://github.com/Dheerajmadhukar/4-ZERO-3.git /opt/4-ZERO-3
  echo -e "${GREEN}✅ Cloned to /opt/4-ZERO-3${NC}"
else
  echo -e "${GREEN}✅ 4-ZERO-3 already exists in /opt${NC}"
fi

# Ensure the script is executable
chmod +x /opt/4-ZERO-3/403-bypass.sh

# Create symlink to /usr/bin/403bypasser
ln -sf /opt/4-ZERO-3/403-bypass.sh /usr/bin/403bypasser
echo -e "${GREEN}🔗 Symlinked 403-bypass.sh to /usr/bin/403bypasser${NC}"

# Clone repo if not present
if [[ ! -d "/opt/openredirex" ]]; then
  echo -e "${YELLOW}📥 Cloning OpenRedirex...${NC}"
  git clone https://github.com/devanshbatham/openredirex /opt/openredirex
  echo -e "${GREEN}✅ Cloned to /opt/openredirex${NC}"
else
  echo -e "${GREEN}✅ OpenRedirex already exists in /opt${NC}"
fi


# Create main.sh launcher
cat << 'EOF' > /opt/openredirex/main.sh
#!/bin/bash
cd /opt/openredirex
python3 openredirex.py "$@"
EOF

chmod +x /opt/openredirex/main.sh

# Symlink to /usr/bin
ln -sf /opt/openredirex/main.sh /usr/bin/openredirex
echo -e "${GREEN}🔗 Symlinked OpenRedirex to /usr/bin/openredirex${NC}"

### === Loxs Install === ###
if [[ ! -d "/opt/loxs" ]]; then
  echo -e "${YELLOW}📥 Cloning Loxs...${NC}"
  git clone https://github.com/coffinxp/loxs /opt/loxs
  echo -e "${GREEN}✅ Loxs cloned to /opt/loxs${NC}"
else
  echo -e "${GREEN}✅ Loxs already exists in /opt${NC}"
fi

# Create virtual environment
if [[ ! -d "/opt/loxs/venv" ]]; then
  echo -e "${YELLOW}🐍 Creating virtual environment for Loxs...${NC}"
  python3 -m venv /opt/loxs/venv
  echo -e "${GREEN}✅ venv created at /opt/loxs/venv${NC}"
else
  echo -e "${GREEN}✅ venv already exists for Loxs${NC}"
fi

# Install requirements.txt using venv pip
echo -e "${YELLOW}📦 Installing requirements.txt in Loxs venv...${NC}"
/opt/loxs/venv/bin/pip install --upgrade pip &>/dev/null
/opt/loxs/venv/bin/pip install -r /opt/loxs/requirements.txt --break-system-packages

### === coffinxp_scripts Install === ###
if [[ ! -d "/opt/coffinxp_scripts" ]]; then
  echo -e "${YELLOW}📥 Cloning coffinxp_scripts...${NC}"
  git clone https://github.com/coffinxp/scripts /opt/coffinxp_scripts
  echo -e "${GREEN}✅ coffinxp_scripts cloned to /opt/coffinxp_scripts${NC}"
else
  echo -e "${GREEN}✅ coffinxp_scripts already exists in /opt${NC}"
fi

pipx install uro
pipx ensurepath
echo -e "${GREEN}🎉 All tasks complete!${NC}"

