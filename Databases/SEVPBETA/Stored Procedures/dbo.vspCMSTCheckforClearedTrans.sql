SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMSTCheckforClearedTrans]
/************************************************************************
* CREATED:	mh 6/22/04	    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*   Used in CMST to check CMDT for cleared transactions.  Idea is
*	we will not allow changes to beginning balance if any items have
*	been cleared.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@cmco bCompany = 0, @cmacct bCMAcct = null, @stmtdte bDate = null, @clrcnt int = 0 output, 
	@msg varchar(60) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @cmco is null
	begin
		select @msg = 'Missing CM Company', @rcode = 1
		goto bspexit
	end

	if @cmacct is null
	begin
		select @msg = 'Missing CM Account', @rcode = 1
		goto bspexit
	end

	if @stmtdte is null
	begin
		select @msg = 'Missing Statement Date', @rcode = 1
		goto bspexit
	end

	select @clrcnt = count(1) from dbo.CMDT where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @stmtdte

bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMSTCheckforClearedTrans] TO [public]
GO
