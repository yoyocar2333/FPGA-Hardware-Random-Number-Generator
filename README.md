# 亂數點名器 · LFSR Pseudorandom Draw Engine (FPGA Lab 1)

A SystemVerilog **pseudorandom** draw engine on the Terasic **DE2-115** (Intel Cyclone IV E) board. Press a button and the displayed number spins fast, then decelerates to a stop — a "slot-machine / lucky-draw" effect usable for random roll-call in class.

> NTUEE Logic Design Lab — Lab 1 (team10). An introductory lab focused on FSM design, an LFSR source, button debouncing, and seven-segment display. The LFSR is deterministic and is **not** a cryptographic RNG or a physical true-random source.

**English** | [繁體中文](#traditional-chinese)

<a id="english"></a>

## Features

- **Variable-speed spin** — press `KEY0` to start; the number spins quickly, then slows to a stop.
- **Instant stop** (bonus) — press `KEY0` again mid-spin to freeze immediately.
- **History** (bonus) — press `KEY2` to cycle through the last 4 results.
- **Instant draw** (bonus) — press `KEY3` to generate a number with no waiting.
- **Seven-segment output** — result shown as decimal 0–15 on `HEX1` (tens) and `HEX0` (ones).

## System Architecture

### Finite State Machine

| State | Trigger | Description |
|-------|---------|-------------|
| `S_IDLE`  | default | Idle; shows history results or waits for a key press |
| `S_WORK`  | `KEY0`  | Spinning; `delay` ramps from `MIN_DELAY` up to `MAX_DELAY`, producing the visual "slow-down" |
| `S_IMME`  | `KEY3`  | Draws a single value with no waiting |
| `S_STORE` | —       | Writes the result into the history buffer, returns to `S_IDLE` |

The deceleration is implemented by increasing a `delay` threshold: after each spin step the next wait grows by `DELAY_STEP`, until it exceeds `MAX_DELAY` and the spin stops.

### Random Source: 32-bit LFSR

A 32-bit Fibonacci linear-feedback shift register with feedback taps at bits `31, 21, 1, 0`, corresponding to the polynomial `x³² + x²² + x² + x + 1` — a **maximal-length sequence** (period 2³²−1).

- Seed is `32'h368B_4F78`, which **must be non-zero** (an all-zero state locks the LFSR).
- The low 4 bits `lfsr_reg[3:0]` are taken as the 0–15 random output.

### Button Debounce

`Debounce.sv` filters mechanical bounce with a two-flip-flop synchronizer plus a counter, and emits `o_pos` / `o_neg` edge pulses. This design uses `o_neg` (the press edge) as a single-cycle trigger so one press is never counted twice.

## Hardware Mapping

| Board element | Signal | Function |
|---------------|--------|----------|
| `KEY0` | `i_start` | Start / instant stop |
| `KEY1` | `i_rst_n` | System reset (active-low) |
| `KEY2` | `i_in2`   | View history (cycle last 4) |
| `KEY3` | `i_in3`   | Instant draw |
| `HEX1`, `HEX0` | `o_random_out` | Result display (tens / ones) |
| `CLOCK_50` | `i_clk` | 50 MHz system clock |

## File Structure

```
team10_lab1/
├── README.md
├── .gitignore
├── LICENSE
└── src/
    ├── Top.sv                  # Core: FSM + LFSR + history (team's original work)
    └── DE2_115/
        ├── DE2_115.sv          # Top-level wrapper / board pin hookup (course skeleton)
        ├── Debounce.sv         # Button debounce (course skeleton)
        ├── SevenHexDecoder.sv  # Seven-segment decoder (course skeleton)
        ├── DE2_115.qsf         # Quartus pin & project assignments
        └── DE2_115.sdc         # Timing constraints (50 MHz)
```

## Build & Program

Requires **Intel Quartus Prime** (Lite edition is sufficient) and a **DE2-115** board.

> This repo does **not** include a `.qpf` (Quartus project file), so the project cannot be opened directly. Rebuild it manually with the steps below — this works regardless of Quartus version.

1. Create a new project in Quartus. For **Device**, select `Cyclone IV E — EP4CE115F29C7`.
2. Set the **Top-Level Entity** to `DE2_115`.
3. Add all `.sv` files under `src/`, plus `DE2_115.qsf` and `DE2_115.sdc`.
4. `Processing → Start Compilation`.
5. Use the **Programmer** to flash the generated `.sof` to the FPGA.

## Attribution

For an honest portfolio, the authorship is stated explicitly:

- **Team's original work:** `Top.sv` (the random-generation FSM, LFSR, history buffer, and the three bonus features).
- **Course-provided skeleton:** `DE2_115.sv`, `Debounce.sv`, `SevenHexDecoder.sv`, `DE2_115.qsf`, and `DE2_115.sdc` are the lab's provided framework / board template, which the team wired together and built upon.

## ⚠️ Academic Integrity

This is coursework. Before publishing, **verify your course's disclosure policy** so that students still taking the class cannot simply copy the solution. Keep the repo **private** while the course is ongoing and switch to public after it ends.

## License

MIT — see [LICENSE](./LICENSE).

---

<a id="traditional-chinese"></a>

# 中文版 · LFSR 偽亂數點名器

於 Terasic **DE2-115**(Intel Cyclone IV E)開發板上，以 SystemVerilog 實作的 **LFSR 偽亂數** 點名器。按下按鍵後數字會先快速跳動、再逐漸減速停下,模擬「拉霸 / 抽籤」的效果,可用於課堂隨機點名。

> NTUEE 邏輯設計實驗 Lab 1(team10)。本專案為入門級實驗,重點在 FSM 設計、LFSR 亂數、按鍵防彈跳與七段顯示。

[English](#english) | **繁體中文**

## 功能

- **變速亂數跳動**:按 `KEY0` 開始,數字快速跳動後逐漸減速停止。
- **立即停止**(Bonus):跳動途中再按一次 `KEY0` 即立刻定格。
- **歷史紀錄**(Bonus):按 `KEY2` 可循環檢視最近 4 次的亂數結果。
- **瞬間亂數**(Bonus):按 `KEY3` 不須等待,立即產生一個亂數。
- **七段顯示**:結果以十進位 0–15 顯示於 `HEX1`(十位)與 `HEX0`(個位)。

## 系統架構

### 有限狀態機 (FSM)

| 狀態 | 觸發 | 說明 |
|------|------|------|
| `S_IDLE`  | 預設 | 待機;顯示歷史結果或等待按鍵觸發 |
| `S_WORK`  | `KEY0` | 亂數跳動,`delay` 由 `MIN_DELAY` 逐步遞增至 `MAX_DELAY`,視覺上呈現「減速」 |
| `S_IMME`  | `KEY3` | 不經等待,立即取一筆亂數 |
| `S_STORE` | — | 將結果寫入歷史緩衝區,回到 `S_IDLE` |

跳動的「減速」是用 `delay` 計數門檻遞增實現:每完成一次跳動,下一次的等待時間就加上 `DELAY_STEP`,直到超過 `MAX_DELAY` 才停止。

### 亂數來源:32-bit LFSR

採用 32-bit Fibonacci 線性回饋移位暫存器(LFSR),回饋抽頭位於 bit `31, 21, 1, 0`,對應多項式 `x³² + x²² + x² + x + 1`,為**最大長度序列**(週期 2³²−1)。

- 種子(seed)為 `32'h368B_4F78`,**不可為 0**(全 0 會使 LFSR 卡死)。
- 取輸出時使用低 4 位 `lfsr_reg[3:0]` 作為 0–15 的亂數。

### 按鍵防彈跳 (Debounce)

`Debounce.sv` 以「雙正反器同步器 + 計數器」濾除機械彈跳,並輸出 `o_pos` / `o_neg` 邊緣脈衝。本專案使用 `o_neg`(按下瞬間)作為單週期觸發訊號,避免一次按壓被重複判定。

## 硬體對應

| 板上元件 | 訊號 | 功能 |
|----------|------|------|
| `KEY0` | `i_start` | 開始 / 立即停止跳動 |
| `KEY1` | `i_rst_n` | 系統重置(active-low) |
| `KEY2` | `i_in2`   | 檢視歷史(循環最近 4 筆) |
| `KEY3` | `i_in3`   | 立即產生亂數 |
| `HEX1`, `HEX0` | `o_random_out` | 顯示亂數結果(十位 / 個位) |
| `CLOCK_50` | `i_clk` | 50 MHz 系統時脈 |

## 檔案結構

```
team10_lab1/
├── README.md
├── .gitignore
├── LICENSE
└── src/
    ├── Top.sv                  # 核心:FSM + LFSR + 歷史紀錄(本隊原創)
    └── DE2_115/
        ├── DE2_115.sv          # 頂層 wrapper,連接板上接腳(課程框架)
        ├── Debounce.sv         # 按鍵防彈跳(課程框架)
        ├── SevenHexDecoder.sv  # 七段顯示解碼(課程框架)
        ├── DE2_115.qsf         # Quartus 接腳與專案設定
        └── DE2_115.sdc         # 時序限制(50 MHz)
```

## 建置與燒錄

需要 **Intel Quartus Prime**(Lite 版本即可)與 **DE2-115** 開發板。

> 本 repo **未含 `.qpf`**(Quartus 專案檔),無法直接開啟專案。請依下列步驟手動重建——此方式不受 Quartus 版本限制。

1. 在 Quartus 新建專案,**Device** 選 `Cyclone IV E — EP4CE115F29C7`。
2. **Top-Level Entity** 設為 `DE2_115`。
3. 將 `src/` 下所有 `.sv`、以及 `DE2_115.qsf`、`DE2_115.sdc` 加入專案。
4. `Processing → Start Compilation` 完成合成與佈局。
5. 以 `Programmer` 將 `.sof` 燒錄至 FPGA。

## 程式碼歸屬

為誠實呈現作品內容,特此標註:

- **本隊原創**:`Top.sv`(亂數產生 FSM、LFSR、歷史紀錄與三項 Bonus 功能)。
- **課程提供框架**:`DE2_115.sv`、`Debounce.sv`、`SevenHexDecoder.sv`、`DE2_115.qsf`、`DE2_115.sdc` 為實驗課提供之骨架 / 板級樣板,本隊在其上整合與接線。

## ⚠️ 學術誠信

本專案為課程實驗作業。公開發布前,請先**確認課程的公開政策**,避免讓仍在修課的同學直接取得解答而違反學術誠信規範。建議在課程結束後再轉為公開(public),課程進行中先保持私有(private)。

## License

MIT,詳見 [LICENSE](./LICENSE)。
