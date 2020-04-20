SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMClearTotals    Script Date: 8/28/99 9:34:15 AM ******/
   
   
   
   
   CREATE procedure [dbo].[bspCMClearTotals]
    /***********************************************************
     * CREATED BY: SE   8/20/96
     * MODIFIED By : GG 4/30/99
     *
     * USAGE:
     * Called by the CM Clear program to provide cleared Adjustment, Check/EFT,
     * Deposit, and Transfer totals for a specific CM Account and Statement Date.
     *
     * INPUT PARAMETERS
     *   	@co   		CM Company
     *	@cmacct		CM Account
     *	@stmtdate	Statement Date
     *
     * OUTPUT PARAMETERS
     *	@errmsg		Error message
     *
     * RETURN VALUE
     *	0		success
     *	1		failure
     *
     *****************************************************/
    
    	@co bCompany, @cmacct bCMAcct, @stmtdate bDate,	@errmsg varchar(255) output
    
    as
    
    set nocount on
    
    declare @transtotal bDollar, @adjtotal bDollar, @chktotal bDollar, @deptotal bDollar, @rcode int
    
    declare @adjcount int, @chkcount int, @depcount int, @transfercount int, @variance bDollar, @workbal bDollar,
            @stmtbal bDollar
    
    select @rcode = 0
    
    
    select @adjtotal = isnull(sum(isnull(Amount,0)),0)
    	from bCMDT
    	where CMCo = @co and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 0
            and Void = 'N'
    
    select @adjcount = (select count(*) 
                        from bCMDT
                        where CMCo = @co and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 0
                           and Void = 'N')
    
    -- combine EFTs with Checks
    select @chktotal = isnull(sum(isnull(Amount,0)),0)
    	from bCMDT
    	where CMCo = @co and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType in (1,4)
            and Void = 'N'
    
    select @chkcount = (select count(*) 
                        from bCMDT
                        where CMCo = @co and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType in (1,4)
                           and Void = 'N')
    
    
    
    select @deptotal = isnull(sum(isnull(Amount,0)),0)
    	from bCMDT
    	where CMCo = @co and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 2
            and Void = 'N'
    
    select @depcount = (select count(*)
                        from bCMDT
    	            where CMCo = @co and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 2
                           and Void = 'N')
    
    
    select @transtotal = isnull(sum(isnull(Amount,0)),0)
    	from bCMDT
    	where CMCo = @co and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 3
            and Void = 'N'
    
    select @transfercount = (select count(*)
                             from bCMDT
    	                 where CMCo = @co and CMAcct = @cmacct and StmtDate = @stmtdate and CMTransType = 3
                                and Void = 'N')
    
    
    select @workbal = (select WorkBal from CMST where CMCo = @co and CMAcct = @cmacct and StmtDate = @stmtdate)
    
    select @stmtbal = (select StmtBal from CMST where CMCo = @co and CMAcct = @cmacct and StmtDate = @stmtdate)
    
    
    select @variance = (@workbal - @stmtbal) 
    
    select 'ChkTotal'=isnull(@chktotal*-1,0), 'DepTotal' =isnull(@deptotal,0), 'AdjTotal'=isnull(@adjtotal,0), 'TransTotal' = isnull(@transtotal,0),
          'TransCount'=(isnull(@adjcount,0) + isnull(@chkcount,0) + isnull(@depcount,0) + isnull(@transfercount,0)),
          'WorkBal' = @workbal, 'Variance' = @variance
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMClearTotals] TO [public]
GO
