# Getting Started

This guide provides a step-by-step process for setting up the UC-1 Pro stack on a new system.

## Prerequisites

Before you begin, ensure your system meets the following requirements:

- **Operating System**: Ubuntu 24.04 LTS
- **GPU**: NVIDIA RTX 5090 with 32GB VRAM
- **RAM**: 96GB recommended
- **Storage**: At least 100GB of free space for models and data.

## Step 1: Install Dependencies

The first step is to install the necessary software dependencies. This includes Docker, Docker Compose, and the NVIDIA Container Toolkit. We have created a script to automate this process.

```bash
# Make the script executable
chmod +x scripts/install-dependencies.sh

# Run the script with sudo
sudo ./scripts/install-dependencies.sh
```

After the script completes, you **must log out and log back in** for the user group changes to take effect. This allows you to run Docker commands without `sudo`.

To verify the installation, run the following command:

```bash
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

This should output the status of your NVIDIA GPU, confirming that Docker is correctly configured to use it.

## Step 2: Clone and Configure the Project

Next, clone the project repository from GitHub and navigate into the project directory.

```bash
git clone https://github.com/your-username/UC-1-Pro.git
cd UC-1-Pro
```

Now, run the initial setup script. This script will check for the required `.env` file and guide you to create it.

```bash
chmod +x setup-uc1-pro.sh
./setup-uc1-pro.sh
```

If the `.env` file does not exist, you will be prompted to create it from the template:

```bash
cp .env.template .env
```

Now, open the `.env` file in a text editor and customize the settings. At a minimum, you should change the default passwords and secret keys.

## Step 3: Start the Application Stack

Once the configuration is complete, you can start the entire application stack using the `start.sh` script.

```bash
./scripts/start.sh
```

This will pull all the necessary Docker images and start all the services in the background. The initial startup may take some time as the models are downloaded.

## Step 4: Accessing the Services

Once the stack is running, you can access the various services through your web browser:

- **Open-WebUI**: `http://localhost:8080`
- **Model Manager**: `http://localhost:8084`
- **Prometheus (Monitoring)**: `http://localhost:9090`

Congratulations! The UC-1 Pro stack is now up and running.
