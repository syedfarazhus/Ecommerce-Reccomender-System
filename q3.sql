-- Curators

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Recommender;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    CID INT NOT NULL,
    categoryName TEXT NOT NULL,
    PRIMARY KEY(CID, categoryName)
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS custcat CASCADE;
DROP VIEW IF EXISTS shouldbought CASCADE;
DROP VIEW IF EXISTS didbuy CASCADE;
DROP VIEW IF EXISTS notBuyCurator CASCADE;
DROP VIEW IF EXISTS buyCurator CASCADE;
DROP VIEW IF EXISTS shouldreviewed CASCADE;
DROP VIEW IF EXISTS didreview CASCADE;
DROP VIEW IF EXISTS notRevCurator CASCADE;

-- Define views for your intermediate steps here:

-- all combinations of cid and category
create view custcat as
  select cid, cat.category
  from customer, (select distinct category from item) as cat;

-- all the customers and all the items for each category
-- what should have happen for each category
create view shouldbought as
  select customer.cid, item.iid, item.category
  from item, customer
  order by cid, category, iid;

-- all the items that the customers actually did buy
create view didbuy as
  select purchase.cid, lineitem.iid, item.category
  from purchase, lineitem, item
  where purchase.pid = lineitem.pid and LineItem.IID = item.iid;

create view notBuyCurator as
  (select * from shouldbought) except (select * from didbuy)
  order by cid, category, iid;

create view buyCurator as
  (select * from custcat) except (select cid, category from notbuycurator);

create view shouldreviewed as
  select cid, buycurator.category, IID
  from buycurator, item
  where buycurator.category = item.category;

create view didreview as
  select buyCurator.cid, item.category, item.iid
  from review, buyCurator, item
  where review.cid = buyCurator.cid and comment is not NULL and review.iid = item.iid
  order by cid, category;

create view notRevCurator as
  select distinct i.cid, i.category
  from
  ((select * from shouldreviewed) except (select * from didreview)) as i;

-- Your query that answers the question goes below the "insert into" line:
insert into q3
(select * from buyCurator) except (select * from notRevCurator);
