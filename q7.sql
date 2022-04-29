-- Fraud Prevention

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Recommender;


-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS pastday CASCADE;
DROP VIEW IF EXISTS tobedeleted CASCADE;

-- Define views for your intermediate steps here:
create view pastday as
  SELECT pid, cid, d, cnumber,
  rank() OVER (PARTITION BY cnumber ORDER BY d) as num
  FROM purchase
  WHERE purchase.d BETWEEN NOW() - INTERVAL '24 HOURS' AND NOW()
  ORDER BY cnumber, purchase.d;

create view tobedeleted as
  select pid
  from pastday
  where num > 5;

-- Your SQL code that performs the necessary deletions goes here:

delete from lineitem where pid in (select * from tobedeleted);
delete from purchase where pid in (select * from tobedeleted);
