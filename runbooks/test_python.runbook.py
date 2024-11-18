import os

print(os.popen("whoami").read().strip())