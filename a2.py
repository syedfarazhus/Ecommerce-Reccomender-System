"""
A recommender for online shopping.
csc343, Fall 2021
University of Toronto.

--------------------------------------------------------------------------------
This file is Copyright (c) 2021 Diane Horton and Emily Franklin.
All forms of distribution, whether as given or with any changes, are
expressly prohibited.
--------------------------------------------------------------------------------
"""
from typing import List, Optional
import psycopg2 as pg
from psycopg2._psycopg import cursor

from ratings import RatingsTable


class Recommender:
    """A simple recommender that can work with data conforming to the schema in
    schema.sql.

    === Instance Attributes ===
    dbConnection: Connection to a database of online purchases and product
        recommendations.

    Representation invariants:
    - The database to which dbConnection is connected conforms to the schema
      in schema.sql.
    """

    def __init__(self) -> None:
        """Initialize this Recommender, with no database connection yet.
        """
        self.db_conn = None

    def connect_db(self, url: str, username: str, pword: str) -> bool:
        """Connect to the database at url and for username, and set the
        search_path to "recommender". Return True iff the connection was made
        successfully.

        >>> rec = Recommender()
        >>> # This example will make sense if you change the arguments as
        >>> # appropriate for you.
        >>> rec.connect_db("csc343h-dianeh", "dianeh", "")
        True
        >>> rec.connect_db("test", "postgres", "password") # test doesn't exist
        False
        """
        try:
            self.db_conn = pg.connect(dbname=url, user=username, password=pword,
                                      options="-c search_path=recommender")
        except pg.Error:
            return False

        return True

    def disconnect_db(self) -> bool:
        """Return True iff the connection to the database was closed
        successfully.

        >>> rec = Recommender()
        >>> # This example will make sense if you change the arguments as
        >>> # appropriate for you.
        >>> rec.connect_db("csc343h-dianeh", "dianeh", "")
        True
        >>> rec.disconnect_db()
        True
        """
        try:
            self.db_conn.close()
        except pg.Error:
            return False

        return True

    def recommend_generic(self, k: int) -> Optional[List[int]]:
        """Return the item IDs of recommended items. An item is recommended if
        its average rating is among the top k average ratings for items in the
        PopularItems table.

        If there are not enough rated popular items, there may be fewer than
        k items in the returned list.  If there are ties among the highly
        rated popular items, there may be more than k items that could be
        returned. (This is similar to the hyperconsumers query in Part 1.)
        In that case, order these items by item ID (lowest to highest) and
        take the lowest k.  The net effect is that the number of items returned
        will be <= k.

        If an error is raised, return None.

        Preconditions:
        - Repopulate has been called at least once.
          (Do not call repopulate in this method.)
        - k > 0
        """
        try:
            pop_items = []
            rec_items = []
            cur = self.db_conn.cursor()

            cur.execute('select review.iid, avg(rating) as avgrating '
                        'from PopularItems, review '
                        'where PopularItems.iid = review.iID '
                        'group by review.iid '
                        'order by avgrating desc;')

            for record in cur:
                pop_items.append((record[0], record[1]))

            if len(pop_items) > k:
                pop_items = \
                    sorted(pop_items,
                           key=lambda element: (-element[1], element[0]))
                pop_items = pop_items[0:k]

            cur.close()

            for t in pop_items:
                rec_items.append(t[0])
            return rec_items

        except pg.Error:
            return None

    def recommend(self, cust: int, k: int) -> Optional[List[int]]:
        """Return the item IDs of items that are recommended for the customer
        with customer ID cust.

        Choose the recommendations as follows:
        - Find the curator whose whose ratings of the 2 most-sold items in
          each category (according to PopularItems) are most similar to the
          customer’s own ratings on these same items.
          HINT: Fill a RatingsTable with the appropriate information and call
          function find_similar_curator.
        - Recommend products that this curator has rated highest. Include
          up to k items, and only items that cust has not bought.

        If there are not enough products rated by this curator, there may be
        fewer than k items in the returned list.  If there are ties among their
        top-rated items, there may be more than k items that could be
        returned. (This is similar to the hyperconsumers query in Part 1.)
        In that case, order these items by item ID (lowest to highest) and
        take the lowest k.  The net effect is that the number of items returned
        will be <= k.

        You will need to put the ratings of all curators on PopularItems into
        your RatingsTable. Get these ratings from the snapshot that is
        currently stored in table DefinitiveRatings.

        If the customer does not have any ratings in common with any of the
        curators (so no similar curator could be found), or if the customer
        has already bought all of the items that are highly recommended by
        their similar curator, then return generic recommendations.

        If an error is raised, return None.

        Preconditions:
        - Repopulate has been called at least once.
          (Do not call repopulate in this method.)
        - k > 0
        - cust is a CID that exists in the database.
        """
        try:
            cur = self.db_conn.cursor()
            rec_tuples = []
            rec_items = []

            similar_curator = most_similar(cust, cur)
            if similar_curator is None:
                return self.recommend_generic(k)

            q = 'select iid, rating ' \
                'from review ' \
                'where cid = {0} and iid not in ' \
                '(select lineitem.iid ' \
                'from purchase, lineitem, item ' \
                'where purchase.pid = lineitem.pid ' \
                'and LineItem.IID = item.iid ' \
                'and purchase.cid = {1}) ' \
                'order by rating desc;'.format(similar_curator, cust)
            cur.execute(q)
            rec_tuples = cur.fetchall()

            cur.close()

            if len(rec_tuples) == 0:
                return self.recommend_generic(k)
            elif len(rec_tuples) > k:
                rec_tuples = \
                    sorted(rec_tuples,
                           key=lambda element: (-element[1], element[0]))
                rec_tuples = rec_tuples[0:k]

            for t in rec_tuples:
                rec_items.append(t[0])
            return rec_items

        except pg.Error:
            return None

    def repopulate(self) -> int:
        """Repopulate the database tables that store a snapshot of information
        derived from the base tables: PopularItems and DefinitiveRatings.

        Remove all tuples from these tables and regenerate their content based
        on the current contents of the database. Return 0 if repopulate is
        successful and -1 if there are any errors.

        The meaning of the snapshot tables, and hence what should be in them:
        - PopularItems: The IID of the two items from each category that have
          sold the highest number of units among all items in that category.
        - DefinitiveRatings: The ratings given by curators on the items in the
          PopularItems table.
        """
        try:
            cur = self.db_conn.cursor()

            cur.execute('truncate PopularItems cascade;')
            self.db_conn.commit()

            cur.execute('DROP VIEW IF EXISTS itemsales cascade; '
                        'DROP VIEW IF EXISTS topseller cascade; '
                        'DROP VIEW IF EXISTS nottop cascade; '
                        'DROP VIEW IF EXISTS secondtopseller cascade; ')

            cur.execute('create view itemsales as '
                        'select item.iid, category, sum(quantity) as sales '
                        'from item, lineitem '
                        'where item.iid = lineitem.iid '
                        'group by item.iid '
                        'order by sales desc; '
                        'create view topseller as '
                        'select t1.iid, t1.category, t1.sales '
                        'from itemsales t1 '
                        'where t1.sales = (select max(t2.sales) '
                        'from itemsales t2 '
                        'where t2.category = t1.category); '
                        'create view nottop as '
                        '(select * from itemsales) '
                        'except (select * from topseller); '
                        'create view secondtopseller as '
                        'select t1.iid, t1.category, t1.sales '
                        'from nottop t1 '
                        'where t1.sales = (select max(t2.sales) '
                        'from nottop t2 '
                        'where t2.category = t1.category); '
                        '(select * from topseller) '
                        'union (select * from secondtopseller);')

            new_pop = cur.fetchall()
            for it in new_pop:
                query1 = 'Insert into PopularItems values ({0});'.format(it[0])
                cur.execute(query1)
            self.db_conn.commit()

            cur.execute('select Curator.cid, popularitems.iid, review.rating '
                        'from popularitems, Curator, review '
                        'where popularitems.iid = review.iid '
                        'and review.cid = Curator.cid;')

            new_defrat = cur.fetchall()
            for it in new_defrat:
                query2 = 'Insert into DefinitiveRatings values ({0},{1},{2})' \
                         ''.format(it[0], it[1], it[2])
                cur.execute(query2)
            self.db_conn.commit()

            cur.close()

        except pg.Error:
            return -1


# NB: This is defined outside of the class, so it is a function rather than
# a method.

def most_similar(cust: int, c: cursor):
    """Helper for recommend to built ratings table
    and find most similar curator
    """
    customers = []
    curators = []
    items = []

    c.execute('select cid from curator;')
    for i in c:
        curators.append(i[0])

    q = '(select * from definitiveratings) union ' \
        '(select cid, popularitems.iid, rating ' \
        'from popularitems, review ' \
        'where popularitems.iid = review.iid ' \
        'and review.cid = {0});'.format(cust)
    c.execute(q)
    all_ratings = c.fetchall()

    for row in all_ratings:
        if row[0] not in customers:
            customers.append(row[0])
        if row[1] not in items:
            items.append(row[1])

    max_r = len(customers)
    max_i = len(items)
    rate_table = RatingsTable(max_r, max_i)
    for tup in all_ratings:
        rate_table.set_rating(tup[0], tup[1], tup[2])

    return find_similar_curator(rate_table, curators, cust)


def find_similar_curator(ratings: RatingsTable,
                         curator_ids: List[int],
                         cust_id: int) -> Optional[int]:
    """Return the id of the curator who is most similar to the customer
    with iD cust_id based on their ratings, or None if the customer and curators
    have no ratings in common.

    The difference between two customers c1 anc c2 is determined as follows:
    For each pair of ratings by the two customers on the same item, we compute
    the difference between ratings. The overall difference between two customers
    is the average of these ratings differences.

    Preconditions:
    - ratings.get_all_ratings(cust_id) is not None
      That is, cust_id is in the ratings table.
    - For all cid in curator_ids, ratings.get_all_ratings(cid) is not None
      That is, all the curators are in the ratings table.
    """
    cust_rating = ratings.get_all_ratings(cust_id)

    min_curator = None
    min_diff = float('inf')

    for curator in curator_ids:
        cur_rating = ratings.get_all_ratings(curator)

        diff_sum = 0
        num_rtings = 0
        for i in range(len(cur_rating)):
            if cur_rating[i] is not None and cust_rating[i] is not None:
                diff_sum += abs(cur_rating[i] - cust_rating[i])
                num_rtings += 1

        if num_rtings != 0:
            diff = diff_sum / num_rtings
            if diff < min_diff:
                min_diff = diff
                min_curator = curator

    return min_curator


def sample_testing_function() -> None:
    rec = Recommender()
    # TODO: Change this to connect to your own database:
    rec.connect_db("csc343h-dianeh", "dianeh", "")
    # TODO: Test one or more methods here.


if __name__ == '__main__':
    # TODO: Put your testing code here, or call testing functions such as
    # this one:
    # sample_testing_function()

    rec = Recommender()
    rec.connect_db("csc343h-hussa790", "hussa790", "")
    cur = rec.db_conn.cursor()

    print(rec.recommend(1599, 3))
