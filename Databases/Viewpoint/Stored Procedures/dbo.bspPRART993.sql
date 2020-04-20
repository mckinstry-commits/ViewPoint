SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRART993    Script Date: 8/28/99 9:33:12 AM ******/
   CREATE  proc [dbo].[bspPRART993]
   /********************************************************
   * CREATED BY: 	EN 6/1/98
   * MODIFIED BY:	EN 1/12/99
   *				EN 10/7/02 - issue 18877 change double quotes to single
   *				EN 12/03/03 - issue 23061  added isnull check
   *				EN 12/31/04 - issue 26244  default exemptions
   *				EN 2/07/05 - issue 26943  added low income tax rate computation
   *
   * USAGE:
   * 	Calculates Arkansas Income Tax
   *
   * INPUT PARAMETERS:
   
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status
   *	@exempts	# of exemptions
   *	@miscfactor 1 if using low income tax rates, else 0
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = '', @exempts tinyint = 0,
    @miscfactor bRate, @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @a1 bDollar, @baseamt bDollar, @rate bUnitCost, @excessover bDollar, @procname varchar(30)
   
   --#26943 declarations
   declare @a2 bDollar
   
   select @rcode = 0, @a1 = 0, @amt = 0
   select @procname = 'bspPRART993'
   
   -- #26244 set default exemptions if passed in value is invalid
   if (@status is null) or (@status is not null and @status not in ('','S','M','H')) select @status = ''
   if @miscfactor is not null and @miscfactor = 0 select @status = '' --status only used for low income tax rate computations (ie. when misc factor=1)
   if @exempts is null select @exempts = 0
   
   /* validate pay periods */
   if @ppds = 0
   	begin
   	select @msg = isnull(@procname,'') + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings */
   select @a1 = @subjamt * @ppds
   
   /* subtract standard deduction from annualized earnings */
   select @a2 = @a1 - 2000
   
   /* determine tax bracket */
   if @a2 < 3000
   	begin
   	select @baseamt=0, @rate=.01, @excessover=3000
   	goto end_bracket
   	end
   if @a2 < 6000
   	begin
   	select @baseamt=30, @rate=.025, @excessover=@a2-3000
   	goto end_bracket
   	end
   if @a2 < 9000
   	begin
   	select @baseamt=105, @rate=.035, @excessover=@a2-6000
   	goto end_bracket
   	end
   if @a2 < 15000
   	begin
   	select @baseamt=210, @rate=.045, @excessover=@a2-9000
   	goto end_bracket
   	end
   if @a2 < 25000
   	begin
   	select @baseamt=480, @rate=.06, @excessover=@a2-15000
   	goto end_bracket
   	end
   select @baseamt=1080, @rate=.07, @excessover=@a2-25000
   
   end_bracket:
   
   /* calculate tax */
   select @amt = @baseamt + (@rate * @excessover)
   
   --#26943 low income tax rate computations
   if @status='S' --single
   	begin
   	if @a1 >= 7800 and @a1 <= 9300 select @amt = @amt / 3 --use 1/3 of normal tax rate
   	if @a1 >= 9301 and @a1 <= 11400 select @amt = (@amt / 3) * 2 --use 2/3 of normal tax rate
   	end
   if @status='M' --married filing joint
   	begin
   	if @a1 >= 15500 and @a1 <= 16000 select @amt = @amt / 3 --use 1/3 of normal tax rate
   	if @a1 >= 16001 and @a1 <= 16200 select @amt = (@amt / 3) * 2 --use 2/3 of normal tax rate
   	end
   if @status='H' --unmarried head of household
   	begin
   	if @a1 >= 12100 and @a1 <= 15200 select @amt = @amt / 3 --use 1/3 of normal tax rate
   	if @a1 >= 15201 and @a1 <= 16200 select @amt = (@amt / 3) * 2 --use 2/3 of normal tax rate
   	end
   
   /* subtract personal tax credits and de-annualize */
   select @amt = (@amt - (@exempts * 20)) / @ppds
   if @amt < 0 select @amt = 0
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRART993] TO [public]
GO
