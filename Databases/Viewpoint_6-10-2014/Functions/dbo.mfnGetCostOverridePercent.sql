SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create FUNCTION [dbo].[mfnGetCostOverridePercent]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				bContract	
,	@inValue				decimal(18,2)
,	@inExcludeWorkStream	VARCHAR(255)
,	@inExcludeRevenueType   varchar(255)
)
RETURNS decimal(12,8)

AS

BEGIN

DECLARE @retVal decimal(12,8)
DECLARE @tot decimal(18,2)
DECLARE @pct decimal(12,8)

SELECT
	@tot = SUM(jccp.ProjCost)
FROM
	JCCI jcci JOIN
	JCJP jcjp on
		jcci.JCCo=jcjp.JCCo
	and jcci.Contract=jcjp.Contract
	and jcci.Item=jcjp.Item 
	AND jcci.JCCo=@inCompany 
	AND ( ltrim(rtrim(jcci.Contract))=@inContract or @inContract is null ) JOIN
	JCJM jcjm ON
		jcjp.JCCo=jcjm.JCCo
	AND jcjp.Job=jcjm.Job 
	AND (jcjm.udProjWrkstrm NOT IN (@inExcludeWorkStream) OR @inExcludeWorkStream IS null) 
	AND ( COALESCE(jcci.udRevType,'C') NOT in (@inExcludeRevenueType) OR  @inExcludeRevenueType IS NULL ) JOIN
	JCCP jccp ON
		jcjp.JCCo=jccp.JCCo
	and jcjp.Job=jccp.Job
	and jcjp.Phase=jccp.Phase
	and jcjp.PhaseGroup=jccp.PhaseGroup		
	and jccp.Mth <= dbo.mfnFirstOfMonth(@inMonth) 


SELECT @retVal = 
	CASE
		WHEN COALESCE(@tot,0) = 0 THEN 1.000
		ELSE CAST( (@inValue / @tot) AS decimal(12,8) )
	END 

RETURN @retVal

END

GO
