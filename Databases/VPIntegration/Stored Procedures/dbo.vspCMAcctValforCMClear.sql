SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMAcctValforCMClear]
/************************************************************************
* CREATED:	mh 6/6/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Validate CMAcct and return balance info
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/


    (@cmco bCompany, @cmacct bCMAcct, @begbal bDollar output, @workbal bDollar output,
	@stmtbal bDollar output, @variance bDollar output, @stmtdte bDate output,  @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

        exec @rcode = bspCMAcctVal @cmco, @cmacct, @msg output

		if @rcode = 1
			goto vspexit

		select @begbal = BegBal, @workbal = WorkBal, @stmtbal = StmtBal, @stmtdte = StmtDate, 
		@variance = (WorkBal - StmtBal) 
		from CMST where CMCo = @cmco and CMAcct = @cmacct and Status = 0 

		if @stmtbal is null
		begin
			select @msg = 'You must first have an Open Statement for this Account.', @rcode = 1
			goto vspexit
		end
		
--select @variance = @workbal - @stmtbal

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMAcctValforCMClear] TO [public]
GO
