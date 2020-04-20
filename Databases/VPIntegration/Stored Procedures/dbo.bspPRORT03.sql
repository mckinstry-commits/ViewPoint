SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRORT03    Script Date: 8/28/99 9:33:32 AM ******/
   CREATE      proc [dbo].[bspPRORT03]
   /********************************************************
   * CREATED BY: 	GG 1/6/98
   * MODIFIED BY:	GG 1/6/98
   *               EN 11/01/99 - personal exemption updated - effective 1/1/2000
   *               GG 03/28/00 - set tax amount to 0.00 if calculated as negative
   *				EN 11/26/01 - issue 15185 - update effective 1/1/2002
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 2/3/03 - issue 20263  updated effective 3/1/2003
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
   
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @procname = 'bspPRORT03'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize Federal Tax and adjust for allowable deduction */
   select @fedmax = @fedtax * @ppds
   if @fedmax > 3500 select @fedmax = 3500
   
   /* annualize earnings and deduct allowance for exemptions and Fed tax */
   select @a = (@subjamt * @ppds) - @fedmax
   
   /* single with less than 3 exemptions */
   if @status = 'S' and @exempts < 3
   	begin
   	if @a < 300  goto bspexit
   	if @a < 8030
   		begin
   		select @basetax = 0, @dedn = 300, @rate = .07
   		goto bspcalc
   		end
   	select @basetax = 541, @dedn = 8030, @rate = .09
   	goto bspcalc
   	end
   /* all others */
   if @a < 2725 goto bspexit
   if @a < 16065
   	begin
   	select @basetax = 0, @dedn = 2725, @rate = .07
   	goto bspcalc
   	end
   select @basetax = 934, @dedn = 16065, @rate = .09
   
   bspcalc: /* calculate Oregon Tax */
   	select @amt = ((@basetax + (@a - @dedn) * @rate) - (147 * @exempts)) / @ppds
   
   bspexit:
       if @amt is null or @amt < 0 select @amt = 0
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRORT03] TO [public]
GO
