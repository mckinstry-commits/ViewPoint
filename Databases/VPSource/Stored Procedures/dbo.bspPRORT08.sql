SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRORT08]    Script Date: 01/16/2008 09:51:48 ******/
 CREATE  proc [dbo].[bspPRORT08]
 /********************************************************
 * MODIFIED BY:	GG 1/6/98
 *               EN 11/01/99 - personal exemption updated - effective 1/1/2000
 *               GG 03/28/00 - set tax amount to 0.00 if calculated as negative
 *				EN 11/26/01 - issue 15185 - update effective 1/1/2002
 *				EN 10/8/02 - issue 18877 change double quotes to single
 *				EN 2/3/03 - issue 20263  updated effective 3/1/2003
 *				EN 1/11/05 - issue 26244  default status and exemptions
 *				EN 1/20/06 - issue 119958  update effective 1/1/2006
 *				EN 12/05/06 - issue 123248  update effective 1/1/2007
 *				EN 12/16/08 - issue 126760  update effective 1/1/2008
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
 @fedmax bDollar, @stddedn bDollar, @procname varchar(30)
 
 select @rcode = 0, @basetax = 0, @dedn = 0, @rate = 0, @procname = 'bspPRORT08'
 
 -- #26244 set default status and/or exemptions if passed in values are invalid
 if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
 if @exempts is null select @exempts = 0
 
 if @ppds = 0
 	begin
 	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
 	goto bspexit
 	end
 
 /* annualize Federal Tax and adjust for allowable deduction */
 select @fedmax = @fedtax * @ppds
 if @fedmax > 5600 select @fedmax = 5600
 
 /* annualize earnings and deduct allowance for exemptions and Fed tax */
 select @a = (@subjamt * @ppds) - @fedmax
 
 /* single with less than 3 exemptions */
 if @status = 'S' and @exempts < 3
 	begin
	select @stddedn = 1825
 	if @a < 2850
		begin
		select @basetax = 0, @dedn = 0, @rate = .05
		goto bspexit
		end
 	if @a < 7150
 		begin
 		select @basetax = 143, @dedn = 2850, @rate = .07
 		goto bspcalc
 		end
 	select @basetax = 444, @dedn = 7150, @rate = .09
 	goto bspcalc
 	end
 /* all others */
 select @stddedn = 3650
 if @a < 5700
	begin
	select @basetax = 0, @dedn = 0, @rate = .05
	goto bspexit
	end
 if @a < 14300
 	begin
 	select @basetax = 285, @dedn = 5700, @rate = .07
 	goto bspcalc
 	end
 select @basetax = 887, @dedn = 14300, @rate = .09
 
 bspcalc: /* calculate Oregon Tax */
	select @a = @a - @stddedn
 	select @amt = ((@basetax + (@a - @dedn) * @rate) - (169 * @exempts)) / @ppds
 
 bspexit:
     if @amt is null or @amt < 0 select @amt = 0
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRORT08] TO [public]
GO
