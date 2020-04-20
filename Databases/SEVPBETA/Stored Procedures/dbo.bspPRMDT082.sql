SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMDT082]    Script Date: 12/13/2007 10:19:49 ******/
    CREATE proc [dbo].[bspPRMDT082]
    /********************************************************
    * CREATED BY: 	EN 11/01/01 - this revision effective 1/1/2002
    * MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
    *				EN 12/02/03 - issue 23145  update effective 1/1/2004
    *				EN 1/14/04 - issue 23500  Maryland state tax calculating negative amount in certain cases
    *				EN 11/16/04 - issue 26219  update effective 1/1/2005 ... non-resident rate changed to 6% but resident rate base (4.75%) remains the same
    *											passing in @res (Y/N) flag which specifies whether or not employee is a resident
    *				EN 1/4/05 - issue 26244  default exemptions and miscfactor
	*				EN 12/13/07 - issue 126491 update effective 1/1/2008 - exemption changed and added tax brackets rather than just using a flat tax rate
	*				EN 7/24/08 - #129150  update effective 7/1/2008 - added tax bracket and modified base tax computation
    *
    * USAGE:
    * 	Calculates Maryland Income Tax
    *
    * INPUT PARAMETERS:
    *	@subjamt 	subject earnings
    *	@ppds		# of pay pds per year
    *	@exempts	# of exemptions
    *	@miscfactor	factor used for speacial tax routines
    *
    * OUTPUT PARAMETERS:
    *	@amt		calculated tax amount
    *	@msg		error message if failure
    *
    * RETURN VALUE:
    * 	0 	    	success
    *	1 		failure
    **********************************************************/
    (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = null, @exempts tinyint = 0,
    @miscfactor bRate = 0, @res char(1) = 'Y', @amt bDollar = 0 output, @msg varchar(255) = null output)
    as
    set nocount on
    
    declare @rcode int, @annualized_wage bDollar, @rate bRate,
    @procname varchar(30), @deductions bDollar,
	@bracket1 int, @bracket2 int, @bracket3 int, @bracket4 int, @basetax bDollar, @excesswage bDollar

    select @rcode = 0, @rate = 0, @procname = 'bspPRMDT082'
   
    -- #26244 set default exemptions and/or misc factor if passed in values are invalid
    if @exempts is null select @exempts = 0
    if @miscfactor is null select @miscfactor = 0
    
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    	goto bspexit
    	end
    
    
    /* annualize earnings */
    select @annualized_wage = (@subjamt * @ppds)
    
    /* no tax on annual income below 5000 */
    if @annualized_wage < 5000
    	begin
    	select @amt = 0
    	goto bspexit
    	end
    
    select @deductions = @annualized_wage * .15
    
    if @deductions < 1500 select @deductions = 1500
    if @deductions > 2000 select @deductions = 2000
    
    
    select @annualized_wage = @annualized_wage - @deductions - (3200 * @exempts)
    
    if @annualized_wage < 0 select @annualized_wage = 0
    
   --#126491 add brackets
   /* select calculation elements for Married Filing Joint or Head of Household */
   if @status = 'M'
		begin
		select @bracket1 = 200000, @bracket2 = 350000, @bracket3 = 500000, @bracket4 = 1000000
		--1st bracket
		select @basetax = 0, @rate = .0475 + @miscfactor
		if @annualized_wage <= @bracket1
			begin
			select @excesswage = @annualized_wage
			goto bspcalc
			end
		--2nd bracket
		select @basetax = @rate * @bracket1, @rate = .05 + @miscfactor
		if @annualized_wage <= @bracket2
			begin
			select @excesswage = @annualized_wage - @bracket1
			goto bspcalc
			end
		--3rd bracket
		select @basetax = @basetax + (@rate * (@bracket2 - @bracket1)), @rate = .0525 + @miscfactor
		if @annualized_wage <= @bracket3
			begin
			select @excesswage = @annualized_wage - @bracket2
			goto bspcalc
			end
		--4th bracket
		select @basetax = @basetax + (@rate * (@bracket3 - @bracket2)), @rate = .055 + @miscfactor
		if @annualized_wage <= @bracket4
			begin
			select @excesswage = @annualized_wage - @bracket3
			goto bspcalc
			end
		--5th (highest) bracket
		select @basetax = @basetax + (@rate * (@bracket4 - @bracket3)), @rate = .0625 + @miscfactor
		select @excesswage = @annualized_wage - @bracket4
		goto bspcalc
		end
  
   /* select calculation elements for Single, Married Filing Separately, or Dependent */
		begin
		select @bracket1 = 150000, @bracket2 = 300000, @bracket3 = 500000, @bracket4 = 1000000
		--1st bracket
		select @basetax = 0, @rate = .0475 + @miscfactor
		if @annualized_wage <= @bracket1
			begin
			select @excesswage = @annualized_wage
			goto bspcalc
			end
		--2nd bracket
		select @basetax = @rate * @bracket1, @rate = .05 + @miscfactor
		if @annualized_wage <= @bracket2
			begin
			select @excesswage = @annualized_wage - @bracket1
			goto bspcalc
			end
		--3rd bracket
		select @basetax = @basetax + (@rate * (@bracket2 - @bracket1)), @rate = .0525 + @miscfactor
		if @annualized_wage <= @bracket3
			begin
			select @excesswage = @annualized_wage - @bracket2
			goto bspcalc
			end
		--4th bracket
		select @basetax = @basetax + (@rate * (@bracket3 - @bracket2)), @rate = .055 + @miscfactor
		if @annualized_wage <= @bracket4
			begin
			select @excesswage = @annualized_wage - @bracket3
			goto bspcalc
			end
		--5th (highest) bracket
		select @basetax = @basetax + (@rate * (@bracket4 - @bracket3)), @rate = .0625 + @miscfactor
		select @excesswage = @annualized_wage - @bracket4
		goto bspcalc
		end

    bspcalc: /* calculate Maryland Tax */
		select @amt = (@basetax + (@excesswage * @rate)) / @ppds

   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMDT082] TO [public]
GO
