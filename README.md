# 32-bit 5-stage Pipelined MIPS CPU

Verilog HDL로 설계한 32-bit 5-stage Pipeline MIPS CPU입니다.

개인 프로젝트로 Pipeline 구조와 Hazard 처리 원리를 RTL 수준에서 구현하고,
다양한 명령어 조합을 활용한 RTL Simulation과 STA를 통해 기능과 Timing을 검증했습니다.

### 주요 구현 및 성과

- 5-stage Pipeline: `IF / ID / EX / MEM / WB`
- Data Hazard 처리: `Forwarding`, `Load-use Stall`
- Control Hazard 처리: `Branch Flush`, `Jump Flush`
- 다양한 명령어 조합과 Corner Case 기반 RTL Simulation 검증
- STA 기반 Critical Path 분석 및 조합논리 구조 개선
- 최대 동작주파수 **101 MHz → 132 MHz, 약 31% 향상**

---

## 개발 환경

| 구분 | 내용 |
|---|---|
| HDL | Verilog HDL |
| Tool | Xilinx Vivado |
| Architecture | 32-bit MIPS |
| Pipeline | IF / ID / EX / MEM / WB |
| 기능 검증 | Vivado Behavioral Simulation |
| Timing 검증 | Static Timing Analysis |
| 목표 주파수 | 100 MHz |

### 지원 명령어

- **R-Type**: `add`, `sub`, `and`, `or`, `slt`
- **I-Type**: `addi`, `lw`, `sw`, `beq`
- **J-Type**: `j`

---

## Pipeline 구조

CPU를 `IF`, `ID`, `EX`, `MEM`, `WB`의 5개 Stage로 구성하고,
각 Stage 사이에 Pipeline Register를 배치하여 Data와 Control Signal을 전달하도록 설계했습니다.

- `IF/ID`
- `ID/EX`
- `EX/MEM`
- `MEM/WB`

| Stage | 주요 기능 |
|---|---|
| IF | Instruction Fetch, PC Update |
| ID | Instruction Decode, Register Read |
| EX | ALU Operation, Branch Decision |
| MEM | Data Memory Access |
| WB | Register Write Back |

### Pipeline 동작 확인

Reset 해제 후 `PC[31:0]`가 `0 → 4 → 8 → 12 → ...` 순서로 증가하는 것을 확인했습니다.

첫 번째 `add $1, $2, $3` 명령어(`0x00430820`)가  
`Instruction_IF → Instruction_ID → Instruction_EX → Instruction_MEM → Instruction_WB`  
순서로 이동하는 것을 통해 5-stage Pipeline의 정상 동작을 확인했습니다.

![Pipeline Flow](image/pipeline_flow.png)

---

# RTL Simulation 검증

Hazard가 발생하도록 명령어 시퀀스를 구성하고,
Vivado Behavioral Simulation에서 Pipeline 내부 Data Path와 Control Signal을 관측했습니다.

| 구분 | 검증 내용 |
|---|---|
| EX/MEM Forwarding | 직전 명령어의 연산 결과 전달 |
| MEM/WB Forwarding | 한 명령어 이전의 연산 결과 전달 |
| Forwarding Priority | EX/MEM과 MEM/WB 조건이 동시에 성립할 때 우선순위 확인 |
| Load-use Hazard | 1-cycle Stall 및 이후 Forwarding 확인 |
| Branch | Taken / Not Taken 및 Pipeline Flush 확인 |
| Jump | Jump Target 이동 및 IF Stage Flush 확인 |

---

## Data Hazard

이전 명령어의 연산 결과가 Register File에 반영되기 전에
다음 명령어가 해당 Register 값을 필요로 하는 경우 RAW Hazard가 발생합니다.

일반적인 RAW Hazard는 EX/MEM 또는 MEM/WB Pipeline Register에 저장된 결과를
EX Stage의 ALU 입력으로 전달하는 Forwarding으로 처리했습니다.

Forwarding Unit에서는 EX Stage의 Source Register와
MEM, WB Stage의 Destination Register를 비교하여
`ForwardA[1:0]`, `ForwardB[1:0]` 신호를 생성합니다.

- `Forward = 10`: EX/MEM 경로 선택
- `Forward = 01`: MEM/WB 경로 선택
- 두 조건이 동시에 성립하면 EX/MEM Forwarding 우선

`lw` 직후 Load Data를 사용하는 Load-use Hazard는
Load Data가 MEM Stage 이후에 유효해지므로 Forwarding만으로 처리할 수 없습니다.

따라서 1-cycle Stall과 Bubble을 삽입한 후
MEM/WB Stage의 Load Data를 Forwarding하도록 설계했습니다.

---

## 1. EX/MEM Forwarding

직전 명령어의 연산 결과를 다음 명령어가 바로 사용하는 경우입니다.

### 검증 명령어

```text
add $1, $2, $3
sub $4, $1, $3
```

Instruction Code:

```text
add $1, $2, $3  → 0x00430820
sub $4, $1, $3  → 0x00232022
```

`sub` 명령어가 EX Stage에 진입할 때
직전 `add` 명령어는 MEM Stage에 위치합니다.

### 파형 관측

```text
Instruction_EX      = 0x00232022
Instruction_MEM     = 0x00430820

Write_register_MEM  = 1
rs_EX               = 1

ForwardA            = 10

Read_data1          = 19
Read_data2          = 10
ALU_result           = 9
```

`Write_register_MEM = 1`과 `rs_EX = 1`이 일치하면서
`ForwardA = 10`이 발생하는 것을 확인했습니다.

EX/MEM Stage의 연산 결과 `19`가 ALU Operand로 전달되고,
`19 - 10 = 9`의 결과가 출력되는 것을 통해
EX/MEM Forwarding의 정상 동작을 검증했습니다.

![EX/MEM Forwarding](image/exmem_forwarding.png)

---

## 2. MEM/WB Forwarding

한 명령어 간격을 두고 이전 연산 결과를 사용하는 경우입니다.

### 검증 명령어

```text
add $1, $2, $3
nop
sub $4, $1, $3
```

`nop`을 삽입하여 `sub` 명령어가 EX Stage에 진입할 때
`add`의 결과가 WB Stage에 위치하도록 구성했습니다.

### 파형 관측

```text
Instruction_EX     = 0x00232022

Write_register_MEM = 0
Write_register_WB  = 1
rs_EX              = 1

ForwardA           = 01

Read_data1         = 19
Read_data2         = 10
ALU_result          = 9
```

EX/MEM Forwarding 조건은 성립하지 않고
`Write_register_WB = 1`과 `rs_EX = 1`이 일치하면서
`ForwardA = 01`이 발생했습니다.

WB Stage의 결과 `19`가 ALU Operand로 전달되고,
최종 `ALU_result = 9`가 출력되는 것을 통해
MEM/WB Forwarding을 검증했습니다.

![MEM/WB Forwarding](image/memwb_forwarding.png)

---

## 3. Forwarding Priority

EX/MEM과 MEM/WB Stage에 동일한 Destination Register의 결과가 존재하는 경우
가장 최근에 연산된 값을 사용해야 합니다.

### 검증 명령어

```text
add $1, $2, $3
sub $1, $5, $6
add $4, $1, $7
```

연산 결과:

```text
첫 번째 add  → $1 = 19
sub           → $1 = 6
마지막 add    → $4 = 6 + 3 = 9
```

마지막 `add`가 `$1`을 사용할 때
MEM/WB에는 이전 값 `19`,
EX/MEM에는 최신 값 `6`이 존재합니다.

### 파형 관측

```text
Instruction_EX     = 0x00272020

Write_register_MEM = 1
Write_register_WB  = 1
rs_EX              = 1

ForwardA           = 10

Read_data1         = 6
Read_data2         = 3
ALU_result          = 9
```

두 Forwarding 조건이 동시에 성립한 상황에서
`ForwardA = 10`이 발생하며 EX/MEM Stage의 최신 값 `6`이 선택되는 것을 확인했습니다.

이를 통해 `EX/MEM > MEM/WB`의 Forwarding 우선순위를 검증했습니다.

![Forwarding Priority](image/forwarding_priority.png)

---

## 4. Load-use Hazard

`lw` 명령어가 Memory에서 읽어온 값을
바로 다음 명령어가 사용하는 경우입니다.

### 검증 명령어

```text
lw  $6, 400($0)
add $7, $5, $6
```

Instruction Code:

```text
lw  $6, 400($0)  → 0x8c060190
add $7, $5, $6   → 0x00a63820
```

Load Data는 MEM Stage 이후에 유효해지므로
바로 다음 `add`의 EX Stage에서 사용할 수 없습니다.

### Hazard 검출

`lw`가 EX Stage,
`add`가 ID Stage에 위치한 Cycle에서 다음 신호를 확인했습니다.

```text
Instruction_EX = 0x8c060190
Instruction_ID = 0x00a63820

MemRead_EX     = 1
rt_EX          = 6
rt_ID          = 6

Stall          = 1
```

`lw`의 Destination Register `$6`을
다음 `add`가 Source Register로 사용하면서 `Stall = 1`이 발생합니다.

Stall 동안 `PC[31:0]`가 `92`에서 한 Cycle 유지되는 것을 통해
PC Hold 동작을 확인했습니다.

### Stall 이후 Forwarding

```text
Write_data_reg_WB = 100
ForwardB          = 1
ALU_result         = 112
```

Load Data `100`이 MEM/WB Stage에서 Forwarding되어
`add` 명령어의 Operand로 전달됩니다.

```text
$5 = 12
$6 = 100

12 + 100 = 112
```

최종 `ALU_result = 112`를 통해
1-cycle Stall 이후 Load Data가 정상적으로 사용되는 것을 확인했습니다.

![Load-use Hazard](image/load_use_stall.png)

---

# Control Hazard

Branch 또는 Jump의 Target이 결정되기 전에
후속 명령어가 Pipeline에 진입하면서 Control Hazard가 발생할 수 있습니다.

Branch는 EX Stage에서 Taken 여부를 결정하고,
Jump는 ID Stage에서 Target을 결정하도록 구성했습니다.

분기 결과에 따라 잘못 진입한 명령어를 Pipeline Register에서 Flush합니다.

---

## 5. Branch Not Taken / Taken

### Branch Not Taken

검증 명령어:

```text
beq $10, $11, 4
```

Instruction Code:

```text
0x114b0004
```

Register 초기값:

```text
$10 = 4
$11 = 1
```

### 파형 관측

```text
Instruction_EX  = 0x114b0004

Branch_EX       = 1
Zero            = 0
Branchtaken_EX  = 0

Flush_IF_ID     = 0
Flush_ID_EX     = 0

PC              = 40
Next_PC         = 44
```

두 Register 값이 다르므로 `Zero = 0`,
`Branchtaken_EX = 0`으로 유지됩니다.

Flush가 발생하지 않고
`Next_PC = 44`로 순차 실행되는 것을 확인했습니다.

![Branch Not Taken](image/branch_not_taken.png)

---

### Branch Taken

검증 명령어:

```text
beq $10, $10, 4
```

Instruction Code:

```text
0x114a0004
```

두 Source Register 값이 동일하므로 Branch Taken 조건이 성립합니다.

### 파형 관측

```text
Instruction_EX  = 0x114a0004

Branch_EX       = 1
Zero            = 1
Branchtaken_EX  = 1

Flush_IF_ID     = 1
Flush_ID_EX     = 1

PC              = 52
Next_PC         = 64
```

`Branch_EX = 1`, `Zero = 1`에 따라
`Branchtaken_EX = 1`이 발생합니다.

Branch가 EX Stage에서 확정될 때
이미 IF/ID와 ID/EX에 진입한 후속 명령어를 제거하기 위해
`Flush_IF_ID = 1`, `Flush_ID_EX = 1`이 발생합니다.

`Next_PC = 64`를 통해 Branch Target으로 정상적으로 이동하는 것을 확인했습니다.

![Branch Taken](image/branch_taken.png)

---

## 6. Jump

Jump는 ID Stage에서 Target Address를 결정하도록 구성했습니다.

### 검증 명령어

```text
j 20
```

Instruction Code:

```text
0x08000014
```

### 파형 관측

```text
Instruction_ID = 0x08000014

Jump           = 1
Flush_IF_ID    = 1
Flush_ID_EX    = 0

PC             = 72
Next_PC        = 80

Instruction_IF = 0x00430820
```

Jump Target이 ID Stage에서 결정되므로
이미 IF Stage에 진입한 명령어만 제거하기 위해
`Flush_IF_ID = 1`이 발생합니다.

`Flush_ID_EX = 0`으로 유지되고
`Next_PC = 80`으로 변경되는 것을 통해 Jump 동작을 검증했습니다.

![Jump Flush](image/jump_flush.png)

---

# Static Timing Analysis 및 Timing 최적화

기능 검증 이후 Clock Constraint를 설정하고
Static Timing Analysis를 수행하여 FPGA 구현 시 Timing을 검증했습니다.

초기 분석에서 Branch 명령어 경로가 Critical Path를 형성하는 것을 확인했습니다.

Timing Path를 분석한 뒤 해당 경로의 조합논리 구조를 개선하고
다시 STA를 수행하여 Timing 성능을 비교했습니다.

| 구분 | 개선 전 | 개선 후 |
|---|---:|---:|
| 최대 동작주파수 | 101 MHz | 132 MHz |
| 성능 향상 | - | 약 31% |

조합논리 구조 개선을 통해 최대 동작주파수를
**101 MHz에서 132 MHz로 약 31% 향상**시켰으며,
목표 주파수인 100 MHz Timing Constraint를 충족했습니다.

이를 통해 RTL 기능 검증뿐 아니라
Critical Path를 분석하고 RTL 구조를 개선하여
Timing 성능을 최적화하는 과정을 경험했습니다.

---

# 프로젝트 결과

- Verilog HDL 기반 32-bit 5-stage Pipeline CPU 설계
- `IF / ID / EX / MEM / WB` Pipeline 구조 구현
- `Forwarding`, `Load-use Stall`을 통한 Data Hazard 처리
- `Branch Flush`, `Jump Flush`를 통한 Control Hazard 처리
- 다양한 Hazard와 Corner Case를 RTL Simulation으로 검증
- STA 기반 Branch Critical Path 분석
- 조합논리 구조 개선을 통해 최대 동작주파수 **101 MHz → 132 MHz**
- 최대 동작주파수 약 **31% 향상**
