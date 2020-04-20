SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAZT98    Script Date: 8/28/99 9:33:12 AM ******/
   CREATE  proc [dbo].[bspPRAZT98]
   /********************************************************
   * CREATED BY: 	EN 6/2/98
   * MODIFIED BY:  GG 8/11/98
   *				EN 10/7/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates Arizona Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt	subject earnings
   *	@fedtax	 	Federal Tax
   *	@fedbasis	earnings subject to Federal Tax
   *	@miscfactor	Arizonia tax rate 
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   	(@subjamt bDollar = 0, @fedtax bDollar, @fedbasis bDollar, @miscfactor bRate,
    	 @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @rate bDollar, @procname varchar(30)
   
   select @rcode = 0, @rate = 0, @procname = 'bspPRAZT98'
   
   /* if either basis or tax is 0, do not calculate tax */
   if @fedbasis = 0 or @fedtax = 0 goto bspexit
   
   /* calculate subject amount - proportion of Federal Tax on Arizonia earnings */
   select @subjamt = (@subjamt * @fedtax) / @fedbasis
   
   /* find tax rate */
   select @rate = .32
   if @miscfactor = .1 select @rate = @miscfactor
   if @miscfactor = .2 select @rate = @miscfactor
   if @miscfactor = .17 select @rate = @miscfactor
   if @miscfactor = .22 select @rate = @miscfactor
   if @miscfactor = .28 select @rate = @miscfactor
   
   /* calculate tax */
   select @amt = @rate * @subjamt
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAZT98] TO [public]
GO
