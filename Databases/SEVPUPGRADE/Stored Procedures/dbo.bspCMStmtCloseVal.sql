SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMStmtCloseVal    Script Date: 2/10/2003 10:21:27 AM ******/
    
    
    CREATE   procedure [dbo].[bspCMStmtCloseVal]
    /************************************************************************
    * CREATED:	MH 2/07/03    
    * MODIFIED:  mh 1/11/2005 Issue 26511    
    *
    * Purpose of Stored Procedure
    *
    *    Validate closing of CM Statement.
    *    
    *           
    * Notes about Stored Procedure
    * 
    *
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
    
        (@cmco bCompany, @cmacct bCMAcct, @currstmtdate bDate, @currstatus tinyint, 
    	@workbal bDollar, @stmtbal bDollar, @msg varchar(80) = '' output)
    
    as
    set nocount on
    
    
    	declare @prevstmtdate bDate, @rcode int
    
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
    
    	if @currstatus is null
    	begin
    		select @msg = 'Missing Status', @rcode = 1
    		goto bspexit
    	end
    
    	if @currstmtdate is null
    	begin
    		select @msg = 'Missing Statement Date', @rcode = 1
    		goto bspexit
    	end
    
    	if @currstatus = 0
    	begin
    
   /*26511
   Need to raise an error if the user attempts to open a statement when there is a later statement for
   this CM Account on file.  Open or closed, it does not matter.  mh 1/11/05
   */
   		if exists(select 1 from dbo.CMST with (nolock) where CMCo = @cmco and CMAcct = @cmacct and StmtDate > @currstmtdate)
   		begin
   			if @currstatus = 0
   			begin
   				select @msg = 'You cannot open a Statement when there is a later Statement on file.', @rcode = 1 
   				goto bspexit
   			end
   		end
   
    		select @prevstmtdate = StmtDate 
    		from dbo.CMST with (nolock)
    		where CMCo=@cmco and CMAcct = @cmacct and 
    		StmtDate = (select max(StmtDate) from dbo.CMST with (nolock) where CMCo=@cmco and CMAcct = @cmacct)
    
    		if @currstmtdate > @prevstmtdate
   		begin
   /*
   I think the intent of the following statement was to raise an error if a user attempts to open/reopen 
   the latest statement when there is a prior open statement.  If the Status of the Previous Statement
   is 0 then raise an error "You cannot open a Statement when there is a later Statement on file." does
   not make sense.  I think I meant to say previous or prior instead of later.  Validation on the 
   Statement date key field prevents this condition from occuring anyway.  mh 1/11/2005
   */
   			--check the status of previous statement
   			if (select Status from dbo.CMST with (nolock) where CMCo = @cmco and CMAcct = @cmacct and StmtDate = @prevstmtdate) = 0
   			begin
   	 			--select @msg = 'You cannot open a Statement when there is a later Statement on file.', @rcode = 1
   				select @msg = 'You cannot open a Statement when there is a prior open Statement on file.', @rcode = 1
    				goto bspexit
   			end
    		end
    	end
    
    	if @currstatus = 1
    	begin
    		if @stmtbal <> @workbal
    		begin
    			select @msg = 'You cannot close a Statement that does not balance.', @rcode = 1
    			goto bspexit
    		end
    	end
    
    
    bspexit:
    
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMStmtCloseVal] TO [public]
GO
