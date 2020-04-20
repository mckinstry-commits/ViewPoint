SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRFWT05    Script Date: 8/28/99 9:33:20 AM ******/
     CREATE proc [dbo].[bspPRFWT05]
     /********************************************************
     * CREATED BY: 	EN 12/12/00 - update effective 1/1/2001
     * MODIFIED BY:  EN 6/18/01 - update effective 7/1/2001
     *				EN 12/18/01 - update effective 1/1/2002
     *				EN 10/8/02 - issue 18877 change double quotes to single
     *				EN 11/22/02 - issue 19461  update effective 1/1/2003
     *				EN 5/29/03 - issue 21381  update effective retroactive to 1/1/2003
     *				EN 1/26/04 - issue 23516  default exempts to 0 if passed in as null
     *				EN 2/11/04 - issue 23668  remove automatic rounding in favor of using the 
     *											"Round result to nearest whole dollar" checkbox in PR Dedn/Liabs
     *				EN 12/2/04 - issue 26375  update effective 1/1/2005
     *
     * USAGE:
     * 	Calculates Federal Income Tax
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
     
     select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @amt = 0, @procname = 'bspPRFWT05'
     
     if (@status is not null and @status <> 'M') or (@status is null) select @status = 'S'    -- use single status if not valid
    
     if @exempts is null select @exempts = 0
     
     if @ppds = 0
     	begin
     	select @msg = @procname + ': Missing # of Pay Periods per year!', @rcode = 1
     	goto bspexit
     	end
     
     /* annualize earnings and deduct allowance for exemptions */
     select @a = (@subjamt * @ppds) - (@exempts * 3200)
     /* married */
     if @status = 'M'
     	begin
     	if @a < 8000  goto bspexit
     	if @a < 22600
     		begin
     		select @basetax = 0, @dedn = 8000, @rate = .1
     		goto bspcalc
     		end
     	if @a < 66200
     		begin
     		select @basetax = 1460, @dedn = 22600, @rate = .15
     		goto bspcalc
     		end
     	if @a < 120750
     		begin
     		select @basetax = 8000, @dedn = 66200, @rate = .25
     		goto bspcalc
     		end
     	if @a < 189600
     		begin
     		select @basetax = 21637.5, @dedn = 120750, @rate = .28
     		goto bspcalc
     		end
     	if @a < 333250
     		begin
     		select @basetax = 40915.5, @dedn = 189600, @rate = .33
     		goto bspcalc
     		end
     	select @basetax = 88320, @dedn = 333250, @rate = .35
     	goto bspcalc
     	end
     /* single */
     if @status = 'S'
     	begin
     	if @a < 2650 goto bspexit
     	if @a < 9800
     		begin
     		select @basetax = 0, @dedn =2650, @rate = .1
     		goto bspcalc
     		end
     	if @a < 31500
     		begin
     		select @basetax = 715, @dedn =9800, @rate = .15
     		goto bspcalc
     		end
     	if @a < 69750
     		begin
     		select @basetax = 3970, @dedn = 31500, @rate = .25
     		goto bspcalc
     		end
     	if @a < 151950
     		begin
     		select @basetax = 13532.5, @dedn = 69750, @rate = .28
     		goto bspcalc
     		end
     	if @a < 328250
     		begin
     		select @basetax = 36548.5, @dedn = 151950, @rate = .33
     		goto bspcalc
     		end
     	select @basetax = 94727.5, @dedn = 328250, @rate = .35
     	goto bspcalc
     	end
     bspcalc: /* calculate Federal Tax */
     	select @amt = (@basetax + (@a - @dedn) * @rate) / @ppds
     	if @amt is null or @amt < 0 select @amt = 0
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRFWT05] TO [public]
GO