import pyximport; pyximport.install()
import brute_crc32b
import sys


if __name__ == "__main__":
    INPUT_CSV = "scan\\list\\Overwatch STU type list.csv"  # Sombra's current list of STU types
    INPUT_CSV2 = "scan\\list\\Overwatch STU type list.csv"  # dynaomi's list of STU fields
    OUTPUT_CSV = "out\\output.csv"
    LOG_FILE = "out\\log.txt"
    LOG_TO_FILE = True
    LOG_FAILS = False
    MAX_STR_LENGTH = 99999
    MAX_PROCS = 4
    brute_crc32b.do_the_things(INPUT_CSV, INPUT_CSV2, OUTPUT_CSV, LOG_TO_FILE, LOG_FILE,
                               LOG_FAILS, MAX_STR_LENGTH, MAX_PROCS)
