# Trace-Driven HPC Scheduling with OAR and SimGrid

This repository provides a **trace-driven simulation environment** for evaluating classical scheduling policies in heterogeneous High-Performance Computing (HPC) grids.

The project is implemented with **SimGrid**, uses resource-management and scheduling abstractions based on **OAR**, and executes workloads derived from the historical **Grid'5000 GWA-T-2 trace**. The simulated infrastructure is a heterogeneous Grid'5000-inspired platform composed of 64 compute nodes organized into eight clusters.

The following scheduling policies are evaluated under the same workload, platform, and execution model:

* FIFO
* FIFO with Matching
* Easy Backfilling
* Conservative Backfilling

## Main Features

* Trace-driven HPC simulation
* Heterogeneous multi-cluster platform
* OAR-based scheduling abstractions
* FIFO, resource matching, and backfilling policies
* Allocation locality and load-balancing analysis
* Host energy consumption modeling
* Reproducible multi-window experiments
* Performance, QoS, energy, and scheduler-overhead metrics

## Technologies

* C++17
* SimGrid <version>
* Python
* Bash
* CMake

---

## 1. Installation and Configuration

### 1.1 Create the project root

```bash
mkdir -p ~/oar_simgrid_project
cd ~/oar_simgrid_project
export PROJECT_ROOT="$PWD"
```

### 1.2 Install SimGrid

Download `simgrid-<version>.tar.gz` from the official SimGrid website:

https://simgrid.org/

Place the archive in `$PROJECT_ROOT`, then extract it:

```bash
cd "$PROJECT_ROOT"
tar -xzf simgrid-<version>.tar.gz
```

Set the local installation directory:

```bash
export SIMGRID_INSTALL_DIR="$PROJECT_ROOT/simgrid"
mkdir -p "$SIMGRID_INSTALL_DIR"
```

Configure, build, and install SimGrid:

```bash
cd "$PROJECT_ROOT/simgrid-<version>"
mkdir -p build
cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX="$SIMGRID_INSTALL_DIR" \
    -Denable_documentation=OFF \
    -Denable_java=OFF \
    -Denable_python=OFF

make -j"$(nproc)"
make install
```

Configure the environment:

```bash
export PATH="$SIMGRID_INSTALL_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$SIMGRID_INSTALL_DIR/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$SIMGRID_INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
```

Verify the installation:

```bash
pkg-config --modversion simgrid
```

The expected version is:

```text
Installed version
```
place the projet file ``create_project_oar_simgrid_v1.sh```in the rood directory.

At this point, the root directory should contain installation files including:

```text
$PROJECT_ROOT/
├── simgrid-4.1/
└── create_project_oar_simgrid_v1.sh
```

---

## 2. Create the Project

Place `create_project_oar_simgrid_v1.sh` in `$PROJECT_ROOT`, then run:

```bash
cd "$PROJECT_ROOT"

chmod +x create_project_oar_simgrid_v1.sh
./create_project_oar_simgrid_v1.sh
```

The script creates the complete project structure, including the simulator source code, heterogeneous platform, workload preparation tools, validation scripts, and experimental execution scripts.

Enter the generated project directory:

```bash
cd "$PROJECT_ROOT/oar_simgrid_schedulers_v1"
```

---

## 3. Prepare the Workload

The experiments use workloads derived from the historical **GWA-T-2 Grid'5000 trace**.

Prepare 30 experimental windows with up to 10,000 jobs using seed 42:

```bash
./prepare_replicate_windows.sh 10000 30 42
```

The five experimental load levels correspond to:

```text
0.20  0.40  0.60  0.80  1.00
```

representing nested subsets from 20% to 100% of the jobs selected for each window.

---

## 4. Run the Experiments

Run the complete experimental protocol:

```bash
./run_raw_experiments.sh 10000 30
```

This evaluates the four scheduling policies across the 30 workload windows and five load levels.

The experiment therefore comprises:

```text
30 windows × 5 load levels × 4 schedulers = 600 runs
```

The execution script compiles the simulator, organizes the generated results automatically, and stores the results for each window in the `raw_experiments` directory.. The 

---

## 5. Output

The main output files include:

```text
results.csv
scenario_results.csv
schedule_trace.csv
energy_summary.csv
scheduler_diagnostics.csv
```

These files contain the data used to evaluate the scheduling policies in terms of performance, quality of service, allocation locality, load balancing, energy consumption, and scheduler computational cost.

---

## Associated Paper

This repository contains the experimental implementation associated with:

**Trace-Driven Simulation of OAR-Based Scheduling Policies in a Heterogeneous HPC Grid**

The paper provides the complete methodology, experimental design, scheduling-policy definitions, and analysis of the results.
