SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspCMClearGetTotals]
	/******************************************************
	* CREATED BY:  markh 
	* MODIFIED By: 
	*
	* Usage:  Retrieve the totals from CMDT For CMClear.
	*	
	*
	* Input params:
	*
	*	@cmco - CM Company
	*	@cmacct - CM Account
	*	@stmtdate - Statement Date
	*	
	*
	* Output params:
	*
	*	@adjtotal - Total Adjustments
	*	@chktotal - Total Checks
	*	@deptotal - Total Deposits
	*	@transtotal - Total Transfers
	*	@adjcount - Total number of cleared Adjustments
	*	@chkcount - Total number of cleared Checks
	*	@depcount - Total number of cleared Deposits
	*	@transfercount - Total number of cleared Transfers
	*	@transcount number of transactions cleared.
	*	@workbal - Working balance
	*	@stmtbal - Statement Balance
	*	@variance - Variance
	*	@begbal -Beginning Balance
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
    (@cmco bCompany, @cmacct bCMAcct, @stmtdate bDate, @adjtotal bDollar output, 
	@chktotal bDollar output, @deptotal bDollar output, @transtotal bDollar output, 
	@transcount int output, @workbal bDollar output, @stmtbal bDollar output, 
	@variance bDollar output, @begbal bDollar output, @msg varchar(80) = '' output)

as
set nocount on

	declare @rcode int, @adjcount int, @chkcount int, @depcount int, @transfercount int 

    select @rcode = 0

	if @cmco is null
	begin
		select @msg = 'Missing CM Company.', @rcode = 1
		goto vspexit
	end

	if @cmacct is null
	begin
		select @msg = 'Missing CM Account.', @rcode = 1
		goto vspexit
	end

	if @stmtdate is null
	begin
		select @msg = 'Missing CM Statement Date.', @rcode = 1
		goto vspexit
	end
 
    select @adjtotal = isnull(sum(isnull(Amount,0)),0)
    	from bCMDT
    	where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 0
            and Void = 'N'
    
    select @adjcount = (select count(1) 
                        from bCMDT
                        where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 0
                           and Void = 'N')
    
    -- combine EFTs with Checks
    select @chktotal = isnull(sum(isnull(Amount,0)),0)
    	from bCMDT
    	where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType in (1,4)
            and Void = 'N'
    
    select @chkcount = (select count(1) 
                        from bCMDT
                        where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType in (1,4)
                           and Void = 'N')
    
    
    
    select @deptotal = isnull(sum(isnull(Amount,0)),0)
    	from bCMDT
    	where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 2
            and Void = 'N'
    
    select @depcount = (select count(1)
                        from bCMDT
    	            where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 2
                           and Void = 'N')
    
    
    select @transtotal = isnull(sum(isnull(Amount,0)),0)
    	from bCMDT
    	where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 3
            and Void = 'N'
    
    select @transfercount = (select count(1)
                             from bCMDT
    	                 where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 3
                                and Void = 'N')
    
    
    select @workbal = WorkBal, @stmtbal = StmtBal, @begbal = BegBal from CMST where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @stmtdate
    
    select @variance = (@workbal - @stmtbal) 
    
    select @chktotal=isnull(@chktotal*-1,0), @deptotal =isnull(@deptotal,0), 
	@adjtotal=isnull(@adjtotal,0), @transtotal = isnull(@transtotal,0),
    @transcount=(isnull(@adjcount,0) + isnull(@chkcount,0) + isnull(@depcount,0) + isnull(@transfercount,0))
	 
	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspCMClearGetTotals] TO [public]
GO
