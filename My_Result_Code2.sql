-- [02. 일별/월별/년도별 구매자 수, 구매 건수 조회]

-- <1. 일별 데이터>
SELECT o.orderDate order_date, 
-- orders 테이블에서 중복값을 제외한 구매자 번호와 주문번호를 카운트.
	COUNT(DISTINCT customerNumber) AS customer_c,
    COUNT(DISTINCT orderNumber) AS order_c
FROM classicmodels.orders o	
-- 행제약 조건 : 배송 완료되지 않은 행이면서 주문 취소상태인 것. 
WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled')	
GROUP BY order_date;

-- <2. 월별 데이터>
SELECT SUBSTR(o.orderDate, 1, 7) order_month,
	COUNT(DISTINCT customerNumber) AS customer_c,
    COUNT(DISTINCT orderNumber) AS order_c
FROM classicmodels.orders o
WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled')	
GROUP BY order_month;

-- <3. 년도별 데이터>
SELECT YEAR(o.orderDate) order_year,
	COUNT(DISTINCT customerNumber) AS customer_c,
    COUNT(DISTINCT orderNumber) AS order_c
FROM classicmodels.orders o
WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled')	
GROUP BY order_year;

-- 2-3-5) 행제약 조건 적용 전 토탈 확인
-- SELECT SUM(cc), SUM(oc)
-- FROM (
--     SELECT YEAR(o.orderDate) oyear,
--         COUNT(customerNumber) AS cc,
--         COUNT(orderNumber) AS oc
--     FROM classicmodels.orders o
--     -- WHERE (o.shippedDate IS NOT NULL) AND (o.status <> 'Cancelled')	--	-> 주석을 풀면 행제약 조건의 토탈
--     GROUP BY oyear
-- ) t;-- 
