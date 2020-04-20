USE Viewpoint
go

--Variables
DECLARE @Co bCompany
DECLARE @Mth bMonth
DECLARE @BatchId INT
DECLARE @JE_Journal bJrnl

DECLARE @JCTotal bDollar
DECLARE @GLJCTotal bDollar
DECLARE @GLJCJETotal bDollar

SELECT	@Co=20,@Mth='3/1/2015',@BatchId=2389
--SELECT @Co=1,@Mth='3/1/2015',@BatchId=4569, @JE_Journal='PJ'

SELECT 'HQBC' AS TableName,* FROM HQBC WHERE Co=@Co AND Mth=@Mth AND BatchId=@BatchId
SELECT 'APGL' AS TableName,* FROM APGL WHERE APCo=@Co AND Mth=@Mth AND BatchId=@BatchId
SELECT 'APJC' AS TableName,* FROM APJC WHERE APCo=@Co AND Mth=@Mth AND BatchId=@BatchId
SELECT 'JCCD' AS TableName,* FROM JCCD WHERE Mth=@Mth AND BatchId=@BatchId --AND 1=0
SELECT 'GLDT' AS TableName,* FROM GLDT WHERE Mth=@Mth AND BatchId=@BatchId --AND 1=0
SELECT 'GLDT_JE' AS TableName,* FROM GLDT WHERE Mth=@Mth AND Jrnl=@JE_Journal AND  LTRIM(RTRIM(GLRef)) = CAST(@BatchId AS VARCHAR(20)) --BatchId=@BatchId --AND 1=0

SELECT @JCTotal=COALESCE(SUM(ActualCost),0) FROM JCCD WHERE Mth=@Mth AND BatchId=@BatchId --AND 1=0
SELECT 'JCCD Total',@JCTotal AS JCCD_Total

SELECT 'GLDT Total by Acct',GLCo, GLAcct, COALESCE(SUM(Amount),0) AS GLDT_JC_Total FROM GLDT WHERE Mth=@Mth AND BatchId=@BatchId GROUP BY  GLCo, GLAcct--AND 1=0
SELECT 'GLDT Total',COALESCE(SUM(Amount),0) AS GLDT_JC_Total FROM GLDT WHERE Mth=@Mth AND BatchId=@BatchId --AND 1=0
SELECT @GLJCTotal=COALESCE(SUM(Amount),0) FROM GLDT WHERE Mth=@Mth AND BatchId=@BatchId AND CAST(LEFT(GLAcct,1) AS INT)>=5 --AND 1=0
SELECT 'GLDT JC Total',@GLJCTotal AS GLDT_JC_Total


SELECT 'GLDT_JE Total by Acct',GLCo, GLAcct, COALESCE(SUM(Amount),0) AS GLDT_JE_Total FROM GLDT WHERE Mth=@Mth AND Jrnl='PJ' AND GLRef LIKE '%' + CAST(@BatchId AS VARCHAR(20)) + '%' GROUP BY  GLCo, GLAcct --BatchId=@BatchId --AND 1=0
SELECT 'GLDT_JE Total',COALESCE(SUM(Amount),0) AS GLDT_JE_Total FROM GLDT WHERE Mth=@Mth AND Jrnl=@JE_Journal AND LTRIM(RTRIM(GLRef)) LIKE '%' +  CAST(@BatchId AS VARCHAR(20)) + '%'--BatchId=@BatchId --AND 1=0
SELECT @GLJCJETotal=COALESCE(SUM(Amount),0) FROM GLDT WHERE Mth=@Mth AND Jrnl=@JE_Journal AND LTRIM(RTRIM(GLRef)) LIKE '%' + CAST(@BatchId AS VARCHAR(20)) + '%' AND CAST(LEFT(GLAcct,1) AS INT)>=5
SELECT 'GLDT_JE JC Total',@GLJCJETotal AS GLDT_JE_Total

SELECT @Co AS Company,@Mth AS Month,@BatchId AS BatchId, 'JC/GL Delta' AS Label, @JCTotal AS JCTotal, @GLJCTotal AS GLJCTotal, @GLJCJETotal AS GLJCJETotal,  @JCTotal-(@GLJCTotal + @GLJCJETotal) AS Variance


