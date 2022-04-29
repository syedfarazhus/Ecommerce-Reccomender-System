-- Small sample dataset for Assignment 2.

-- Item(IID, category, description, price)
INSERT INTO Item VALUES
(0, 'toy', 'nerf gun', 40.00),
(1, 'Book', 'Cloud Atlas', 21.00),
(2, 'Book', 'A Thousand Splendid Suns', 14.00),
(3, 'Book', 'Homegoing', 22.00),
(4, 'Book', 'Trickster', 18.00),
(5, 'Toy', 'Lego Hogwarts School of Witchcraft and Wizardry', 99.00);

-- Customer(CID, email, lastName, firstName, title)
INSERT INTO Customer VALUES
(1550, NULL, 'Thegoonaz','Croraz', 'OG'),
(1599, 'g@g.com', 'Granger', 'Hermione', 'Ms'),
(1518, 'p@p.com', 'Potter', 'Harry', 'Mr'),
(1515, 'w@w.com', 'Weasley', 'Ron', 'Master'),
(1500, NULL, 'Dumbledor', 'Albus', 'Professor');

-- Purchase(PID, CID, d, cNumber, card)
INSERT INTO Purchase VALUES
(98, 1550,'2021-01-01', 99999, 'Mastercard'),
(99, 1599, '2019-11-01', 12345, 'Amex'),
(100, 1515, '2019-11-01', 12345, 'Amex'),
(101, 1500, '2019-11-01', 64210, 'Visa'),
(102, 1518, '2021-01-01', 99999, 'Mastercard');

-- LineItem(PID, IID, quantity)
INSERT INTO LineItem VALUES
(98, 1, 1),
(98, 2, 1),
(98, 3, 1),
(98, 4, 1),
(99, 1, 1),
(99, 2, 1),
(99, 3, 1),
(99, 4, 1),
(101, 5, 1),
(100, 4, 1),
(100, 1, 2),
(100, 3, 2),
(100, 5, 1),
(101, 2, 4),
(102, 3, 10);

-- Review(CID, IID, rating, comment)
INSERT INTO Review VALUES
(1599, 2, 4, 'nice'),
(1599, 3, 4, NULL),
(1550, 1, 5 ,'fire'),
(1550, 2, 5 ,'fire'),
(1550, 3, 5 ,'fire'),
(1550, 4, 5 ,'fire'),
(1515, 5, 3, NULL),
(1515, 1, 4, 'A CLASSIC!'),
(1515, 4, 5, 'Fantastic read!'),
(1500, 5, 5, 'just like home'),
(1518, 4, 5, 'Ron said it was fantastic and he was right!!!');

-- Helpfulness(reviewer, IID, observer, helpfulness)
INSERT INTO Helpfulness VALUES
(1515, 1, 1500, False),
(1515, 4, 1599, False),
(1515, 4, 1518, True),
(1515, 4, 1515, True),
(1515, 4, 1500, True),
(1518, 4, 1599, True),
(1518, 4, 1515, True),
(1518, 4, 1500, False);
