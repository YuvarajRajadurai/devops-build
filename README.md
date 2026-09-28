# devops-build

A CI/CD project that builds a React app into an Nginx Docker image, pushes it to Docker Hub, and deploys it automatically to an AWS EC2 instance using Jenkins. Pushes to the `dev` branch deploy the **dev** image, and merges into `main` deploy the **prod** image.

> **Screenshots:** all images below are loaded from the `screenshots/` folder. Put your screenshots there using the file names shown (or change the paths).

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Tech Stack](#tech-stack)
4. [Repository Structure](#repository-structure)
5. [Docker Setup](#docker-setup)
6. [AWS EC2 Setup](#aws-ec2-setup)
7. [Jenkins Setup](#jenkins-setup)
8. [CI/CD Pipeline](#cicd-pipeline)
9. [Branch and Registry Strategy](#branch-and-registry-strategy)
10. [Deployment Results](#deployment-results)
11. [Monitoring](#monitoring)
12. [Useful Commands](#useful-commands)

---

## Project Overview

| Item | Details |
|------|---------|
| Repository | https://github.com/YuvarajRajadurai/devops-build.git |
| Web server | Nginx (`nginx:stable-alpine`) |
| Registry | Docker Hub (`yuvarajjr/devops-build-dev`, `yuvarajjr/devops-build-prod`) |
| CI/CD | Jenkins (multibranch pipeline, GitHub webhook) |
| Hosting | AWS EC2 (Ubuntu, t2.micro) |
| App port | 80 |

---

## Architecture

```
Developer --push--> GitHub (dev / main)
                        |
                        | webhook
                        v
                    Jenkins (Jenkinsfile)
                        |
        +---------------+----------------+
        |                                |
   branch: dev                      branch: main
        |                                |
 build image -> push to           build image -> push to
 devops-build-dev                 devops-build-prod
        |                                |
        +---------------+----------------+
                        |
                        v
              deploy.sh on EC2 (Docker)
                        |
                        v
                  App on port 80
```

![Architecture diagram](screenshots/architecture.png)

---

## Tech Stack

- **Docker**: containerises the app with Nginx
- **Nginx**: serves the static React build
- **Jenkins**: automates build, push, and deploy
- **GitHub**: source control with `dev` and `main` branches
- **Docker Hub**: separate dev and prod repositories
- **AWS EC2**: Ubuntu server hosting Jenkins and the app
- **Monitoring**: see [Monitoring](#monitoring)

---

## Repository Structure

```
devops-build/
├── build/            # React production build
├── Dockerfile        # Nginx image for the app
├── nginx.conf        # Nginx site configuration
├── build.sh          # Builds the Docker image
├── deploy.sh         # Pulls the image and restarts the container
└── Jenkinsfile       # Declarative pipeline
```

---

## Docker Setup

The image is based on `nginx:stable-alpine`. It clears the default Nginx content, copies the React `build/` folder, applies a custom `nginx.conf`, exposes port 80, and includes a health check.

![Dockerfile](screenshots/dockerfile.png)

**Build locally**

```bash
chmod +x build.sh
./build.sh 1
```

**Pull and run the dev image manually**

```bash
docker pull yuvarajjr/devops-build-dev:latest

docker run -d \
  --name devops-build \
  --restart unless-stopped \
  -p 80:80 \
  yuvarajjr/devops-build-dev:latest
```

![Docker images and running container](screenshots/docker-setup.png)

---

## AWS EC2 Setup

1. Launch an Ubuntu `t2.micro` instance.
2. Create or select a key pair and download the `.pem` file.
3. Configure the security group:

| Type | Port | Source | Purpose |
|------|------|--------|---------|
| SSH | 22 | My IP (`x.x.x.x/32`) | Admin access |
| HTTP | 80 | 0.0.0.0/0 | Application |
| HTTPS | 443 | 0.0.0.0/0 | Application (optional) |
| Custom TCP | 8080 | Restrict to your IP | Jenkins |

4. Connect to the instance:

```bash
ssh -i <your-key>.pem ubuntu@<EC2_PUBLIC_IP>
```

5. Install Docker and Jenkins on the instance, and add the `jenkins` user to the `docker` group.

![EC2 instance](screenshots/ec2-instance.png)

![EC2 security group](screenshots/security-group.png)

---

## Jenkins Setup

1. Install Jenkins and unlock it with the initial admin password.
2. Install the suggested plugins, plus the Docker Pipeline and GitHub plugins.
3. Add credentials:
   - `Github-cred`: GitHub username and personal access token
   - Docker Hub credentials: Docker Hub username and access token (exposed to the pipeline as `DOCKER_PASS`)
4. Create a **Multibranch Pipeline** job pointing to the GitHub repository.
5. Add a GitHub webhook: `http://<EC2_PUBLIC_IP>:8080/github-webhook/`

![Jenkins dashboard](screenshots/jenkins-dashboard.png)

![Jenkins credentials](screenshots/jenkins-credentials.png)

![GitHub webhook](screenshots/github-webhook.png)

---

## CI/CD Pipeline

The `Jenkinsfile` runs these stages:

| Stage | Runs on | Description |
|-------|---------|-------------|
| Checkout SCM | all branches | Pulls the code from GitHub |
| Build Docker Image | all branches | Runs `build.sh <build-number>` |
| Docker Login | all branches | Logs in to Docker Hub with stored credentials |
| Push DEV Image | `dev` only | Tags and pushes `yuvarajjr/devops-build-dev:<n>` and `:latest` |
| Push PROD Image | `main` only | Tags and pushes `yuvarajjr/devops-build-prod:<n>` and `:latest` |
| Deploy DEV | `dev` only | Runs `deploy.sh` with the dev image |
| Deploy PROD | `main` only | Runs `deploy.sh` with the prod image |
| Post Actions | all branches | Logs out of Docker Hub |

`deploy.sh` pulls the image, stops and removes the old container, starts the new one on port 80, shows the container status, and cleans up unused images.

![Jenkins pipeline stage view](screenshots/pipeline-stages.png)

---

## Branch and Registry Strategy

| Branch | Docker Hub repository | Deployed by |
|--------|-----------------------|-------------|
| `dev` | `yuvarajjr/devops-build-dev` | Push to `dev` |
| `main` | `yuvarajjr/devops-build-prod` | Merge `dev` into `main` |

**Workflow**

```bash
git checkout dev
git add .
git commit -m "Build 7"
git push origin dev          # triggers the dev pipeline

git checkout main
git merge dev
git push origin main         # triggers the prod pipeline
```

![Git merge](screenshots/git-merge.png)

![Docker Hub dev and prod repositories](screenshots/dockerhub-repos.png)

---

## Deployment Results

Both pipelines completed successfully.

### Dev pipeline (push to `dev`)

- Commit message: `Build 7`
- Image built as `devops-build:7`
- Pushed to `yuvarajjr/devops-build-dev:7` and `:latest`
- Deployed to the EC2 container `devops-build-app` on port 80
- Result: **SUCCESS**

![Dev build console output](screenshots/jenkins-dev-build.png)

### Prod pipeline (merge into `main`)

- Commit message: `Merge branch 'dev'`
- Image built as `devops-build:2`
- Pushed to `yuvarajjr/devops-build-prod:2` and `:latest`
- Deployed to the EC2 container `devops-build-app` on port 80
- Result: **SUCCESS**

![Main build console output](screenshots/jenkins-main-build.png)

### Application status

![Running application](screenshots/app-status.png)

---

## Monitoring

Describe the monitoring tools you set up here (for example, the dashboards, metrics, and alerts you configured), and add the screenshots below.

![Monitoring dashboard](screenshots/monitoring-dashboard.png)

![Monitoring alerts or targets](screenshots/monitoring-alerts.png)

---

## Useful Commands

```bash
# Check running containers
docker ps

# View container logs
docker logs devops-build-app

# Check container health
docker inspect --format='{{.State.Health.Status}}' devops-build-app

# Restart the container
docker restart devops-build-app

# List local images
docker images
```

---

## Author

**Yuvaraj**: GUVI x HCL DevOps project
