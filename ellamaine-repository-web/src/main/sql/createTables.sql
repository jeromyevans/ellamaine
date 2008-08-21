-- tables are created automatically by the perl application
-- use this for testing, but verify that it's consistent with the code

CREATE TABLE IF NOT EXISTS AdvertisementRepository
   (ID INTEGER ZEROFILL PRIMARY KEY AUTO_INCREMENT,
   DateEntered DATETIME NOT NULL,
   SourceURL TEXT,
   Datestamp DATE,
   Year INTEGER,
   Month INTEGER,
   Day INTEGER
   );

