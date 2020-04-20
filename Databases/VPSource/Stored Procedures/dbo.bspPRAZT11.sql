SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAZT11    Script Date: 8/28/99 9:33:12 AM ******/
CREATE PROC [dbo].[bspPRAZT11]
/********************************************************
* CREATED BY: 	EN 6/2/98
* MODIFIED BY:  GG 8/11/98
*		EN 01/02/02 - update effective 1/1/2002
*		EN 2/14/02 - issue 15752 - fix to default to lowest rate rather than highest if rate is not specified
*		EN 9/26/02 - issue 18714  missing 34% tax bracket in code
*		EN 10/7/02 - issue 18877 change double quotes to single
*		EN 7/8/03 - issue 21777  update effective 7/1/03
*		EN 11/5/03 - issue 22938  remove $5 per month limit
*		EN 12/23/04 - issue 26632  update effective 1/1/05
*		EN 4/20/2009 #133346  update effective 5/1/2009
*		EN 12/1/2009 #136934  rates updated effective 1/1/2010 ... also updated code used to determine rate to make it easier to maintain rates in the future
*		EN 5/26/2010 #139365  Arizona changing from rate of Federal Tax to Rate of Gross and updating rates.
*							At the same time we are retaining functionality to validate rate and provide default rate.
*		TJL 09/01/10 - issue #141012, Use MiscFactor of 1.3% regardless of Annualized Earnings (Even when less than 15000)
*		EN 12/14/2010 #142444 update effective 1/1/2011 ... removed $15,000 earnings breakpoint and added .8% as a valid rate
*		CHS 02/21/2011	- #143229
*
* USAGE:
* 	Calculates Arizona Income Tax
*
* INPUT PARAMETERS:
*	@subjamt	subject earnings
*	@fedtax	 	Federal Tax
*	@fedbasis	earnings subject to Federal Tax
*	@miscfactor	Arizonia tax rate 
*	@ppds		# of pay period per year (parameter added with issue 15752)
*
* OUTPUT PARAMETERS:
*	@amt		calculated tax amount
*	@msg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
(@subjamt bDollar = 0, @miscfactor bRate,
	 @ppds tinyint, @amt bDollar = 0 output, @msg varchar(255) = null output)
AS
SET NOCOUNT ON

DECLARE @Rate bRate
   
				--CHS 02/21/2011	- #143229
				--Note: from PM
				--AZ state tax calculations should distinguish exempt employees (i.e. 0.00 rate setup in PRED) 
				--from employees with no override (i.e. no PRED entry).  If a 0.00 rate exists then the calculated 
				--tax amount should be 0.00 (assuming no add-on amount).  If no PREDemployee override exists for 
				--AZ tax in PRED then the minimum current rate should be applied (0.8%).

				--CHS 02/21/2011	- #143229
				--To accomplish this we set @miscfactor to null so that the AZ tax routine know that a tax rate has 
				--not been intentially set to zero and that it shold default a minimum tax.

IF @miscfactor IS NOT NULL
	BEGIN
	SELECT @Rate = @miscfactor --product manager (Gary) confirmed that any rate is fair game
	END
ELSE	 
	BEGIN
	SELECT @Rate = .027
	END 

--SELECT @Rate = 0
--
---- default rate
--IF @miscfactor IN (.008, .013, .018, .027, .036, .042, .051)
--BEGIN
--	SELECT @Rate = @miscfactor
--END
   
/* calculate tax */
SELECT @amt = @Rate * @subjamt
   
RETURN 0



GO
GRANT EXECUTE ON  [dbo].[bspPRAZT11] TO [public]
GO
