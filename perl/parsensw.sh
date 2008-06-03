#!/bin/sh
cd /var/lib/ellamaine/deploy

# REAL-ESTATE Sales
perl Ellamaine.pl command=start\&config=realestatesalesnsw\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesnsw\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesnsw\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesnsw\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesnsw\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesnsw\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesnsw\&startrange=U\&endrange=ZZ &


# REAL-ESTATE Rentals
perl sleeprand.pl 30
perl Ellamaine.pl command=start\&config=realestaterentalsnsw\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsnsw\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsnsw\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsnsw\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsnsw\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsnsw\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsnsw\&startrange=U\&endrange=ZZ &


# Domain Sales
perl sleeprand.pl 30
perl Ellamaine.pl command=start\&config=domainsalesnsw\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesnsw\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesnsw\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesnsw\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesnsw\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesnsw\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesnsw\&startrange=U\&endrange=ZZ &


# Domain Rentals
perl sleeprand.pl 30
perl Ellamaine.pl command=start\&config=domainrentalsnsw\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsnsw\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsnsw\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsnsw\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsnsw\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsnsw\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsnsw\&startrange=U\&endrange=ZZ &

