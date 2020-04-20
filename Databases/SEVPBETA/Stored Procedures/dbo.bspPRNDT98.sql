SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRNDT98    Script Date: 8/28/99 9:33:29 AM ******/
   CREATE   proc [dbo].[bspPRNDT98]
   /********************************************************
   * CREATED BY: 	bc 6/15/98
   * MODIFIED BY:	GG 8/11/98
   *				EN 10/8/02 - issue 18877 change double quotes to single
   *
   * USAGE:
   * 	Calculates North Dakota Income Tax
   *
   * INPUT PARAMETERS:
   *	@subjamt	subject earnings
   *	@fedtax		Federal Tax 
   *	@fedbasis	earnings subject to Federal Tax
   *	@rate		North Dakota tax rate
   *
   * OUTPUT PARAMETERS:
   *	@amt		calculated tax amount
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   	(@subjamt bDollar = 0, @fedtax bDollar = 0, @fedbasis bDollar = 0, @rate bRate = 0,
    	 @amt bDollar = 0 output, @msg varchar(255) = null output)
   as
   set nocount on
   
   declare @rcode int, @procname varchar(30)
   
   select @rcode = 0, @procname = 'bspPRNDT98'
   
   /* if either basis or tax is 0, do not calculate tax */
   if @fedtax = 0 or @fedbasis = 0 goto bspexit
   
   
   /* calculate subject amount - proportion of Federal Tax on North Dakota earnings */
   select @subjamt = (@subjamt * @fedtax) / @fedbasis
   
   /* calculate North Dakota state income tax (federal) */
   select @amt = @subjamt * @rate
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRNDT98] TO [public]
GO
