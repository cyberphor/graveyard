-- create ProductCategory table
CREATE TABLE ProductCategory (
    ProductCategoryID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(255) NOT NULL
);

-- create Product table
CREATE TABLE Product (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(255) NOT NULL,
    ProductCategoryID INT,
    FOREIGN KEY (ProductCategoryID) REFERENCES ProductCategory(ProductCategoryID)
);

-- insert data into ProductCategory table
INSERT INTO ProductCategory (Name)
VALUES 
('Road Frames'),
('Helmets'),
('Socks'),
('Caps'),
('Jerseys');

-- insert data into Product table
INSERT INTO Product (Name, ProductCategoryID)
VALUES
('HL Road Frame - Black, 58', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('HL Road Frame - Red, 58', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('Sport-100 Helmet, Red', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Helmets')),
('Sport-100 Helmet, Black', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Helmets')),
('Mountain Bike Socks, M', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Socks')),
('Mountain Bike Socks, L', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Socks')),
('Sport-100 Helmet, Blue', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Helmets')),
('AWC Logo Cap', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Caps')),
('Long-Sleeve Logo Jersey, S', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Jerseys')),
('Long-Sleeve Logo Jersey, M', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Jerseys')),
('Long-Sleeve Logo Jersey, L', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Jerseys')),
('Long-Sleeve Logo Jersey, XL', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Jerseys')),
('HL Road Frame - Red, 62', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('HL Road Frame - Red, 44', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('HL Road Frame - Red, 48', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('HL Road Frame - Red, 52', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('HL Road Frame - Red, 56', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('LL Road Frame - Black, 58', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('LL Road Frame - Black, 60', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames')),
('LL Road Frame - Black, 62', (SELECT ProductCategoryID FROM ProductCategory WHERE Name = 'Road Frames'));