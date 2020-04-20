SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRIAT982    Script Date: 8/28/99 9:33:22 AM ******/
     CREATE proc [dbo].[bspPRIAT982]
     /********************************************************
     * CREATED BY: 	EN 6/5/98
     * MODIFIED BY:	EN 6/5/98
     *			GH 1/08/03 issue 19911 - moved taxincome < 0 line and added 'if @amt<0 select @amt=0' to bottom
     *					EN 1/4/05 - issue 26244  default exemptions
     *
     * USAGE:
     * 	Calculates Iowa Income Tax
     *
     * INPUT PARAMETERS:
     *	@subjamt 	subject earnings
     *	@ppds		# of pay pds per year
     *	@status		filing status
     *	@exempts	# of exemptions
     *	@fedtax		Federal Income Tax
     *
     * OUTPUT PARAMETERS:
     *	@amt		calculated tax amount
     *	@msg		error message if failure
     *
     * RETURN VALUE:
     * 	0 	    	success
     *	1 		failure
     **********************************************************/
     (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'S', @exempts tinyint = 0,
      @fedtax bDollar = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
     as
     set nocount on
     
     declare @rcode int, @taxincome bDollar, @first2exempts bDollar, @addlexempts bDollar,
     @firstcredit bDollar, @secondcredit bDollar, @addlcredits bDollar, @creditamt bDollar,
     @procname varchar(30)
     
     select @rcode = 0
     select @procname = 'bspPRIAT982'
   
     -- #26244 set default exemptions if passed in values are invalid
     if @exempts is null select @exempts = 0
     
     if @ppds = 0
     	begin
     	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
     	goto bspexit
     	end
     
     /* determine taxable income */
   
     select @taxincome = (@subjamt - @fedtax) * @ppds
   
   
     /* adjust taxable income for standard deductions */
     select @first2exempts = 1500
     select @addlexempts = 3600
   
     if @exempts <= 1 select @taxincome = @taxincome - @first2exempts
     if @exempts > 1 select @taxincome = @taxincome - @addlexempts
   
     if @taxincome < 0 select @taxincome = 0 -- moved line to this spot issue 19911
   
     /* calculate tax */
     if @taxincome < 1100
     	begin
      	 select @amt = .0036 * @taxincome
      	 goto end_loop
     	end
     select @amt = (.0036 * 1100)
     select @taxincome = @taxincome - 1100
     
     if @taxincome < 1050
     	begin
      	 select @amt = @amt + (.0072 * @taxincome)
      	 goto end_loop
     	end
     select @amt = @amt + (.0072 * 1050)
     select @taxincome = @taxincome - 1050
     
     if @taxincome < 2150
     	begin
     	 select @amt = @amt + (.0243 * @taxincome)
     	 goto end_loop
     	end
     select @amt = @amt + (.0243 * 2150)
     select @taxincome = @taxincome - 2150
     
     if @taxincome < 5450
     	begin
     	 select @amt = @amt + (.0486 * @taxincome)
     	 goto end_loop
     	end
     select @amt = @amt + (.0486 * 5450)
     select @taxincome = @taxincome - 5450
     
     if @taxincome < 6500
     	begin
     	 select @amt = @amt + (.0653 * @taxincome)
     	 goto end_loop
     	end
     select @amt = @amt + (.0653 * 6500)
     select @taxincome = @taxincome - 6500
     
     if @taxincome < 5750
     	begin
     	 select @amt = @amt + (.0698 * @taxincome)
     	 goto end_loop
     	end
     select @amt = @amt + (.0698 * 5750)
     select @taxincome = @taxincome - 5750
     
     if @taxincome < 11000
     	begin
     	 select @amt = @amt + (.0752 * @taxincome)
     	 goto end_loop
     	end
     select @amt = @amt + (.0752 * 11000)
     select @taxincome = @taxincome - 11000
     
     if @taxincome < 16000
     	begin
     	 select @amt = @amt + (.0842 * @taxincome)
     	 goto end_loop
     	end
     select @amt = @amt + (.0842 * 16000)
     select @taxincome = @taxincome - 16000
     
     select @amt = @amt + (.0898 * @taxincome)
     
     end_loop:
     
     /* determine credits */
     select @firstcredit = 20
     select @secondcredit = 20
     select @addlcredits = 40
     
     select @creditamt = 0
     if @exempts > 0 select @creditamt = @firstcredit
     if @exempts > 1 select @creditamt = @creditamt + @secondcredit
     if @exempts > 2 select @creditamt = @creditamt + ((@exempts - 2) * @addlcredits)
     
     /* subtract credits and de-annualize */
     select @amt = round (((@amt - @creditamt) / @ppds),2)
   
   if @amt<0 select @amt=0
     
   select '@amt',@amt
   
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRIAT982] TO [public]
GO
