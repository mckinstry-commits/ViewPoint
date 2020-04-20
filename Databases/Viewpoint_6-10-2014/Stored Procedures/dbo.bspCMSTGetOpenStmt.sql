SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspCMSTGetOpenStmt]
   /************************************************************************
   * CREATED:	MH 3/23/01   
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Get the latest opening statement for a CMAccount.  Used by CMST.    
   *
		122129, need to encapsulate in begin/end statement to resolve an incorrect syntax near 'b' 
		error.  mh 8/16/06  
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   	(@cmco bCompany = 0, @cmacct bCMAcct = null, @stmtdte bDate = null output, @msg varchar(60) = '' output)
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
   	select @msg = 'CM Account not on file!', @rcode = 1
   	goto bspexit
   	end
   
   select @stmtdte = max(StmtDate) from CMST where CMCo = @cmco and CMAcct = @cmacct and Status = 0
   
	--122129, need to encapsulate in begin/end statement to resolve an incorrect syntax near 'b' 
	--error.  mh 8/16/06 
 if @stmtdte is null
	begin
 	select @stmtdte = max(StmtDate) from CMST where CMCo = @cmco and CMAcct = @cmacct and Status = 1
	end

   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMSTGetOpenStmt] TO [public]
GO
