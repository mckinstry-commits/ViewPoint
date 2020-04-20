SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRALT07    Script Date: 8/28/99 9:33:12 AM ******/
    CREATE proc [dbo].[bspPRALT07]
    /********************************************************
    * CREATED BY: 	EN 6/1/98
    * MODIFIED BY:	EN 6/1/98
    * MODIFIED BY:       EN 11/29/99 - neg tax calced if subj amt input is 0 (ie. non-taxable amount)
    *			GH 07/16/01 - prevent negative amount to calculate
    *			EN 10/7/02 - issue 18877 change double quotes to single
    *			EN 12/03/03 - issue 23061  added isnull check
    *			EN 12/31/04 - issue 26244  default status and exemptions
	*			EN 11/03/06 - issue 123000 tax update effective 1/1/2007
    *
    * USAGE:
    * 	Calculates Alabama Income Tax
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
    (@subjamt bDollar = 0, @ppds tinyint = 0, @status char(1) = 'O', @exempts tinyint = 0,
    @fedtax bDollar = 0, @amt bDollar = 0 output, @msg varchar(255) = null output)
    as
    set nocount on
    
    declare @rcode int, @a1 bDollar, @stddedn bDollar, @persexempt bDollar, @depexempt bDollar,
	@basetax1 bDollar, @basetax2 bDollar,
    @rate1 bDollar, @rate2 bDollar, @rate3 bDollar, @increment tinyint, @procname varchar(30)
    
    select @rcode = 0
    select @rate1 = .02, @rate2 = .04, @rate3 = .05
    select @procname = 'bspPRALT07'
 
    -- #26244 set default status and/or exemptions if passed in values are invalid
    if (@status is null) or (@status is not null and @status not in ('O','S','H','M','B')) select @status = 'O'
    if @exempts is null select @exempts = 0
 
    if @ppds = 0
    	begin
    	select @msg = isnull(@procname,'') + ':  Missing # of Pay Periods per year!', @rcode = 1
    	goto bspexit
    	end
    
    if @subjamt < .01
        begin
        select @amt = 0
        goto bspexit
        end
    
    /* annualize earnings */
    select @a1 = @subjamt * @ppds

    /* deduct standard dedn from earnings */
	--establish minimum std dedn
	if @status = 'O' or @status = 'S' or @status = 'H' or @status = 'M' select @stddedn = 2000
	if @status = 'B' select @stddedn = 4000
	--set the deduction increment per $500 increase
	if @status = 'O' or @status = 'S' select @increment = 25
	if @status = 'H' select @increment = 135
	if @status = 'B' select @increment = 175
	if @status = 'M' select @increment = 88
	--compute the exact std dedn based on earnings with a cap just past the dedn for 20,001 thru 20,500
	if @status = 'O' or @status = 'S' or @status = 'B' or @status = 'H'
		begin
		if @a1 <= 29500 select @stddedn = @stddedn + @increment
		if @a1 <= 29000 select @stddedn = @stddedn + @increment
		if @a1 <= 28500 select @stddedn = @stddedn + @increment
		if @a1 <= 28000 select @stddedn = @stddedn + @increment
		if @a1 <= 27500 select @stddedn = @stddedn + @increment
		if @a1 <= 27000 select @stddedn = @stddedn + @increment
		if @a1 <= 26500 select @stddedn = @stddedn + @increment
		if @a1 <= 26000 select @stddedn = @stddedn + @increment
		if @a1 <= 25500 select @stddedn = @stddedn + @increment
		if @a1 <= 25000 select @stddedn = @stddedn + @increment
		if @a1 <= 24500 select @stddedn = @stddedn + @increment
		if @a1 <= 24000 select @stddedn = @stddedn + @increment
		if @a1 <= 23500 select @stddedn = @stddedn + @increment
		if @a1 <= 23000 select @stddedn = @stddedn + @increment
		if @a1 <= 22500 select @stddedn = @stddedn + @increment
		if @a1 <= 22000 select @stddedn = @stddedn + @increment
		if @a1 <= 21500 select @stddedn = @stddedn + @increment
		if @a1 <= 21000 select @stddedn = @stddedn + @increment
		if @a1 <= 20500 select @stddedn = @stddedn + @increment
		if @a1 <= 20000 select @stddedn = @stddedn + @increment
		end
	--compute the exact std dedn based on earnings with a cap just past the dedn for 10,001 thru 10,250
	if @status='M'
		begin
		if @a1 <= 14750 select @stddedn = @stddedn + @increment
		if @a1 <= 14500 select @stddedn = @stddedn + @increment
		if @a1 <= 14250 select @stddedn = @stddedn + @increment
		if @a1 <= 14000 select @stddedn = @stddedn + @increment
		if @a1 <= 13750 select @stddedn = @stddedn + @increment
		if @a1 <= 13500 select @stddedn = @stddedn + @increment
		if @a1 <= 13250 select @stddedn = @stddedn + @increment
		if @a1 <= 13000 select @stddedn = @stddedn + @increment
		if @a1 <= 12750 select @stddedn = @stddedn + @increment
		if @a1 <= 12500 select @stddedn = @stddedn + @increment
		if @a1 <= 12250 select @stddedn = @stddedn + @increment
		if @a1 <= 12000 select @stddedn = @stddedn + @increment
		if @a1 <= 11750 select @stddedn = @stddedn + @increment
		if @a1 <= 11500 select @stddedn = @stddedn + @increment
		if @a1 <= 11250 select @stddedn = @stddedn + @increment
		if @a1 <= 11000 select @stddedn = @stddedn + @increment
		if @a1 <= 10750 select @stddedn = @stddedn + @increment
		if @a1 <= 10500 select @stddedn = @stddedn + @increment
		if @a1 <= 10250 select @stddedn = @stddedn + @increment
		if @a1 <= 10000 select @stddedn = @stddedn + @increment
		end

	-- establish Personal Exemption
	if @status = 'O' select @persexempt = 0
	if @status = 'S' or @status = 'M' select @persexempt = 1500
	if @status = 'B' or @status = 'H' select @persexempt = 3000

	-- establish Dependent Exemption
	if @a1 <= 20000 select @depexempt = 1000 * @exempts
	if @a1 > 20000 and @a1 <= 100000 select @depexempt = 500 * @exempts
	if @a1 > 100000 select @depexempt = 300 * @exempts

	-- subtract std dedn, ,personal exemption, dependent exemption, and annual fed tax from annual earnings
	select @a1 = @a1 - (@stddedn + @persexempt + @depexempt + (@fedtax*@ppds) )

	-- establish tax brackets
    if @status = 'O' or @status = 'S' or @status = 'H' or @status = 'M' select @basetax1 = 500, @basetax2 = 2500
    if @status = 'B' select @basetax1 = 1000, @basetax2 = 5000
  
    /* calculate tax */
    if @a1 < @basetax1
    	begin
     	 select @amt = @rate1 * @a1
     	 goto end_calc
    	end
    select @amt = (@rate1 * @basetax1)
    select @a1 = @a1 - @basetax1
    if @a1 < @basetax2
    	begin
     	 select @amt = @amt + (@rate2 * @a1)
     	 goto end_calc
    	end
    select @amt = @amt + (@rate2 * @basetax2)
    select @a1 = @a1 - @basetax2
    select @amt = @amt + (@rate3 * @a1)
    
    end_calc:
 
    select @amt = @amt / @ppds
    if @amt < 0 select @amt = 0
    
    
    bspexit:
    
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRALT07] TO [public]
GO
