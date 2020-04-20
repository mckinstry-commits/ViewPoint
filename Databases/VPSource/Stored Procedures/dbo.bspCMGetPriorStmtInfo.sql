SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   CREATE   procedure [dbo].[bspCMGetPriorStmtInfo]
   /************************************************************************
   * CREATED:	MH 1/10/03    
   * MODIFIED:  MH 2/25/09 - #132312 Corrected @priorstmtdate from varchar(20) to bDate
   *
   * Purpose of Stored Procedure
   *
   *	Get prior statement info for CMStatement form.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   

       (@cmco bCompany, @cmacct bCMAcct, @stmtdate bDate,
   	@priorstmtdate bDate output, @priorstatus varchar(10) output,
   	@begbal bDollar output, @workbal bDollar output, @stmtbal bDollar output, 
   	@msg varchar(80) = '' output)

   
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
   
   if @stmtdate is null
   begin
   	select @msg = 'Missing Statement Date', @rcode = 1
   	goto bspexit
   end
   
	if (Select max(StmtDate) from CMST where CMCo = @cmco and CMAcct = @cmacct) > @stmtdate 
	begin
		select @msg = 'The Statement Date entered is earlier than a Statement Date already on file.', @rcode = 1
		goto bspexit
	end

	if exists(Select 1 from CMST where CMCo = @cmco and CMAcct = @cmacct and Status = 0 and StmtDate < @stmtdate)
	begin
		select @msg = 'Open prior Statement exists for this CM Co/Acct. Cannot add new Statement!', @rcode = 1
		goto bspexit
	end

   	select @priorstmtdate = StmtDate, @priorstatus = case Status when 1 then 'Closed' else 'Open' end, 
   	@begbal = BegBal, @workbal = WorkBal, @stmtbal = StmtBal 
   	from CMST 
   	where CMCo = @cmco and CMAcct = @cmacct and StmtDate = 
   		(select max(StmtDate) from CMST where CMCo = @cmco and 
   		CMAcct = @cmacct and StmtDate < @stmtdate)
   
   	if @priorstmtdate is null	
   	begin
   
   		select @priorstatus = 'N/A'
   
   		select @begbal = 0.00
   		select @workbal = 0.00
   		select @stmtbal = 0.00
   
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMGetPriorStmtInfo] TO [public]
GO
