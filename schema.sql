-- Change nothing in this file.

DROP SCHEMA IF EXISTS Recommender CASCADE;
CREATE SCHEMA Recommender;
SET SEARCH_PATH TO Recommender;

-- An item for sale.
-- IID is the item's ID, category describes the kind of item it is, description
-- gives further details about the item, and price is its current price.
CREATE TABLE Item (
	IID INT,
	category TEXT NOT NULL,
	description TEXT NOT NULL,
	price FLOAT NOT NULL,
	PRIMARY KEY (IID)
);

-- A customer.
-- CID is the customer's ID, email is their email address, lastName and
-- firstName make up their name, and title is the title by which they prefer
-- to be addressed, e.g., 'Ms', 'Dr.'.  It may or may not include punctuation,
-- and could be any string the customer wishes -- it need not be a standard
-- title.
CREATE TABLE Customer (
	CID INT,
	email TEXT,
	lastName TEXT NOT NULL,
	firstName TEXT NOT NULL,
	title TEXT DEFAULT 'Customer',
	PRIMARY KEY(CID)
);

-- A purchase by a customer.
-- (This could also be called an "order", but order is a keyword in SQL.)
-- PID is the ID for this purchase, CID is the ID of the customer who made
-- the purchase, d is the date on which the purchase was made, cNumber is
-- the credit card (and card is the name of the credit card company) to
-- which the purchase was billed.
CREATE TABLE Purchase (
	PID INT,
	CID INT NOT NULL,
	d TIMESTAMP NOT NULL,
	cNumber INT NOT NULL,
	card TEXT NOT NULL,
	PRIMARY KEY (PID),
	FOREIGN KEY (CID) REFERENCES Customer(CID)
);

-- A line item on a particular purchase.
-- PID is the purchase ID, IID is the item that was ordered, quantity indicates
-- how many of it were ordered.  (For instance, a customer might order three
-- of the same t-shirt.)
CREATE TABLE LineItem (
	PID INT,
	IID INT,
	quantity INT NOT NULL,
	PRIMARY KEY(PID, IID),
	FOREIGN KEY (PID) REFERENCES Purchase(PID),
	FOREIGN KEY (IID) REFERENCES Item(IID)
);

-- A customer's review of an item.
-- CID is the ID of the customer who gave the review, IID is ID of the item
-- that they reviewed, number is a numeric rating, and comment is a review
-- comment that they may have given along with the rating.
CREATE TABLE Review (
	CID INT,
	IID INT,
	rating INT NOT NULL,
	comment TEXT,
	PRIMARY KEY (CID, IID),
	FOREIGN KEY (CID) REFERENCES Customer(CID),
	FOREIGN KEY (IID) REFERENCES Item(IID)
);

-- One customer's vote on the helpfulness of another customer's review.
-- reviewer is the ID of the customer whose review is being judged,
-- IID is the item they reviewed, observer is the ID of the customer
-- who is judging reviewer's review, and helpfulness indicates whether
-- observer found the review helpful.
CREATE TABLE Helpfulness (
	reviewer INT,
	IID INT,
	observer INT,
	helpfulness BOOLEAN NOT NULL,
	PRIMARY KEY (reviewer, IID, observer),
	FOREIGN KEY (reviewer) REFERENCES Customer(CID),
	FOREIGN KEY (IID) REFERENCES Item(IID),
	FOREIGN KEY (observer) REFERENCES Customer(CID),
	FOREIGN KEY (reviewer, IID) REFERENCES Review(CID, IID)
);

-- Derived tables used in part 3
CREATE TABLE Curator(
	CID INT PRIMARY KEY,
	FOREIGN KEY (CID) REFERENCES Customer(CID)
);

CREATE TABLE PopularItems(
	IID INT PRIMARY KEY,
	FOREIGN KEY (IID) REFERENCES Item(IID)
);

CREATE TABLE DefinitiveRatings(
	CID INT,
	IID INT,
	rating INT,
	PRIMARY KEY (CID, IID),
	FOREIGN KEY (IID) REFERENCES PopularItems(IID)
);
