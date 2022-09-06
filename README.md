# Extended-ARM
Added a global predictor with index sharing to the pipelined ARM processor rtl from Harris & Harris textbook.
The processor supports:
  - ADD, SUB, AND, and ORR
  - LDR and STR
  - RAW Hazard
  - LDR Hazard
  - Control Hazards due to Branch or PC write

and has a 4-bit global predictor with index sharing.
