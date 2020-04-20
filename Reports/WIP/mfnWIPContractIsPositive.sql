IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnWIPContractIsPositive')
BEGIN
	PRINT 'DROP FUNCTION mfnWIPContractIsPositive'
	DROP FUNCTION dbo.mfnWIPContractIsPositive
END
go

--TODO: Should use Projections or Calculated WIP Values
PRINT 'CREATE FUNCTION mfnWIPContractIsPositive'
go

CREATE  FUNCTION [dbo].[mfnWIPContractIsPositive]
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
		@netDollars = SUM(ProjContractAmt) - SUM(ProjectedCost)
	FROM 
		--Change to use views
		mvwWIPData
	WHERE
		JCCo=@Company
	AND ThroughMonth=@Month
	AND Contract=@Contract

	IF @netDollars < 0
		SELECT @retVal = 0
	ELSE
		SELECT @retVal = 1
	
	RETURN @retVal
	
end
GO