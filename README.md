# 32-bit 5-Stage Pipelined MIPS CPU

Verilog HDL 기반의 32-bit 5-stage Pipelined MIPS CPU입니다.

명령어 실행을 IF, ID, EX, MEM, WB의 5개 Stage로 구성하고, Pipeline 구조에서 발생하는 Data Hazard와 Control Hazard를 처리하기 위한 Forwarding, Stall, Flush 로직 구현.

Hazard가 발생하는 명령어 시퀀스를 직접 구성하고 Vivado Behavioral Simulation에서 Pipeline 내부 Data Path와 Control Signal을 확인했습니다.

---

## Development Environment

| Category | Description |
|---|---|
| HDL | Verilog HDL |
| Tool | Xilinx Vivado |
| Architecture | 32-bit MIPS |
| Pipeline | IF / ID / EX / MEM / WB |
| Verification | Vivado Behavioral Simulation |
| Timing Target | 100 MHz |

### Supported Instructions

- R-Type : `add`, `sub`, `and`, `or`, `slt`
- I-Type : `addi`, `lw`, `sw`, `beq`
- J-Type : `j`

---

## Pipeline Structure

CPU를 IF, ID, EX, MEM, WB의 5개 Stage로 구성.

각 Stage 사이에 Pipeline Register를 배치하여 Data와 Control Signal 전달.

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

PC가 4씩 증가하며 각 명령어가 IF → ID → EX → MEM → WB 순서로 이동하는 것을 Simulation에서 확인.

![Pipeline Flow](image/pipeline_flow.png)

---

# Verification

Hazard가 발생하는 명령어 시퀀스를 구성하고 Vivado Behavioral Simulation에서 Pipeline의 Data Path와 Control Signal을 확인.

주요 관측 신호:

- `PC`
- Stage별 Instruction
- `ForwardA`, `ForwardB`
- `Stall`
- `Branch_EX`
- `Zero`
- `Branchtaken_EX`
- `Flush_IF_ID`
- `Flush_ID_EX`
- Write Back Data

---

## Data Hazard

Pipeline에서 이전 명령어의 연산 결과가 Register File에 반영되기 전에 다음 명령어가 해당 Register 값을 필요로 할 경우 RAW Hazard 발생.

일반적인 RAW Hazard는 EX/MEM, MEM/WB Pipeline Register의 결과를 ALU 입력으로 직접 전달하는 Forwarding 방식으로 처리.

Forwarding Unit에서 `RegWrite_MEM`, `RegWrite_WB`와 Source/Destination Register를 비교하여 `ForwardA`, `ForwardB` 신호 생성.

- `Forward = 10` : EX/MEM 결과 선택
- `Forward = 01` : MEM/WB 결과 선택
- 동시 조건 발생 시 `EX/MEM > MEM/WB` 우선순위 적용

`lw` 직후 Load Data를 사용하는 Load-use Hazard는 Load 결과가 MEM Stage 이후에 유효해지므로 Forwarding만으로 처리 불가.

Load-use Hazard 발생 시 1-cycle Stall과 Bubble 삽입 후 MEM/WB Forwarding을 통해 최신 값 전달.

---

## 1. EX/MEM Forwarding

바로 이전 명령어의 연산 결과를 다음 명령어에서 사용하는 경우.

```text
add $1, $2, $3
sub $4, $1, $3
```

`add` 결과가 Register File에 Write Back되기 전에 다음 `sub` 명령어에서 `$1` 사용.

EX/MEM Pipeline Register의 ALU 결과를 EX Stage 입력으로 직접 전달.

Simulation에서 EX/MEM Forwarding 발생과 최종 연산 결과 확인.

```text
$1 = 19
$4 = 9
```

![EX/MEM Forwarding](image/exmem_forwarding.png)

---

## 2. MEM/WB Forwarding

한 명령어 간격을 두고 이전 연산 결과를 사용하는 경우.

```text
add $1, $2, $3
nop
sub $4, $1, $3
```

`add` 결과가 MEM/WB Stage에 있는 시점에 `sub`가 해당 Register 값을 사용.

MEM/WB의 Write Back Data를 EX Stage ALU 입력으로 전달.

Simulation에서 MEM/WB Forwarding 동작과 최종 결과 확인.

```text
$1 = 19
$4 = 9
```

![MEM/WB Forwarding](image/memwb_forwarding.png)

---

## 3. Forwarding Priority

EX/MEM과 MEM/WB에 동일한 Destination Register의 결과가 존재할 경우 가장 최근 값을 선택해야 함.

```text
add $1, $2, $3
sub $1, $5, $6
add $4, $1, $7
```

마지막 `add` 명령어가 `$1`을 사용할 때 두 Forwarding 조건이 동시에 발생할 수 있음.

MEM/WB의 이전 `add` 결과보다 EX/MEM의 최신 `sub` 결과를 우선하도록 `EX/MEM > MEM/WB` 우선순위 적용.

```text
첫 번째 add  → $1 = 19
sub          → $1 = 6
마지막 add   → 최신 $1 = 6 사용
$4 = 9
```

Simulation에서 EX/MEM의 최신 값이 선택되는 것을 확인.

![Forwarding Priority](image/forwarding_priority.png)

---

## 4. Load-use Hazard

`lw` 명령어가 Memory에서 읽은 값을 바로 다음 명령어에서 사용하는 경우.

```text
lw  $6, 400($0)
add $7, $5, $6
```

Load Data는 MEM Stage 이후에 유효해지므로 바로 다음 명령어의 EX Stage에서 사용할 수 없음.

`MemRead_EX = 1`이고 `rt_EX`와 다음 명령어의 Source Register가 일치하는 경우 Load-use Hazard로 판별.

### Hazard 처리

1. PC Hold
2. IF/ID Pipeline Register Hold
3. ID/EX Control Signal을 0으로 설정
4. Bubble 삽입
5. 1-cycle Stall
6. 다음 Cycle에서 MEM/WB Forwarding

검증 조건:

```text
Memory[100] = 100
$5 = 12
```

최종 결과:

```text
$6 = 100
$7 = 12 + 100 = 112
```

Simulation에서 Stall 발생 후 MEM/WB Forwarding을 통해 정상 연산되는 것을 확인.

![Load-use Hazard](image/load_use_stall.png)

---

## Control Hazard

Branch 또는 Jump 명령어의 분기 결과가 확정되기 전에 후속 명령어가 이미 Pipeline에 진입하면서 Control Hazard 발생.

잘못 진입한 명령어를 Pipeline Register에서 Flush하여 처리.

---

## 5. Branch Not Taken / Taken

Branch 명령어는 ID Stage에서 Decode되며, 실제 Taken 여부는 EX Stage에서 `Branch_EX && Zero`를 통해 결정.

### Branch Not Taken

```text
beq $10, $11, 4
```

Register 초기값:

```text
$10 = 4
$11 = 1
```

두 값이 다르므로 `Zero = 0`.

```text
Branch_EX      = 1
Zero           = 0
Branchtaken_EX = 0
Flush_IF_ID    = 0
Flush_ID_EX    = 0
```

Flush 없이 PC 순차 진행.

![Branch Not Taken](image/branch_not_taken.png)

### Branch Taken

```text
beq $10, $10, 4
```

두 Register 값이 같으므로 `Zero = 1`.

```text
Branch_EX      = 1
Zero           = 1
Branchtaken_EX = 1
Flush_IF_ID    = 1
Flush_ID_EX    = 1
```

Branch가 EX Stage에서 확정되는 시점에는 후속 명령어가 IF/ID와 ID/EX에 진입한 상태.

두 Pipeline Register를 Flush하고 Branch Target으로 PC 변경.

검증 시퀀스에서는 PC 44의 Branch 명령어 실행 후 PC 64로 분기하는 것을 확인.

![Branch Taken](image/branch_taken.png)

---

## 6. Jump

Jump는 Register 비교가 필요하지 않으므로 ID Stage에서 Jump Target 결정.

Jump가 결정되는 시점에는 후속 명령어가 IF/ID에만 진입한 상태이므로 IF/ID만 Flush.

```text
Flush_IF_ID = 1
Flush_ID_EX = 0
```

검증 시퀀스:

```text
PC68 : jump 20
PC72 : 잘못 Fetch된 명령어 → Flush
PC80 : Jump Target
```

Simulation에서 `Jump = 1`, `Flush_IF_ID = 1` 발생 후 Target PC인 80으로 이동하는 것을 확인.

![Jump Flush](image/jump_flush.png)

---

## WB → ID Bypass

WB Stage의 Register Write와 ID Stage의 Register Read가 같은 Cycle에 발생할 경우 이전 Register 값이 읽히는 문제를 방지하기 위한 Bypass 경로 구성.

WB의 Destination Register와 ID에서 읽는 Source Register가 같을 경우 Register File의 기존 값 대신 Write Back Data를 직접 전달.

동일 Cycle의 Write Back 값을 ID Stage에서 바로 사용할 수 있도록 처리.

---

## Static Timing Analysis

합성 후 Static Timing Analysis를 통해 목표 주파수 100 MHz에서 Setup Timing 확인.

초기 STA에서 Branch 관련 경로가 Critical Path를 형성하며 Setup Timing 위반 발생.

Timing Path 분석 후 Branch 경로의 조합논리 구조를 개선하고 다시 STA를 수행하여 100 MHz Timing Constraint 충족.
