SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRFWT98    Script Date: 8/28/99 9:33:20 AM ******/
   CREATE   proc [dbo].[bspPRFWT98]
   /********************************************************
   * CREATED BY: 	GG 1/6/98
   * MODIFIED BY:	GG 07/01/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates 1998 Federal Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@status		filing status (S or M)
   *	@exempts	# of exemptions
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated Fed tax amount
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
   declare @rcode int, @a bDollar, @basetax bDollar, @dedn bDollar, @rate bRate, @procname varchar(30)
   select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @amt = 0, @procname = 'bspPRFWT98'
   if @ppds = 0
   	begin
   	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
   	goto bspexit
   	end
   /* annualize earnings and deduct allowance for exemptions */
   select @a = (@subjamt * @ppds) - (@exempts * 2700)
   /* married */
   if @status = 'M'
   	begin
   	if @a < 6450  goto bspexit
   	if @a < 46750
   		begin
   		select @basetax = 0, @dedn = 6450, @rate = .15
   		goto bspcalc
   		end
   	if @a < 96450
   		begin
   		select @basetax = 6045, @dedn = 46750, @rate = .28
   		goto bspcalc
   		end
   	if @a < 160350
   		begin
   		select @basetax = 19961, @dedn = 96450, @rate = .31
   		goto bspcalc
   		end
   	if @a < 282850
   		begin
   		select @basetax = 39770, @dedn = 160350, @rate = .36
   		goto bspcalc
   		end
   	select @basetax = 83870, @dedn = 282850, @rate = .396
   	goto bspcalc
   	end
   /* single */
   if @status = 'S'
   	begin
   	if @a < 2650 goto bspexit
   	if @a < 26900
   		begin
   		select @basetax = 0, @dedn =2650, @rate = .15
   		goto bspcalc
   		end
   	if @a < 57450
   		begin
   		select @basetax = 3637.5, @dedn = 26900, @rate = .28
   		goto bspcalc
   		end
   	if @a < 129650
   		begin
   		select @basetax =12191.5, @dedn = 57450, @rate = .31
   		goto bspcalc
   		end
   	if @a < 280000
   		begin
   		select @basetax =34573.5, @dedn = 129650, @rate = .36
   		goto bspcalc
   		end
   	select @basetax = 88699.5, @dedn = 280000, @rate = .396
   	goto bspcalc
   	end
   bspcalc: /* calculate Federal Tax */
   	select @amt = (@basetax + (@a - @dedn) * @rate) / @ppds
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT98] TO [public]
GO
