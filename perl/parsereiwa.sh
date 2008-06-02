#!/bin/sh

# REIWA SALES
perl Ellamaine.pl "command=start\&config=reiwasales\&startrange=A\&endrange=Ga" &
perl sleeprand.pl 20
perl Ellamaine.pl "command=start\&config=reiwasales\&startrange=G\&endrange=Na" &
perl sleeprand.pl 20
perl Ellamaine.pl "command=start\&config=reiwasales\&startrange=N\&endrange=Ta" &
perl sleeprand.pl 20
perl Ellamaine.pl "command=start\&config=reiwasales\&startrange=T\&endrange=ZZ" &

# REIWA RENTALS
perl sleeprand.pl 30
perl Ellamaine.pl "command=start\&config=reiwarentals\&startrange=A\&endrange=Ga" &
perl sleeprand.pl 20
perl Ellamaine.pl "command=start\&config=reiwarentals\&startrange=G\&endrange=Na" &
perl sleeprand.pl 20
perl Ellamaine.pl "command=start\&config=reiwarentals\&startrange=N\&endrange=Ta" &
perl sleeprand.pl 20
perl Ellamaine.pl "command=start\&config=reiwarentals\&startrange=T\&endrange=ZZ" &
