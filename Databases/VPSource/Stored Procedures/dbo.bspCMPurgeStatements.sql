SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspCMPurgeStatements]
   
   	/********************************************************
   	 * CREATED BY: JM 8/24/97
   	 * MODIFIED By: 
   	 *
   	 * USAGE: Used by CM Purge program to delete closed statement 
   	 * 	  headers from CMST and associated statement detail 
   	 *	  from CMDT
   	 *
   	 * Pass: CM Company, CMAcct, Through Month
   	 *
   	 * Returns: 0 and message if successful, 1 and message if error
   	 *********************************************************/
   
   (@cmco bCompany = null, @cmacct bCMAcct = null, @thrudate bDate = null, @msg varchar(150) output)
   
   as
   set nocount on
   
   declare @rcode int, @stmtdate bDate, @LastMthSubClosed bMonth, @opensubmth bMonth, @chardate varchar(25)
   
   select @rcode = 0
   select @stmtdate = null
   
   /* check for missing CM Company */
   if @cmco is null
   	begin
   	select @msg = 'Missing CM Company!', @rcode = 1
   	goto bspexit
   	end
   
   /* check for missing CM Acct */
   if @cmacct is null
   	begin
   	select @msg = 'Missing CM Acct!', @rcode = 1
   	goto bspexit
   	end
   
   /* check for missing Thru Date */
   if @thrudate is null
   	begin
   	select @msg = 'Missing Thru Date!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @opensubmth = max(dbo.CMDT.Mth) 
   from dbo.CMDT with (nolock) 
   Where CMDT.CMCo = @cmco and CMDT.CMAcct = @cmacct and CMDT.StmtDate <= @thrudate
   
   
   select @LastMthSubClosed = LastMthSubClsd From dbo.bGLCO with (nolock) where GLCo = 
        (Select GLCo from dbo.CMAC with(nolock) Where CMCo = @cmco and CMAcct = @cmacct)
   
   if @opensubmth is null
        begin
        select @msg = 'No purgable transactions exist.', @rcode = 1
        goto bspexit
        end
   
   if @opensubmth > @LastMthSubClosed /*or @opensubmth is null*/
        begin
        select @chardate = convert(varchar(25), @LastMthSubClosed)
        select @msg = 'Cannot purge transactions that exist in an open subledger.' + char(13) + 'Latest available date to'
        select @msg = @msg + ' purge transactions is ' +  substring(@chardate, 1, len(@chardate) - 7) + '.', @rcode = 1
        goto bspexit
        end
   
   
   
   /* select header for which to delete details (beginning statement date)*/
   declare purge_curs cursor local fast_forward for
   select StmtDate 
   from dbo.bCMST with (nolock) 
   where CMCo = @cmco 
   	and CMAcct = @cmacct 
   	and StmtDate <= @thrudate 
   	and StmtDate is not null
   	and Status = 1
   
   open purge_curs
   fetch next from purge_curs into @stmtdate
   
   while @@fetch_status = 0
   begin
   
   	Update dbo.CMDT
       Set Purge = 'Y'
       Where CMCo = @cmco and CMAcct = @cmacct and Purge = 'N' and 
   	StmtDate between @stmtdate and @thrudate
   
   	delete dbo.bCMDT 
   	where CMCo = @cmco 
   		and CMAcct = @cmacct 
   		and StmtDate = @stmtdate
   
   	fetch next from purge_curs into @stmtdate
   end
   
   
   /* delete closed statement headers from CMST for CMCo/CMAcct/ThruDate */
   delete dbo.bCMST where CMCo = @cmco and CMAcct = @cmacct and StmtDate <= @thrudate and Status = 1
   
   select @msg = 'Statement purge successfully completed.'
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMPurgeStatements] TO [public]
GO
