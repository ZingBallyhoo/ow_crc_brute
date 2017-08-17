import csv
import itertools
import os
import time
from multiprocessing import Process, Queue

cdef extern  from "crc2.h":
    unsigned int iolib_crc32(unsigned int previous_crc, unsigned char *buf, unsigned int length)

cdef str crc32b(str s):
    cdef bytes b = bytes(s, 'utf-8')
    cdef unsigned char* msg = b

    return hex(iolib_crc32(0, msg, len(s))).strip('0x').upper()

cdef list permitted_chars = list('abcdefghijklmnopqrstuvwxyz01234567890_')


class WriterProcess(Process):
    def __init__(self, in_queue, log_file, should_log, output_csv):
        super(WriterProcess, self).__init__()
        self.log_file = log_file
        self.should_log = should_log
        self.output_csv = output_csv
        self.in_queue = in_queue

    def run(self):
        cdef list csv_cache = []
        cdef list fieldnames = ['Hash', 'Name']

        while True:
            n = self.in_queue.get()
            if n is None:
                return
            if n[0] == "good":
                with open(self.output_csv, 'r') as foutput_csv:
                    csv_cache = foutput_csv.readlines()
                with open(self.output_csv, 'w') as foutput_csv:
                    foutput_csv.writelines(csv_cache)
                    writer = csv.DictWriter(foutput_csv, fieldnames=fieldnames)
                    writer.writerow({'Hash': n[1], 'Name': n[2]})
            if n[0] == "good" or self.log_fails:
                with open(self.log_file, 'a') as log_file:
                    log_file.write('{}: {}\n'.format(n[2], n[1]))



class WorkerProcess(Process):
    def __init__(self, todo_list, read_queue, write_queue, log_fails):
        super(WorkerProcess, self).__init__()
        self.todo_list = todo_list
        self.read_queue = read_queue
        self.write_queue = write_queue
        self.log_fails = log_fails

    def run(self):
        cdef int n
        cdef str combo
        cdef str combo_crc
        cdef bint log_fails = self.log_fails
        cdef list todo_list = self.todo_list

        while True:
            n = self.read_queue.get()
            if n is None:
                # self.read_queue.task_done()
                break
            for combo in map(''.join, itertools.product(permitted_chars, repeat=n)):
                # print(combo)
                combo_crc = crc32b(combo)
                if combo_crc in todo_list:
                    print("Found CRC for \"{}\": \"{}\"".format(combo, combo_crc))
                    self.write_queue.put(["good", combo_crc, combo])
                elif log_fails:
                    self.write_queue.put(["fail", combo_crc, combo])
           #  self.read_queue.task_done()



def do_the_things(str input_csv, str input_csv2, str output_csv, bint log_to_file, str log_file_path, bint log_fails, max_str_length, max_processes):
    assert crc32b('stuconfigvar') == 'BFD9AADD'

    s2 = time.time()
    for i in range(1000000):
        crc32b('hello')
    e2 = time.time()
    print("Time benchmark: {}".format(e2-s2))

    cdef list todo_list = []
    cdef bint should_log = log_file_path is not None and log_to_file
    cdef list fieldnames
    if should_log:
        open(log_file_path, 'w').close()  # clear

    with open(input_csv, 'r') as csv_file:
        reader = csv.DictReader(csv_file)
        todo_list.extend(d['Hash'] for d in filter(lambda x: x[' Name'] == ' N/A', list(reader)))

    with open(input_csv2, 'r') as csv_file2:
        reader2 = csv.DictReader(csv_file2)
        todo_list.extend(d['Hash'] for d in filter(lambda x: x[' Name'] == ' N/A', list(reader2)))

    # todo_list = [d['Hash'] for d in filter(lambda x: x[' Name'] != ' N/A', list(reader))]
    # [*filter(lambda x: x[' Name'] == ' N/A', list(reader))]
    print("TODO count: {}".format(len(todo_list)))

    fieldnames = ['Hash', 'Name']
    with open(output_csv, 'r') as output_csv_file:
        if os.fstat(output_csv_file.fileno()).st_size > 0:
            input("Warning: {} has data, are you sure? (press enter) ".format(output_csv))
    with open(output_csv, 'w') as output_csv_file:
        writer = csv.DictWriter(output_csv_file, fieldnames=fieldnames)
        if os.fstat(output_csv_file.fileno()).st_size == 0 or not csv.Sniffer().has_header(
                output_csv_file.read(1024)):
            writer.writeheader()

    write_queue = Queue()
    length_queue = Queue()
    #length_queue = JoinableQueue()

    processes = [WriterProcess(write_queue, log_file_path, should_log, output_csv)] + \
                [WorkerProcess(todo_list, length_queue, write_queue, log_fails) for i in range(max_processes-1)]

    for process in processes:
        process.start()

    for l in range(max_str_length):
        length_queue.put(l)

    for i in range(max_processes-1):
        length_queue.put(None)

    processes[0].join()
