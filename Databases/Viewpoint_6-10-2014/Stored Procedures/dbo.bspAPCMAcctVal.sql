SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[bspAPCMAcctVal]
   /***********************************************************
    * CREATED BY: MV   10/11/01
    * MODIFIED By : kb 8/5/2 - issue #18204 CHanged to use APCompany to validate
     	was using CMCompany against @apco
    *			MV 10/18/02 - 18878 quoted identifier cleanup
    * USAGE:
    * validates CM Account through APCo
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   APCo   AP Co get CMCo 
    *   CMAcct Account to validate against CMAC
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of CMAcct
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@apco bCompany = 0, @cmacct bCMAcct = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
    
   if @apco is null
   	begin
   	select @msg = 'Missing AP Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @cmacct is null
   	begin
   	select @msg = 'Missing CM Account!', @rcode = 1
   	goto bspexit
   	end
   
   select distinct @msg = a.Description 
   	from CMAC a join APCO b on b.CMCo = a.CMCo
   	where b.APCo = @apco and a.CMAcct = @cmacct
   
   
   if @@rowcount = 0
   	begin
   	select @msg = 'CM Account not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCMAcctVal] TO [public]
GO
