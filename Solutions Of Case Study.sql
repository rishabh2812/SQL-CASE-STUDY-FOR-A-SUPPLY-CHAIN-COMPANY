use supply_chain;
show tables;

 -- CASE STUDY --
 
--    KNOWING THE DATASET 
 
-- Country WIse Number of Customers.... 
select country,count(*) 'total customers' from customer group by country;

-- Products which are not discontinued 
select * from product where IsDiscontinued=0;

-- List of Company and the product they supply
select CompanyName,ProductName from supplier,product where supplier.id=product.SupplierId;

-- Customers who live in Mexico
select * from customer where Country='Mexico' or Country='mexico';

-- Costliest Item Order by Customer;
select *,unitprice*quantity 'ordervalue' from orderitem where unitprice*quantity=(select max(unitprice*quantity) from orderitem);

-- Supplier ID with highest number of products 
select supplierid,companyname,count(ProductName) from product inner join supplier on supplier.id=product.SupplierId 
group by supplierid order by count(productname) desc limit 2;

-- Month Wise and Year Wise Order
update orders set orderDate=STR_TO_DATE(orderdate, '%b %d %Y %r');
select id,month(orderdate),year(orderdate),ordernumber,customerid,totalamount from orders;

-- Country with maximum supplier 
select country,count(*) as total from supplier group by country order by count(*) desc limit 1;

-- Csutomer with No order
select * from customer where id not in (select customerid from orders);

-- KNOWING THE BUSINESS 

-- product based high demand 
select productid,productname,count(productid) from orderitem,product where orderitem.productid=product.id group by productid  order by count(productid) desc;

-- orders delieverd every year
select year(orderdate),count(*)'Orders' from orders group by year(orderdate);

-- year wise revenue 
select year(orderdate) as 'Year',sum(totalamount) as 'Revenue' from orders group by year (orderdate);

-- customer with highest order amount
select customerid,firstname,lastname,city,country,phone,sum(totalamount) as revenue from customer,orders 
where orders.customerid=customer.id group by customerid order by revenue desc limit 1;


-- total amount ordered by each customer from high to low . 
select customerid,firstname,lastname,city,country,phone,sum(totalamount) as revenue from customer,orders 
where orders.customerid=customer.id group by customerid order by revenue desc;

-- Current and PRevious Order Amount of Customer
select customerid,firstname,lastname,orderdate,totalamount from 
(select customerid,firstname,lastname,orderdate,totalamount,row_number() over(partition by customerid) as top2 from 
customer,orders where orders.customerid=customer.id)t1 where top2<3 order by customerid,orderdate desc; 

-- Top 3 Suppliers Revenue 
select supplierid,companyname,sum(productrevenue) as supplier_revenue from 
(select productid,productname,product.supplierid,companyname,orderitem.unitprice*quantity as productrevenue from orderitem,product,supplier where 
orderitem.productid=product.id and product.supplierid=supplier.id group by productid order by productrevenue desc)t 
group by supplierid order by supplier_revenue desc limit 3;

-- Latest Order Date of the Customer and Its details
select customerid,firstname,lastname,orderdate,totalamount from 
(select customerid,firstname,lastname,orderdate,totalamount,row_number() over(partition by customerid order by orderdate desc) as latest from 
customer,orders where orders.customerid=customer.id)t where latest=1;
 
 -- Product Name and Supplier Name for each order 
 select * from orders;
 select o.id,o.orderdate,pr.productname,s.companyname,o.totalamount from orders o,orderitem oi,product pr,supplier s where 
 o.id=oi.orderid and oi.productid=pr.id and pr.supplierid=s.id order by o.id;


-- BUSINESS ANALYSIS 

-- Customer who ordered more than 10 products in a single order
select * from (select customerid,firstname,lastname,orderid,count(productid) as totalproducts from orderitem,orders,customer
 where orders.id=orderitem.orderid and orders.customerid=customer.id group by orderid)t where totalproducts>=10;

-- Products with order quantity 1
select productid,productname,orderitem.unitprice,quantity from orderitem,product where orderitem.productid=product.id and quantity=1;

-- Companies that sells product which costs>100
select Companyname,ProductName,Unitprice from product,supplier where product.supplierid=supplier.id and unitprice >100;

-- Customers and Supplier list
select 'customer' as TYPE,concat(firstname,' ',lastname) as NAME,city,country,phone from customer 
union 
select 'supplier' as TYPE,contactname as NAME, city,country,phone from supplier ;


-- Customer arranged as same city and country 
select city,country,firstname,lastname,phone from(select *,row_number() over (partition by country,city) from customer)t;

--  CHALLENGE INSIGHTS

 
-- Amount Saved in each order 
select *,sum(money_saved) from 
(select *,realprice-billprice as MONEY_SAVED from 
(select *,actualprice*quantity as realprice,discountedprice*quantity as Billprice from
(select orderitem.orderid,product.productname,product.unitprice as actualprice,orderitem.unitprice as discountedprice,orderitem.quantity from 
orderitem,product where orderitem.productid=product.id order by orderid)t)t1)t2 group by orderid order by money_saved desc;

-- Products on Demand
select productid,productname,count(productid) as TimesOrdered from orderitem,product where orderitem.productid=product.id group by productid  order by count(productid) desc;

-- Competitors for Richard's Supply
select productid,productname,companyname from orderitem,product,supplier where orderitem.productid=product.id and product.supplierid=supplier.id group by productid  order by count(productid) desc;


-- List to display customers and supplier with conditions as :-
-- Both customer and supplier belong to same country
-- customer who doesnot have supplier in their country
-- supplier who doesnot have customer in their country
select 'customer',c.firstname, c.lastname, c.Country AS CustomerCountry, 
s.country as SupplierCountry, s.CompanyName
from customer c left join Supplier s 
on c.country = s.country
union
select 'supplier',c.firstname, c.lastname, c.country as CustomerCountry, 
s.country as suppliercountry, s.companyname
FROM customer c RIGHT JOIN Supplier s
ON c.country = s.country;



-- TOP 2 Suppliers 
select * ,rank() over(order by supplier_revenue desc) from (select supplierid,companyname,sum(productrevenue) as supplier_revenue from 
(select productid,productname,product.supplierid,companyname,orderitem.unitprice*quantity as productrevenue from orderitem,product,supplier where 
orderitem.productid=product.id and product.supplierid=supplier.id group by productid order by productrevenue desc)t 
group by supplierid order by supplier_revenue)t1 limit 2;


-- UK dependent on other country for supply 
select * from (select 'customer',c.firstname, c.lastname, c.Country AS CustomerCountry, 
s.country as SupplierCountry, s.CompanyName
from customer c left join Supplier s 
on c.country = s.country
union
select 'supplier',c.firstname, c.lastname, c.country as CustomerCountry, 
s.country as suppliercountry, s.companyname
FROM customer c RIGHT JOIN Supplier s
ON c.country = s.country)t1 where customercountry='UK' and suppliercountry !='UK';
