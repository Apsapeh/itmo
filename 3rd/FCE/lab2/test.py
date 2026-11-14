import serial, struct

s = serial.Serial('/dev/ttyUSB1', 115200, timeout=2)
a, b = 10, 20
for i in range(10):  
    s.write(struct.pack('<BB', a, b + i))
    resp = s.read(1)
    print(resp.hex(), int.from_bytes(resp, 'little'))
