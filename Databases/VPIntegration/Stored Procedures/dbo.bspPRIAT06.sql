SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRIAT06    Script Date: 8/28/99 9:33:22 AM ******/
   CREATE    proc [dbo].[bspPRIAT06]
   /********************************************************
   * CREATED BY: 	EN 6/5/98
   * MODIFIED BY:	EN 6/5/98
   *			GH 1/08/03 issue 19911 - moved taxincome < 0 line and added 'if @amt<0 select @amt=0' to bottom
   *					EN 1/4/05 - issue 26244  default exemptions
   *					EN 2/15/05 - 27117  Tax update effective 4/1/05
   *				EN 12/13/05 - 119644  Update effective 4/1/05 ** addition to previous issue 27117 **
   *				EN 2/20/06 - 120279  update effective 4/1/06
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
   select @procname = 'bspPRIAT06'
 
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
   select @first2exempts =1650
   select @addlexempts = 4060
 
   if @exempts <= 1 select @taxincome = @taxincome - @first2exempts
   if @exempts > 1 select @taxincome = @taxincome - @addlexempts
 
   if @taxincome < 0 select @taxincome = 0 -- moved line to this spot issue 19911
 
   /* calculate tax */
   if @taxincome < 1300
   	begin
    	 select @amt = .0036 * @taxincome
    	 goto end_loop
   	end
   select @amt = (.0036 * 1300)
   select @taxincome = @taxincome - 1300
   
   if @taxincome < 1300
   	begin
    	 select @amt = @amt + (.0072 * @taxincome)
    	 goto end_loop
   	end
   select @amt = @amt + (.0072 * 1300)
   select @taxincome = @taxincome - 1300
   
   if @taxincome < 2600
   	begin
   	 select @amt = @amt + (.0243 * @taxincome)
   	 goto end_loop
   	end
   select @amt = @amt + (.0243 * 2600)
   select @taxincome = @taxincome - 2600
   
   if @taxincome < 6500
   	begin
   	 select @amt = @amt + (.045 * @taxincome)
   	 goto end_loop
   	end
   select @amt = @amt + (.045 * 6500)
   select @taxincome = @taxincome - 6500
   
   if @taxincome < 7800
   	begin
   	 select @amt = @amt + (.0612 * @taxincome)
   	 goto end_loop
   	end
   select @amt = @amt + (.0612 * 7800)
   select @taxincome = @taxincome - 7800
   
   if @taxincome < 6500
   	begin
   	 select @amt = @amt + (.0648 * @taxincome)
   	 goto end_loop
   	end
   select @amt = @amt + (.0648 * 6500)
   select @taxincome = @taxincome - 6500
   
   if @taxincome < 13000
   	begin
   	 select @amt = @amt + (.0680 * @taxincome)
   	 goto end_loop
   	end
   select @amt = @amt + (.0680 * 13000)
   select @taxincome = @taxincome - 13000
   
   if @taxincome < 19500
   	begin
   	 select @amt = @amt + (.0792 * @taxincome)
   	 goto end_loop
   	end
   select @amt = @amt + (.0792 * 19500)
   select @taxincome = @taxincome - 19500
   
   select @amt = @amt + (.0898 * @taxincome)
   
   end_loop:
   
   /* determine credits */
   select @firstcredit = 40 --#27117 changed from 20 to 40
   select @secondcredit = 40 --#27117 changed from 20 to 40
   select @addlcredits = 40
   
   select @creditamt = 0
   if @exempts > 0 select @creditamt = @firstcredit
   if @exempts > 1 select @creditamt = @creditamt + @secondcredit
   if @exempts > 2 select @creditamt = @creditamt + ((@exempts - 2) * @addlcredits)
   
   /* subtract credits and de-annualize */
   select @amt = round (((@amt - @creditamt) / @ppds),0)
 
 if @amt<0 select @amt=0
   
 select '@amt',@amt
 
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRIAT06] TO [public]
GO
