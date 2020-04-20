SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create FUNCTION [dbo].[mfnGetRevenueOverrideAmount]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				bContract	
,	@inOverrideAmount		decimal(18,2)
,	@inValue				decimal(18,2)
)
RETURNS decimal(18,2)

AS
/* TODO : 
		Calc Percent on ProjectedRevenue 
		Adjust to take : (Contract Override - Sum(Contract ProjDollars)) * Contract Item Override Percentage + Contract Item ProjDollars to get prorated Override Amount.	
*/
BEGIN

DECLARE @retVal decimal(18,2)
DECLARE @tot decimal(18,2)
DECLARE @pct decimal(12,8)

SELECT @pct=dbo.mfnGetRevenueOverridePercent(@inCompany,@inMonth,@inContract, @inValue)

select @retVal = 
	CASE @inOverrideAmount
		WHEN 0 THEN @inValue
		ELSE @inOverrideAmount * @pct
	END 

RETURN @retVal

END

GO
