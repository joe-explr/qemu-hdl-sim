# QEMU-HDL Co-Simulation (QEMU 10.1.3)

This repository implements a QEMU-to-HDL co-simulation stack for PCIe device development and validation.  
It couples a custom QEMU PCIe endpoint model to HDL simulation through ZeroMQ/CZMQ and SystemVerilog DPI, so guest software in a VM can interact with a simulated hardware device.

Primary focus in this fork: migration and stabilization for `QEMU 10.1.3`.

## Quick Summary (Recruiters)

- Built a full-stack co-simulation integration across virtualization, systems C, hardware simulation, and scripting.
- Ported and maintained a custom QEMU PCIe device model for modern `QEMU 10.1.3`.
- Added stronger runtime diagnostics and fail-fast behavior for distributed VM/HDL debug.
- Integrated memory-mapped I/O, MSI-X interrupts, NIC packet forwarding, and serial channel plumbing between VM and HDL.
- Delivered reproducible scripts for building patched/unpatched QEMU and launching comparative VM workflows.

## Quick Summary (Researchers)

- Reproduces the QEMU-HDL co-simulation concept from the referenced FPGA co-sim paper, adapted to a newer QEMU codebase.
- Implements bidirectional transaction transport:
  - QEMU MMIO accesses forwarded to HDL over ZMQ.
  - HDL-issued host memory transactions and interrupts serviced by QEMU.
- Supports configurable PCIe identity and BAR/MSI-X layout via runtime initialization exchange between HDL and QEMU.
- Provides side channels for NIC and serial traffic in addition to PCIe MMIO.
- Includes dual-VM workflow (patched accelerator VM + baseline VM) for comparative evaluation.

Reference paper:
`https://compas.cs.stonybrook.edu/~shcho/publication/FPGA_2018_CoSim.pdf`

## Architecture Overview

High-level data path:

`Guest Driver/App` -> `QEMU accelerator-pcie device` -> `ZMQ sockets` -> `DPI C bridge` -> `HDL (AXI/PCIe side)`

Reverse path:

`HDL` -> `DPI C bridge` -> `ZMQ sockets` -> `QEMU accelerator-pcie` -> `host memory / MSI-X / NIC / serial`

Core control flow:

1. HDL and QEMU establish socket endpoints using `NPU_COSIM_PORT`.
2. QEMU device class init sends an `INIT` request and receives `ACCConf` (BAR validity/size/offset, PCI IDs, MSI-X config).
3. QEMU realizes BAR regions and registers `accelerator-pcie`.
4. MMIO reads/writes in guest become request/response ZMQ transactions with HDL.
5. HDL can issue host memory read/write requests and MSI-X interrupts back into QEMU.
6. Optional NIC and serial channels operate through dedicated socket pairs.

## Repository Structure

- `accelerator_pcie.c`
  - Custom QEMU PCIe device model (`-device accelerator-pcie`)
  - MMIO handlers, MSI-X setup, QEMU fd handlers, NIC + serial integration
  - Runtime logging controls (`ACCELERATOR_LOG_LEVEL`, `ACCELERATOR_ZMQ_WARN_MS`)
- `acc.h`
  - Shared protocol structs/enums (`ACCData`, `ACCConf`, BAR/MSI-X metadata)
- `bridge-ip/QEMUPCIeBridge/hdl/dpi-pcie.c`
  - DPI bridge that translates HDL-side transactions to/from QEMU socket protocol
- `qemu-10.1.3-cosim.patch`
  - Patch applied onto upstream QEMU 10.1.3 source
- `scripts/`
  - Build, environment, bridge setup, simulation launch, VM launch automation
- `platform/`
  - FPGA/simulation platform files (Vivado/TCL/SystemVerilog assets)
- `docs/`
  - Additional setup notes and historical documentation

## What Is Implemented in This Fork

- QEMU integration updated for `QEMU 10.1.3`.
- Custom PCIe emulation device with:
  - up to 6 BAR-backed MMIO regions,
  - dynamic BAR config received from HDL at startup,
  - MSI-X vector setup and notification,
  - host memory read/write servicing from HDL requests.
- ZeroMQ transport channels for:
  - QEMU MMIO request/response,
  - HDL host-memory request/response,
  - NIC packet transfer,
  - serial forwarding.
- Reliability and debugging improvements:
  - stricter error handling in critical socket/frame paths,
  - trace/debug log levels and timing-aware receive warnings,
  - clearer initialization and failure behavior.
- Legacy lockstep mode removed from active workflow.

## Build and Run Workflow (Current)

Detailed operational steps are in `scripts/instructions.txt`.

Typical sequence:

1. Build patched and baseline QEMU:
   - `cd scripts && ./build-qemus.sh`
2. Create network bridge/tap:
   - `./make-bridge.sh`
3. Build bridge IP/platform artifacts as required:
   - `./build_bridge-ip.sh`
   - `./build_platform.sh`
4. Set environment:
   - `source ./saved_session.sh` (and/or `source ./sourceme.sh`)
5. Start HDL simulation:
   - via Vivado batch scripts (`vcu128_base.tcl`, `scripts/run_sim.tcl`)
6. Launch VMs:
   - `./run-cosim.sh`

## Key Runtime Inputs

- `NPU_COSIM_PORT`
  - base port for all socket channels
- `BRIDGE`
  - Linux bridge name used by QEMU tap networking
- `ACCELERATOR_LOG_LEVEL`
  - log level for accelerator device (`off|error|warn|info|debug|trace`)
- `ACCELERATOR_ZMQ_WARN_MS`
  - warning interval for long receive waits

Most of these are set by scripts under `scripts/`.

## Dependencies (Common)

- QEMU build toolchain (C compiler, make, etc.)
- `libzmq` and `libczmq`
- Vivado/VCS or equivalent HDL simulation stack used by the environment
- Python package(s) used by helper tooling (for example `tomli`)

Exact environment assumptions depend on your lab/server setup and license availability.

## Notes and Limitations

- Some paths and helper binaries in scripts are environment-specific.
- Disk images used by VM launch scripts are external to this repository.
- Networking/bridge operations may require `sudo`.
- This repository targets co-simulation experimentation and validation workflows, not production device emulation packaging.
