SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRLAT09    Script Date: 8/28/99 9:33:25 AM ******/
   CREATE proc [dbo].[bspPRLAT09]
   /********************************************************
   * CREATED BY: 	EN 6/6/98
   * MODIFIED BY:	EN 6/6/98
   *				EN 1/17/02 - issue 15940 - tax not calculated correctly
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *				EN 11/19/02 - issue 19394  tax update effective 1/1/2003
   *				EN 2/14/03 - issue 20151  replace check for over 2 reg exempts with code to put overflow into addl exempts
   *				EN 1/4/05 - issue 26244  default exemptions
   *				EN 12/09/08 - #131398  update effective 1/1/2009
   *
   * USAGE:
   * 	Calculates Louisianna Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt 	subject earnings
   *	@ppds		# of pay pds per year
   *	@regexempts	# of personal exemptions (should be 0, 1, or 2)
   *	@addlexempts	# of dependents
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   (@subjamt bDollar = 0, @ppds tinyint = 0, @regexempts tinyint = 0,
    @addlexempts tinyint = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
	as
	set nocount on

	declare @rcode int, @annualsalary bDollar, @taxrate1 bRate, @taxrate2 bRate, @taxrate3 bRate, 
	@lowbracket bDollar, @highbracket bDollar, @totalexempt bDollar, @procname varchar(30)

	select @rcode = 0, @procname = 'bspPRLAT09'
   
	if @ppds = 0
	begin
	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
	goto bspexit
	end

	-- #26244 set default exemptions if passed in values are invalid
	if @regexempts is null select @regexempts = 0
	if @addlexempts is null select @addlexempts = 0

	-- issue 20151  regular exemptions over 2 are transferred to additional exemptions
	if @regexempts > 2
	begin
	select @addlexempts = @addlexempts + (@regexempts - 2)
	select @regexempts = 2
	end

	-- define tax bracket range amounts and tax rates for ...
	-- ... taxpayers who are not married and filing jointly
	if @regexempts = 0 or @regexempts = 1
		select @taxrate1 = .021, @taxrate2 = .016, @taxrate3 = .0135, @lowbracket = 12500, @highbracket = 50000
	-- ... married filing jointly
	if @regexempts = 2
		select @taxrate1 = .021, @taxrate2 = .0165, @taxrate3 = .0135, @lowbracket = 25000, @highbracket = 100000

	-- annualize taxable income
	select @annualsalary = (@subjamt * @ppds)
	if @annualsalary < 0 goto bspexit

	-- compute tax
	if @annualsalary <= @lowbracket 
		select @amt = @taxrate1 * @annualsalary
	if @annualsalary >= @lowbracket and @annualsalary <= @highbracket
		select @amt = (@lowbracket * @taxrate1) + ((@taxrate1 + @taxrate2) * (@annualsalary - @lowbracket))
	if @annualsalary > @highbracket
		select @amt = ((@lowbracket * @taxrate1) + ((@highbracket - @lowbracket) * (@taxrate1 + @taxrate2))) +
						((@taxrate1 + @taxrate2 + @taxrate3) * (@annualsalary - @highbracket))
 
	-- determine total exemption/dependent credit amount
	select @totalexempt = (@regexempts * 4500) + (@addlexempts * 1000)
   
	-- compute annual exemption tax credit reduction
 	if @totalexempt <= @lowbracket 
		select @amt = @amt - (@taxrate1 * @totalexempt)
	if @totalexempt >= @lowbracket
		select @amt = @amt - ((@lowbracket * @taxrate1) + ((@taxrate1 + @taxrate2) * (@totalexempt - @lowbracket)))

	if @amt < 0 select @amt = 0

	-- de-annualized tax
	select @amt = @amt / @ppds


	bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRLAT09] TO [public]
GO
