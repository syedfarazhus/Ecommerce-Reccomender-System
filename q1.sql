-- Unrated products.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Recommender;
DROP TABLE IF exists q1 CASCADE;

CREATE TABLE q1(
    CID INTEGER,
    firstName TEXT NOT NULL,
	lastName TEXT NOT NULL,
    email TEXT
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS norevitem CASCADE;
DROP VIEW IF EXISTS norevpurchase CASCADE;
DROP VIEW IF EXISTS CustofInterest CASCADE;

-- Define views for your intermediate steps here:

--all items that have no reviews
create view norevitem as
  (select iid from item) except (select iid from review);

--customer and item of every purchase of a non reviewed item
create view norevpurchase as
  select customer.cid, lineitem.iid
  from customer, purchase, lineitem
  where customer.cid = purchase.cid and purchase.pid = lineitem.PID and lineitem.IID in (select * from norevitem);

-- cid of customers who bought 3 different non rated items
CREATE view CustofInterest as
  select distinct t1.cid
  from norevpurchase t1, norevpurchase t2, norevpurchase t3
  where t1.cid = t2.cid and t2.cid = t3.cid and
  t1.iid <> t2.iid and t2.iid <> t3.iid and t1.iid <> t3.iid;


-- Your query that answers the question goes below the "insert into" line:
insert into q1
  select customer.cid, firstname, lastname, email
  from CustofInterest, customer
  where CustofInterest.cid = customer.cid;
