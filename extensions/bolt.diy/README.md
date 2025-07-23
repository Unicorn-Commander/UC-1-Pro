# Bolt.DIY

Bolt.DIY is a development environment for building AI applications. It allows you to quickly prototype and experiment with different LLMs and AI tools.

## Setup and Usage

**IMPORTANT**: Before running `docker-compose up`, you must clone the official Bolt.DIY repository into this directory.

1.  **Clone the Bolt.DIY Repository**:

    Navigate into this `extensions/bolt.diy` directory and clone the Bolt.DIY repository:

    ```bash
    cd extensions/bolt.diy
    git clone https://github.com/stackblitz-labs/bolt.diy.git .
    ```

    *Note: The `.` at the end of the `git clone` command is important. It clones the repository directly into the current directory, not into a new subdirectory.*

2.  **Navigate to the Bolt.DIY directory**:

    ```bash
    cd extensions/bolt.diy
    ```

3.  **Start Bolt.DIY**:

    ```bash
    docker-compose up --build
    ```

    The `--build` flag is important here as Bolt.DIY is built from source within the container.

4.  **Access Bolt.DIY**:

    Once the container is running, you should be able to access Bolt.DIY in your web browser at `http://localhost:5173`.

## Integration with UC-1 Pro

This `docker-compose.yml` is configured to connect Bolt.DIY to your UC-1 Pro's `unicorn-network`. It also sets the `OPENAI_API_BASE_URL` to point to your local `vLLM` instance, allowing Bolt.DIY to use your self-hosted LLM.
