#!/usr/bin/env python3

import tkinter as tk
import sys

import test

root = tk.Tk() 

a_var = tk.StringVar()
b_var = tk.StringVar()
answer_var = tk.StringVar()
fpga_ser = None

def main():
    global fpga_ser
    fpga_ser = test.new_fpga_serial(sys.argv[1], 115200, 2)

    font = ("Arial", 25) 
    a_var.set("0")
    b_var.set("0")

    tk.Label(root, text="A: ", font=font).grid(row=0, column=0)
    tk.Label(root, text="B: ", font=font).grid(row=1, column=0)
    tk.Label(root, text="Answer: ", font=font).grid(row=2, column=0)
    tk.Label(root, textvariable=answer_var, font=font).grid(row=2, column=1)

    entry1 = tk.Entry(root, textvariable=a_var, font=font)
    entry2 = tk.Entry(root, textvariable=b_var, font=font)

    entry1.grid(row=0, column=1)
    entry2.grid(row=1, column=1)

    button = tk.Button(root, text="Send", width=25, command=send_pressed, font=font)
    button.grid(row=3, column=0, columnspan=2)

    root.mainloop()

def send_pressed():
    a = int(a_var.get())
    b = int(b_var.get())

    if a < 0 or a > 65535 or b < 0 or b > 65535:
        answer_var.set("BAD VALUE")
        return

    resp = test.uart_fpga(a, b, fpga_ser)
    answer_var.set(str(resp))

if __name__ == "__main__":
    main()
