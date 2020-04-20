SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRUTT082]
/********************************************************
* CREATED BY: 	bc 6/8/98
* MODIFIED BY:	bc 6/8/98
*				EN 12/18/01 - update effective 1/1/2002
*				EN 10/9/02 - issue 18877 change double quotes to single
*				EN 1/11/05 - issue 26244  default status and exemptions
*				EN 11/1/06 - issue 122962 update effective 1/1/2007
*				EN 11/06/07 - issue 126096 update effective 1/1/2008
*				EN 2/15/08 - issue 127123 update effective 1/1/2008 ... revision to first 1/1/2008 update
*				GG 03/13/08 - #127417 - don't allow negative tax amount
*
* USAGE:
* 	Calculates Utah Income Tax
*
* INPUT PARAMETERS:
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status
*	@exempts	# of exemptions
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
    
    declare @rcode int, @procname varchar(30), @creditperallowance int, @baseallowance int, 
	@lowbracketrate bRate, @highbracketrate bRate, @highbracketlimit bDollar, @highbracketwages bDollar,
	@totalallowance bDollar, @highbracketreduction bDollar, @taxreduction bDollar
    
    
    select @rcode = 0, @procname = 'bspPRUTT082'
	select @lowbracketrate = .05, @highbracketrate = .013
    
    -- #26244 set default status and/or exemptions if passed in values are invalid
    if (@status is null) or (@status is not null and @status not in ('S','M')) select @status = 'S'
    if @exempts is null select @exempts = 0
    
    if @ppds = 0
    	begin
    	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
    
    	goto bspexit
    	end
    
	-- Variables for Weekly pay period calculation (@ppds=52)
	if @ppds = 52
	begin
		select @creditperallowance = 2
		--base allowance and high bracket limits for single and married
		if @status = 'S' select @baseallowance = 5, @highbracketlimit = 231
		if @status = 'M' select @baseallowance = 7, @highbracketlimit = 346
 		goto bspcalc
   end

	-- Variables for Bi-Weekly pay period calculation (@ppds=26)
	if @ppds = 26
	begin
		select @creditperallowance = 5
		--base allowance and high bracket limits for single and married
		if @status = 'S' select @baseallowance = 10, @highbracketlimit = 462
		if @status = 'M' select @baseallowance = 14, @highbracketlimit = 692
		goto bspcalc
    end

	-- Variables for Semi-Monthly pay period calculation (@ppds=24)
	if @ppds = 24
	begin
		select @creditperallowance = 5
		--base allowance and high bracket limits for single and married
		if @status = 'S' select @baseallowance = 10, @highbracketlimit = 500
		if @status = 'M' select @baseallowance = 16, @highbracketlimit = 750
 		goto bspcalc
    end

	-- Variables for Monthly pay period calculation (@ppds=12)
	if @ppds = 12
	begin
		select @creditperallowance = 10
		--base allowance and high bracket limits for single and married
		if @status = 'S' select @baseallowance = 21, @highbracketlimit = 1000
		if @status = 'M' select @baseallowance = 31, @highbracketlimit = 1500
		goto bspcalc
    end

   
    bspcalc: /* calculate Utah Tax */
    
	-- low bracket tax amount 
    select @amt = round((@subjamt * @lowbracketrate),0) 
    if @amt < 0 select @amt = 0
	-- total allowance
	select @totalallowance = (@exempts * @creditperallowance) + @baseallowance
	-- high bracket wages (can be no less than 0)
	select @highbracketwages = (@subjamt - @highbracketlimit)
	if @highbracketwages < 0 select @highbracketwages = 0
	-- tax amount reduction for wages in the higher tax bracket
	select @highbracketreduction = round((@highbracketwages * @highbracketrate),0)
	-- total allowance minus high bracket reduction (can be no less than 0)
	select @taxreduction = @totalallowance - @highbracketreduction
	if @taxreduction < 0 select @taxreduction = 0
	-- reduce low bracket tax amount by allowancees and high bracket reduction
	select @amt = @amt - @taxreduction
	
	-- #127417 - don't allow negative amount
	if @amt < 0 select @amt = 0

    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUTT082] TO [public]
GO
