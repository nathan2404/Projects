Use Mint_Classic_Project;

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

----------------------------All Product Names and Classifications situated in all warehouses-----------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Select P.productCode,P.productName,P.productLine, P.productScale, W.warehousename, W.warehouseCode 
From Products as P
Inner Join Warehouses as W on W.warehouseCode = P.warehouseCode
Order by warehouseCode , productLine;


--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

----------------------------------------Products present in orders------------------------------------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


Select P.productCode , P.productname,P.productline, P.warehousecode ,OD.orderNumber  
From Products as P
Inner Join OrderDetails as OD on P.productcode = OD.productCode
Order by productLine, warehouseCode;



--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

-----------------------------------------Products not present in any orders---------------------------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Select P.productCode, P.productname,P.productline, P.quantityInStock, P.warehousecode, OD.orderNumber
From Products as P
Left outer Join OrderDetails as OD on P.productcode = OD.productCode
Where orderNumber is Null
Order by productLine, warehouseCode;


--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

-------------------Total Count All Product Names and Classifications situated in all warehouses--------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Select P.productLine, W.warehousename, W.warehouseCode,Count(P.productCode) as 'Number_of Products_Per_Warehouse', W.warehousePctCap 
From Products as P
Inner Join Warehouses as W on W.warehouseCode = P.warehouseCode
Group by productLine, W.warehouseCode, W.warehouseName,W.warehousePctCap
Order by warehouseCode , productLine;

With Piv_Product_Line
as
(
	Select P.productLine, W.warehouseCode, P.productCode
	From Products as P
	Inner Join Warehouses as W on W.warehouseCode = P.warehouseCode
)
	Select productLine as 'Product Line', A, B, C, D
	from Piv_Product_Line as PPL
		Pivot(Count(productcode)
			For warehousecode in (a,b,c,d)) as H 


--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

----------------------------Quantity Sold as Per Order ID and Per Item---------------------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Select OD.ordernumber,OD.productcode, P.productname,OD.quantityOrdered,P.productline, P.warehousecode
From OrderDetails as OD
Inner Join Products as P on P.productcode = OD.productCode
Order by productLine, warehouseCode;

-------------------------------------------------------------------------------------------------------------
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

------------------------------Total Quantity Sold as Per Product--------------------------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Select OD.productcode, P.productname, Sum(OD.quantityOrdered) as 'Total_QTY_Sold',P.productline, P.warehousecode
From OrderDetails as OD
Inner Join Products as P on P.productcode = OD.productCode
Group By productName, OD.productCode, productLine, warehouseCode
Order by productLine, warehouseCode;

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

----------------------Time Period in between Orders that each individual customer orders------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX


With Nxt_Orddate
as
(
	Select customernumber,ordernumber, orderdate as 'orderdate', 
		LEAD(Orderdate) Over W as 'Next_Orderdate'
	From Orders
	Window W as (Partition by customerNumber
					Order by Orderdate, ordernumber) 

)


Select customernumber, ordernumber , [orderdate],[Next_Orderdate], 
	DATEDIFF(Day,[orderdate],[Next_Orderdate]) as 'Days_Difference'

From Nxt_Orddate;

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

-------------------------Average Time Period Between Orders In Days---------------------------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
With Nxt_Orddate
as
(
	Select customernumber,ordernumber, orderdate as 'orderdate', 
		LEAD(Orderdate) Over W as 'Next_Orderdate'
	From Orders
	Window W as (Partition by customerNumber
					Order by Orderdate, ordernumber) 

)
,
Day_Diff
as
(
	Select customernumber, ordernumber , [orderdate],[Next_Orderdate], 
	DATEDIFF(Day,[orderdate],[Next_Orderdate]) as 'Days_Difference'
	From Nxt_Orddate

)

Select customerNumber,
		AVG([Days_Difference]) as 'AVG_Ordering_In_Days'
From Day_Diff
Group by customerNumber;


--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

------------------------------------------Stock Anomalies---------------------------------------------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Select  P.productCode,   P.productname, P.productline, P.buyPrice, 
			Sum(OD.quantityOrdered) as 'Total_Qty_Sold', P.quantityinstock as 'Qty_In_Stock'
	
From OrderDetails as OD
Inner Join Products as P on P.productcode = OD.productCode
Group By P.productCode,P.productName, P.productLine ,P.quantityinstock,P.buyPrice
Having Sum(quantityOrdered) > quantityInStock
Order by productline;

/*

Create View Stock_Anomalies
as
Select  P.productCode,   P.productname, P.productline, P.buyPrice, 
			Sum(OD.quantityOrdered) as 'Total_Qty_Sold', P.quantityinstock as 'Qty_In_Stock'
	
From OrderDetails as OD
Inner Join Products as P on P.productcode = OD.productCode
Group By P.productCode,P.productName, P.productLine ,P.quantityinstock,P.buyPrice
Having Sum(quantityOrdered) > quantityInStock;

*/

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

------------------------------------------Checking the Order Status of All Stock Anomalies-------------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Select OD.ordernumber,
					DENSE_RANK() Over(Order by OD.productCode) as 'Prod_Code_Num',
					P.productcode,P.productline, P.productname,OD.quantityOrdered,P.quantityInStock , 
			O.orderdate, O.requireddate, O.shippeddate, O.status, O.comments
From OrderDetails as OD
Inner Join Products as P on P.productcode = OD.productCode
Inner Join Orders as O on O.orderNumber = OD.orderNumber
Where P.productCode in (Select productCode from Stock_Anomalies)
Order by [Prod_Code_Num];

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

----------------------------Stock Movement(Period of Less than 100 days and more than 400 days) of All Products Per Warehouse-------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

-- Use the Having Clause and select the warehouse (A, B, C and D) 

With Nxt_Orddate
as
(
	Select customernumber,ordernumber, orderdate as 'orderdate', 
		LEAD(Orderdate) Over W as 'Next_Orderdate'
	From Orders
	Window W as (Partition by customerNumber
					Order by Orderdate, ordernumber) 

)
,
Day_and_Month_Diff
as
(
	Select customernumber, ordernumber , [orderdate],[Next_Orderdate], 
	DATEDIFF(Day,[orderdate],[Next_Orderdate]) as 'Days_Difference',
	DATEDIFF(MONTH,[orderdate],[Next_Orderdate]) as 'Months_Difference'
	From Nxt_Orddate

)

Select  customernumber, Day_and_Month_Diff.ordernumber , 
					[orderdate],[Next_Orderdate],[Days_Difference],[Months_Difference],
											OD.productcode, P.productname,P.productLine,OD.quantityOrdered, P.warehouseCode
From Day_and_Month_Diff
Inner Join OrderDetails as OD on OD.orderNumber = Day_and_Month_Diff.orderNumber
Inner Join Products as P on OD.productCode = P.productCode
Where Days_Difference < 100 or Days_Difference > 400
Group by customernumber, Day_and_Month_Diff.ordernumber ,[orderdate],[Next_Orderdate],[Days_Difference],[Months_Difference],
			OD.productcode, P.productname,P.productLine,OD.quantityOrdered, P.warehouseCode
Having warehouseCode = 'D'
Order by Days_Difference Desc;


--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

------------------------------The minimum days between orders for the applicable Products ----------------------------------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

With Nxt_Orddate
as
(
	Select customernumber,ordernumber, orderdate as 'orderdate', 
		LEAD(Orderdate) Over W as 'Next_Orderdate'
	From Orders
	Window W as (Partition by customerNumber
					Order by Orderdate, ordernumber) 

)
,
Day_and_Month_Diff
as
(
	Select customernumber, ordernumber , [orderdate],[Next_Orderdate], 
	DATEDIFF(Day,[orderdate],[Next_Orderdate]) as 'Days_Difference',
	DATEDIFF(MONTH,[orderdate],[Next_Orderdate]) as 'Months_Difference'
	From Nxt_Orddate

)

Select  customernumber, Day_and_Month_Diff.ordernumber , 
					[orderdate],[Next_Orderdate],([Days_Difference]),[Months_Difference],
											OD.productcode, P.productname,P.productLine,OD.quantityOrdered, P.warehouseCode
From Day_and_Month_Diff
Inner Join OrderDetails as OD on OD.orderNumber = Day_and_Month_Diff.orderNumber
Inner Join Products as P on OD.productCode = P.productCode
Where Days_Difference < 100 or Days_Difference > 400
Group by customernumber, Day_and_Month_Diff.ordernumber ,[orderdate],[Next_Orderdate],[Days_Difference],[Months_Difference],
			OD.productcode, P.productname,P.productLine,OD.quantityOrdered, P.warehouseCode
Having Days_Difference in (Select Min([Days_Difference]) 
								From Day_and_Month_Diff)
Order by Days_Difference Desc , productLine;

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

---------------------------------Total Revenue Per Product and Total Revenue for Qty In Stock ------------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

With Revenue_Eva_Per_Product
As
(
	Select  P.productCode,   P.productname, P.productline, P.buyPrice, 

		Sum(OD.quantityOrdered) as 'Total_Qty_Sold', 
			
			P.quantityinstock as 'Qty_In_Stock'
	
	From OrderDetails as OD
	Inner Join Products as P on P.productcode = OD.productCode
	Group By P.productCode,P.productName, P.productLine ,P.quantityinstock,P.buyPrice


),

Total_Rev
as
(

	Select ROW_NUMBER() Over(Order by productline) as 'Number_Identifier',

		productcode , productname, productline, [Total_Qty_Sold], 
			
			[Total_Qty_Sold] * buyPrice as 'Total_Revenue_Per_Product',
			[Qty_In_Stock] * buyPrice as 'Qty_On_Hand_Revenue'  , 
			[Qty_In_Stock]
	
	From Revenue_Eva_Per_Product
	Group By productName, productCode, productLine,[Total_Qty_Sold], [Qty_In_Stock], buyPrice 

	
)
	Select  [Number_Identifier], productname, productcode, productline, [Total_Qty_Sold],  [Total_Revenue_Per_Product], 
			 
			 Sum([Total_Revenue_Per_Product]) Over(Order by [Number_Identifier]
														Rows between Unbounded Preceding
															and Current Row) as 'Revenue_Tally',
			[Qty_In_Stock],
			[Qty_On_Hand_Revenue],
			
			Sum([Qty_On_Hand_Revenue])			Over (Order by [Number_Identifier]
															Rows between Unbounded Preceding 
															and Current Row) as 'Revenue_In_Stock_Tally'
			 
From Total_Rev
Group By [Number_Identifier], productName,productCode, productLine,
				[Total_Qty_Sold],[Total_Revenue_Per_Product], 
					[Qty_In_Stock], [Qty_On_Hand_Revenue] 
Order by [Number_Identifier], productline;

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

--------------------Total Revenue Per Product and Total Revenue for Qty In Stock without Stock Anomalies-----------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

With Revenue_Eva_Per_Product
As
(
	Select  P.productCode,   P.productname, P.productline, P.buyPrice, 

		Sum(OD.quantityOrdered) as 'Total_Qty_Sold', 
			
			P.quantityinstock as 'Qty_In_Stock'
	
	From OrderDetails as OD
	Inner Join Products as P on P.productcode = OD.productCode
	Group By P.productCode,P.productName, P.productLine ,P.quantityinstock,P.buyPrice


),

Total_Rev
as
(

	Select ROW_NUMBER() Over(Order by productline) as 'Number_Identifier',

		productcode , productname, productline, [Total_Qty_Sold], 
			
			[Total_Qty_Sold] * buyPrice as 'Total_Revenue_Per_Product',
			[Qty_In_Stock] * buyPrice as 'Qty_On_Hand_Revenue'  , 
			[Qty_In_Stock]
	
	From Revenue_Eva_Per_Product
	Group By productName, productCode, productLine,[Total_Qty_Sold], [Qty_In_Stock], buyPrice 

	
)
	Select  [Number_Identifier], productname, productcode, productline, [Total_Qty_Sold],  [Total_Revenue_Per_Product], 
			 
			 Sum([Total_Revenue_Per_Product]) Over(Order by [Number_Identifier]
														Rows between Unbounded Preceding
															and Current Row) as 'Revenue_Tally',
			[Qty_In_Stock],
			[Qty_On_Hand_Revenue],
			
			Sum([Qty_On_Hand_Revenue])			Over (Order by [Number_Identifier]
															Rows between Unbounded Preceding 
															and Current Row) as 'Revenue_In_Stock_Tally'
			 
From Total_Rev
Where productCode not in (Select productCode from Stock_Anomalies)
Group By [Number_Identifier], productName,productCode, productLine,
				[Total_Qty_Sold],[Total_Revenue_Per_Product], 
					[Qty_In_Stock], [Qty_On_Hand_Revenue] 
Order by [Number_Identifier], productline;

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

----------------------Total Revenue Per Product and Total Revenue for Qty In Stock for Stock Anomalies-------------------------

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

With Revenue_Eva_Per_Product
As
(
	Select  P.productCode,   P.productname, P.productline, P.buyPrice, 

		Sum(OD.quantityOrdered) as 'Total_Qty_Sold', 
			
			P.quantityinstock as 'Qty_In_Stock'
	
	From OrderDetails as OD
	Inner Join Products as P on P.productcode = OD.productCode
	Group By P.productCode,P.productName, P.productLine ,P.quantityinstock,P.buyPrice


),

Total_Rev
as
(

	Select ROW_NUMBER() Over(Order by productline) as 'Number_Identifier',

		productcode , productname, productline, [Total_Qty_Sold], 
			
			[Total_Qty_Sold] * buyPrice as 'Total_Revenue_Per_Product',
			[Qty_In_Stock] * buyPrice as 'Qty_On_Hand_Revenue'  , 
			[Qty_In_Stock]
	
	From Revenue_Eva_Per_Product
	Group By productName, productCode, productLine,[Total_Qty_Sold], [Qty_In_Stock], buyPrice 

	
)
	Select  [Number_Identifier], productname, productcode, productline, [Total_Qty_Sold],  [Total_Revenue_Per_Product], 
			 
			 Sum([Total_Revenue_Per_Product]) Over(Order by [Number_Identifier]
														Rows between Unbounded Preceding
															and Current Row) as 'Revenue_Tally',
			[Qty_In_Stock],
			[Qty_On_Hand_Revenue],
			
			Sum([Qty_On_Hand_Revenue])			Over (Order by [Number_Identifier]
															Rows between Unbounded Preceding 
															and Current Row) as 'Revenue_In_Stock_Tally'
			 
From Total_Rev
Group By [Number_Identifier], productName,productCode, productLine,
				[Total_Qty_Sold],[Total_Revenue_Per_Product], 
					[Qty_In_Stock], [Qty_On_Hand_Revenue]
Having Total_Qty_Sold > Qty_In_Stock
Order by [Number_Identifier], productline;

--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

Select *  
From Warehouses;

Select *  
From Products
Order by productLine;

Select *  
From Orders;

Select *  
From OrderDetails;

Select *  
From Customers;

Select *  
From Offices;


Select *  
From Productlines;


Select *  
From Payments;


