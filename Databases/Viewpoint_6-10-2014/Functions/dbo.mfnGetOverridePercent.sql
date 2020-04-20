SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[mfnGetOverridePercent]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				bContract	
,	@inValue				decimal(18,2)
)
RETURNS DECIMAL(8,3)

AS

BEGIN

DECLARE @retVal decimal(8,3)
DECLARE @tot decimal(18,2)
DECLARE @pct decimal(18,2)

SELECT
	@tot = SUM(jcip.ContractAmt)
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
		WHEN @tot = 0 THEN 1.000
		ELSE CAST( (@inValue / @tot) AS DECIMAL(8,3) )
	END 

RETURN @retVal

END

GO
