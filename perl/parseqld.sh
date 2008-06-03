#!/bin/sh
cd /var/lib/ellamaine/deploy

# REAL-ESTATE Sales
perl Ellamaine.pl command=start\&config=realestatesalesqld\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesqld\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesqld\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesqld\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesqld\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesqld\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesqld\&startrange=U\&endrange=ZZ &


# REAL-ESTATE Rentals
perl sleeprand.pl 30
perl Ellamaine.pl command=start\&config=realestaterentalsqld\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsqld\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsqld\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsqld\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsqld\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsqld\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsqld\&startrange=U\&endrange=ZZ &


# Domain Sales
perl sleeprand.pl 30
perl Ellamaine.pl command=start\&config=domainsalesqld\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesqld\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesqld\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesqld\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesqld\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesqld\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesqld\&startrange=U\&endrange=ZZ &


# Domain Rentals
perl sleeprand.pl 30
perl Ellamaine.pl command=start\&config=domainrentalsqld\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsqld\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsqld\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsqld\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsqld\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsqld\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsqld\&startrange=U\&endrange=ZZ &

