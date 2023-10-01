
/**********************************************************************
 [09. 국가별 년도별 재구매율 조회]
 ※ 특정 국가에 거주하는 구매자 중 다음 년도에도 연속해서 구매 이력을 가지는 구매자의 비
 1. inner join orders, orderdetails (using orderNumber) as customer_count
 2. inner join customers, customer_count (using customerNumber) as purchasing_history
 3. group by customerNumber
**********************************************************************/

 -- inner join orders, orderdetails (using orderNumber)
 CREATE OR REPLACE VIEW customer_count as
	SELECT o.orderDate, o.customerNumber
	FROM orders o LEFT OUTER JOIN orderdetails ot ON o.orderNumber = ot.orderNumber
	GROUP BY o.orderNumber;

-- inner join customers, customer_count (using customerNumber) as purchasing_history
-- 고객별 해당연도에 구매 이력 조회 (있다면 1, 없다면 0)
/*
 ┌──────────────────────────────────────────────────────────────┐
 │ customerNumber │ country │ year_2003 │ year_2004 │ year_2005 │
 │──────────────────────────────────────────────────────────────│    
 │103             │ France  │ 1         │ 0         │ 0         │
 │──────────────────────────────────────────────────────────────│    
 │103             │ France  │ 0         │ 1         │ 0         │
 │──────────────────────────────────────────────────────────────│    
 │103             │ France  │ 0         │ 1         │ 0         │
 │──────────────────────────────────────────────────────────────│
                             .
                             .
                             .
*/

CREATE or REPLACE VIEW purchasing_history AS
	SELECT c.customerNumber, c.country,
			CASE WHEN year(cc.orderDate) = 2003 THEN 1 ELSE 0 END year_2003,
			CASE WHEN year(cc.orderDate) = 2004 THEN 1 ELSE 0 END year_2004,
			CASE WHEN year(cc.orderDate) = 2005 THEN 1 ELSE 0 END year_2005
	FROM customers c INNER JOIN customer_count cc ON cc.customerNumber = c.customerNumber;


-- group by customerNumber
/*
 ┌──────────────────────────────────────────────────────────────┐
 │ customerNumber │ country │ year_2003 │ year_2004 │ year_2005 │
 │──────────────────────────────────────────────────────────────│    
 │103             │ France  │ 1         │ 1         │ 0         │
 │──────────────────────────────────────────────────────────────│    
 │112             │ UAS     │ 1         │ 1         │ 0         │
 │──────────────────────────────────────────────────────────────│    
 │114             │ France  │ 1         │ 1         │ 0         │
 │──────────────────────────────────────────────────────────────│
                             .
                             .
                             .
*/
CREATE or REPLACE VIEW retention AS
	SELECT customerNumber, country,
		CASE WHEN sum(year_2003) >= 1 THEN 1 ELSE 0 END year_2003,
		CASE WHEN sum(year_2004) >= 1 THEN 1 ELSE 0 END year_2004,
		CASE WHEN sum(year_2005) >= 1 THEN 1 ELSE 0 END year_2005
	FROM purchasing_history
	GROUP BY customerNumber;

-- 나라별 연도별 재구매율 계산
SELECT country,
	IFNULL(round(count(case WHEN year_2003 = 1 AND year_2004 = 1 THEN customerNumber  END) / count(case WHEN year_2003 = 1 THEN customerNumber END) * 100, 2), 0) retention_03_to_04,
    IFNULL(round(count(case WHEN year_2003 = 1 AND year_2005 = 1 THEN customerNumber  END) / count(case WHEN year_2003 = 1 THEN customerNumber END) * 100 ,2), 0) retention_03_to_05,
    IFNULL(round(count(case WHEN year_2004 = 1 AND year_2005 = 1 THEN customerNumber  END) / count(case WHEN year_2004 = 1 THEN customerNumber END) *100, 2), 0) retention_04_to_05
FROM retention
GROUP BY country;
