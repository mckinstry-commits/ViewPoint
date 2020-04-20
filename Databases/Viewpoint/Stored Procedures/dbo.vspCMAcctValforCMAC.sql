SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMAcctValforCMAC]
/************************************************************************
* CREATED:	mh 8/30/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Return Description for CM Account
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

   	(@cmco bCompany = 0, @cmacct bCMAcct = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
    
   if @cmco is null
   	begin
   	select @msg = 'Missing CM Company!', @rcode = 1
   	goto vspexit
   	end
   
   if @cmacct is null
   	begin
   	select @msg = 'Missing CM Account!', @rcode = 1
   	goto vspexit
   	end
   
   select @msg = Description 
   	from CMAC
   	where CMCo = @cmco and CMAcct = @cmacct
  
vspexit:

   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMAcctValforCMAC] TO [public]
GO
