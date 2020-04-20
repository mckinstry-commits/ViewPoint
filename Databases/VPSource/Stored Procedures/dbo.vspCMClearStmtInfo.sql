SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMClearStmtInfo]
/************************************************************************
* CREATED:	mh 5/16/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Retreive statement info for use in CMClear.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@cmco bCompany, @cmacct bCMAcct, @begbal bDollar output, @workbal bDollar output, @stmtbal bDollar output, 
	@stmtdte bDate output, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	select @begbal = BegBal, @workbal = WorkBal, @stmtbal = StmtBal, @stmtdte = StmtDate 
	from CMST where CMCo = @cmco and CMAcct = @cmacct and Status = 0 

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMClearStmtInfo] TO [public]
GO
