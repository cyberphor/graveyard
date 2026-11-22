SELECT TOP 20 ProductCategory.Name as CategoryName, Product.name as ProductName 
FROM ProductCategory
JOIN Product
ON ProductCategory.productcategoryid = Product.productcategoryid;