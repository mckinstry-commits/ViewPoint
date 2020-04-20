SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRORM04    Script Date: 8/28/99 9:33:32 AM ******/
   CREATE      proc [dbo].[bspPRORM04]
   /********************************************************
   * CREATED BY: 	EN 2/6/04 - as per issue 23613
   * MODIFIED BY:	
   *
   * USAGE:
   * 	Calculates Oregon's Multnomah County Income Tax
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
   @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @a bDollar, @dedn bDollar, @exmptn bDollar, @rate bRate,
   @procname varchar(30)
   
   select @rcode = 0, @dedn = 0, @exmptn = 0, @rate = 0, @procname = 'bspPRORM04'
   
   if @ppds = 0
   	begin
   	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   
   /* annualize earnings */
   select @a = (@subjamt * @ppds)
   
   /* single / married filing separately */
   if @status = 'S'
   	begin
   	select @dedn = 1640, @exmptn = 2500, @rate = .0125
   	goto bspcalc
   	end
   
   /* married filing jointly / head of household / qualifying widower */
   select @dedn = 3280, @exmptn = 5000, @rate = .0125
   
   bspcalc: /* calculate Oregon Tax */
   	select @amt = ((@a - @dedn - @exmptn) * @rate) / @ppds
   
   bspexit:
       if @amt is null or @amt < 0 select @amt = 0
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRORM04] TO [public]
GO
