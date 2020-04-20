--DROP FUNCTION mfnGetRevenueOverrideAmount
IF EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='FUNCTION' AND ROUTINE_SCHEMA='dbo' AND ROUTINE_NAME='mfnGetRevenueOverrideAmount')
BEGIN
	PRINT 'DROP FUNCTION mfnGetRevenueOverrideAmount'
	DROP FUNCTION dbo.mfnGetRevenueOverrideAmount
END
go

PRINT 'CREATE FUNCTION mfnGetRevenueOverrideAmount'
go

--create FUNCTION mfnGetRevenueOverrideAmount
create FUNCTION dbo.mfnGetRevenueOverrideAmount
(
	@inCompany				tinyint
,	@inMonth				smalldatetime
,	@inContract				VARCHAR(10) --bContract	
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
	CASE COALESCE(@inOverrideAmount,0)
		WHEN 0 THEN @inValue
		ELSE @inOverrideAmount * @pct
	END 

RETURN @retVal

END
GO