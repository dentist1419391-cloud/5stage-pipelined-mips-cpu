# 32-bit 5-Stage Pipelined MIPS CPU

Verilog HDL 기반의 32-bit 5-stage Pipelined MIPS CPU입니다.

명령어 실행을 IF, ID, EX, MEM, WB의 5개 Stage로 구성하고, Pipeline에서 발생하는 Data Hazard와 Control Hazard를 처리하기 위해 Forwarding, Stall, Flush 로직을 구현했습니다.

Hazard가 발생하는 명령어 시퀀스를 구성한 뒤 Vivado Behavioral Simulation에서 Pipeline 내부 신호와 최종 연산 결과를 확인했습니다.

---

## Development Environment

| Category | Description |
|---|---|
| HDL | Verilog HDL |
| Tool | Xilinx Vivado |
| Architecture | 32-bit MIPS |
| Pipeline | IF / ID / EX / MEM / WB |
| Simulation | Vivado Behavioral Simulation |

### Supported Instructions

- R-Type : `add`, `sub`, `slt`
- I-Type : `addi`, `lw`, `sw`, `beq`
- J-Type : `j`

---

## Pipeline Structure

CPU를 IF, ID, EX, MEM, WB의 5개 Stage로 구성하고 각 Stage 사이에 Pipeline Register를 배치했습니다.

- `IF/ID`
- `ID/EX`
- `EX/MEM`
- `MEM/WB`

| Stage | Function |
|---|---|
| IF | Instruction Fetch |
| ID | Instruction Decode / Register Read |
| EX | ALU Operation / Branch Decision |
| MEM | Data Memory Access |
| WB | Register Write Back |

### Pipeline 동작 확인

PC가 순차적으로 증가하고 각 명령어가 Pipeline Stage를 따라 이동하는 것을 Simulation에서 확인했습니다.

![Pipeline Flow](images/pipeline_flow.png)

---

## Data Hazard

### EX/MEM Forwarding

이전 명령어의 연산 결과가 Register File에 Write Back되기 전에 다음 명령어가 해당 값을 사용하는 경우 EX/MEM의 결과를 ALU 입력으로 전달합니다.

검증 명령어:

```text
add $1, $2, $3
sub $4, $1, $3
```

`add`의 결과가 아직 Write Back되지 않은 상태에서 다음 `sub` 명령어가 `$1`을 사용하도록 구성했습니다.

Simulation에서 EX/MEM Forwarding이 발생하고 최신 연산 결과가 ALU 입력으로 전달되는 것을 확인했습니다.

![EX/MEM Forwarding](images/exmem_forwarding.png)

---

### MEM/WB Forwarding

한 명령어 간격의 Data Dependency에서는 MEM/WB Stage의 Write Back Data를 EX Stage의 ALU 입력으로 전달합니다.

검증 명령어:

```text
add $1, $2, $3
nop
sub $4, $1, $3
```

MEM/WB 단계의 연산 결과가 Forwarding되어 `sub` 명령어에서 사용되는 것을 확인했습니다.

![MEM/WB Forwarding](images/memwb_forwarding.png)

---

### Forwarding Priority

EX/MEM과 MEM/WB Forwarding 조건이 동시에 성립할 경우 더 최근 결과인 EX/MEM 값을 우선하도록 구성했습니다.

검증 명령어:

```text
add $1, $2, $3
sub $1, $5, $6
add $4, $1, $7
```

마지막 `add` 명령어에서 `$1`의 이전 값이 아닌 바로 앞 `sub`의 최신 결과가 선택되는 것을 확인했습니다.

![Forwarding Priority](images/forwarding_priority.png)

---

## Load-use Hazard

`lw` 명령어의 Load Data는 MEM Stage 이후에 유효해지기 때문에 바로 다음 명령어에서 해당 Register를 사용하는 경우 Forwarding만으로 해결할 수 없습니다.

검증 명령어:

```text
lw  $6, 400($0)
add $7, $5, $6
```

Load-use Hazard가 검출되면 다음과 같이 처리합니다.

1. PC Hold
2. IF/ID Pipeline Register Hold
3. ID/EX Control Signal을 0으로 설정
4. Bubble 삽입
5. 1-cycle Stall
6. 다음 Cycle에서 MEM/WB Forwarding

Simulation에서 Stall 이후 Load Data가 정상적으로 Forwarding되는 것을 확인했습니다.

```text
Memory[100] = 100
$6 = 100
$7 = 12 + 100 = 112
```

![Load-use Hazard](images/load_use_stall.png)

---

## Control Hazard

Branch 또는 Jump가 실행될 때 분기 결과가 결정되기 전에 Pipeline에 들어온 후속 명령어를 Flush하여 Control Hazard를 처리합니다.

### Branch Not Taken

Branch Taken 여부는 EX Stage에서 결정합니다.

검증 명령어:

```text
beq $10, $11, 4
```

두 Register 값이 다르기 때문에 Branch가 발생하지 않는 경우입니다.

```text
Branch_EX      = 1
Zero           = 0
Branchtaken_EX = 0
Flush_IF_ID    = 0
Flush_ID_EX    = 0
```

Flush 없이 PC가 순차적으로 진행하는 것을 확인했습니다.

![Branch Not Taken](images/branch_not_taken.png)

---

### Branch Taken

검증 명령어:

```text
beq $10, $10, 4
```

두 Register 값이 같아 EX Stage에서 Branch Taken이 결정됩니다.

```text
Branch_EX      = 1
Zero           = 1
Branchtaken_EX = 1
Flush_IF_ID    = 1
Flush_ID_EX    = 1
```

Branch가 결정되기 전에 이미 Pipeline에 들어온 IF/ID와 ID/EX의 후속 명령어를 Flush하고 Branch Target으로 PC가 변경되는 것을 확인했습니다.

![Branch Taken](images/branch_taken.png)

---

### Jump

Jump는 ID Stage에서 Target Address를 결정합니다.

Branch와 달리 ID Stage에서 분기가 결정되므로 이미 Fetch된 다음 명령어만 제거하도록 IF/ID Pipeline Register를 Flush합니다.

```text
Flush_IF_ID = 1
Flush_ID_EX = 0
```

Simulation에서 Jump 신호 발생 후 잘못 Fetch된 명령어가 제거되고 Target PC로 이동하는 것을 확인했습니다.

![Jump Flush](images/jump_flush.png)

---

## WB → ID Bypass

WB Stage의 Register Write와 ID Stage의 Register Read가 같은 Cycle에 발생하는 경우 최신 값을 사용할 수 있도록 Register File 내부에 Bypass 경로를 구성했습니다.

WB에서 Write Back되는 값과 ID에서 읽으려는 Register 주소가 같을 경우 Register File에 저장된 이전 값 대신 Write Back Data를 바로 전달하도록 구성했습니다.
