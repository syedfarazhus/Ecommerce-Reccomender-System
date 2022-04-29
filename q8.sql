-- SALE!SALE!SALE!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Recommender;


-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS allsales CASCADE;
DROP VIEW IF EXISTS onsale CASCADE;

-- Define views for your intermediate steps here:
create view allsales as
  select item.iid, price, sum(quantity) as sales
  from item, lineitem
  where item.iid = lineitem.iid
  group by item.iid
  order by sales desc;

create view onsale as
  select IID,
  case when price >= 10 and price <= 50 then 0.2
        when price > 50 and price <= 100 then 0.3
        when price > 100 then 0.5 end as discount
  from allsales
  where sales >= 10 and price >= 10;

-- Your SQL code that performs the necessary updates goes here:
update item
  set price = price - (price * onsale.discount)
  from onsale
  where item.iid = onsale.iid;
