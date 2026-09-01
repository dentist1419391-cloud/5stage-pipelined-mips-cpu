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

### EX/MEM Forwarding

바로 이전 명령어의 연산 결과가 필요한 경우, EX/MEM Pipeline Register의 결과를 EX Stage의 ALU 입력으로 전달하도록 구현했습니다.

```text
add $1, $2, $3
sub $4, $1, $3
```

위 명령어 조합에서 `add`의 결과가 Register File에 Write Back되기 전에 다음 `sub` 명령어에서 해당 값을 필요로 합니다.

이때 `ForwardA = 10`이 발생하고, EX/MEM의 ALU 연산 결과가 EX Stage 입력으로 Forwarding되는 것을 확인했습니다.

![EX/MEM Forwarding](images/exmem_forwarding.png)

### MEM/WB Forwarding

한 명령어의 간격이 존재하는 Data Dependency에서는 MEM/WB Stage의 Write Back Data를 EX Stage 입력으로 전달하도록 구현했습니다.

`Forward = 01`일 때 MEM/WB의 값을 선택하며, EX/MEM과 MEM/WB Forwarding 조건이 동시에 만족되는 경우에는 더 최근 값인 **EX/MEM 결과를 우선 선택**하도록 설계했습니다.

---

## Load-use Hazard

`lw` 명령어의 Load Data는 MEM Stage 이후에 유효해지므로, 바로 다음 명령어가 해당 Register를 사용하는 경우 Forwarding만으로 Hazard를 해결할 수 없습니다.

```text
lw  $6, 400($0)
add $7, $5, $6
```

Load-use Dependency를 검출하면 다음과 같이 처리합니다.

1. PC Hold
2. IF/ID Pipeline Register Hold
3. ID/EX Control Signal을 0으로 설정
4. Bubble 삽입
5. 1-cycle Stall
6. 이후 MEM/WB Forwarding

Simulation에서 `Stall = 1`이 발생한 뒤 Load된 값 `100`이 Forwarding되어 최종적으로 `$7 = 112`가 되는 것을 확인했습니다.

![Load-use Hazard](images/load_use.png)

---

## Control Hazard - Branch

`beq` 명령어는 EX Stage에서 Branch Taken 여부를 결정하도록 구현했습니다.

Branch Taken 시 이미 Pipeline에 진입한 잘못된 명령어를 제거하기 위해 `IF/ID`와 `ID/EX` Pipeline Register를 Flush합니다.

```text
Flush_IF_ID = 1
Flush_ID_EX = 1
```

### Branch Taken 검증

```text
beq $10, $10, 4
```

Simulation에서 다음과 같이 Branch Taken과 Flush 동작을 확인했습니다.

```text
Branch_EX      = 1
Zero           = 1
Branchtaken_EX = 1
Flush_IF_ID    = 1
Flush_ID_EX    = 1
Next_PC        = 64
```

잘못 Fetch된 명령어가 제거되고 Branch Target인 PC 64로 이동하는 것을 확인했습니다.

![Branch Taken](images/branch_taken.png)

Branch Not Taken 조건에서는 Flush가 발생하지 않고 PC가 순차적으로 증가하는 것을 확인했습니다.

---

## Control Hazard - Jump

Jump 명령어는 ID Stage에서 Target Address를 결정하도록 구현했습니다.

Jump 발생 시 이미 Fetch된 다음 명령어만 제거하기 위해 IF/ID Pipeline Register만 Flush합니다.

```text
Flush_IF_ID = 1
Flush_ID_EX = 0
```

검증 명령어:

```text
j 20
```

Simulation에서 `Jump = 1`, `Flush_IF_ID = 1`이 발생하고 Target Address인 **PC 80**으로 이동하는 것을 확인했습니다.

![Jump](images/jump.png)

---

## Verification

Hazard가 발생하도록 명령어 시퀀스를 구성하고 Vivado Behavioral Simulation의 Waveform에서 Data Path와 Control Signal을 확인했습니다.

| Verification Case | Expected Behavior | Result |
|---|---|---|
| Sequential Execution | PC + 4 | PASS |
| EX/MEM Forwarding | EX/MEM Result → EX | PASS |
| MEM/WB Forwarding | MEM/WB Result → EX | PASS |
| Forwarding Priority | EX/MEM > MEM/WB | PASS |
| Load-use Hazard | 1-cycle Stall + Forwarding | PASS |
| Branch Not Taken | Sequential PC | PASS |
| Branch Taken | IF/ID + ID/EX Flush | PASS |
| Jump | IF/ID Flush | PASS |
| WB → ID Bypass | 최신 Register 값 전달 | PASS |

---

## Development Environment

| Category | Environment |
|---|---|
| HDL | Verilog HDL |
| Tool | Xilinx Vivado |
| Simulation | Vivado Behavioral Simulation |
| Architecture | 32-bit MIPS |
| Pipeline | IF / ID / EX / MEM / WB |
