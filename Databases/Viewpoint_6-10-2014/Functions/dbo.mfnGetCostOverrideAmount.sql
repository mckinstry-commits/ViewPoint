SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create FUNCTION [dbo].[mfnGetCostOverrideAmount]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				bContract	
,	@inOverrideAmount		decimal(18,2)
,	@inValue				decimal(18,2)
,	@inExcludeWorkStream	VARCHAR(255)
,	@inExcludeRevenueType   varchar(255)
)
RETURNS decimal(18,2)

AS

	
/* TODO : 
	Calc Percent on ProjectedCost
	Adjust to take : (Cost Override - Sum(ProjCost)) * Cost Override Percentage + Contract Item ProjCost to get prorated Override Amount.	
*/


BEGIN

DECLARE @retVal decimal(18,2)
DECLARE @tot decimal(18,2)
DECLARE @pct decimal(12,8)

SELECT @pct=dbo.mfnGetCostOverridePercent(@inCompany,@inMonth,@inContract, @inValue, @inExcludeWorkStream, @inExcludeRevenueType )

--Here
--RETURN Difference between Percentage of Override and original projected abount

select @retVal = 
	CASE @inOverrideAmount
		WHEN 0 THEN @inValue
		ELSE @inOverrideAmount * @pct
	END 
--SELECT ((2700000.00 - 2675000.00) * 1) + 2675000.00


RETURN @retVal

END

GO
