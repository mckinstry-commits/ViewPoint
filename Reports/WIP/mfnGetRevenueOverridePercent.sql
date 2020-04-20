--DROP FUNCTION mfnGetRevenueOverridePercent
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnGetRevenueOverridePercent')
BEGIN
	PRINT 'DROP FUNCTION mfnGetRevenueOverridePercent'
	DROP FUNCTION dbo.mfnGetRevenueOverridePercent
END
go

PRINT 'CREATE FUNCTION mfnGetRevenueOverridePercent'
go

--create FUNCTION mfnGetRevenueOverridePercent
create FUNCTION dbo.mfnGetRevenueOverridePercent
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10) -- bContract	
,	@inValue				decimal(18,2)
)
RETURNS DECIMAL(18,15)

AS

BEGIN

DECLARE @retVal decimal(18,15)
DECLARE @tot decimal(18,2)
DECLARE @pct decimal(18,15)

SELECT
	@tot = SUM(jcip.ProjDollars)
FROM
	dbo.JCCI jcci JOIN
	dbo.JCIP jcip ON
		jcci.JCCo=jcip.JCCo
	AND jcci.Contract=jcip.Contract
	AND jcci.Item=jcip.Item 
	AND jcci.JCCo=@inCompany
	AND ( ltrim(rtrim(jcci.Contract))=@inContract or @inContract is null )
	AND jcip.Mth <= dbo.mfnFirstOfMonth(@inMonth)


SELECT @retVal = 
	CASE
		WHEN COALESCE(@tot,0) = 0 THEN 1.000
		ELSE CAST( (@inValue / @tot) AS DECIMAL(18,15) )
	END 

RETURN @retVal

END
go
