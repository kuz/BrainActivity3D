import time
from threading import Thread

number = 0

def increase_number():
    global number
    while True:
        number += 1

def read_number():
    global number
    while True:
        time.sleep(1)
        print number

def main():
    counter = Thread(target=increase_number)
    printer = Thread(target=read_number)
    counter.start()
    printer.start()

main()