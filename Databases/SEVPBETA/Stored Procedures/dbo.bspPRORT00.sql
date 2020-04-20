SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRORT00    Script Date: 8/28/99 9:33:32 AM ******/
   CREATE   proc [dbo].[bspPRORT00]
   /********************************************************
   * CREATED BY: 	GG 1/6/98
   * MODIFIED BY:	GG 1/6/98
   *               EN 11/01/99 - personal exemption updated - effective 1/1/2000
   *               GG 03/28/00 - set tax amount to 0.00 if calculated as negative
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Oregon Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status
   *	@exempts	# of exemptions
   *	@fedtax		Federal Income tax
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
   
   declare @rcode int, @a bDollar, @basetax bDollar, @dedn bDollar, @rate bRate,
   @fedmax bDollar, @procname varchar(30)
   
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @procname = 'bspPRORT00'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize Federal Tax and adjust for allowable deduction */
   select @fedmax = @fedtax * @ppds
   if @fedmax > 3000 select @fedmax = 3000
   
   /* annualize earnings and deduct allowance for exemptions and Fed tax */
   select @a = (@subjamt * @ppds) - @fedmax
   
   /* single with less than 3 exemptions */
   if @status = 'S' and @exempts < 3
   	begin
   	if @a < 1090  goto bspexit
   	if @a < 6800
   		begin
   		select @basetax = 0, @dedn = 1090, @rate = .07
   		goto bspcalc
   		end
   	select @basetax = 400, @dedn = 6800, @rate = .09
   	goto bspcalc
   	end
   /* all others */
   if @a < 2860 goto bspexit
   if @a < 13000
   	begin
   	select @basetax = 0, @dedn =2860, @rate = .07
   	goto bspcalc
   	end
   select @basetax = 710, @dedn = 13000, @rate = .09
   
   bspcalc: /* calculate Oregon Tax */
   	select @amt = ((@basetax + (@a - @dedn) * @rate) - (134 * @exempts)) / @ppds
   
   bspexit:
       if @amt is null or @amt < 0 select @amt = 0
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRORT00] TO [public]
GO
