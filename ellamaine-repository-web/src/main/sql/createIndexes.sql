-- new indexes as of 21 August 2008
create index advertisementRepositoryByDate on advertisementRepository(Datestamp);
create index advertisementRepositoryByYearMonthDay on advertisementRepository(Year, Month, Day);
