SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMClearRange]
/************************************************************************
* CREATED:  mh 6/20/06    
* MODIFIED:		mh 01/21/08 - Issue 126070.  Do not clear checks that exist in PRVP   
*
* Purpose of Stored Procedure
*
*    Auto Clear CMDT.  Used by CMClear.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/


    (@cmco bCompany, @cmacct bCMAcct, @clearing bYN, @stmtdate bDate, @criteria varchar(8000), @clearedcnt int = 0 output, @msg varchar(80) output)

as
set nocount on

	declare @rcode int, @sql varchar(8000), @join varchar(500), @prvpcriteria varchar(500)



	select @rcode = 0

	select @join = 'From CMDT left Join PRVP on PRVP.CMCo = CMDT.CMCo and PRVP.CMRef = CMDT.CMRef and PRVP.CMRefSeq = CMDT.CMRefSeq '
	
	select @criteria = @criteria + ' and CMDT.InUseBatchId IS NULL and CMDT.CMCo = ' + convert(varchar(5), @cmco) + 
	' and CMDT.CMAcct = ' + convert(varchar(10), @cmacct) 

	select @prvpcriteria = ' and PRVP.PaidDate is null'

	if @clearing = 'Y' 
	begin
		select @sql = 'Update dbo.CMDT set CMDT.ClearDate = ''' + convert(varchar(11), @stmtdate) + '''' 
		+ ', CMDT.StmtDate = ''' + convert(varchar(11), @stmtdate) + '''' + 
		', CMDT.ClearedAmt = (case when Void = ''Y'' then 0.00 else Amount end) ' + @join + ' where ' + @criteria + @prvpcriteria

	end

	if @clearing = 'N'
	begin
		select @sql = 'Update dbo.CMDT set ClearDate = null, StmtDate = null, ClearedAmt = 0 where ' + @criteria
	end
 
	exec(@sql)
	select @clearedcnt = @@rowcount

	if exists(select 1 from dbo.PRVP p (nolock)
	join dbo.CMDT c (nolock) on p.CMCo = c.CMCo and p.CMAcct = c.CMAcct and p.CMRef = c.CMRef 
	where c.StmtDate Is Null and /*CMDT.ActDate <='10/31/07' and CMDT.InUseBatchId IS NULL and*/ c.CMCo = @cmco
		 and c.CMAcct = @cmacct)
	begin
		select @msg = 'Void items in Payroll not interfaced to CM have not been cleared.', @rcode = 7
	end 
	
vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMClearRange] TO [public]
GO
