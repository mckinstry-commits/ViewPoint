SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMPurgeInfo    Script Date: 8/28/99 9:34:16 AM ******/
   CREATE  procedure [dbo].[bspCMPurgeInfo]
   
   /***********************************************************
    * CREATED BY: JM 8/25/97
    * MODIFIED By : 
    *
    * USAGE:
    * 	Returns last and oldest stmt dates from CMST for  
    *      a CMCo/CMAcct 
    *
    * INPUT PARAMETERS
    *   CMCo
    *   CMAcct
    *   
    * OUTPUT PARAMETERS
    *   @laststmtdate 	Last CMST.StmtDate
    *   @oldeststmtdate	Oldest CMST.StmtDate
    *   @errmsg      	Error message if applicable
    *
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/ 
   
   @cmco bCompany = null, @cmacct bCMAcct = null, @errmsg varchar(255) output
   
   as
   set nocount on
   
   declare @laststmtdate bDate, @oldeststmtdate bDate, @rcode int
   select @rcode = 0
   
   if @cmco is null
   	begin
   	select @errmsg = 'Missing CM Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @cmacct is null
   	begin
   	select @errmsg = 'Missing CM Acct!', @rcode = 1
   	goto bspexit
   	end
   
   /* get oldest stmt date for CMCo/CMAcct */
   select @oldeststmtdate = min(StmtDate) from bCMST where CMCo = @cmco and CMAcct = @cmacct
   
   /* get latest stmt date for CMCo/CMAcct */
   select @laststmtdate = max(StmtDate) from bCMST where CMCo = @cmco and CMAcct = @cmacct
   
   /* final select to return recordset */
   select 'OldestStmtDate' = @oldeststmtdate, 'LastStmtDate' = @laststmtdate
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMPurgeInfo] TO [public]
GO
