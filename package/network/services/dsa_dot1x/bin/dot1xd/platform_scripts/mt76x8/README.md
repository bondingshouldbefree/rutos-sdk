# mt76x8 .1x port blocker
hostapd is attached to a virtual 802.1x port, the aim with it is to simulate DSA, as 802.1x is a port-based protocol.

## block port flow
- a blocked port is moved into an "isolated" vlan where it is by itself, so packets could only go to the cpu.
- a tc rule is installed to redirect all .1x packets from the specific isolated vlan to the virtual .1x port.
- a tc rule is installed on the virtual .1x port to mirror packets back to the original interface.
- another tc rule is installed to drop all other packets from the isolated vlan.

## unblock port flow
- old blocking tc rules are deleted.
- a new tc rule is created to copy packets of authorized sMAC to virtual .1x port.
- port is moved from the isolation vlan into the requested accept vlan.


# lua capability wrapper

from https://www.in-ulm.de/~mascheck/various/shebang/#setuid
> The setuid/gid-bit became ignored on many systems for security reasons.
 This is mainly due to the race condition between the kernel starting the interpreter and
 the interpreter starting the script: meanwhile, you could replace the script.

Running a C program with ambient capabilties that simply runs a lua file is prone to the same security issues.

This runner has the lua code embedded directly in the binary, which means it is impossible to replace it.

For convenienve the lua code is stored in mt76x8.lua and embedded into the binary at compile time.
