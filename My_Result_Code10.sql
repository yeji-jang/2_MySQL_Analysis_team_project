-- [10. 미국의 베스트셀러 TOP 5 제품, 매출액, 순위 정보 조회]

-- 1. 고객-주문 테이블을 연결하고 고객 테이블의 국가정보가 미국인 행제약 뷰 만들기.
CREATE VIEW customer_order_vw AS
SELECT c.country, o.orderNumber 		-- > 국가, 주문번호 col 가져오기 
FROM customers AS c
JOIN orders AS o ON c.customerNumber = o.customerNumber
WHERE c.country = 'USA';

-- 2. 상품-주문상세 테이블을 연결한 뷰 만들기
CREATE VIEW products_orderdetails_vw AS  
SELECT p.productName, od.quantityOrdered, od.priceEach, od.orderNumber -- > 제품명, 주문수량, 개당가격, 주문번호 col 가져오기   
FROM products AS p
JOIN orderdetails AS od ON p.productCode = od.productCode; 

-- 3. 위 두 개의 view를 조인하여 쿼리 만들기
-- 3-1. 매출액 : 그룹화한 컬럼명으로 sum(개당가격 * 주문수량)
-- 3-2. 계산된 매출액을 내림차순으로 정렬하여, 순위를 매김.
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


