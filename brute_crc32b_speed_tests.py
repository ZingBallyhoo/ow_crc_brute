import binascii
import time
import zlib


def crc32b(s):
    return hex(binascii.crc32(bytes(s.lower(), 'utf-8')) % (1 << 32)).strip('0x').upper()


def zlib_crc32(s):
    return hex(zlib.crc32(bytes(s.lower(), 'utf-8'))).strip('0x').upper()


if __name__ == "__main__":
    # test1
    s1 = time.time()
    for i in range(1000000):
        crc32b('hello')
    e1 = time.time()

    s2 = time.time()
    for i in range(1000000):
        zlib_crc32('hello')
    e2 = time.time()

    print(e1 - s1, e2-s2)
    # print(e2-s2)



