# Scripts and Tooling

The `scripts/` directory contains a set of useful scripts for managing the UC-1 Pro stack.

## `install-dependencies.sh`

This script automates the installation of all necessary dependencies on a fresh Ubuntu 24.04 LTS server.

**Usage:**

```bash
chmod +x scripts/install-dependencies.sh
sudo ./install-dependencies.sh
```

## `setup-uc1-pro.sh`

This script performs initial checks and setup tasks required before running the main stack for the first time.

**Usage:**

```bash
chmod +x setup-uc1-pro.sh
./setup-uc1-pro.sh
```

## `start.sh`

This is the main script for starting the entire application stack.

**Usage:**

```bash
./scripts/start.sh
```

## `stop.sh`

This script gracefully stops and removes all the containers, networks, and volumes associated with the stack.

**Usage:**

```bash
./scripts/stop.sh
```

## `logs.sh`

This script allows you to view the logs of a specific service.

**Usage:**

```bash
# To view logs of a specific service
./scripts/logs.sh <service_name>

# To see a list of available services
./scripts/logs.sh
```

## `health-check.sh`

This script checks the health of all the running services.

**Usage:**

```bash
./scripts/health-check.sh
```

## `monitor.sh`

This script provides a simple, real-time monitor of the container status.

**Usage:**

```bash
./scripts/monitor.sh
```

## `switch-model.sh`

This script allows you to switch the main LLM model used by the vLLM service.

**Usage:**

```bash
./scripts/switch-model.sh <model_id> [quantization]
```

## `test-inference.sh`

This script sends a test request to the vLLM service to verify that it is working correctly.

**Usage:**

```bash
./scripts/test-inference.sh
```

## `backup.sh`

This script creates a backup of the essential configuration files.

**Usage:**

```bash
./scripts/backup.sh
```
