/***************************************************************************************************
										<일별/월별/년도별 매출액 조회> -최민혁
***************************************************************************************************/

-- 일별 매출액
-- date_format() 날짜 표시
SELECT date_format(o.orderDate,'%Y-%m-%d') as day,

-- 매출액 ( 판매수량 * 판매 단가) 의 합
	   SUM(od.priceEach * od.quantityOrdered) AS daily_Sales
FROM orders o
-- o.orderNumber,od.orderNumber 연결
	LEFT JOIN orderdetails od ON o.orderNumber = od.orderNumber
-- o.shippedDate 가 null 이 아니면서 o.status 가 'Cancelled' 가 아닐경우
WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled')
GROUP BY o.orderDate
order by day;

-- 월별 매출액
SELECT date_format(o.orderDate,'%Y-%m') AS month,
       SUM(od.quantityOrdered * od.priceEach) AS monthly_Sales
FROM orders o
	LEFT JOIN orderdetails od ON o.orderNumber = od.orderNumber
WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled')
GROUP BY month
ORDER BY month;

-- 연별 매출액
SELECT date_format(o.orderDate,'%Y') AS year,
       SUM(od.quantityOrdered * od.priceEach) AS year_Sales
FROM orders o
	LEFT JOIN orderdetails od ON o.orderNumber = od.orderNumber
WHERE (o.shippedDate is not NULL) AND (o.status <> 'Cancelled')
GROUP BY year
ORDER BY year;

/***************************************************************************************************
									<국가별, 도시별 매출액 조회> -최민혁
***************************************************************************************************/

-- 도시별 매출액
SELECT c.city,  SUM(od.quantityOrdered * od.priceEach) AS city_Sales
FROM orders o
-- 주문,고객, 주문 상세 테이블을 각각 customerNumber ,orderNumber 열을 기준으로 연결
	LEFT JOIN customers c ON o.customerNumber = c.customerNumber
	LEFT JOIN orderdetails od ON o.orderNumber = od.orderNumber
WHERE (o.shippedDate is not NULL) AND (o.status <> 'Cancelled')
GROUP BY c.city;

-- 국가별 매출액
SELECT c.country, SUM(od.quantityOrdered * od.priceEach) AS country_Sales
FROM orders o
	LEFT JOIN customers c ON o.customerNumber = c.customerNumber
	LEFT JOIN orderdetails od ON o.orderNumber = od.orderNumber 
WHERE (o.shippedDate is not NULL) AND (o.status <> 'Cancelled')
GROUP BY c.country;

/***************************************************************************************************
							<북미(USA, Canada) vs 비북미 매출액 비교 조회> -최민혁
***************************************************************************************************/

SELECT 
-- country에서 'usa''canada' 를 north America , 그 외 'Non-north America' 로 하고 region으로 별칭 지정
   IF( c.country IN ('USA', 'Canada'), 'North America', 'Non-North America' )AS region,
    SUM(od.quantityOrdered * od.priceEach) AS total_sales
FROM 
    orders o
    LEFT JOIN customers c ON o.customerNumber = c.customerNumber
    LEFT JOIN orderdetails od ON o.orderNumber = od.orderNumber
WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled')
GROUP BY region;

-- --------------------------------------------------------------------------------------------------------------------

/***************************************************************************************************
								<일별/월별/년도별 구매자 수, 구매 건수 조회> -장예지
***************************************************************************************************/

-- <일별 데이터>
SELECT o.orderDate order_date, 
-- orders 테이블에서 중복값을 제외한 구매자 번호와 주문번호를 카운트.
	COUNT(DISTINCT customerNumber) AS customer_c,
    COUNT(DISTINCT orderNumber) AS order_c
FROM classicmodels.orders o	
-- 행제약 조건 : 배송 완료되지 않은 행이면서 주문 취소상태인 것. 
WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled')	
GROUP BY order_date;

-- <월별 데이터>
SELECT SUBSTR(o.orderDate, 1, 7) order_month,
	COUNT(DISTINCT customerNumber) AS customer_c,
    COUNT(DISTINCT orderNumber) AS order_c
FROM classicmodels.orders o
WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled')	
GROUP BY order_month;

-- <년도별 데이터>
SELECT YEAR(o.orderDate) order_year,
	COUNT(DISTINCT customerNumber) AS customer_c,
    COUNT(DISTINCT orderNumber) AS order_c
FROM classicmodels.orders o
WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled')	
GROUP BY order_year;

/***************************************************************************************************
									<국가별 년도별 재구매율 조회>
			※ 특정 국가에 거주하는 구매자 중 다음 년도에도 연속해서 구매 이력을 가지는 구매자의 비율 -장예지
***************************************************************************************************/

 -- VIEW 1. (고객정보 조회) left join -> orders, orderdetails (using orderNumber)
 CREATE OR REPLACE VIEW customer_count as
	SELECT o.orderDate, o.customerNumber
	FROM orders o LEFT OUTER JOIN orderdetails ot ON o.orderNumber = ot.orderNumber
	GROUP BY o.orderNumber;


-- VIEW 2. (구매이력 조회) inner join -> customers, view1 (using customerNumber) as purchasing_history
-- 고객별 해당연도에 구매 이력 조회 (있다면 1, 없다면 0)
CREATE or REPLACE VIEW purchasing_history AS
	SELECT c.customerNumber, c.country,
			CASE WHEN year(cc.orderDate) = 2003 THEN 1 ELSE 0 END year_2003,
			CASE WHEN year(cc.orderDate) = 2004 THEN 1 ELSE 0 END year_2004,
			CASE WHEN year(cc.orderDate) = 2005 THEN 1 ELSE 0 END year_2005
	FROM customers c INNER JOIN customer_count cc ON cc.customerNumber = c.customerNumber;

    
-- VIEW 3. VIEW 2를 가지고 고객별로 년도별 구매이력을 구한다.  
CREATE or REPLACE VIEW retention AS
	SELECT customerNumber, country,
		CASE WHEN sum(year_2003) >= 1 THEN 1 ELSE 0 END year_2003,
		CASE WHEN sum(year_2004) >= 1 THEN 1 ELSE 0 END year_2004,
		CASE WHEN sum(year_2005) >= 1 THEN 1 ELSE 0 END year_2005
	FROM purchasing_history
	GROUP BY customerNumber;
    

-- 최종 VIEW 3로 나라별 연도별 재구매율 계산
SELECT country,
	IFNULL(round(count(case WHEN year_2003 = 1 AND year_2004 = 1 THEN customerNumber  END) / count(case WHEN year_2003 = 1 THEN customerNumber END) * 100, 2), 0) retention_03_to_04,
    IFNULL(round(count(case WHEN year_2003 = 1 AND year_2005 = 1 THEN customerNumber  END) / count(case WHEN year_2003 = 1 THEN customerNumber END) * 100 ,2), 0) retention_03_to_05,
    IFNULL(round(count(case WHEN year_2004 = 1 AND year_2005 = 1 THEN customerNumber  END) / count(case WHEN year_2004 = 1 THEN customerNumber END) *100, 2), 0) retention_04_to_05
FROM retention
GROUP BY country;
    

/***************************************************************************************************
							<미국의 베스트셀러 TOP 5 제품, 매출액, 순위 정보 조회> -장예지
***************************************************************************************************/

-- VIEW 1. 고객-주문 테이블을 연결하고 고객 테이블의 국가정보가 미국인 행제약 뷰 만들기.*********/////////////////////////////////////////566666
CREATE VIEW customer_order_vw AS
SELECT c.country, o.orderNumber 		-- > 국가, 주문번호 col 가져오기 
FROM customers AS c
JOIN orders AS o ON c.customerNumber = o.customerNumber
WHERE c.country = 'USA';

-- VIEW 2. 상품-주문상세 테이블을 연결한 뷰 만들기
CREATE VIEW products_orderdetails_vw AS  
SELECT p.productName, od.quantityOrdered, od.priceEach, od.orderNumber -- > 제품명, 주문수량, 개당가격, 주문번호 col 가져오기   
FROM products AS p
JOIN orderdetails AS od ON p.productCode = od.productCode; 

-- 위 두 개의 view를 조인하여 쿼리 만들기
--  매출액 : 그룹화한 컬럼명으로 sum(개당가격 * 주문수량)
--  계산된 매출액을 내림차순으로 정렬하여, 순위를 매김.
SELECT t.country, t.productName, t.total_sales, t.rank_rnk
FROM ( 
   SELECT co.country,
         pod.productName, 
         SUM(pod.priceeach * pod.quantityordered) as total_sales,
         RANK() over (ORDER BY SUM(pod.priceeach * pod.quantityordered) DESC) rank_rnk  
   FROM products_orderdetails_vw as pod INNER JOIN customer_order_vw as co
                          ON pod.orderNumber = co.orderNumber
GROUP BY co.country, pod.productName
) t
-- 4. 상위 5위 데이터만 조회
WHERE t.rank_rnk <= 5;

-- --------------------------------------------------------------------------------------------------------------------

/***************************************************************************************************
							<년도별 인당 매출액 (AMV: Average Member value)> - 황은옥
***************************************************************************************************/

WITH temp AS (
SELECT o.orderNumber
	  ,o.shippedDate -- 매출액에서 제외하는 기준을 shippedDate로 잡았기 때문에 매출액으로 기록되는 기준도 shippedDate로 (합의 필요)
      ,o.customerNumber
      ,od.persales
FROM orders o LEFT JOIN (SELECT orderNumber
								,SUM(quantityOrdered * priceEach) persales -- 주문번호별 매출액 
						 FROM orderdetails
						 GROUP BY orderNumber) od 
					 ON o.orderNumber = od.orderNumber
WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled') -- orderDetails 에서 shippedDate가 누락됐거나 status가 취소된 것으로 나온 order는 매출액에서 제외
)

SELECT YEAR(shippedDate) year 
       ,COUNT(customerNumber) customercnt -- 연도별 고객 수
       ,SUM(persales) totalsales -- 연도별 매출
	   ,ROUND(SUM(persales) / COUNT(customerNumber),2) salesperperson -- 연도별 인당 매출액
FROM temp
GROUP BY 1;

/***************************************************************************************************
								<가입자 이탈율(Churn Rate) 조회> -황은옥
 ※ 특정시점(2005년 6월 1일)을 기준으로 마지막 구매일이 일정기간(3개월=90일) 이상 지난 고객의 비율
***************************************************************************************************/

-- 6월 1일로부터 90일 전에 구매한 사람 / 전체 고객
-- 구매일이니까 orderDate 기준이고 shippedDate와 status 고려하지 않고 '구매 결정'으로만 판단한 결과

SELECT COUNT(CASE WHEN lastpurchaseinterval >= 90 THEN customerNumber END) *100/ COUNT(*)  churn_rate
FROM (SELECT customerNumber
			,DATEDIFF('2005-06-01', MAX(orderDate)) lastpurchaseinterval
	  FROM orders
	  GROUP BY customerNumber)lpi;
-- 70.4082%

-- --------------------------------------------------------------------------------------------------------------------

/***************************************************************************************************
						<년도별 건당 매출액 (ATV: Average Transaction value)> -이건희
									※ 거래 1건당 평균 매출액
***************************************************************************************************/

-- 일별 / 주문별 매출액
SELECT o.orderDate, o.orderNumber, sum(ot.priceEach * ot.quantityOrdered) mount
FROM orders o INNER JOIN orderdetails ot ON o.orderNumber = ot.orderNumber
WHERE o.status != 'Cancelled' and o.shippedDate IS NOT null
GROUP BY o.orderNumber;

 -- create view atv table
CREATE OR REPLACE VIEW atv AS
	SELECT o.orderDate, o.orderNumber, sum(ot.priceEach * ot.quantityOrdered) mount
	FROM orders o INNER JOIN orderdetails ot ON o.orderNumber = ot.orderNumber
	WHERE o.status != 'Cancelled' and o.shippedDate IS NOT null
	GROUP BY o.orderNumber;
 
 -- 연도별 건당 매출액
Select year(atv.orderDate), avg(atv.mount)
From atv
GROUP BY year(atv.orderDate);

/***************************************************************************************************
								<국가별 매출액 TOP 5 및 순위 조회> -이건희
***************************************************************************************************/

-- inner join atv, (inner join (customers, orders))
SELECT country, sum(mount) country_value
FROM customers c INNER JOIN orders o ON c.customerNumber = o.customerNumber
				INNER JOIN atv ON atv.orderNumber = o.orderNumber
GROUP BY country;

-- ranking
SELECT country, sum(mount) country_value, rank() over (ORDER BY sum(mount) desc) ranking
FROM customers c INNER JOIN orders o ON c.customerNumber = o.customerNumber
				INNER JOIN atv ON atv.orderNumber = o.orderNumber
GROUP BY country;

-- create view country ranking
CREATE VIEW country_rank as
	SELECT country, sum(mount) country_value, rank() over (ORDER BY sum(mount) desc) ranking
	FROM customers c INNER JOIN orders o ON c.customerNumber = o.customerNumber
					INNER JOIN atv ON atv.orderNumber = o.orderNumber
	-- WHERE ranking < 5
	GROUP BY country;

SELECT *
From country_rank
WHERE ranking <= 5;

/***************************************************************************************************
								<년도별 재구매율(Retention Rate) by 이건희>
							※ 다음 년도에도 연속해서 구매 이력을 가지는 구매자의 비율
***************************************************************************************************/

 -- 회원 중 주문을 하지 않은 회원이 있는지 체크
 CREATE OR REPLACE VIEW customer_count as
	SELECT o.orderDate, o.customerNumber
	FROM orders o LEFT OUTER JOIN orderdetails ot ON o.orderNumber = ot.orderNumber
	GROUP BY o.orderNumber;

SELECT DISTINCT c.customerNumber
FROM customers c LEFT OUTER JOIN customer_count cc ON c.customerNumber = cc.customerNumber;

-- 고객별 해당연도에 구매 이력 조회 (있다면 1, 없다면 0)
CREATE or REPLACE VIEW purchasing_history AS
	SELECT o.customerNumber,
			CASE WHEN year(o.orderDate) = 2003 THEN 1 ELSE 0 END year_2003,
			CASE WHEN year(o.orderDate) = 2004 THEN 1 ELSE 0 END year_2004,
			CASE WHEN year(o.orderDate) = 2005 THEN 1 ELSE 0 END year_2005
	FROM orders o INNER JOIN orderdetails od ON o.orderNumber = od.orderNumber
	GROUP BY o.orderNumber;

CREATE or REPLACE VIEW retention AS
	SELECT customerNumber,	
		CASE WHEN sum(year_2003) >= 1 THEN 1 ELSE 0 END year_2003,
		CASE WHEN sum(year_2004) >= 1 THEN 1 ELSE 0 END year_2004,
		CASE WHEN sum(year_2005) >= 1 THEN 1 ELSE 0 END year_2005
	FROM purchasing_history
	GROUP BY customerNumber;

SELECT *
from retention;

-- 연도별 재구매율
SELECT 
	count(case WHEN year_2003 = 1 AND year_2004 = 1 THEN customerNumber  END) / count(case WHEN year_2003 = 1 THEN customerNumber END) retention_03_to_04,
    count(case WHEN year_2003 = 1 AND year_2005 = 1 THEN customerNumber  END) / count(case WHEN year_2003 = 1 THEN customerNumber END) retention_03_to_05,
    count(case WHEN year_2003 = 0 AND year_2004 = 1 AND year_2005 = 1 THEN customerNumber  END) / count(case WHEN year_2003 = 0 AND year_2004 = 1 THEN customerNumber END) retention_04_to_05
FROM retention;

/***************************************************************************************************
								<년도별 재구매율(Retention Rate) by 황은옥>
							※ 다음 년도에도 연속해서 구매 이력을 가지는 구매자의 비율
***************************************************************************************************/
-- 고객별 구매이력이 있는 orders 테이블에서 고객당 구매 연도와 첫 구매 연도를 JOIN한 preprocessed 테이블 임시 생성
WITH preprocessed AS (
SELECT o.customerNumber
      ,YEAR(o.orderDate) year
      ,f.firstorderyear
FROM orders o INNER JOIN (SELECT customerNumber
                                 ,MIN(YEAR(orderDate)) firstorderyear -- 첫 구매 연도
						  FROM orders
						  GROUP BY customerNumber) f 
					  ON o.customerNumber = f.customerNumber)

SELECT firstorderyear
      ,ROUND(year0 / year0 * 100, 2) AS year0_pct
      ,ROUND(year1 / year0 * 100, 2) AS year1_pct
      ,ROUND(year2 / year0 * 100, 2) AS year2_pct
      ,ROUND(year3 / year0 * 100, 2) AS year3_pct
FROM (SELECT firstorderyear  -- 첫 구매 연도 
			,COUNT(DISTINCT customerNumber) AS year0 -- 첫 구매 연도에 구매한 고객 수 
			,COUNT(DISTINCT CASE WHEN year = firstorderyear + 1 THEN customerNumber END) AS year1 -- 첫 구매 연도 다음, 이듬해에 연속하여 구매한 고객 수
			,COUNT(DISTINCT CASE WHEN year = firstorderyear + 2 THEN customerNumber END) AS year2 -- 첫 구매 연도 다음다음해, 후년에 연속하여 구매한 고객 수  
			,COUNT(DISTINCT CASE WHEN year = firstorderyear + 3 THEN customerNumber END) AS year3 -- 첫 구매 연도 3년 뒤에 구매한 고객 수 orders 테이블에는 3년간의 데이터가 있으므로 당연히 0
	 FROM preprocessed
	 GROUP BY firstorderyear) cnt 
GROUP BY firstorderyear