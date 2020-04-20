SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create FUNCTION [dbo].[mfnGetPercentComplete]
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				bContract	
,	@inIsLocked				bYN
,	@inExcludeWorkStream	varchar(255)
,	@inExcludeRevenueType   varchar(255)
,	@curEstimatedCost		decimal(18,2)	
,	@projectedCost			decimal(18,2)	
,	@overrideCost			decimal(18,2)		
)
RETURNS DECIMAL(8,3)

AS

BEGIN

DECLARE @retVal DECIMAL(8,3)
DECLARE @revtot decimal(18,2)
DECLARE @costtot decimal(18,2)
DECLARE @nettot decimal(18,2)

--If Sum(ProjectedRevenue [including overrides]) - Sum(ProjectedCost [including overrides]) < 0
--	Return 100% for PercentComplete
--Else
--	Return jccp.CurrEstCost / Projected Cost [including overrides] as DECIMAL(8,3)

SELECT 
	@revtot = SUM(ORProjContractAmt) 
FROM 
	dbo.mfnGetWIPRevenue(@inCompany,@inMonth,@inContract,@inIsLocked,@inExcludeWorkStream,@inExcludeRevenueType)

SELECT 
	@costtot= SUM(ORProjectedCost) 
FROM 
	dbo.mfnGetWIPCost(@inCompany,@inMonth,@inContract,@inIsLocked,@inExcludeWorkStream,@inExcludeRevenueType)
	
SELECT @nettot=@revtot-@costtot

SELECT @retVal=
	CASE 
		WHEN @nettot < 0 THEN 1.000
		ELSE 
			CASE 
				WHEN coalesce(@overrideCost,0)=0 AND coalesce(@projectedCost,0)=0 THEN 0.00
				WHEN coalesce(@overrideCost,0)=0 AND coalesce(@projectedCost,0)<>0 THEN CAST(@curEstimatedCost / ( @projectedCost ) AS decimal(8,3))
				ELSE CAST(@curEstimatedCost / ( dbo.mfnGetCostOverrideAmount(@inCompany,@inMonth,@inContract,COALESCE(@overrideCost,0), @projectedCost, @inExcludeWorkStream,@inExcludeRevenueType ) ) AS decimal(8,3))
			END
	END		


RETURN @retVal

END

GO
