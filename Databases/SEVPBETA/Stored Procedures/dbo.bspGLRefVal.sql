SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Stored Procedure dbo.bspGLRefVal    Script Date: 8/28/99 9:34:46 AM ******/
   CREATE  proc [dbo].[bspGLRefVal]
   /**************************************************************
    * Created: ????
    * Modified: GG 04/11/01 - cleanup
    *			 MV 01/31/03 - #20246 dbl quote cleanup.
    *
    * Usage:
    *  Called from various GL forms to validate GL Reference #.  References
    *  may be setup in bGLRF prior to posting journal entries, or they will
    *  be added via the bGLAS insert trigger.
    *
    * Input:
    *  @glco       GL Co#
    *  @mth        Month
    *  @jrnl       Journal
    *  @adjust     Adjustment period - Y or N
    *
    * Output:
    *  @msg        Reference description or errro message
    *
    * Return code:
    *  @rcode      0 = success, 1 = error
    ************************************************************/
       (@glco bCompany = null, @mth bMonth = null, @jrnl bJrnl = null, @ref bGLRef= null,
   	 @adjust bYN, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @adj bYN
   
   select @rcode = 0, @msg = null
   
   if @glco is null
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   if @mth is null
   	begin
   	select @msg = 'Mising Month!', @rcode = 1
       goto bspexit
   	end
   if @jrnl is null
   	begin
   	select @msg = 'Missing Journal!', @rcode = 1
   	goto bspexit
   	end
   if @ref is null
   	begin
   	select @msg = 'Missing GL Reference!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @adj = Adjust
   from bGLRF
   where GLCo = @glco and @mth = Mth and @jrnl = Jrnl and @ref = GLRef
   if @@rowcount = 0 goto bspexit  -- return 0 if Reference not on file
   
   
   if @adj <> @adjust
   
   	begin
   	select @msg = 'Reference exists and the adjustment flags don''t match.', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLRefVal] TO [public]
GO
