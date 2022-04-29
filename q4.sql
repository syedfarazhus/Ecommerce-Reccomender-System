-- Best and Worst Categories

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Recommender;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
    month TEXT NOT NULL,
    highestCategory TEXT NOT NULL,
    highestSalesValue FLOAT NOT NULL,
    lowestCategory TEXT NOT NULL,
    lowestSalesValue FLOAT NOT NULL
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS Months CASCADE;
DROP VIEW IF EXISTS allmonthlysales CASCADE;
DROP VIEW IF EXISTS emptysales CASCADE;
DROP VIEW IF EXISTS salevaluemonthly CASCADE;
DROP VIEW IF EXISTS leftoverinmonth CASCADE;
DROP VIEW IF EXISTS bettersalesvalue CASCADE;
DROP VIEW IF EXISTS emptysalevalue CASCADE;
DROP VIEW IF EXISTS totalmonthlysales CASCADE;
DROP VIEW IF EXISTS salesrank CASCADE;
DROP VIEW IF EXISTS topsellers CASCADE;
DROP VIEW IF EXISTS bottomsellers CASCADE;
DROP VIEW IF EXISTS finaltable CASCADE;
DROP VIEW IF EXISTS charmonth CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW Months as
  select DATE '2021-01-01' +
  (interval '1' month * generate_series(0,11)) as mo;

create view allmonthlysales as
  select extract(month from mo) as mon,
  item.category, item.price,
  sum(quantity) as quan
  from months, purchase, lineitem, item
  where extract(month from mo) = extract(month from d)
  and 2020 = extract(year from d)
  and purchase.pid = lineitem.PID
  and lineitem.iid = item.iid
  group by mon, item.iid;

create view emptysales as
  select cat.category, 0.0 as sales
  from
  (select distinct category from item) as cat;

create view salevaluemonthly as
  select mon, category, sum(quan*price) as sales
  from allmonthlysales
  group by mon, category;

create view leftoverinmonth as
  select x.mo, x.category, 0.0 as sales
  from
      ((select distinct extract(month from months.mo) as mo ,
      emptysales.category
      from months, salevaluemonthly, emptysales
      where extract(month from months.mo)
      in (select mon from salevaluemonthly))
    except
      (select mon, category from salevaluemonthly)) as x;

create view bettersalesvalue as
  (select * from salevaluemonthly) union ( select * from leftoverinmonth);

create view emptysalevalue as
  select extract(month from months.mo) as mo, emptysales.*
  from months, emptysales
  where extract(month from months.mo) not in
  (select mon from salevaluemonthly)
  order by mo;

create view totalmonthlysales as
  (select * from bettersalesvalue) union (select * from emptysalevalue);

create view salesrank as
  select totalmonthlysales.*,
  rank() OVER (PARTITION BY mon ORDER BY sales DESC) as salerank,
  rank() OVER (PARTITION BY mon ORDER BY sales) as nosalerank
  from totalmonthlysales;

create view topsellers as
  select extract(month from mo) as mo, category as highestCategory,
  sales as highestSalesValue
  from months, salesrank
  where extract(month from mo) = salesrank.mon
  and salesrank.salerank = 1;

create view bottomsellers as
  select extract(month from mo) as mo, category as lowestCategory,
  sales as lowestSalesValue
  from months, salesrank
  where extract(month from mo) = salesrank.mon
  and salesrank.nosalerank = 1;

create view finaltable as
  select topsellers.mo,
  highestCategory, highestSalesValue,
  lowestCategory, lowestSalesValue
  from topsellers, bottomsellers
  where topsellers.mo = bottomsellers.mo;

CREATE VIEW charmonth as
  SELECT to_char(DATE '2014-01-01' +
    (interval '1 month' * generate_series(0,11)), 'MM') as monthaz;

-- Your query that answers the question goes below the "insert into" line:
insert into q4
  select monthaz,
  highestCategory, highestSalesValue,
  lowestCategory,lowestSalesValue
  from finaltable, charmonth
  where cast(monthaz as DOUBLE PRECISION) = mo;
