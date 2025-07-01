# Kuzco Idle Scripts

This repository contains a collection of shell scripts designed to manage and automate the operation of worker nodes for services like `inference.net` and `kuzco`. These scripts intelligently start and stop worker processes based on system resource utilization (CPU, GPU) and battery levels, ensuring that high-priority tasks are not interrupted and that the system's resources are used efficiently.

## Scripts

### `inf.sh`

A sophisticated management script for `inference.net` nodes.

**Features:**

*   **Smart Evasion:** Stops the inference process only when both CPU and GPU loads are high, preventing unnecessary restarts.
*   **Battery Protection:** Pauses the node when the battery is low and resumes when it's sufficiently charged.
*   **Idle Restart:** Automatically restarts nodes that have been idle for too long.
*   **Process Cleanup:** Ensures clean shutdowns to prevent zombie processes.
*   **Environment Compatibility:** Uses `screen` for robust background process management.

**Usage:**

1.  Make the script executable:
    ```bash
    chmod +x inf.sh
    ```
2.  Run the script with the desired worker name:
    ```bash
    ./inf.sh <WorkerName>
    ```

### `kuzco_idle_start_Final.sh`

An advanced script for managing `kuzco` worker nodes.

**Features:**

*   **CPU Thresholding:** Starts or stops the `kuzco` worker based on CPU usage.
*   **GPU Power Monitoring:** Detects active inference tasks by monitoring GPU power consumption.
*   **Idle Restart:** Restarts the `kuzco` worker if no inference is detected for over an hour.
*   **Log Management:** Includes hourly reporting and automatic cleanup of old log files.

**Usage:**

The script is pre-configured with a worker name. To use it, simply execute the script:

```bash
./kuzco_idle_start_Final.sh
```

### `kuzco_idle_start_V0.sh`

A simpler, initial version for managing `kuzco` worker nodes.

**Features:**

*   **CPU Thresholding:** Starts or stops the `kuzco` worker based on CPU usage.
*   **Basic Logging:** Logs actions and CPU usage to a monitor file.

**Usage:**

1.  Edit the script to set your `WORKER_ID` and `CODE_ID`.
2.  Run the script:
    ```bash
    ./kuzco_idle_start_V0.sh
    ```

## Configuration

Each script contains configuration variables at the top of the file. These can be modified to suit your specific needs, such as changing CPU thresholds, check intervals, or worker names. The `inf.sh` and `kuzco_idle_start_Final.sh` scripts include a worker database directly within the script, mapping worker names to their respective IDs.

## Dependencies

*   `bash`
*   `bc` (for floating-point arithmetic)
*   `pmset` (on macOS, for battery monitoring)
*   `powermetrics` (on macOS, for GPU power monitoring)
*   `screen` (for `inf.sh`)
*   `kuzco` and/or `inference` command-line tools installed and in the system's `PATH`.
