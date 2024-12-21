# Last Level Cache Design and Simulation

This project focuses on designing and simulating a Last Level Cache (LLC) for processors, addressing the challenge of memory systems lagging behind high-speed processors. By implementing a caching mechanism, critical data and instructions are stored closer to the processor for faster access.

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
- Supports **silent**, **normal**, and **debug** simulation modes.
- Provides detailed statistics, including cache hit/miss ratios and MESI state transitions.

## Testing Strategies
- Validates **read** and **write operations**.
- Tests **Pseudo-LRU functionality** for efficient replacement.
- Evaluates **MESI FSM transitions** for different cache scenarios.

### Testing MESI protocol
<img src="https://github.com/user-attachments/assets/d87b4c16-a33b-42a7-b98c-5fc62e4b06b8" alt="image2" width="450" />





---

This project was undertaken as part of the **ECE585 course** at **Portland State University** under the guidance of **Prof. Mark G. Faust**.
