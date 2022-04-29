-- Helpfulness

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO Recommender;
DROP TABLE IF EXISTS q2 CASCADE;

create table q2(
    CID INTEGER,
    firstName TEXT NOT NULL,
    helpfulness_category TEXT
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.
DROP VIEW IF EXISTS revHelpfullness CASCADE;
DROP VIEW IF EXISTS RevHelpRatio CASCADE;
DROP VIEW IF EXISTS scoretable CASCADE;

-- Define views for your intermediate steps here:

-- gives the count for how many ppl thought a review was helpful and not helpful
-- for all reviews rated on helpfullness
create view revHelpfullness as
  select customer.cid, review.IID, sum(CAST(helpfulness AS int)) AS helpful,
  count(*)-sum(CAST(helpfulness AS int)) as nothelpfull
  from customer, review, helpfulness
  where customer.cid = review.cid and customer.cid = helpfulness.reviewer
  and helpfulness.iid = review.IID
  group by customer.cid, review.IID;

-- shows amount of helpfull reviews and total reviews of each customer rated
create view RevHelpRatio as
  select x.cid, sum(CAST(x.helpfulrev AS int)) AS NumHelpfulrev, count(y.total) as totalrev
  from
    (select revHelpfullness.cid, revHelpfullness.IID,
    case when helpful > nothelpfull then True else False end as helpfulrev
    from revHelpfullness) as x,
    (select review.cid, count(review.iid) as total from Review group by review.cid) as y
  where x.cid = y.cid
  group by x.cid;

--helpfullness score for all customers in the system
create view scoretable as
  (select RevHelpRatio.cid, customer.firstname,
  cast(NumHelpfulrev as decimal)/totalrev as helpscore
  from RevHelpRatio, Customer
  where RevHelpRatio.cid = Customer.cid)
    union
  (select Customer.cid, Customer.firstname, 0 as helpscore
  from Customer,
  ((select cid from Customer) except (select cid from RevHelpRatio)) as zerorated
  where Customer.cid = zerorated.cid);

-- Your query that answers the question goes below the "insert into" line:
insert into q2

select cid, firstname, case
                        when helpscore >= 0.8 then 'very helpful'
                        when helpscore < 0.5 then 'not helpful'
                        else 'somewhat helpful' end as helpfulness_category
from scoretable;
