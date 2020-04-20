SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMAcctVal    Script Date: 8/28/99 9:32:36 AM ******/
   CREATE   proc [dbo].[bspCMAcctVal]
   /***********************************************************
    * CREATED BY: SE   8/20/96
    * MODIFIED By : SE 8/20/96
    *				MV 04/12/06 - APCompany 6X recode - change err msg
    *
    * USAGE:
    * validates CM Account to make it is accessible through CMAC
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   CMCo   CM Co to validate agains 
    *   CMAcct Account to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of CMAcct
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@cmco bCompany = 0, @cmacct bCMAcct = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
    
   if @cmco is null
   	begin
   	select @msg = 'Missing CM Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @cmacct is null
   	begin
   	select @msg = 'Missing CM Account!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description 
   	from CMAC
   	where CMCo = @cmco and CMAcct = @cmacct
   
   
   if @@rowcount = 0
   	begin
   	select @msg = 'CM Account not on file.', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMAcctVal] TO [public]
GO
