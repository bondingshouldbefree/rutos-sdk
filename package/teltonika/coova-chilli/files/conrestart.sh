#!/bin/sh

[ -z "$KNAME" ] && exit

./etc/chilli/condown.sh
./etc/chilli/conup.sh

exit 0