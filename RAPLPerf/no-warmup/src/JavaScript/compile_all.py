import sys
import os
from subprocess import call, Popen, PIPE

path = '.'
action = 'compile'


def file_exists(file_path):
    return os.path.isfile(file_path) if file_path else False


def main():
    for root, dirs, files in os.walk(path):
        print('Checking ' + root)
        makefile = os.path.join(root, "Makefile")
        if file_exists(makefile):
            cmd = f'cd {root} && make {action}'
            pipes = Popen(cmd, shell=True, stdout=PIPE, stderr=PIPE)
            std_out, std_err = pipes.communicate()

            # Decode with 'replace' to handle invalid UTF-8 bytes
            std_out = std_out.decode('utf-8', errors='replace')
            std_err = std_err.decode('utf-8', errors='replace')

            if action in ['compile', 'run']:
                if pipes.returncode != 0:
                    # An error happened!
                    err_msg = f"{std_err.strip()}. Code: {pipes.returncode}"
                    print(f'[E] Error on {root}: ')
                    print(err_msg)
                elif std_err:
                    # Return code is 0 (no error), but we may want to log the stderr output
                    print('[OK]')
                else:
                    print('[OK]')
        if action == 'measure':
            call(['sleep', '5'])


if __name__ == '__main__':
    if len(sys.argv) == 2:
        act = sys.argv[1]
        if act in ['compile', 'run', 'clean', 'measure']:
            print(f'Performing "{act}" action...')
            action = act
        else:
            print(f'Error: Unrecognized action "{act}"')
            sys.exit(1)
    else:
        print('Performing "compile" action...')
        action = 'compile'

    main()
