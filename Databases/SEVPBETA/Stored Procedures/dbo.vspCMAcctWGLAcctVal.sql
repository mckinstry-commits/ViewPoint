SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMAcctWGLAcctVal]
/************************************************************************
* CREATED:    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

        
    (@cmco bCompany = null, @cmacct bCMAcct = null, @cmglacct bGLAcct = null output, @msg varchar(80) = '' output)

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
   
	select @msg = Description, @cmglacct = GLAcct from CMAC where CMCo = @cmco and CMAcct = @cmacct
      
	if @@rowcount = 0
   	begin
   		select @msg = 'CM Account not on file.', @rcode = 1
   		goto vspexit
   	end

vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMAcctWGLAcctVal] TO [public]
GO
