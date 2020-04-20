SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLRevJrnlVal    Script Date: 8/28/99 9:34:46 AM ******/
   CREATE  proc [dbo].[bspGLRevJrnlVal]
   /********************************************************
    *	MODIFIED BY:	MV 01/31/03 - #20246 dbl quote cleanup.
    *
    * validates that this is a valid reversal Journal
    * pass in GL Co# and Journal
    * returns Journal description
   */
   	(@glco bCompany = 0, @jrnl bJrnl = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int, @rev bJrnl
   select @rcode = 0
   
   select @rev = 'N'
   
   if @glco = 0
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @jrnl is null
   	begin
   	select @msg = 'Missing Journal!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @rev=Rev from bGLJR
   	where GLCo = @glco and Jrnl = @jrnl
   
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Journal not on file!', @rcode = 1
   	end
   else
      begin
        if @rev='N'
           select @msg = 'Journal not setup as a reversing journal!', @rcode=1
      end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLRevJrnlVal] TO [public]
GO
