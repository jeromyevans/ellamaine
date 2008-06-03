#!/bin/sh
cd /var/lib/ellamaine/deploy

# REAL-ESTATE Sales
perl Ellamaine.pl command=start\&config=realestatesalesact\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesact\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesact\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesact\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesact\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesact\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestatesalesact\&startrange=U\&endrange=ZZ &


# REAL-ESTATE Rentals
perl sleeprand.pl 30
perl Ellamaine.pl command=start\&config=realestaterentalsact\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsact\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsact\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsact\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsact\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsact\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=realestaterentalsact\&startrange=U\&endrange=ZZ &


# Domain Sales
perl sleeprand.pl 30
perl Ellamaine.pl command=start\&config=domainsalesact\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesact\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesact\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesact\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesact\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesact\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainsalesact\&startrange=U\&endrange=ZZ &


# Domain Rentals
perl sleeprand.pl 30
perl Ellamaine.pl command=start\&config=domainrentalsact\&startrange=A\&endrange=D &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsact\&startrange=D\&endrange=G &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsact\&startrange=G\&endrange=J &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsact\&startrange=J\&endrange=N &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsact\&startrange=N\&endrange=Q &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsact\&startrange=Q\&endrange=U &
perl sleeprand.pl 20
perl Ellamaine.pl command=start\&config=domainrentalsact\&startrange=U\&endrange=ZZ &

