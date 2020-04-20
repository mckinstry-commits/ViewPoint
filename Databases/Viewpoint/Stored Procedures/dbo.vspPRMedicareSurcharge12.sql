SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[vspPRMedicareSurcharge12]    Script Date: 12/13/2007 15:22:31 ******/
CREATE PROC [dbo].[vspPRMedicareSurcharge12]
/********************************************************
* CREATED BY: 	EN 11/27/2012	D-05383/#146657
*
* USAGE:
* 	Calculates Additional Medicare Surcharge (deduction). 
*	If employee's YTD wages have exceeded the threshold, compute the surcharge as a rate of gross
*	of the wages that exceed the threshold. 
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ytdaccum	YTD wages (includes subject earnings)
*
* OUTPUT PARAMETERS:
*	@amt			calculated Medicare surcharge amount
*	@eligibleamt	portion of subjamt that is eligible for the Medicare surcharge
*	@msg			error message IF failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, 
 @ytdaccum bDollar = 0, 
 @amt bDollar = 0 OUTPUT, 
 @eligibleamt bDollar = 0 OUTPUT,
 @msg varchar(255) = null OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode int, 
		@Threshold bDollar,
		@Rate bUnitCost

SELECT @Threshold = 200000,
	   @Rate = .009,
	   @eligibleamt = 0

IF @ytdaccum > @Threshold --do YTD earnings (including this pay pd's earnings) exceed the threshold?
BEGIN
	IF @ytdaccum - @subjamt > @Threshold --do YTD earnings (not including this pay pd's earnings) exceed the threshold?
	BEGIN
		--entire wages earned this pay period are subject to the surcharge 
		SELECT @eligibleamt = @subjamt
	END
	ELSE
	BEGIN
		--only the wages that exceed the threshold are subject to the surcharge
		SELECT @eligibleamt = @ytdaccum - @Threshold
	END
END

--compute the medicare deduction
SELECT @amt = @eligibleamt * @Rate


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRMedicareSurcharge12] TO [public]
GO
