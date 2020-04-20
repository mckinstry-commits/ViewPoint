SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLPurgeJrnlTrans    Script Date: 8/28/99 9:34:45 AM ******/
   
   CREATE  procedure [dbo].[bspGLPurgeJrnlTrans]
   /********************************************************
   * Created: ??
   * Modified: GG 05/13/98
   *           GG 07/31/01 - #13946 allow purge by selective Journal
   *			MV 01/31/03 - #20246 dbl quote cleanup.
   *
   * Used by GL Purge program to delete Journal Transactions.
   *
   * Updates bGLDT purge flag to 'Y', so that Account Summary
   * and Balances are not backed out when rows are deleted.
   *
   * Inputs:
   *   @glco       GL Company #
   *   @thrumth    Purge through month
   *   @jrnl       Journal to purge, all journals if null
   *
   * Output:
   *   @msg        Message
   *
   * Return:
   *   0           Successful
   *   1           Error
   *
   *********************************************************/
   
   	(@glco bCompany = null, @thrumth bMonth = null, @jrnl bJrnl = null, @msg varchar(255) output)
   
   as
   set nocount on
   declare @rcode int, @lastmthglclsd bMonth, @topurge int
   
   select @rcode = 0
   
   /* check for missing GL Company */
   if @glco is null
   	begin
   	select @msg = 'Missing GL Company #!', @rcode = 1
   	goto bspexit
   	end
   
   /* check for missing Month */
   if @thrumth is null
   	begin
   	select @msg = 'Missing month to purge through!', @rcode = 1
   	goto bspexit
   	end
   
   select @lastmthglclsd = LastMthGLClsd from bGLCO where GLCo = @glco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid GL Company #!', @rcode = 1
   	goto bspexit
   	end
   
   if @thrumth > @lastmthglclsd or @lastmthglclsd is null
   	begin
   	select @msg = 'Can only purge through the last month closed in GL!', @rcode = 1
   	goto bspexit
   	end
   
   -- update Purge flag in bGLDT so delete trigger will not remove amounts from bGLAS or bGLBL
   update bGLDT
   set Purge = 'Y'
   where GLCo = @glco and Mth <= @thrumth and Jrnl = isnull(@jrnl,Jrnl)
   
   select @topurge = @@rowcount    -- # of rows to be purged
   
   /* delete rows to be purged */
   delete bGLDT
   where GLCo = @glco and Purge = 'Y'
   
   if @@rowcount <> @topurge
   	begin
   	select @msg = 'Problems with purge.  Not all records were deleted!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg = 'Deleted ' + convert(varchar(10),@topurge) + ' GL Journal transactions.'
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLPurgeJrnlTrans] TO [public]
GO
