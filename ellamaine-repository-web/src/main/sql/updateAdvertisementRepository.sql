-- migrate data for new indexes by date 21 August 2008
alter table advertisementrepository add column Datestamp DATE;
alter table advertisementrepository add column Year INTEGER;
alter table advertisementrepository add column Month INTEGER;
alter table advertisementrepository add column Day INTEGER;

update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered) where id < 10000000;
update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered) where id >= 1000000 and id < 2000000;
update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered) where id >= 2000000 and id < 3000000;
update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered) where id >= 3000000 and id < 4000000;
update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered) where id >= 4000000 and id < 5000000;
update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered) where id >= 5000000 and id < 6000000;
update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered) where id >= 6000000 and id < 7000000;
update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered) where id >= 7000000 and id < 8000000;
update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered) where id >= 8000000 and id < 9000000;
update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered) where id >= 9000000 and id < 10000000;
