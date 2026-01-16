
# Laravel Docker Scaffolding Tool

Professional Docker setup generator for Laravel applications with smart configuration and zero-hassle deployment.

[![Version](https://img.shields.io/badge/version-1.0.1-blue.svg)](https://github.com/NicoIzumi30/deploy-laravel-docker)
[![PHP](https://img.shields.io/badge/PHP-8.1%20|%208.2%20|%208.3%20|%208.4-777BB4.svg)](https://php.net)
[![Laravel](https://img.shields.io/badge/Laravel-11.x%20|%2012.x-FF2D20.svg)](https://laravel.com)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## What is This?

A powerful bash script that generates a complete, production-ready Docker environment for your Laravel applications in seconds. No more manual Docker configuration, just answer a few questions and you're ready to deploy.

### Key Features

- One-line installation via curl or wget
- Interactive CLI configuration with smart defaults
- Support for PHP 8.1, 8.2, 8.3, and 8.4
- Laravel Octane with Swoole built-in
- Optional Redis and phpMyAdmin
- Auto-generated documentation
- Smart deployment script
- Docker DNS auto-configuration

---

## Quick Start

### Installation

Choose your preferred method:

```bash
# Using curl
curl -o setup.sh https://raw.githubusercontent.com/NicoIzumi30/deploy-laravel-docker/main/setup.sh
chmod +x setup.sh
./setup.sh

# Using wget
wget https://raw.githubusercontent.com/NicoIzumi30/deploy-laravel-docker/main/setup.sh
chmod +x setup.sh
./setup.sh

# Direct execution
bash <(curl -s https://raw.githubusercontent.com/NicoIzumi30/deploy-laravel-docker/main/setup.sh)
```

### Deploy

```bash
./deploy.sh
```

---

## What Gets Generated

```
your-project/
├── Dockerfile
├── docker-compose.yml
├── docker-entrypoint.sh
├── .env
├── .dockerignore
├── README.md
├── deploy.sh
├── terminal.sh
├── db-access.sh
├── redis-cli.sh (if Redis enabled)
└── docker/
    ├── mysql/my.cnf
    └── ssh/
```

---

## Configuration Options

### Project Setup
- Project name and slug
- PHP version (8.1 to 8.4)
- Custom ports for all services
- Database credentials with auto-generated passwords

### Startup Behavior
- Auto-run migrations on container start
- Auto-run seeders
- Auto-create storage symlinks

### Optional Services
- Redis for caching and sessions
- phpMyAdmin for database management
- SSH key injection for git operations

---

## Service Stack

| Service | Image | Default Port |
|---------|-------|--------------|
| App | php:8.x-cli-alpine | 5059 |
| MySQL | mysql:8.0 | 3343 |
| Redis | redis:7-alpine | 6379 |
| phpMyAdmin | phpmyadmin/phpmyadmin | 8080 |

### PHP Extensions Included
```
gd, pdo_mysql, mbstring, exif, pcntl, bcmath, zip, redis, swoole
```

---

## Usage Examples

### Basic Setup
```bash
./setup.sh
# Accept all defaults
./deploy.sh
```

### Custom Configuration
```bash
./setup.sh
# Project: My Awesome App
# PHP: 8.4
# App Port: 8080
# Redis: Yes
# phpMyAdmin: Yes
```

### Quick Access
```bash
./terminal.sh           # Access app container
./db-access.sh          # MySQL CLI
./redis-cli.sh          # Redis CLI

docker compose logs -f  # View logs
docker compose ps       # Check status
```

---

## System Requirements

### Minimum
- OS: Linux, macOS, or WSL2
- Docker: 20.10+
- Docker Compose: 2.0+
- Bash: 4.0+

### Recommended
- RAM: 4GB+ available
- Disk: 10GB+ free space
- CPU: 2+ cores

---

## Troubleshooting

### Docker Can't Pull Images
The script will automatically configure Docker DNS. If issues persist:
```bash
sudo nano /etc/docker/daemon.json
# Add: {"dns": ["8.8.8.8", "8.8.4.4"]}
sudo systemctl restart docker
```

### Port Already in Use
```bash
lsof -i :5059
# Kill process or choose different port during setup
```

### Permission Errors
```bash
docker exec -it your-app chmod -R 777 storage
docker exec -it your-app chmod -R 777 bootstrap/cache
```

### APP_KEY Missing
```bash
# Automatically fixed by deploy.sh or:
docker exec -it your-app php artisan key:generate
```

---

## Advanced Configuration

### Override Deployment Behavior
```bash
./deploy.sh
# Choose "n" when prompted to override settings temporarily
```

### Environment Variables
Edit `.env` to customize:
```env
DOCKER_RUN_MIGRATION=true
DOCKER_RUN_SEEDER=false
DOCKER_RUN_STORAGE_LINK=true
CACHE_DRIVER=redis
SESSION_DRIVER=redis
```

---

## Security Best Practices

**Implemented by Default:**
- Strong random passwords
- Minimal Alpine images
- Isolated Docker networks
- Health checks for all services

**Production Checklist:**
- Change all default passwords
- Set Redis password
- Use HTTPS with reverse proxy
- Restrict database access by IP
- Regular security updates

---

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Support

- **Documentation**: Generated README.md has detailed information
- **Issues**: Report bugs at [GitHub Issues](https://github.com/NicoIzumi30/deploy-laravel-docker/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/NicoIzumi30/deploy-laravel-docker/discussions)

---

## Quick Reference

```bash
# Setup
curl -o setup.sh https://raw.githubusercontent.com/NicoIzumi30/deploy-laravel-docker/main/setup.sh
chmod +x setup.sh && ./setup.sh

# Deploy
./deploy.sh

# Access
./terminal.sh
./db-access.sh
./redis-cli.sh

# Management
docker compose up -d
docker compose down
docker compose logs -f
docker compose ps
```

---

## Author

**NicoIzumi30**
- GitHub: [@NicoIzumi30](https://github.com/NicoIzumi30)

