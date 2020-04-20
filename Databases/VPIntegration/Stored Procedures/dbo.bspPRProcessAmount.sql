SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRProcessAmount    Script Date: 8/28/99 9:33:33 AM ******/
   CREATE   procedure [dbo].[bspPRProcessAmount]
   /***********************************************************
    * CREATED BY: 	 GG  02/16/98
    * MODIFIED BY:    GG  02/16/98
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * Calculates Flat Amount deductions and liabilities.
    * Called from various bspPRProcess procedures.
    *
    * INPUT PARAMETERS
    *  @basisamt	calculation basis - earnings subject to this DL
    *  @amt		amount to use
    *  @limitbasis	basis to apply limit - 'N' none, 'S' subject amount, 'C' calculated amount
    *  @limitamt	limit amount
    *  @limitcorrect	correct calculated amount if limit exceeded - 'Y' or 'N'
    *  @accumelig	accumulated eligible earnings based on limit period
    *  @accumsubj 	accumulated subject earnings based on limit period
    *  @accumamt	accumulated DL amount based on limit period
    *  @ytdelig	year-to-date eligible earnings
    *  @ytdactual	year-to-date DL amount
    *
    * OUTPUT PARAMETERS
    *  @calcamt	calculated DL amount
    *  @eligamt	eligible earnings
    *  @errmsg	error message 
    * 
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   	@basisamt bDollar = null, @amt bUnitCost = null, @limitbasis char(1) = null, @limitamt bDollar,
   	@limitcorrect char(1), @accumelig bDollar, @accumsubj bDollar, @accumamt bDollar, @ytdelig bDollar,
   	@ytdactual bDollar, @calcamt bDollar output, @eligamt bDollar output, @errmsg varchar(255) output
   
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @calcamt = 0.00, @eligamt = 0.00
   
   if @basisamt is null or @amt is null or @limitbasis is null 
   	begin
   	select @errmsg = 'Missing Basis,  Amount, and/or Limit Basis.  Cannot calculate this Flat Amount Dedn/Liab!', @rcode = 1
   	goto bspexit
   	end
   
   if @basisamt = 0.00		/* set to 0.00 if no basis earnings */
   	begin
   	select @eligamt = 0.00, @calcamt = 0.00
   	goto bspexit
   	end
   if @limitbasis = 'N'	/* No Limit - reverse sign if negative earnings */
   	begin
   	select @eligamt = @basisamt, @calcamt = @amt
   	if  @basisamt < 0.00 select @calcamt = @calcamt * -1
   	end
   if @limitbasis = 'S'	/* Subject Amount Limit */
   	begin
   	select @eligamt = @basisamt
   	if @basisamt > 0.00		/* positive earnings */
   		begin
   		if (@eligamt + @accumelig) > @limitamt
   			begin
   			select @eligamt = @limitamt - @accumelig
   			if @limitcorrect = 'N' and @eligamt < 0.00 select @eligamt = 0.00
   			end
   		end
   	if @basisamt < 0.00		/* negative earnings */
   		begin
   		if @accumsubj >= @limitamt
   			begin
   			select @eligamt = @accumsubj + @basisamt - @limitamt
   			if @eligamt > 0.00 select @eligamt = 0.00
   			end
   		end
   	/* calculate DL amount */
   	select @calcamt =
   		case 
   			when @eligamt > 0.00 then @amt
   			when @eligamt < 0.00 then @amt * -1
   			else 0.00
   		end
   	end
   if @limitbasis = 'C'	/* Calculated Amount Limit */
   	begin
   	if @basisamt > 0.00		/* positive earnings */
   		begin
   		select @calcamt = @amt
   		if (@accumamt + @calcamt) > @limitamt
   			begin
   			select @calcamt = @limitamt - @accumamt
   			if @limitcorrect = 'N' and @calcamt < 0.00 select @calcamt = 0.00
   			end
   		select @eligamt = @basisamt
   		if @calcamt <= 0.00 select @eligamt = 0.00
   		end
   	if @basisamt < 0.00		/* negative earnings */
   		begin
   		if @accumamt < @limitamt
   			begin
   			select @eligamt = @basisamt
   			end
   		else
   			begin
   			select @eligamt = @accumsubj + @basisamt - @limitamt
   			if @eligamt > 0.00 select @eligamt = 0.00
   			end
   		select @calcamt =
   			case
   				when @eligamt > 0.00 then @amt
   				when @eligamt < 0.00 then @amt * -1
   				else 0.00
   			end
   		end
   	
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessAmount] TO [public]
GO
