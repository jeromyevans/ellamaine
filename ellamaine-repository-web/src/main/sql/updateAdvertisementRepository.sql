-- migrate data for new indexes by date 21 August 2008
alter table advertisementrepository add column Datestamp DATE;
alter table advertisementrepository add column Year INTEGER;
alter table advertisementrepository add column Month INTEGER;
alter table advertisementrepository add column Day INTEGER;

update advertisementRepository
  set Datestamp = date(dateEntered),
      Year = year(dateEntered),
      Month = month (dateEntered),
      Day = day(dateEntered);



