import sys
import argparse
import subprocess

if len(sys.argv) == 1:
    pid = subprocess.Popen(['python', '-i', 'seed.py']).pid
else:

    parser = argparse.ArgumentParser()
    parser.add_argument("-c")
    parser.add_argument("-m")
    parser.add_argument("script")
    parsed, unknown = parser.parse_known_args()
    print(parsed, unknown)

    #pid = subprocess.Popen(['python'] + sys.argv).pid
