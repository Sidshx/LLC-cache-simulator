# Last Level Cache Design and Simulation

This project focuses on designing and simulating a Last Level Cache (LLC) for processors, addressing the challenge of memory systems lagging behind high-speed processors. By implementing a caching mechanism, critical data and instructions are stored closer to the processor for faster access. This project is fully parameterizable and can be easily adapted to changes in the given specifications.

## Project File Structure

```
+---Documents
|       ECE585_F24_MSD_Group11_Project_Report.pdf
|       Group11_chcekpoint2.pptx
|       ProjectRequirements.pdf
|       cc1.din
|       rwims.din
|       
+---LLC_Code
|   |   TOP.sv
|   |   cc1.din
|   |   pkg_bus.sv
|   |   pkg_line.sv
|   |   pkg_plru.sv
|   |   rwims.din
|   |   
|   +---traces
|   |       t0.din
|   |       t1.din
|   |       t10.din
|   |       ...
|   |       
|   \---Traces_Transcript
|           T0_Transcript.txt
|           T10_Transcript.txt
|           T11_Transcript.txt
            ...
```
# Simulation and Debugging Commands

## DEBUG mode: With `DEBUG` Defined
```bash
vlog +define+DEBUG TOP.sv
```
## SILENT mode 
```bash
vlog TOP.sv
```
## To Run
```bash
vsim -c LLC_Cache -do "run -all" +trace_file=cc1.din
```
## Key Features
### L2 Cache Specifications
- **Total Capacity**: 16MB
- **Byte Line**: 64 bytes
- **Associativity**: 16-way set
- **Coherence Protocol**: MESI
- **Replacement Policy**: Pseudo-LRU

### L1 Cache Specifications
- **Byte Line**: 64 bytes
- **Associativity**: 4-way set
- **Write Policy**: Write-once (initial write-through, subsequent write-back)

### Design Architecture
<img src="https://github.com/user-attachments/assets/4e1ed105-3db1-42a7-88fb-d5c12b17e4ca" alt="image" width="620" />


## Functional Highlights
- Implements **MESI protocol** for cache coherence.
- Supports **silent** and **debug** simulation modes.
- Provides detailed statistics, including cache hit/miss ratios and MESI state transitions.

## Testing Strategies
- Validates **read** and **write operations**.
- Tests **Pseudo-LRU functionality** for efficient replacement.
- Evaluates **MESI FSM transitions** for different cache scenarios.

### Testing MESI protocol
<img src="https://github.com/user-attachments/assets/d87b4c16-a33b-42a7-b98c-5fc62e4b06b8" alt="image2" width="450" />





---

This project was undertaken as part of the **ECE585 course** at **Portland State University** under the guidance of **Prof. Mark G. Faust**.
