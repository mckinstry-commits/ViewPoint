SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRDCT09]    Script Date: 01/10/2008 09:49:01 ******/
     CREATE  proc [dbo].[bspPRDCT09]
     /********************************************************
     * CREATED BY: 	EN 12/20/00 - tax update effective 1/1/2001
     *			GH 9/27/01 - issue 14740 correct wage bracket to 20K-30K
     *			EN 10/31/01 - issue 15106 update effective 1/1/2002
 	*			EN 4/25/02 - issue 17112 Wash DC recinds last tax update ... it reverts back to 2001 rates
 	*			EN 10/8/02 - issue 18877 change double quotes to single
 	*			EN 12/23/04 - issue 26634  update effective 1/1/2005
 	*			EN 12/31/04 - issue 26244  default status and exemptions
 	*			EN 1/11/05 - issue 26774  fixed minimum limit, status 'F'
	 *			EN 12/22/05 - issue 119704  update effective 1/1/2006
	*			EN 1/16/07 - issue 123575  update effective 1/1/2007
	*			EN 1/10/08 - issue 126686  update effective 1/1/2008
	*			EN 12/12/08 - #131426  update effective 1/1/2009
     *
     * USAGE:
     * 	Calculates District of Columbia Income Tax
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
    
     declare @rcode int, @a bDollar, @procname varchar(30)
    
     select @rcode = 0, @procname = 'bspPRDCT09'
 
     -- #26244 set default status and/or exemptions if passed in values are invalid
     if (@status is null) or (@status is not null and @status not in ('S','M','F')) select @status = 'S'
     if @exempts is null select @exempts = 0
    
     if @ppds = 0
     	begin
     	select @msg = @procname + ':  Missing # of Pay Periods per year!', @rcode = 1
     	goto bspexit
     	end
 
     /* annualize subject amount and subtract exemption amt */
     select @a = (@subjamt * @ppds) - (1750 * @exempts)
 
     /* calculate tax */
     select @amt = 0
     if @status <> 'F' --Single Filers or Married Persons filing jointly
         begin
         if @a >= 4200 and @a < 10000 select @amt = ((@a - 4200) * .04)
         if @a >= 10000 and @a < 40000 select @amt = (232 + (@a - 10000) * .06)
         if @a >= 40000 select @amt = (2032 + (@a - 40000) * .085)
         end
     if @status = 'F' --Married Persons filing separate retrun or combined separate return
         begin
         if @a >= 2100 and @a < 10000 select @amt = ((@a - 2100) * .04)
         if @a >= 10000 and @a < 40000 select @amt = (316 + (@a - 10000) * .06)
         if @a >= 40000 select @amt = (2116 + (@a - 40000) * .085)
         end
     select @amt = @amt / @ppds
    
    
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDCT09] TO [public]
GO
