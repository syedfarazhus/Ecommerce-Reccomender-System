SET SEARCH_PATH TO Recommender;
DROP TABLE IF EXISTS newpopularitems CASCADE;

create view itemsales as
  select item.iid, category, sum(quantity) as sales
  from item, lineitem
  where item.iid = lineitem.iid
  group by item.iid
  order by sales desc;

create view topseller as
  select t1.iid, t1.category, t1.sales
  from itemsales t1
  where t1.sales = (select max(t2.sales)
                    from itemsales t2
                    where t2.category = t1.category);

create view nottop as
  (select * from itemsales) except (select * from topseller);

create view secondtopseller as
  select t1.iid, t1.category, t1.sales
  from nottop t1
  where t1.sales = (select max(t2.sales)
                    from nottop t2
                    where t2.category = t1.category);

create view newpopularitems as
  (select * from topseller) union (select * from secondtopseller);
