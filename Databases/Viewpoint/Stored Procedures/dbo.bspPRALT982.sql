SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRALT982    Script Date: 8/28/99 9:33:12 AM ******/
      CREATE proc [dbo].[bspPRALT982]
      /********************************************************
      * CREATED BY: 	EN 6/1/98
      * MODIFIED BY:	EN 6/1/98
      * MODIFIED BY:       EN 11/29/99 - neg tax calced if subj amt input is 0 (ie. non-taxable amount)
      *			GH 07/16/01 - prevent negative amount to calculate
      *			EN 10/7/02 - issue 18877 change double quotes to single
      *			EN 12/03/03 - issue 23061  added isnull check
      *			EN 12/31/04 - issue 26244  default status and exemptions
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
      
      declare @rcode int, @a1 bDollar, @a2 bDollar, @basetax1 bDollar, @basetax2 bDollar,
      @rate1 bDollar, @rate2 bDollar, @rate3 bDollar, @procname varchar(30)
      
      select @rcode = 0
      select @rate1 = .02, @rate2 = .04, @rate3 = .05
      select @procname = 'bspPRALT982'
   
      -- #26244 set default status and/or exemptions if passed in values are invalid
      if (@status is null) or (@status is not null and @status not in ('O','S','M')) select @status = 'O'
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
      
      /* annualize earnings and calculate 20% */
      select @a1 = @subjamt * @ppds
      select @a2 = @a1 * .2
      
      /* no exemptions */
      if @status = 'O'
      
      	begin
      	 if @a2 > 2000 select @a2 = 2000 /* apply limit */
      	 select @basetax1 = 500, @basetax2 = 2500
      	end
      
      /* single */
      if @status = 'S'
      	begin
      	 if @a2 > 2000 select @a2 = 2000 /* apply limit */
      	 select @a2 = @a2 + 1500 /* personal exemption */
      	 select @basetax1 = 500, @basetax2 = 2500
      	end
      
      /* married */
      if @status = 'M'
      	begin
      	 if @a2 > 4000 select @a2 = 4000 /* apply limit */
      	 select @a2 = @a2 + 3000 /* personal exemption */
      	 select @basetax1 = 1000, @basetax2 = 5000
      	end
      
      /* multiply # of dependents other than spouse by $300 */
      select @a2 = @a2 + (300 * @exempts)
      
      /* less annualized Fed tax */
      select @a1 = @a1 - @a2 - (@fedtax * @ppds)
      
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
GRANT EXECUTE ON  [dbo].[bspPRALT982] TO [public]
GO
