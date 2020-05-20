# ueca-based-eceg
An open-source area-optimized Elliptic Curve Elgamal Cryptosystem in Hardware. 
This repository contains all source files in addition to the Verilog Header file to create an Elliptic Curve Elgamal Cryptosystem for the NIST-recommened curves: *secp128r1, secp160r1, secp192r1, secp224r1, secp256r1, secp384r1 and secp521r1*. A small test curve with 15 bits is also included
## Getting Started
To get starting, create a new Xilinx Vivado project and import all sources into your project. The top module is the encrypt_decrypt module. 
## Choosing a curve
To choose the desired curve, go to the Verilog Header file "parameters.vh" comment out all curves but the values for the desired one. 
