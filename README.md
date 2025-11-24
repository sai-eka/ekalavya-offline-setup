# EkaLavya Offline Setup

This package contains the setup for deploying the EkaLavya platform in an offline environment.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine installed.

## Installation & Setup

### 1. Extract the Package

Unzip the provided folder to your desired location.

### 2. License Setup

Ensure the `license.key` file provided by the administrator is present in the root directory of this folder.

### 3. Environment Configuration

Ensure your environment files are set up in the `env/` directory.

### 4. Docker Registry Credentials

Create a `.env` file in the root directory with your GitHub credentials to allow pulling images:

```env
GITHUB_USERNAME=your_username
GITHUB_PAT=your_personal_access_token
```

## Running the Application

### 1. Prepare the Environment

**Windows:**
Run `setup.bat`.

**Linux / macOS:**
Run the setup script:

```bash
sh docker-login-ghcr.sh
```

### 2. Start the Stack

Start the entire stack using Docker Compose:

```bash
docker compose up -d
```

This will start:

- **Core Services**: Web, Users, Content, ERP, Files.
- **Tools**: Scratch Editor, App Inventor.
- **Infrastructure**: MySQL.
- **Security**: License Watchdog.

## The License Watchdog

The `license-watchdog` container runs alongside your application to ensure compliance.

- **Function**: It checks the `license.key` every minute.
- **Enforcement**:
  - If the license is **Expired**: It stops all containers.
  - If **Clock Tampering** is detected (system time moved backwards): It stops all containers.
