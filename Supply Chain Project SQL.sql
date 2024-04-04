SELECT * FROM toheebdb.datacosupplychaindataset;

# Converting order date column from string to date format 
UPDATE datacosupplychaindataset
SET order_date = STR_TO_DATE(order_date, '%m/%d/%Y' );

# Converting the shipping date column from string to date format
UPDATE datacosupplychaindataset
SET shipping_date = STR_TO_DATE(shipping_date, '%m/%d/%Y' ); 

# Replacing EE.UU to USA 
UPDATE datacosupplychaindataset
SET Customer_Country = REPLACE(customer_country, "EE. UU.", "USA");

ALTER TABLE datacosupplychaindataset
RENAME COLUMN `Days_for_shipping(real)` TO days_for_shipping_real;
 
 # Product Category with sales amount, profit, times ordered and profit margin
SELECT category_name, 
       ROUND(SUM(order_item_total),2) AS total_sales,
       ROUND(SUM(order_profit_per_order),2) profit, 
       COUNT(*) AS times_ordered,
	   ROUND(ROUND(sum(order_profit_per_order),2)/ROUND(SUM(order_item_total),2) * 100,2) AS profit_margin
FROM datacosupplychaindataset
GROUP BY Category_Name
ORDER BY total_sales DESC;

# Product Name with sales amount, profit, times ordered and profit margin
SELECT Product_Name, 
	   ROUND(SUM(order_item_total),2) AS total_sales, 
       ROUND(SUM(order_profit_per_order),2) AS profit, 
       COUNT(*) AS times_ordered, 
	   ROUND(ROUND(SUM(order_profit_per_order),2)/ROUND(SUM(order_item_total),2) * 100,2) AS profit_margin
FROM datacosupplychaindataset
GROUP BY Product_Name
ORDER BY total_sales DESC;

# How many times were the various payment type used?
SELECT TYPE AS payment_type, 
	   ROUND(SUM(order_item_total),2) AS total_sales,
       COUNT(*) AS time_used
FROM datacosupplychaindataset
GROUP BY payment_type;


# Customer Segment with sales amount, profit, times ordered and profit margin
SELECT customer_segment, 
       ROUND(SUM(order_item_total),2) AS total_sales,  
       ROUND(SUM(order_profit_per_order),2) AS profit,
       ROUND(ROUND(SUM(order_profit_per_order),2)/ROUND(SUM(order_item_total),2) * 100,2) AS profit_margin,
       COUNT(*) AS total_orders
FROM datacosupplychaindataset
GROUP BY Customer_Segment
ORDER BY total_sales;



# Seasonal Trends in sales based on order date by year
SELECT YEAR(order_date)  AS order_year ,
	   ROUND(SUM(order_item_total),2) AS total_sales, 
       ROUND(SUM(order_profit_per_order),2) AS profit, 
       COUNT(*) as total_orders
FROM datacosupplychaindataset
GROUP BY order_year
ORDER BY sales;

# Seasonal Trends in sales based on order date by month
SELECT MONTHNAME(order_date) AS order_month ,
	   ROUND(SUM(order_item_total),2) AS total_sales, 
       ROUND(SUM(order_profit_per_order),2) AS profit,
       COUNT(*) AS total_orders
FROM datacosupplychaindataset
GROUP BY order_month
ORDER BY sales;

# Seasonal Trends in sales based on order date by day in 2018
SELECT DAYNAME(order_date) AS order_day,
       ROUND(SUM(order_item_total),2) AS total_sales,  
       ROUND(SUM(order_profit_per_order),2) AS profit, 
       COUNT(*) AS total_orders
FROM datacosupplychaindataset
WHERE Order_date LIKE "2018%" 
GROUP BY order_day
ORDER BY sales;

# What are the preferred product categories for different customer segments?
WITH ranked_categories AS ( SELECT
        customer_segment,
        category_name,
        ROUND(SUM(order_item_total) ,2) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY customer_segment ORDER BY SUM(order_item_total) DESC) AS category_rank
    FROM datacosupplychaindataset
    GROUP BY customer_segment, category_name
)
SELECT customer_segment,
       category_name,
	   total_sales
FROM ranked_categories
WHERE category_rank = 1;



# Customer Country with sales amount, profit, times ordered and profit margin
SELECT customer_country, 
       ROUND(SUM(order_item_total),2) AS total_sales,  
       ROUND(SUM(order_profit_per_order),2) as profit,
       ROUND(ROUND(SUM(order_profit_per_order),2)/ROUND(SUM(order_item_total),2) * 100,2) AS profit_margin,
       COUNT(*) AS total_orders
FROM datacosupplychaindataset
GROUP BY Customer_Country
ORDER BY total_sales;



# The best selling category in customer_country
WITH ranked_country AS ( SELECT
			customer_country, 
            category_name,  
            ROUND(SUM(order_item_total),2) AS total_sales,
                         ROW_NUMBER() OVER (PARTITION BY customer_country ORDER BY ROUND(SUM(Order_Item_Total),2) DESC) AS customer_countryrank
                         FROM datacosupplychaindataset
                         GROUP BY Customer_Country, Category_Name
                         )
					SELECT 
                        customer_country,
                        category_name, 
                        total_sales
					FROM ranked_country
					WHERE customer_countryrank = 1;
                    
                    
				
# Order Country with sales amount, profit, times ordered and profit margin
SELECT order_country,
       ROUND(SUM(order_item_total),2) AS total_sales,  
       ROUND(SUM(order_profit_per_order),2) AS profit,
       ROUND(ROUND(SUM(order_profit_per_order),2)/ROUND(SUM(order_item_total),2) * 100,2) AS profit_margin,
       COUNT(*) AS total_orders
FROM datacosupplychaindataset
GROUP BY Order_Country
ORDER BY total_sales DESC;



#  Shipping modes with no of orders, percentage difference , expected delivery day and average late delivery risk
WITH total_orders AS ( SELECT 
				shipping_mode, 
                COUNT(shipping_mode) AS no_of_orders, 
                CASE WHEN Shipping_Mode = "Standard class" THEN "4 days"
                WHEN Shipping_Mode = "First class" THEN "1 day" 
                WHEN Shipping_Mode = "second class" THEN "2 days" 
                WHEN Shipping_Mode = "same day" THEN "same day" 
                END AS expected_delivery_day,
                AVG(Late_delivery_risk) AS avg_late_delivery_risk,
                ROUND(AVG(days_for_shipping_real),2) AS avg_real_shipping_days
				FROM datacosupplychaindataset
				GROUP BY shipping_mode
	             )
				 SELECT shipping_mode, 
                        no_of_orders, 
                        CONCAT(ROUND((no_of_orders/(SELECT SUM(no_of_orders) 
                                                    FROM total_orders)) * 100, 2), "%") AS percentage,
                        expected_delivery_day,
                        avg_real_shipping_days
                        avg_late_delivery_risk
                        FROM total_orders
                        GROUP BY shipping_mode;
                        
# Delivery Status
SELECT delivery_status,
       COUNT(*) AS value
FROM datacosupplychaindataset
GROUP BY Delivery_Status
ORDER BY value DESC;


# No of shipping by order_country
SELECT order_country,
	 COUNT(*) AS no_of_shipping
FROM datacosupplychaindataset
GROUP BY Order_Country
ORDER BY no_of_shipping DESC;



# The most preferred shipping mode in customer_country
WITH ranked_shipping AS ( SELECT
                          Customer_Country, 
                          COUNT(shipping_mode)  AS no_of_shipping, 
                          shipping_mode, 
						ROW_NUMBER() OVER (PARTITION BY customer_country ORDER BY COUNT(shipping_mode) DESC) AS customer_shipping_rank
						FROM datacosupplychaindataset
                        GROUP BY Customer_Country, Shipping_Mode)
                        SELECT customer_country, shipping_mode, no_of_shipping
                        FROM ranked_shipping
                        WHERE customer_shipping_rank = 1
                        GROUP BY customer_country;
                        
                        
                        
# No of shipping by year
SELECT YEAR(order_date) AS order_year, 
           COUNT(*) AS no_of_shipping
FROM datacosupplychaindataset
GROUP BY order_year 
ORDER BY order_year DESC;



# No of Shipping by month
SELECT MONTHNAME(order_date) AS order_month,
	   COUNT(*) AS no_of_shipping
FROM datacosupplychaindataset
GROUP BY order_month 
ORDER BY order_month DESC;


# No of shipping by week
SELECT DAYNAME(order_date) AS order_day, 
       COUNT(*) AS no_of_shipping
FROM datacosupplychaindataset
GROUP BY order_day
ORDER BY order_day DESC;



                               

                         
                        



 
 

