SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create FUNCTION [dbo].[mfnGetRevenueOverridePercent]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				bContract	
,	@inValue				decimal(18,2)
)
RETURNS DECIMAL(12,8)

AS

BEGIN

DECLARE @retVal decimal(12,8)
DECLARE @tot decimal(18,2)
DECLARE @pct decimal(12,8)

SELECT
	@tot = SUM(jcip.ProjDollars)
FROM
	JCCI jcci JOIN
	JCIP jcip ON
		jcci.JCCo=jcip.JCCo
	AND jcci.Contract=jcip.Contract
	AND jcci.Item=jcip.Item 
	AND jcci.JCCo=@inCompany
	AND ( ltrim(rtrim(jcci.Contract))=@inContract or @inContract is null )
	AND jcip.Mth <= dbo.mfnFirstOfMonth(@inMonth)


SELECT @retVal = 
	CASE
		WHEN COALESCE(@tot,0) = 0 THEN 1.000
		ELSE CAST( (@inValue / @tot) AS DECIMAL(12,8) )
	END 

RETURN @retVal

END

GO
