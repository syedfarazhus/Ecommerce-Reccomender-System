-- Hyperconsumers

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Recommender;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
    year TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT,
    items INTEGER NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS yearlysales CASCADE;
DROP VIEW IF EXISTS top5yearly CASCADE;
-- Define views for your intermediate steps here:

create view yearlysales as
  select extract(year from d) as year, purchase.cid, sum(lineitem.quantity) as units
  from purchase, lineitem, item
  where purchase.pid = lineitem.pid and LineItem.IID = item.iid
  group by year, purchase.cid
  order by year, units desc;

create view top5yearly as
  select year, cid, units, spot
  from
    (SELECT year, cid, units,
    rank() OVER (PARTITION BY year ORDER BY units DESC) as spot
    FROM yearlysales) as rankedsales
  where spot <= 5;

-- Your query that answers the question goes below the "insert into" line:
insert into q5
select year, firstname||' '||lastname as name, email, units
from top5yearly, customer
where top5yearly.cid = customer.cid
order by year, top5yearly.spot
