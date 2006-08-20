

REM REIWA SALES
start "reiwasales:A-Ga" perl Ellamaine.pl "command=start&config=reiwasales&startrange=A&endrange=Ga";
perl sleeprand.pl 20
start "reiwasales:G-Na" perl Ellamaine.pl "command=start&config=reiwasales&startrange=G&endrange=Na";
perl sleeprand.pl 20
start "reiwasales:N-Ta" perl Ellamaine.pl "command=start&config=reiwasales&startrange=N&endrange=Ta";
perl sleeprand.pl 20
start "reiwasales:T-Zz" perl Ellamaine.pl "command=start&config=reiwasales&startrange=T&endrange=ZZ";

REM REIWA RENTALS
perl sleeprand.pl 30
start "reiwarentals:A-Ga" perl Ellamaine.pl "command=start&config=reiwarentals&startrange=A&endrange=Ga";
perl sleeprand.pl 20
start "reiwarentals:G-Na" perl Ellamaine.pl "command=start&config=reiwarentals&startrange=G&endrange=Na";
perl sleeprand.pl 20
start "reiwarentals:N-Ta" perl Ellamaine.pl "command=start&config=reiwarentals&startrange=N&endrange=Ta";
perl sleeprand.pl 20
start "reiwarentals:T-Zz" perl Ellamaine.pl "command=start&config=reiwarentals&startrange=T&endrange=ZZ";
