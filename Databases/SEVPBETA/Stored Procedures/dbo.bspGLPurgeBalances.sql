SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLPurgeBalances    Script Date: 8/28/99 9:34:44 AM ******/
   CREATE  procedure [dbo].[bspGLPurgeBalances]
   /********************************************************
   * Created: ??
   * Modified:	MV 01/31/03 - #20246 dbl quote cleanup.
   *			GG 10/17/08 - #130666 - spelling correction
   *
   * Used by GL Purge program to delete Account Balances and Budget info.
   *
   * Pass: GL Company #, Through Month
   *
   * Returns: 0 and message if successful, 1 and message if error
   *********************************************************/
   
   	(@glco bCompany = null, @fyemo bMonth = null, @msg varchar(60) output)
   
   as
   set nocount on
   declare @rcode int, @lastmthglclsd bMonth, @lastfyemo bMonth
   
   select @rcode = 0
   
   /* check for missing GL Company */
   if @glco is null
   	begin
   	select @msg = 'Missing GL Company #!', @rcode = 1
   	goto bspexit
   	end
   
   /* check for missing Fiscal Year ending month */
   if @fyemo is null
   	begin
   	select @msg = 'Missing Fiscal Year ending month to purge through!', @rcode = 1
   	goto bspexit
   	end
   
   select @lastmthglclsd = LastMthGLClsd from bGLCO where GLCo = @glco
   if @@rowcount = 0 
   	begin
   	select @msg = 'Invalid GL Company #!', @rcode = 1
   	goto bspexit
   	end
   
   if not exists(select * from bGLFY where GLCo = @glco and FYEMO = @fyemo)
   	begin
   	select @msg = 'Invalid Fiscal Year ending month!', @rcode = 1
   	goto bspexit
   	end
   
   /* get last fully closed fiscal year */
   select @lastfyemo = max(FYEMO) from bGLFY where GLCo = @glco
   	and FYEMO <= @lastmthglclsd
   if @lastfyemo is null
   	begin
   	select @msg = 'No previous Fiscal Year has been fully closed!', @rcode = 1
   	goto bspexit
   	end
   
   if @fyemo > @lastfyemo
   	begin
   	select @msg = 'Can only purge through the last closed Fiscal Year!', @rcode = 1
   	goto bspexit
   	end
   
   /* delete Account Balances through month */
   delete bGLBL where GLCo = @glco and Mth <= @fyemo
   
   /* delete Yearly Balances through fiscal year ending month */
   delete bGLYB where GLCo = @glco and FYEMO <= @fyemo
   
   /* delete Monthly Budgets through month */
   delete bGLBD where GLCo = @glco and Mth <= @fyemo
   
   /* delete Yearly Budet Revision through fiscal year ending month */
   delete bGLBR where GLCo = @glco and FYEMO <= @fyemo
   
   select @msg = 'Successfully deleted Account Balance and Budget entries.'
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLPurgeBalances] TO [public]
GO
