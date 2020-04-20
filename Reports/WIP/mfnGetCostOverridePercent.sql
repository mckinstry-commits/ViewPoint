--DROP FUNCTION mfnGetCostOverridePercent
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnGetCostOverridePercent')
BEGIN
	PRINT 'DROP FUNCTION mfnGetCostOverridePercent'
	DROP FUNCTION dbo.mfnGetCostOverridePercent
END
go

PRINT 'CREATE FUNCTION mfnGetCostOverridePercent'
go

--create FUNCTION mfnGetCostOverridePercent
create FUNCTION dbo.mfnGetCostOverridePercent
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10) --bContract	
,	@inValue				decimal(18,2)
,	@inExcludeWorkStream	VARCHAR(255)
,	@inExcludeRevenueType   varchar(255)
)
RETURNS decimal(18,15)

AS

BEGIN

DECLARE @retVal decimal(18,15)
DECLARE @tot decimal(18,2)
DECLARE @pct decimal(18,15)

SELECT
	@tot = SUM(jccp.ProjCost)
FROM
	dbo.JCCI jcci JOIN
	dbo.JCJP jcjp on
		jcci.JCCo=jcjp.JCCo
	and jcci.Contract=jcjp.Contract
	and jcci.Item=jcjp.Item 
	AND jcci.JCCo=@inCompany 
	AND ( ltrim(rtrim(jcci.Contract))=@inContract or @inContract is null ) JOIN
	dbo.JCJM jcjm ON
		jcjp.JCCo=jcjm.JCCo
	AND jcjp.Job=jcjm.Job 
	AND (jcjm.udProjWrkstrm NOT IN (@inExcludeWorkStream) OR @inExcludeWorkStream IS null) 
	AND ( COALESCE(jcci.udRevType,'C') NOT in (@inExcludeRevenueType) OR  @inExcludeRevenueType IS NULL ) JOIN
	dbo.JCCP jccp ON
		jcjp.JCCo=jccp.JCCo
	and jcjp.Job=jccp.Job
	and jcjp.Phase=jccp.Phase
	and jcjp.PhaseGroup=jccp.PhaseGroup		
	and jccp.Mth <= dbo.mfnFirstOfMonth(@inMonth) 


SELECT @retVal = 
	CASE
		WHEN COALESCE(@tot,0) = 0 THEN 1.000
		ELSE CAST( (@inValue / @tot) AS decimal(18,15) )
	END 

RETURN @retVal

END
GO