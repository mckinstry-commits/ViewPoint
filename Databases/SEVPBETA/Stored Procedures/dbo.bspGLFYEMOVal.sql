SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLFYEMOVal    Script Date: 8/28/99 9:32:46 AM ******/
   
   CREATE  procedure [dbo].[bspGLFYEMOVal]
   /**************************************************************
    *	MODIFIED BY: MV 01/31/03 - #20246 dbl quote cleanup.
    *
    * validates Fiscal Year Ending Month for a given GL Co#
    *
    * pass in GL Co# and month
    * returns 0 if month is FYEMO, 1 and error msg if not
    *
    ***************************************************************/
   
   	(@glco bCompany = 0, @mth bMonth = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @glco = 0
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @mth is null
   	begin
   	select @msg = 'Missing Month!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = 'Valid' from GLFY
   	where GLCo = @glco and FYEMO = @mth
   if @@rowcount = 0
   	begin
   	select @msg = 'This month is not a Fiscal Year Ending month!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLFYEMOVal] TO [public]
GO
