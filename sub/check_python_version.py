import platform
import sys
if int(platform.python_version()[0])==3:
	sys.exit(0)
else:
	sys.exit(1)
