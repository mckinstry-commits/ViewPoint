SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  FUNCTION [dbo].[mfnWIPContractIsPossitive]
(
	@Company				bCompany
,	@Month					bMonth
,	@Contract				bContract
,	@ExcludeWorkstreams		VARCHAR(255) = '''Sales'',''Internal'''
) 
RETURNS bit AS  

begin
	DECLARE @retVal bit
	DECLARE @netDollars decimal(18,2)
	
	SELECT 
		@netDollars = SUM(ProjectedContractAmount) - SUM(ProjectedCost)
	FROM 
		dbo.mfnWIPRevenueAndCost(@Company,@Month,@Contract,@ExcludeWorkstreams)

	IF @netDollars < 0
		SELECT @retVal = 0
	ELSE
		SELECT @retVal = 1
	
	RETURN @retVal
	
end


GO
