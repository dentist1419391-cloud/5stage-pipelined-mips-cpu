[# 32-bit 5-Stage Pipelined MIPS CPU

Verilog HDL로 구현한 32-bit 5-stage pipelined MIPS CPU입니다.

명령어 실행을 IF, ID, EX, MEM, WB의 5개 Stage로 분리하고,
Pipeline 구조에서 발생하는 Data Hazard와 Control Hazard를 처리하기 위해
Forwarding, Stall, Flush 로직을 구현했습니다.

Vivado RTL Simulation을 통해 다양한 명령어 조합에서
Hazard 처리 로직과 Pipeline 동작을 검증했으며,
합성 후 Static Timing Analysis를 수행했습니다.

---

## 1. Development Environment

| Category | Description |
|---|---|
| HDL | Verilog HDL |
| Tool | Xilinx Vivado |
| Architecture | 32-bit MIPS |
| Pipeline | IF / ID / EX / MEM / WB |
| Verification | Vivado Behavioral Simulation |
| Timing Target | 100 MHz |

### Supported Instructions

- R-type : `add`, `sub`, `and`, `or`, `slt`
- I-type : `addi`, `lw`, `sw`, `beq`
- J-type : `j`

---

## 2. System Architecture

CPU는 IF, ID, EX, MEM, WB의 5-stage Pipeline으로 구성했습니다.

각 Stage 사이에 Pipeline Register를 배치하여
Data와 Control Signal을 다음 Stage로 전달하도록 설계했습니다.

- IF/ID
- ID/EX
- EX/MEM
- MEM/WB

![5-Stage Pipeline Architecture](images/architecture.png)

### Pipeline Stage

| Stage | Function |
|---|---|
| IF | Instruction Fetch |
| ID | Instruction Decode / Register Read |
| EX | ALU Operation / Branch Decision |
| MEM | Data Memory Access |
| WB | Register Write Back |

---

## 3. Hazard Handling

### Data Hazard

RAW(Read After Write) Hazard를 처리하기 위해
Forwarding Unit과 Hazard Detection Unit을 구현했습니다.

#### Forwarding

연산 결과가 Register File에 Write Back되기 전에
후속 명령어가 해당 값을 필요로 하는 경우,
Pipeline Register의 결과를 ALU 입력으로 직접 전달합니다.

- EX/MEM → EX Forwarding
- MEM/WB → EX Forwarding
- Forwarding Priority : `EX/MEM > MEM/WB`

#### Load-use Hazard

`lw` 명령어의 데이터는 MEM Stage 이후에 유효해지므로
바로 다음 명령어가 해당 값을 사용하는 경우 Forwarding만으로 해결할 수 없습니다.

따라서 다음과 같이 처리했습니다.

1. Load-use Hazard Detection
2. PC 및 IF/ID Register Hold
3. ID/EX Control Signal을 0으로 설정하여 Bubble 삽입
4. 1-cycle Stall 이후 MEM/WB Forwarding

---

### Control Hazard

#### Branch

`beq`의 Taken 여부는 EX Stage에서 결정됩니다.

Branch Taken 시 이미 Pipeline에 진입한 잘못된 명령어를 제거하기 위해

- IF/ID Flush
- ID/EX Flush

를 수행합니다.

#### Jump

Jump Target은 ID Stage에서 결정하도록 구성했습니다.

따라서 이미 Fetch된 다음 명령어만 제거하기 위해

- IF/ID Flush

를 수행합니다.

---

## 4. RTL Verification

Testbench에 다양한 명령어 조합을 구성하고
Vivado Behavioral Simulation의 waveform을 통해
Pipeline Data Path와 Control Signal을 검증했습니다.

### Verification Summary

| Verification Case | Expected Behavior | Result |
|---|---|---|
| Sequential Execution | PC + 4 | PASS |
| EX/MEM Forwarding | Previous result → EX | PASS |
| MEM/WB Forwarding | WB result → EX | PASS |
| Forwarding Priority | EX/MEM > MEM/WB | PASS |
| Load-use Hazard | 1-cycle Stall + Forwarding | PASS |
| Branch Not Taken | Sequential PC | PASS |
| Branch Taken | IF/ID + ID/EX Flush | PASS |
| Jump | IF/ID Flush | PASS |
| WB → ID Bypass | Latest register value | PASS |

---

### 4-1. EX/MEM Forwarding

연속된 두 명령어 사이에서 RAW Hazard가 발생하는 조건을 구성했습니다.

```text
add $1, $2, $3
sub $4, $1, $3](https://github.com/sky9464881/fpga-8bit-5stage-pipeline-cpu)
