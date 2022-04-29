-- Customer Apreciation Week

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Recommender;


-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS newitem CASCADE;
DROP VIEW IF EXISTS ydpurchase CASCADE;
DROP VIEW IF EXISTS giftto CASCADE;


-- Define views for your intermediate steps here:
create view newitem as
  select max(iid)+1 as iid,'Housewares' as category,
  'Company logo mug' as description, 0 as price
  from item;

insert into item
  select * from newitem;

create view ydpurchase as
  SELECT pid, cid, d, rank() OVER (PARTITION BY cid ORDER BY d) as num
  FROM purchase
  WHERE date(purchase.d) in (select date(now()-interval '1 day'));

create view giftto as
  select pid, max(iid) as iid, 1 as quantity
  from ydpurchase, item
  where num = 1
  group by pid;

-- Your SQL code that performs the necessary insertions goes here:
insert into lineitem select * from giftto;
