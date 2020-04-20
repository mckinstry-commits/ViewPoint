SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRINC983    Script Date: 8/28/99 9:33:23 AM ******/
    CREATE proc [dbo].[bspPRINC983]
    /********************************************************
    * CREATED BY: 	EN 6/6/98
    * MODIFIED BY: GG 12/16/98
    *              EN 3/20/01 - issue 12748 - use addl exemption to calculate dependent exemption
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 1/4/05 - issue 26244  default exemptions
	*			   EN 2/21/2013 #148019 For Indiana/Kentucky reciprocity, make sure that IN County tax is not computed for KY residents
    *
    * USAGE:
    * 	Calculates Indiana County Tax
    *	Called from bspPRProcessLocal
    *
    * INPUT PARAMETERS:
    *	@subjamt 	subject earnings
    *	@ppds		# of pay pds per year
    *	@exempts	# of exemptions
    *	@rate		county tax rate
    *
    * OUTPUT PARAMETERS:
    *	@amt		calculated tax amount
    *	@msg		error message if failure
    *
    * RETURN VALUE:
    * 	0 	    	success
    *	1 		failure
    **********************************************************/
    (@subjamt bDollar = 0, 
	 @ppds tinyint = 0, 
	 @exempts tinyint = 0, 
	 @addexempts tinyint = 0,
     @rate bUnitCost = 0, 
	 @resstate bState = NULL, 
	 @amt bDollar = 0 OUTPUT, 
	 @msg varchar(255) = NULL OUTPUT)

    AS
    SET NOCOUNT ON
 
    IF @resstate = 'KY' 
    BEGIN
		SELECT @amt = 0
		RETURN 0
    END
  
    DECLARE @taxincome bDollar, 
			@regallowance bDollar, 
			@depallowance bDollar, 
			@procname varchar(30)
   
    SELECT @regallowance = 1000, @depallowance = 1500
    SELECT @procname = 'bspPRINC983'
   
    -- #26244 set default exemptions if passed in values are invalid
    IF @exempts IS NULL SELECT @exempts = 0
    IF @addexempts IS NULL SELECT @addexempts = 0
   
    IF @ppds = 0
    BEGIN
    	SELECT @msg = @procname + ':  Missing # of Pay Periods per year!'
    	RETURN 1
    END
   
    /* determine taxable income */
    SELECT @taxincome = (@subjamt * @ppds) - (@exempts * @regallowance) - (@addexempts * @depallowance)
    IF @taxincome < 0 SELECT @taxincome = 0
   
    /* calculate tax */
    SELECT @amt = (@taxincome * @rate) / @ppds
    IF @amt < 0 SELECT @amt = 0
   
   
    RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPRINC983] TO [public]
GO
