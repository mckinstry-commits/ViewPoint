SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspCMRefNonAlphaVal]
   /************************************************************************
   * CREATED:	MH 11/13/01    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Validate CMRef so as not to allow non-numeric CMRefs 
   * 	for checks (trans type 1)    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@cmtranstype bCMTransType, @cmref bCMRef, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @cmtranstype is null	
   	begin
   		select @msg = 'Missing CMTrans Type', @rcode = 1
   		goto bspexit
   	end
   
   	if @cmref is null
   	begin
   		select @msg = 'Missing CMRef', @rcode = 1
   		goto bspexit
   	end
   
   	if @cmtranstype = 1
   	begin
   		if (select isnumeric(@cmref)) = 0
   			begin
   			select @msg = 'CM Reference must be numeric for Trans Type 1 - Check'
   			select @rcode = 1
   			end
   	end
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMRefNonAlphaVal] TO [public]
GO
