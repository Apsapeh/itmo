#!/usr/bin/env python3

import serial
import struct
import sys
import random

# External functions
def new_fpga_serial(dev, baud, timeout=2):
    return serial.Serial(dev, baud, timeout=timeout)

def uart_fpga(a, b, fpga_ser) -> int:
   fpga_ser.write(struct.pack('<H', a)) 
   fpga_ser.write(struct.pack('<H', b))
   resp = fpga_ser.read(2)
   return int.from_bytes(resp, 'little')


# Internal CLI test
def main():
    fpga_ser = new_fpga_serial(sys.argv[1], 115200, 2)
    fpga_ser.reset_input_buffer()

    passed = 0
    failed = 0

    random.seed(131)
    for i in range(int(115200 / (10 * 6))): # ~1 sec
        a = random.randrange(65536)
        b = random.randrange(65536)
        passed, failed = test(a, b, fpga_ser, passed, failed)

    test_vec = (
            (0, 0),
            (0, 65535),
            (65535, 0),
            (65535, 65535),
            (65535, 1),
            (1, 65535),
    )

    for v in test_vec:
        passed, failed = test(v[0], v[1], fpga_ser, passed, failed)
        
    print(f"PASSED={passed}  FAILED={failed}")

def test(a, b, fpga_ser, passed, failed):
    expected = (int(a ** (1/3) + 1.0e-9) + int(b ** (1/2))) % 65536
    got = uart_fpga(a, b, fpga_ser)

    if expected != got:
        print(f"FAILED: a={a}  b={b}  expected={expected}  got={got}")
        failed += 1
    else:
        passed += 1

    return passed, failed


if __name__ == "__main__":
    main()
