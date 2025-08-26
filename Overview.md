# Overview
e-Cryptex is a hardware-based random key generation system implemented on Xilinx FPGAs. The system leverages analog-to-digital converter (ADC) noise as an entropy source to generate cryptographic keys. This project demonstrates a novel approach to hardware random number generation with real-time calibration and adaptive masking techniques.

**This work is submitted to USENIX Security 2026.**

# Key Features

Dual ADC Entropy Source: Utilizes two independent ADC channels for enhanced randomness
Real-time Calibration: Automatic min/max tracking and calibration value computation
Adaptive Masking: Dynamic bit masking based on noise characteristics
Finite State Machine: Robust state management for reliable operation
Debounced Control: Hardware debouncing for stable user input handling
24-bit Key Output: Configurable key generation with entropy mixing

# System Architecture
## Core Components
- e_Cryptex_FSM: Main finite state machine controlling the key generation process
- Clock Management: Integrated clock wizard for precise timing control
- ADC Interface: Dual-channel ADC communication with SPI-like protocol
- Calibration Engine: Real-time noise characterization and compensation

## State Machine Design
The system operates through the following states:

- IDLE: Waiting for activation signal
- WAIT_AFTER_RESET: Initial stabilization period (1s @ 31.25MHz)
- READ_ADC: Concurrent sampling from both ADC channels
- UPDATE_MIN_MAX: Min/max value tracking for calibration
- CALCULATE_CALIBRATION: Computing calibration parameters
- CALCULATE_MASK: Generating adaptive bit masks
- PROCESS_KEY: Final key assembly and output

# Hardware Requirements
## FPGA Resources

- Target Platform: Xilinx 7-Series or newer
- Clock Resources: 2 independent clock domains

## I/O Requirements:

- 2 ADC data lines (SDA1, SDA2)
- 2 ADC busy signals (BUSY1, BUSY2)
- 2 ADC conversion start signals (CONVST1, CONVST2)
- Control inputs (mode_switch, continuous_switch, adc_on)



## External Components

- Dual ADC: 12-bit resolution minimum
- Clock Source: Stable reference clock
- Control Interface: Switches/buttons for mode selection