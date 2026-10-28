*This project has been created as part of the 42 curriculum by samalves.*

# Inception — working study guide

> Temporary handoff for continuing this project with an AI tutor on another computer. Replace this with the final submission README when the project is complete.

## Project goal

Build a Docker Compose web stack inside a Debian/Linux VM:

```text
Browser → NGINX:443 → WordPress/PHP-FPM:9000 → MariaDB:3306
```

NGINX is the only public entrypoint. WordPress/PHP-FPM and MariaDB communicate through a private Docker network. Docker named volumes must persist WordPress files and database data under `/home/samalves/data/`.

## How the AI should help

I am a student learning deliberately. Be a tutor and reviewer, not an implementation agent.

- Do not create, edit, delete, or run project code/configuration unless I explicitly request that exact action.
- Do not build the project for me. Explain concepts, give small tasks, then review my work when asked.
- When I ask “what is next?”, always provide: what to do; why now; the concept; the subject connection; an evaluation landmark; and how to verify it.
- Explain terminology in plain language. Use diagrams/examples when useful.
- During a review, inspect read-only unless I explicitly request an edit.
- Never display, request, commit, or store real passwords; mask sensitive values during reviews.

## Current progress

- Required directory skeleton exists: `secrets/`, `srcs/`, and `srcs/requirements/{mariadb,nginx,wordpress}/`.
- Root `Makefile` and `srcs/docker-compose.yml` exist but are intentionally not implemented yet.
- Root `.gitignore` ignores `srcs/.env` and `secrets/`.
- `srcs/.env` is local and ignored; `srcs/.env.example` is the safe committed template.

Current non-secret configuration keys:

```env
DOMAIN_NAME=samalves.42.fr
HOST_LOGIN=samalves
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_TITLE=...
WP_ADMIN_USER=siteowner
WP_ADMIN_EMAIL=...
WP_USER=editor
WP_USER_EMAIL=...
```

`WP_ADMIN_USER` must not contain `admin` or `administrator`. Passwords do not belong in `.env`.

## Next learning step

Design the local password files and learn Docker secrets and least privilege before writing Compose:

- MariaDB root password
- WordPress database-user password
- WordPress administrator password
- WordPress normal-user password

Real files stay ignored in `secrets/`; safe example templates can be committed.

## Evaluation landmarks

1. **Repository hygiene** — required `srcs/` and root `Makefile`; no credentials in Git.
2. **Configuration and secrets** — distinguish non-secret environment variables from passwords; explain least privilege.
3. **Compose architecture** — three dedicated services, explicit network, two named volumes under `/home/samalves/data/`, only NGINX publishes `443`.
4. **MariaDB** — own Dockerfile, initialization, database login, and non-empty database.
5. **WordPress/PHP-FPM** — own Dockerfile, no NGINX, installed site, and two required users.
6. **NGINX/TLS** — own Dockerfile, HTTPS only on `443`, TLS 1.2/1.3, and FastCGI flow.
7. **Persistence** — edit content, reboot VM, restart Compose, prove data remains.
8. **Defense rehearsal** — explain Docker/Compose, Docker vs VM, images, networks, volumes vs bind mounts, secrets vs environment variables; practice changing a service port and rebuilding.
9. **Documentation** — complete final `README.md`, `USER_DOC.md`, and `DEV_DOC.md`.
10. **Bonus only after mandatory is perfect** — definite interest: static website; possible Redis and FTP.

## Critical constraints

- Custom Dockerfile per mandatory service; Docker Compose; penultimate stable Debian or Alpine; never use `latest`.
- No ready-made NGINX/WordPress/MariaDB service images.
- No `network: host`, `links:`, or `--link`.
- No fake keep-alive/background hacks: `tail -f`, `sleep infinity`, bare `bash`/`sh`, or infinite loops.
- No passwords in Dockerfiles or Git.
- Required local domain: `samalves.42.fr`. Later map it to the VM/local IP in `/etc/hosts`.
- Evaluators may wipe Docker containers, images, volumes, and networks, then run the Makefile from a clean state.

## Concepts already discussed

- Containers isolate processes/filesystems/networks but share the host Linux kernel; a container is not a VM.
- Debian images provide Debian user-space tools/libraries, not their own kernel.
- NGINX is a reverse proxy/gateway: it handles HTTPS and forwards PHP requests to WordPress/PHP-FPM. WordPress manages authentication and queries MariaDB.
- Only NGINX is public. MariaDB and PHP-FPM use internal ports and should not have host port mappings.

## AI-use note for the final README

AI has been used as a learning guide: explaining concepts, reviewing work, providing evaluation landmarks, and helping plan/testing. All implementation must be understood, written, and verified by the student.


ssh to VM:
ssh -p 2222 samalves@127.0.0.1

command to pass files from host to VM:
tar -C /sgoinfre/goinfre/Perso/samalves/Cloud/inception -cf - . \
  | ssh -p 2222 samalves@127.0.0.1 \
    'mkdir -p "$HOME/inception" && tar -xf - -C "$HOME/inception"'