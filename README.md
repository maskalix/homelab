# homelab

A personal library of self-hosted infrastructure configurations, Docker Compose files, system scripts, and tooling resources maintained for a home server environment.

---

## Repository Structure

```
homelab/
├── projects/               # Projects configs + Docker Compose files
├── docker/
│   └── compose/            # TO BE REMOVED: Legacy Compose files
├── system/                 # System-level scripts and configurations
├── pihole_block            # Custom Pi-hole blocklist
└── portainer_apps.json     # Portainer app template definitions
```

---

## Structure
### Docker Hub

Custom Docker images published alongside this repository are available on Docker Hub.

[hub.docker.com/u/maskalicz](https://hub.docker.com/u/maskalicz)

### Pi-hole Blocklist

A curated blocklist for use with [Pi-hole](https://pi-hole.net). Add the raw URL directly to your Pi-hole blocklist sources.

```
https://raw.githubusercontent.com/maskalix/homelab/main/pihole_block
```

### Portainer App Templates

A JSON template file for Portainer's app template feature. Import the raw URL into Portainer under **Settings > App Templates**.

```
https://raw.githubusercontent.com/maskalix/homelab/main/portainer_apps.json
```

---

## Usage

Clone the repository and navigate to the stack you want to deploy:

```bash
git clone https://github.com/maskalix/homelab.git
cd homelab/projects/<service-name>
docker compose up -d
```

Each stack may include its own `.env` file or inline environment variable placeholders. Review the compose file before starting and adjust paths, ports, and credentials to match your setup.

---

## License

This project is licensed under the [Apache License 2.0](LICENSE).
