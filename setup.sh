#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

clear
echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ██╗      █████╗ ██████╗  █████╗ ██╗   ██╗███████╗██╗       ║
║   ██║     ██╔══██╗██╔══██╗██╔══██╗██║   ██║██╔════╝██║       ║
║   ██║     ███████║██████╔╝███████║██║   ██║█████╗  ██║       ║
║   ██║     ██╔══██║██╔══██╗██╔══██║╚██╗ ██╔╝██╔══╝  ██║       ║
║   ███████╗██║  ██║██║  ██║██║  ██║ ╚████╔╝ ███████╗███████╗  ║
║   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚══════╝  ║
║                                                              ║
║           Docker Scaffolding Tool v1.0.1                     ║
║           MySQL 8.0 • Swoole • Smart Deploy                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

show_progress() {
    local duration=$1
    local message=$2
    echo -ne "${CYAN}${message}${NC} "
    for ((i=0; i<=20; i++)); do
        echo -ne "${GREEN}▓${NC}"
        sleep $(echo "$duration / 20" | bc -l)
    done
    echo -e " ${GREEN}✓${NC}"
}

configure_docker_dns() {
    echo -e "\n${PURPLE}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}  ${BOLD}DOCKER DNS CONFIGURATION${NC}             ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════╝${NC}\n"

    echo -e "${DIM}Checking Docker daemon DNS configuration...${NC}\n"

    DAEMON_JSON="/etc/docker/daemon.json"
    NEEDS_CONFIG=false

    if [ ! -f "$DAEMON_JSON" ]; then
        NEEDS_CONFIG=true
        echo -e "${YELLOW}⊘${NC} Docker daemon.json not found"
    else
        if ! grep -q '"dns"' "$DAEMON_JSON" 2>/dev/null; then
            NEEDS_CONFIG=true
            echo -e "${YELLOW}⊘${NC} DNS configuration not found in daemon.json"
        else
            echo -e "${GREEN}✓${NC} Docker DNS already configured"
        fi
    fi

    if [ "$NEEDS_CONFIG" = true ]; then
        echo -e "\n${CYAN}➤${NC} ${BOLD}Configure Docker DNS?${NC}"
        echo -e "${DIM}This will add Google DNS (8.8.8.8, 8.8.4.4) to Docker daemon${NC}"
        echo -e "${DIM}Required for pulling images from Docker Hub${NC}"
        read -p "  └─> Configure now? (y/n) [y]: " CONFIGURE_DNS
        CONFIGURE_DNS=${CONFIGURE_DNS:-y}

        if [[ "$CONFIGURE_DNS" == "y" ]]; then
            echo -e "\n${YELLOW}Configuring Docker DNS (requires sudo)...${NC}"

            if [ -f "$DAEMON_JSON" ]; then
                sudo cp "$DAEMON_JSON" "${DAEMON_JSON}.backup.$(date +%Y%m%d_%H%M%S)"
                echo -e "${GREEN}✓${NC} Backup created: ${DAEMON_JSON}.backup.*"

                if command -v jq &> /dev/null; then
                    sudo jq '. + {"dns": ["8.8.8.8", "8.8.4.4"]}' "$DAEMON_JSON" > /tmp/daemon.json.tmp
                    sudo mv /tmp/daemon.json.tmp "$DAEMON_JSON"
                else
                    TEMP_JSON=$(sudo cat "$DAEMON_JSON" | sed 's/}$/,"dns":["8.8.8.8","8.8.4.4"]}/')
                    echo "$TEMP_JSON" | sudo tee "$DAEMON_JSON" > /dev/null
                fi
            else
                sudo mkdir -p /etc/docker
                echo '{
  "dns": ["8.8.8.8", "8.8.4.4"]
}' | sudo tee "$DAEMON_JSON" > /dev/null
            fi

            echo -e "${GREEN}✓${NC} Docker DNS configured"
            echo -e "\n${YELLOW}Restarting Docker daemon...${NC}"

            if sudo systemctl restart docker; then
                echo -e "${GREEN}✓${NC} Docker daemon restarted successfully"
                sleep 2
            else
                echo -e "${RED}✗${NC} Failed to restart Docker daemon"
                echo -e "${YELLOW}Please restart manually: sudo systemctl restart docker${NC}"
                read -p "Press Enter to continue..."
            fi
        else
            echo -e "${YELLOW}⊘${NC} Skipping DNS configuration"
            echo -e "${DIM}You may need to configure it manually if image pulling fails${NC}"
        fi
    fi
    echo ""
}

configure_docker_dns

echo -e "${PURPLE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}  ${BOLD}KONFIGURASI PROJECT${NC}                  ${PURPLE}║${NC}"
echo -e "${PURPLE}╚═══════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}➤${NC} ${BOLD}Nama Project:${NC} ${DIM}(contoh: My Bini)${NC}"
read -p "  └─> " RAW_NAME
RAW_NAME=${RAW_NAME:-Laravel App}

PROJECT_SLUG=$(echo "$RAW_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
PROJECT_SLUG=${PROJECT_SLUG//[^a-z0-9-]/}

echo -e "  ${GREEN}✓${NC} Project Slug: ${YELLOW}${BOLD}$PROJECT_SLUG${NC}\n"

echo -e "${CYAN}➤${NC} ${BOLD}PHP Version:${NC}"
echo -e "  ${DIM}1)${NC} PHP 8.1"
echo -e "  ${DIM}2)${NC} PHP 8.2"
echo -e "  ${DIM}3)${NC} PHP 8.3"
echo -e "  ${DIM}4)${NC} PHP 8.4 ${GREEN}(Recommended)${NC}"
read -p "  └─> Pilih (1-4) [Default: 4]: " PHP_CHOICE
PHP_CHOICE=${PHP_CHOICE:-4}

case $PHP_CHOICE in
    1) PHP_VERSION="8.1" ;;
    2) PHP_VERSION="8.2" ;;
    3) PHP_VERSION="8.3" ;;
    4) PHP_VERSION="8.4" ;;
    *) PHP_VERSION="8.4" ;;
esac

echo -e "  ${GREEN}✓${NC} PHP Version: ${YELLOW}${BOLD}$PHP_VERSION${NC}\n"

echo -e "${CYAN}➤${NC} ${BOLD}Port Configuration:${NC}"
read -p "  ├─ App Port (Host) [Default: 5059]: " APP_PORT
APP_PORT=${APP_PORT:-5059}
echo -e "  ${GREEN}✓${NC} App Port: ${YELLOW}$APP_PORT${NC}"

read -p "  ├─ App URL [Default: http://localhost:${APP_PORT}]: " APP_URL_INPUT
APP_URL_INPUT=${APP_URL_INPUT:-http://localhost:${APP_PORT}}
echo -e "  ${GREEN}✓${NC} App URL: ${YELLOW}$APP_URL_INPUT${NC}"

read -p "  └─ MySQL Port (Host) [Default: 3343]: " DB_PORT_HOST
DB_PORT_HOST=${DB_PORT_HOST:-3343}
echo -e "  ${GREEN}✓${NC} MySQL Port: ${YELLOW}$DB_PORT_HOST${NC}\n"

echo -e "${CYAN}➤${NC} ${BOLD}Database Configuration:${NC}"
read -p "  ├─ Database Name [Default: ${PROJECT_SLUG//-/_}]: " DB_NAME
DB_NAME=${DB_NAME:-${PROJECT_SLUG//-/_}}
echo -e "  ${GREEN}✓${NC} DB Name: ${YELLOW}$DB_NAME${NC}"

GEN_DB_PASS=$(openssl rand -base64 12)
read -p "  ├─ Database Password [Default: $GEN_DB_PASS]: " DB_PASSWORD
DB_PASSWORD=${DB_PASSWORD:-$GEN_DB_PASS}
echo -e "  ${GREEN}✓${NC} DB Password: ${YELLOW}${DB_PASSWORD}${NC}"

read -p "  └─ MySQL Root Password [Default: root_$GEN_DB_PASS]: " DB_ROOT_PASSWORD
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-root_$GEN_DB_PASS}
echo -e "  ${GREEN}✓${NC} Root Password: ${YELLOW}${DB_ROOT_PASSWORD}${NC}\n"

echo -e "${PURPLE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}  ${BOLD}STARTUP CONFIGURATION${NC}                ${PURPLE}║${NC}"
echo -e "${PURPLE}╚═══════════════════════════════════════════╝${NC}\n"

echo -e "${DIM}Konfigurasi default yang akan dijalankan saat container start${NC}\n"

echo -e "${CYAN}➤${NC} ${BOLD}Default Startup Settings:${NC}"
read -p "  ├─ Jalankan Migrate? (y/n) [y]: " DEF_MIGRATE
[[ "${DEF_MIGRATE:-y}" == "y" ]] && ENV_MIGRATE="true" || ENV_MIGRATE="false"
echo -e "  ${GREEN}✓${NC} Migration: ${YELLOW}$ENV_MIGRATE${NC}"

read -p "  ├─ Jalankan Storage Link? (y/n) [y]: " DEF_STORAGE
[[ "${DEF_STORAGE:-y}" == "y" ]] && ENV_STORAGE="true" || ENV_STORAGE="false"
echo -e "  ${GREEN}✓${NC} Storage Link: ${YELLOW}$ENV_STORAGE${NC}"

read -p "  └─ Jalankan Seeder? (y/n) [n]: " DEF_SEEDER
[[ "${DEF_SEEDER:-n}" == "y" ]] && ENV_SEEDER="true" || ENV_SEEDER="false"
echo -e "  ${GREEN}✓${NC} Seeder: ${YELLOW}$ENV_SEEDER${NC}\n"

echo -e "${PURPLE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}  ${BOLD}OPTIONAL FEATURES${NC}                    ${PURPLE}║${NC}"
echo -e "${PURPLE}╚═══════════════════════════════════════════╝${NC}\n"

echo -e "${CYAN}➤${NC} ${BOLD}Redis Cache Server:${NC}"
read -p "  ├─ Install Redis? (y/n) [n]: " INSTALL_REDIS
INSTALL_REDIS=${INSTALL_REDIS:-n}

if [[ "$INSTALL_REDIS" == "y" ]]; then
    read -p "  └─ Redis Port (Host) [Default: 6379]: " REDIS_PORT
    REDIS_PORT=${REDIS_PORT:-6379}
    echo -e "  ${GREEN}✓${NC} Redis: ${YELLOW}Enabled${NC} on port ${YELLOW}${REDIS_PORT}${NC}\n"

    REDIS_HOST="redis"
    REDIS_PASSWORD=""
    CACHE_DRIVER="redis"
    SESSION_DRIVER="redis"
    QUEUE_CONNECTION="redis"
else
    echo -e "  ${YELLOW}⊘${NC} Redis: Disabled\n"
    CACHE_DRIVER="file"
    SESSION_DRIVER="file"
    QUEUE_CONNECTION="database"
fi

echo -e "${CYAN}➤${NC} ${BOLD}phpMyAdmin:${NC}"
read -p "  ├─ Install phpMyAdmin? (y/n) [n]: " INSTALL_PMA
INSTALL_PMA=${INSTALL_PMA:-n}

if [[ "$INSTALL_PMA" == "y" ]]; then
    read -p "  └─ phpMyAdmin Port (Host) [Default: 8080]: " PMA_PORT
    PMA_PORT=${PMA_PORT:-8080}
    echo -e "  ${GREEN}✓${NC} phpMyAdmin: ${YELLOW}Enabled${NC} on port ${YELLOW}${PMA_PORT}${NC}\n"
else
    echo -e "  ${YELLOW}⊘${NC} phpMyAdmin: Disabled\n"
fi

echo -e "${CYAN}➤${NC} ${BOLD}SSH Key Setup:${NC} ${DIM}(untuk git pull manual)${NC}"
mkdir -p docker/ssh
if [ -f ~/.ssh/id_rsa ]; then
    read -p "  └─ Copy ~/.ssh/id_rsa ke container? (y/n) [y]: " COPY_SSH
    if [[ "${COPY_SSH:-y}" == "y" ]]; then
        cp ~/.ssh/id_rsa docker/ssh/id_rsa
        cp ~/.ssh/id_rsa.pub docker/ssh/id_rsa.pub 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} SSH Key disalin ke container\n"
    else
        echo -e "  ${YELLOW}⊘${NC} SSH Key tidak disalin\n"
    fi
else
    echo -e "  ${YELLOW}⊘${NC} File ~/.ssh/id_rsa tidak ditemukan\n"
fi
touch docker/ssh/placeholder

show_progress 1.5 "Generating configuration files"

mkdir -p docker/mysql

echo -e "\n${PURPLE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}  ${BOLD}CREATING DOCKER FILES${NC}                ${PURPLE}║${NC}"
echo -e "${PURPLE}╚═══════════════════════════════════════════╝${NC}\n"

REDIS_EXT=""
if [[ "$INSTALL_REDIS" == "y" ]]; then
    REDIS_EXT="RUN pecl install redis && docker-php-ext-enable redis"
fi

cat << EOF > Dockerfile
FROM php:${PHP_VERSION}-cli-alpine AS base
WORKDIR /var/www/html
RUN apk add --no-cache ca-certificates curl git zip unzip supervisor nodejs npm tzdata libpng libzip libzip-dev nano bash dos2unix openssh-client
RUN apk add --no-cache --virtual .build-deps \$PHPIZE_DEPS git curl libpng-dev oniguruma-dev icu-dev mysql-client linux-headers brotli-dev
ENV TZ=Asia/Jakarta
RUN docker-php-ext-install -j\$(nproc) gd pdo pdo_mysql mbstring exif pcntl bcmath zip
${REDIS_EXT}
RUN mkdir -p /tmp/swoole && cd /tmp/swoole && curl -L https://pecl.php.net/get/swoole-6.1.0.tgz | tar -xz && cd swoole-6.1.0 && phpize && ./configure --enable-brotli && make -j\$(nproc) && make install && docker-php-ext-enable swoole && cd / && rm -rf /tmp/swoole
RUN apk del .build-deps
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY docker/ssh /root/.ssh
RUN chmod 700 /root/.ssh && if [ -f /root/.ssh/id_rsa ]; then chmod 600 /root/.ssh/id_rsa; ssh-keyscan github.com gitlab.com bitbucket.org >> /root/.ssh/known_hosts; fi
COPY . .
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && dos2unix /usr/local/bin/docker-entrypoint.sh
RUN git config --global --add safe.directory /var/www/html
RUN if [ -f "composer.json" ]; then composer install --no-interaction --optimize-autoloader --no-dev --prefer-dist --ignore-platform-reqs; fi
RUN if [ -f "package.json" ]; then npm install && npm run build && rm -rf node_modules; fi
RUN chown -R www-data:www-data /var/www/html && chmod -R 777 /var/www/html/storage 2>/dev/null || true
EXPOSE ${APP_PORT}
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
EOF
echo -e "  ${GREEN}✓${NC} Created ${BOLD}Dockerfile${NC} ${DIM}(PHP ${PHP_VERSION}$([[ "$INSTALL_REDIS" == "y" ]] && echo " + Redis"))${NC}"

cat << EOF > docker-entrypoint.sh
#!/bin/bash
set -e
echo "[Entrypoint] Starting setup..."

if ! grep -q "laravel/octane" composer.json; then
    echo "[Entrypoint] Installing Octane..."
    composer require laravel/octane --no-interaction
    php artisan octane:install --server=swoole --no-interaction
fi

if grep -q "APP_KEY=" .env && [ -z "\$(grep "APP_KEY=" .env | cut -d '=' -f 2 | tr -d '\r')" ]; then
    echo "[Entrypoint] Warning: APP_KEY is empty. Generating fallback key..."
    php artisan key:generate --force
fi

echo "[Entrypoint] Waiting MySQL..."
while ! nc -z mysql 3306; do sleep 2; done

EOF

if [[ "$INSTALL_REDIS" == "y" ]]; then
cat << EOF >> docker-entrypoint.sh
echo "[Entrypoint] Waiting Redis..."
while ! nc -z redis 6379; do sleep 2; done

EOF
fi

cat << EOF >> docker-entrypoint.sh
echo "[Config] Migration: \$DOCKER_RUN_MIGRATION"
echo "[Config] Seeder:    \$DOCKER_RUN_SEEDER"
echo "[Config] Storage:   \$DOCKER_RUN_STORAGE_LINK"

if [ "\$DOCKER_RUN_MIGRATION" = "true" ]; then
    echo "[Entrypoint] Running migrate..."
    php artisan migrate --force
fi

if [ "\$DOCKER_RUN_SEEDER" = "true" ]; then
    echo "[Entrypoint] Running seeder..."
    php artisan db:seed --force
fi

if [ "\$DOCKER_RUN_STORAGE_LINK" = "true" ]; then
    echo "[Entrypoint] Linking storage..."
    php artisan storage:link 2>/dev/null || true
fi

echo "[Entrypoint] Starting Server..."
php artisan config:clear
php artisan route:clear

if php artisan list | grep -q "octane:start"; then
    exec php artisan octane:start --server=swoole --host=0.0.0.0 --port=${APP_PORT} --workers=4
else
    exec php artisan serve --host=0.0.0.0 --port=${APP_PORT}
fi
EOF
chmod +x docker-entrypoint.sh
echo -e "  ${GREEN}✓${NC} Created ${BOLD}docker-entrypoint.sh${NC}"

cat << EOF > docker-compose.yml
services:
  app:
    build:
      context: .
    container_name: ${PROJECT_SLUG}-app
    restart: unless-stopped
    dns:
      - 8.8.8.8
      - 8.8.4.4
    ports:
      - "${APP_PORT}:${APP_PORT}"
    env_file:
      - .env
    environment:
      DOCKER_RUN_MIGRATION: \${DOCKER_RUN_MIGRATION}
      DOCKER_RUN_SEEDER: \${DOCKER_RUN_SEEDER}
      DOCKER_RUN_STORAGE_LINK: \${DOCKER_RUN_STORAGE_LINK}
      APP_PORT: ${APP_PORT}
      DB_HOST: mysql
      DB_PORT: 3306
EOF

if [[ "$INSTALL_REDIS" == "y" ]]; then
cat << EOF >> docker-compose.yml
      REDIS_HOST: redis
      REDIS_PORT: 6379
EOF
fi

cat << EOF >> docker-compose.yml
    depends_on:
      mysql:
        condition: service_healthy
EOF

if [[ "$INSTALL_REDIS" == "y" ]]; then
cat << EOF >> docker-compose.yml
      redis:
        condition: service_healthy
EOF
fi

cat << EOF >> docker-compose.yml
    networks:
      - ${PROJECT_SLUG}-network
    volumes:
      - ./storage/app:/var/www/html/storage/app
      - ./storage/logs:/var/www/html/storage/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:${APP_PORT}/up"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  mysql:
    image: mysql:8.0
    container_name: ${PROJECT_SLUG}-mysql
    restart: unless-stopped
    dns:
      - 8.8.8.8
      - 8.8.4.4
    ports:
      - "${DB_PORT_HOST}:3306"
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${PROJECT_SLUG}_user
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ${PROJECT_SLUG}-mysql-data:/var/lib/mysql
      - ./docker/mysql/my.cnf:/etc/mysql/conf.d/my.cnf
    networks:
      - ${PROJECT_SLUG}-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${DB_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
    command: --default-authentication-plugin=mysql_native_password
EOF

if [[ "$INSTALL_REDIS" == "y" ]]; then
cat << EOF >> docker-compose.yml

  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_SLUG}-redis
    restart: unless-stopped
    dns:
      - 8.8.8.8
      - 8.8.4.4
    ports:
      - "${REDIS_PORT}:6379"
    command: redis-server --appendonly yes
    volumes:
      - ${PROJECT_SLUG}-redis-data:/data
    networks:
      - ${PROJECT_SLUG}-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
EOF
fi

if [[ "$INSTALL_PMA" == "y" ]]; then
cat << EOF >> docker-compose.yml

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: ${PROJECT_SLUG}-pma
    restart: unless-stopped
    dns:
      - 8.8.8.8
      - 8.8.4.4
    ports:
      - "${PMA_PORT}:80"
    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
      UPLOAD_LIMIT: 256M
    networks:
      - ${PROJECT_SLUG}-network
    depends_on:
      mysql:
        condition: service_healthy
EOF
echo -e "  ${GREEN}✓${NC} Created ${BOLD}docker-compose.yml${NC} ${DIM}(with phpMyAdmin$([[ "$INSTALL_REDIS" == "y" ]] && echo " + Redis"))${NC}"
else
echo -e "  ${GREEN}✓${NC} Created ${BOLD}docker-compose.yml${NC}$([[ "$INSTALL_REDIS" == "y" ]] && echo " ${DIM}(with Redis)${NC}")"
fi

cat << EOF >> docker-compose.yml

volumes:
  ${PROJECT_SLUG}-mysql-data:
    driver: local
EOF

if [[ "$INSTALL_REDIS" == "y" ]]; then
cat << EOF >> docker-compose.yml
  ${PROJECT_SLUG}-redis-data:
    driver: local
EOF
fi

cat << EOF >> docker-compose.yml

networks:
  ${PROJECT_SLUG}-network:
    driver: bridge
EOF

cat << EOF > deploy.sh
#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

chmod +x docker-entrypoint.sh

if [ -f .env ]; then
    source .env 2>/dev/null
fi

if [ -z "\$APP_KEY" ]; then
    echo -e "\${YELLOW}APP_KEY kosong. Generating...${NC}"
    NEW_KEY="base64:\$(openssl rand -base64 32)"
    if [[ "\$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|^APP_KEY=.*|APP_KEY=\$NEW_KEY|" .env
    else
        sed -i "s|^APP_KEY=.*|APP_KEY=\$NEW_KEY|" .env
    fi
    export APP_KEY="\$NEW_KEY"
    echo -e "\${GREEN}✓ APP_KEY Generated: \$NEW_KEY\${NC}"
fi

echo -e "\${CYAN}╔═══════════════════════════════════════════╗\${NC}"
echo -e "\${CYAN}║  Deployment Configuration                 ║\${NC}"
echo -e "\${CYAN}╠═══════════════════════════════════════════╣\${NC}"
echo -e "\${CYAN}║\${NC}  Migration : \${DOCKER_RUN_MIGRATION:-false}"
echo -e "\${CYAN}║\${NC}  Seeder    : \${DOCKER_RUN_SEEDER:-false}"
echo -e "\${CYAN}║\${NC}  Storage   : \${DOCKER_RUN_STORAGE_LINK:-false}"
echo -e "\${CYAN}╚═══════════════════════════════════════════╝\${NC}"
echo ""

read -p "Gunakan konfigurasi di atas? (y/n) [y]: " USE_DEFAULT
USE_DEFAULT=\${USE_DEFAULT:-y}

if [[ "\$USE_DEFAULT" == "n" ]]; then
    echo -e "\${YELLOW}Override Configuration (Hanya untuk deploy ini):\${NC}"

    read -p "Run Migration? (y/n) [n]: " OVR_MIGRATE
    [[ "\$OVR_MIGRATE" == "y" ]] && export DOCKER_RUN_MIGRATION=true || export DOCKER_RUN_MIGRATION=false

    read -p "Run Seeder? (y/n) [n]: " OVR_SEEDER
    [[ "\$OVR_SEEDER" == "y" ]] && export DOCKER_RUN_SEEDER=true || export DOCKER_RUN_SEEDER=false

    read -p "Run Storage Link? (y/n) [y]: " OVR_STORAGE
    [[ "\$OVR_STORAGE" == "y" ]] && export DOCKER_RUN_STORAGE_LINK=true || export DOCKER_RUN_STORAGE_LINK=false
else
    export DOCKER_RUN_MIGRATION=\${DOCKER_RUN_MIGRATION}
    export DOCKER_RUN_SEEDER=\${DOCKER_RUN_SEEDER}
    export DOCKER_RUN_STORAGE_LINK=\${DOCKER_RUN_STORAGE_LINK}
fi

echo -e "\${CYAN}Building and deploying...\${NC}"
docker compose build --no-cache
docker compose down
docker compose up -d

echo ""
echo -e "\${GREEN}✓ Deployment Done!\${NC}"
EOF
chmod +x deploy.sh
echo -e "  ${GREEN}✓${NC} Created ${BOLD}deploy.sh${NC}"

cat << EOF > terminal.sh
#!/bin/bash
docker exec -it ${PROJECT_SLUG}-app bash
EOF
chmod +x terminal.sh
echo -e "  ${GREEN}✓${NC} Created ${BOLD}terminal.sh${NC}"

cat << EOF > db-access.sh
#!/bin/bash
docker exec -it ${PROJECT_SLUG}-mysql mysql -u${PROJECT_SLUG}_user -p${DB_PASSWORD} ${DB_NAME}
EOF
chmod +x db-access.sh
echo -e "  ${GREEN}✓${NC} Created ${BOLD}db-access.sh${NC}"

if [[ "$INSTALL_REDIS" == "y" ]]; then
cat << EOF > redis-cli.sh
#!/bin/bash
docker exec -it ${PROJECT_SLUG}-redis redis-cli
EOF
chmod +x redis-cli.sh
echo -e "  ${GREEN}✓${NC} Created ${BOLD}redis-cli.sh${NC}"
fi

cat << EOF > .dockerignore
vendor
node_modules
.idea
storage/logs/*
EOF
echo -e "  ${GREEN}✓${NC} Created ${BOLD}.dockerignore${NC}"

cat << EOF > docker/mysql/my.cnf
[mysqld]
default-authentication-plugin=mysql_native_password
max_allowed_packet=256M
EOF
echo -e "  ${GREEN}✓${NC} Created ${BOLD}docker/mysql/my.cnf${NC}"

SETUP_KEY="base64:$(openssl rand -base64 32)"

cat << EOF > .env.docker
APP_NAME="${RAW_NAME}"
APP_ENV=production
APP_KEY=${SETUP_KEY}
APP_DEBUG=false
APP_URL=${APP_URL_INPUT}
LOG_CHANNEL=stack
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=${DB_NAME}
DB_USERNAME=${PROJECT_SLUG}_user
DB_PASSWORD=${DB_PASSWORD}
DOCKER_RUN_MIGRATION=${ENV_MIGRATE}
DOCKER_RUN_SEEDER=${ENV_SEEDER}
DOCKER_RUN_STORAGE_LINK=${ENV_STORAGE}
BROADCAST_DRIVER=log
CACHE_DRIVER=${CACHE_DRIVER}
QUEUE_CONNECTION=${QUEUE_CONNECTION}
SESSION_DRIVER=${SESSION_DRIVER}
EOF

if [[ "$INSTALL_REDIS" == "y" ]]; then
cat << EOF >> .env.docker
REDIS_HOST=${REDIS_HOST}
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_PORT=6379
REDIS_CLIENT=phpredis
EOF
fi

cat << EOF >> .env.docker
FILESYSTEM_DISK=local
EOF

cp .env.docker .env
echo -e "  ${GREEN}✓${NC} Created ${BOLD}.env${NC} ${DIM}(with valid APP_KEY$([[ "$INSTALL_REDIS" == "y" ]] && echo " + Redis config"))${NC}\n"

echo -e "${PURPLE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}  ${BOLD}CREATING DOCUMENTATION${NC}               ${PURPLE}║${NC}"
echo -e "${PURPLE}╚═══════════════════════════════════════════╝${NC}\n"

cat << EOF > deploy-guidebook.md
# ${RAW_NAME}

Docker-based Laravel application with automated deployment and configuration.

## Project Information

- **Project Name:** ${RAW_NAME}
- **Project Slug:** ${PROJECT_SLUG}
- **PHP Version:** ${PHP_VERSION}
- **Laravel Framework:** Latest
- **Server:** Laravel Octane with Swoole

---

## Quick Start

### First Time Setup

1. Run the setup script:
   \`\`\`bash
   ./setup-docker.sh
   \`\`\`

2. Deploy the application:
   \`\`\`bash
   ./deploy.sh
   \`\`\`

3. Access your application:
   - App: [${APP_URL_INPUT}](${APP_URL_INPUT})
   - MySQL: \`localhost:${DB_PORT_HOST}\`
$(if [[ "$INSTALL_REDIS" == "y" ]]; then echo "   - Redis: \`localhost:${REDIS_PORT}\`"; fi)
$(if [[ "$INSTALL_PMA" == "y" ]]; then echo "   - phpMyAdmin: [http://localhost:${PMA_PORT}](http://localhost:${PMA_PORT})"; fi)

---

## Configuration

### Ports

| Service | Host Port | Container Port |
|---------|-----------|----------------|
| Application | ${APP_PORT} | ${APP_PORT} |
| MySQL | ${DB_PORT_HOST} | 3306 |
$(if [[ "$INSTALL_REDIS" == "y" ]]; then echo "| Redis | ${REDIS_PORT} | 6379 |"; fi)
$(if [[ "$INSTALL_PMA" == "y" ]]; then echo "| phpMyAdmin | ${PMA_PORT} | 80 |"; fi)

### Database Credentials

- **Database Name:** \`${DB_NAME}\`
- **Username:** \`${PROJECT_SLUG}_user\`
- **Password:** \`${DB_PASSWORD}\`
- **Root Password:** \`${DB_ROOT_PASSWORD}\`

### Default Startup Configuration

- **Run Migration:** \`${ENV_MIGRATE}\`
- **Run Seeder:** \`${ENV_SEEDER}\`
- **Run Storage Link:** \`${ENV_STORAGE}\`

$(if [[ "$INSTALL_REDIS" == "y" ]]; then cat << 'REDIS_SECTION'
### Cache Configuration

- **Cache Driver:** \`redis\`
- **Session Driver:** \`redis\`
- **Queue Connection:** \`redis\`
- **Redis Host:** \`redis\`
- **Redis Port:** \`6379\`

REDIS_SECTION
fi)

---

## Available Commands

### Deployment

\`\`\`bash
./deploy.sh
\`\`\`

### Container Access

\`\`\`bash
./terminal.sh
./db-access.sh
$(if [[ "$INSTALL_REDIS" == "y" ]]; then echo "./redis-cli.sh"; fi)
\`\`\`

### Docker Compose Commands

\`\`\`bash
docker compose up -d
docker compose down
docker compose logs -f
docker compose logs -f app
docker compose logs -f mysql
$(if [[ "$INSTALL_REDIS" == "y" ]]; then echo "docker compose logs -f redis"; fi)
docker compose restart
docker compose build --no-cache
docker compose ps
\`\`\`

### Laravel Artisan Commands

\`\`\`bash
docker exec -it ${PROJECT_SLUG}-app php artisan [command]

docker exec -it ${PROJECT_SLUG}-app php artisan migrate
docker exec -it ${PROJECT_SLUG}-app php artisan db:seed
docker exec -it ${PROJECT_SLUG}-app php artisan tinker
docker exec -it ${PROJECT_SLUG}-app php artisan queue:work
docker exec -it ${PROJECT_SLUG}-app php artisan cache:clear
docker exec -it ${PROJECT_SLUG}-app php artisan config:clear
docker exec -it ${PROJECT_SLUG}-app php artisan route:list
\`\`\`

---

## Troubleshooting

### Application won't start

\`\`\`bash
lsof -i :${APP_PORT}
lsof -i :${DB_PORT_HOST}
$(if [[ "$INSTALL_REDIS" == "y" ]]; then echo "lsof -i :${REDIS_PORT}"; fi)
$(if [[ "$INSTALL_PMA" == "y" ]]; then echo "lsof -i :${PMA_PORT}"; fi)
docker compose logs -f app
docker compose down
docker compose up -d
\`\`\`

### Database connection issues

\`\`\`bash
docker compose ps mysql
docker compose logs mysql
./db-access.sh
\`\`\`

$(if [[ "$INSTALL_REDIS" == "y" ]]; then cat << 'REDIS_TROUBLESHOOT'
### Redis connection issues

\`\`\`bash
docker compose ps redis
./redis-cli.sh
docker compose logs redis
docker exec -it ${PROJECT_SLUG}-redis redis-cli FLUSHALL
\`\`\`

REDIS_TROUBLESHOOT
fi)

### Permission issues

\`\`\`bash
docker exec -it ${PROJECT_SLUG}-app chmod -R 777 storage
docker exec -it ${PROJECT_SLUG}-app chmod -R 777 bootstrap/cache
\`\`\`

### Container keeps restarting

\`\`\`bash
docker compose ps
docker inspect ${PROJECT_SLUG}-app
docker compose logs -f app
\`\`\`

### APP_KEY is missing

\`\`\`bash
docker exec -it ${PROJECT_SLUG}-app php artisan key:generate
\`\`\`

### Clear all caches

\`\`\`bash
docker exec -it ${PROJECT_SLUG}-app php artisan config:clear
docker exec -it ${PROJECT_SLUG}-app php artisan cache:clear
docker exec -it ${PROJECT_SLUG}-app php artisan route:clear
docker exec -it ${PROJECT_SLUG}-app php artisan view:clear
$(if [[ "$INSTALL_REDIS" == "y" ]]; then echo "docker exec -it ${PROJECT_SLUG}-redis redis-cli FLUSHALL"; fi)
\`\`\`

---

## Project Structure

\`\`\`
.
├── docker/
│   ├── mysql/
│   │   └── my.cnf
│   └── ssh/
├── storage/
│   ├── app/
│   └── logs/
├── .env
├── .env.docker
├── docker-compose.yml
├── Dockerfile
├── docker-entrypoint.sh
├── deploy.sh
├── terminal.sh
├── db-access.sh
$(if [[ "$INSTALL_REDIS" == "y" ]]; then echo "├── redis-cli.sh"; fi)
└── deploy-guidebook.md
\`\`\`

---

## Updating Configuration

### Change Startup Behavior

Edit \`.env\` file:

\`\`\`env
DOCKER_RUN_MIGRATION=true
DOCKER_RUN_SEEDER=false
DOCKER_RUN_STORAGE_LINK=true
\`\`\`

Then restart:
\`\`\`bash
docker compose restart app
\`\`\`

---

## Monitoring

### Check Resource Usage

\`\`\`bash
docker stats
docker stats ${PROJECT_SLUG}-app
\`\`\`

### Health Checks

\`\`\`bash
docker compose ps
curl http://localhost:${APP_PORT}/up
\`\`\`

---

## Security Notes

1. Change default passwords in production
2. Never commit .env file to version control
3. Use strong APP_KEY
4. Restrict database access to necessary IPs only
5. Keep Docker images updated regularly
$(if [[ "$INSTALL_REDIS" == "y" ]]; then echo "6. Set Redis password for production environments"; fi)

---

## Development Tips

### Running Tests

\`\`\`bash
docker exec -it ${PROJECT_SLUG}-app php artisan test
\`\`\`

### Running Queue Workers

\`\`\`bash
docker exec -it ${PROJECT_SLUG}-app php artisan queue:work
\`\`\`

### Installing New Packages

\`\`\`bash
docker exec -it ${PROJECT_SLUG}-app composer require vendor/package
docker compose restart app
\`\`\`

### Git Operations Inside Container

\`\`\`bash
./terminal.sh
git pull origin main
composer install
npm install && npm run build
exit
docker compose restart app
\`\`\`

---

## Environment Variables Reference

### Application
- APP_NAME
- APP_ENV
- APP_KEY
- APP_DEBUG
- APP_URL

### Database
- DB_CONNECTION
- DB_HOST
- DB_PORT
- DB_DATABASE
- DB_USERNAME
- DB_PASSWORD

$(if [[ "$INSTALL_REDIS" == "y" ]]; then cat << 'REDIS_ENV'
### Redis
- REDIS_HOST
- REDIS_PORT
- REDIS_PASSWORD
- REDIS_CLIENT

REDIS_ENV
fi)

### Startup Control
- DOCKER_RUN_MIGRATION
- DOCKER_RUN_SEEDER
- DOCKER_RUN_STORAGE_LINK

---

## Support

For issues and questions:
1. Check this README first
2. Review container logs: \`docker compose logs -f\`
3. Check Laravel logs: \`storage/logs/laravel.log\`
4. Verify .env configuration
5. Ensure all ports are available

---

## Notes

- First deploy may take longer as it builds images and installs dependencies
- Subsequent deploys are faster using cached layers
- Storage and logs are persisted in mounted volumes
- Database data is persisted in Docker volumes
$(if [[ "$INSTALL_REDIS" == "y" ]]; then echo "- Redis data is persisted with append-only file"; fi)
- .env changes require container restart to take effect

---

**Generated by Laravel Docker Scaffolding Tool v11**
*Created: $(date +'%Y-%m-%d %H:%M:%S')*
*Made with <3 by Heru*
EOF

echo -e "  ${GREEN}✓${NC} Created ${BOLD}deploy-guidebook.md${NC} ${DIM}(Complete documentation)${NC}\n"

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}                  ${BOLD}${GREEN}SETUP COMPLETE!${NC}                          ${CYAN}║${NC}"
echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}Project:${NC}      ${YELLOW}${RAW_NAME}${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}Slug:${NC}         ${YELLOW}${PROJECT_SLUG}${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}PHP Version:${NC}  ${YELLOW}${PHP_VERSION}${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}App URL:${NC}      ${YELLOW}${APP_URL_INPUT}${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}MySQL Port:${NC}   ${YELLOW}localhost:${DB_PORT_HOST}${NC}"
if [[ "$INSTALL_REDIS" == "y" ]]; then
echo -e "${CYAN}║${NC}  ${BOLD}Redis Port:${NC}   ${YELLOW}localhost:${REDIS_PORT}${NC}"
fi
if [[ "$INSTALL_PMA" == "y" ]]; then
echo -e "${CYAN}║${NC}  ${BOLD}phpMyAdmin:${NC}   ${YELLOW}http://localhost:${PMA_PORT}${NC}"
fi
echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}Startup Config:${NC}"
echo -e "${CYAN}║${NC}    Migration:    ${YELLOW}${ENV_MIGRATE}${NC}"
echo -e "${CYAN}║${NC}    Seeder:       ${YELLOW}${ENV_SEEDER}${NC}"
echo -e "${CYAN}║${NC}    Storage Link: ${YELLOW}${ENV_STORAGE}${NC}"
if [[ "$INSTALL_REDIS" == "y" ]]; then
echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}Cache Config:${NC}"
echo -e "${CYAN}║${NC}    Cache Driver:   ${YELLOW}${CACHE_DRIVER}${NC}"
echo -e "${CYAN}║${NC}    Session Driver: ${YELLOW}${SESSION_DRIVER}${NC}"
echo -e "${CYAN}║${NC}    Queue Driver:   ${YELLOW}${QUEUE_CONNECTION}${NC}"
fi
echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}Next Steps:${NC}"
echo -e "${CYAN}║${NC}    ${PURPLE}▶${NC} Run: ${GREEN}${BOLD}./deploy.sh${NC} to build and start"
echo -e "${CYAN}║${NC}    ${PURPLE}▶${NC} Run: ${GREEN}${BOLD}./terminal.sh${NC} to access container"
echo -e "${CYAN}║${NC}    ${PURPLE}▶${NC} Run: ${GREEN}${BOLD}./db-access.sh${NC} to access MySQL"
if [[ "$INSTALL_REDIS" == "y" ]]; then
echo -e "${CYAN}║${NC}    ${PURPLE}▶${NC} Run: ${GREEN}${BOLD}./redis-cli.sh${NC} to access Redis CLI"
fi
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${DIM}Tools Ini Dibuat Oleh Heru Kristanto - $(date +'%Y-%m-%d %H:%M:%S')${NC}\n"
