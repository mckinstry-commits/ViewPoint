SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMAutoReconcile    Script Date: 11/9/2001 2:44:29 PM ******/
    CREATE              procedure [dbo].[bspCMAutoReconcile]
    /************************************************************************
    * CREATED:    MH 7/31/00    
    * MODIFIED:   GH 10/22/01 Issue #14992 - Cannot auto clear deposits, need to read in CMTransType
    *		
    *				mh 11/09/01...correction to Issue #14992.  See comments below.
    *				SR 09/16/02 Issue 18562 - took ltrim out of CMRef
    *				mh 4/29/03 Issue 20799 - need to look for voided items and raise an error.
    *		DC 10/09/03 #21652  - The Transaction needed to include the Update and Delete Statement.
    *				mh 11/16/04 25821 - Process not looking at CMDT.CMRefSeq
    *				mh 1/25/05 25821 - Added check for Bank Account number in CMAC.  Simplified check
    *								for duplicate transactions in CMDT.  Added checks for missing 
    *								required parameters.
    *				mh 2/8/05  25821 - If Transaction is not found write error back to CMCE.
    *				mh 9/20/05 - Corrected error verbage.
	*				mh 1/21/08 - Isseu 126070 - do not clear checks that exist in PRVP
	*
    * Purpose of Stored Procedure
    *
    *    Auto reconcile CMCE to CMDT.    
    *    
    *           
    * Notes about Stored Procedure
    * 
    *
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
      	(@cmco bCompany, @cmacct bCMAcct, @upload bDate,  @stmtdate bDate, @clrdcount int output,
    	 @errcount int output, @msg varchar(100) output)
    
    as
    set nocount on
    
   	declare @rcode int, @cmacctnumb varchar(20), @count int, 
   	@chktotal bDollar, @chkno bCMRef, @amt bDollar, @clrdate bDate, 
   	@cmtranstype bCMTransType, @voidyn bYN, @clearerror tinyint, 
   	@errmsg varchar(100),
   	@commit int,  --DC #21652
    @transtarted int,  --DC #21652
   	@exist int, 	--DC 21652
   	@seq int,
   	@cleardte bDate,
   	@clearedamt bDollar,
   	@opencurs tinyint,
   	@numrows int
   


   --25821 - Add checks for missing parameters.
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
   
   	if @upload is null
   	begin
   		select @msg = 'Missing Upload Date', @rcode = 1
   		goto bspexit
   	end
   
   	if @stmtdate is null
   	begin
   		select @msg = 'Missing Statement Date', @rcode = 1
   		goto bspexit
   	end
   
   
   
   	select @rcode = 0, @clrdcount = 0, @errcount = 0, @commit = 0, @opencurs = 0
   
   	select @cmacctnumb = BankAcct from dbo.bCMAC with (nolock) where CMCo = @cmco and CMAcct = @cmacct 
   
   --25821 If @@rowcount is 0 or @cmacctnumb is null then Bank Account does not exist in CMAC for this CMCo.
   	if @@rowcount = 0 or @cmacctnumb is null
   	begin
   		select @msg = 'Bank Account number not set up in CMAC.  Unable to use Auto Clear', @rcode = 1
   		goto bspexit
   	end
   
   	--get set of records in CMCE that are to be cleared.
   	declare bcCMCE cursor local fast_forward
   	for
   	select ChkNo, Amount, ClearDate, Seq 
   	from dbo.bCMCE with (nolock)
   	where CMCo = @cmco and UploadDate = @upload and BankAcct = @cmacctnumb
   
   	open bcCMCE
    
   	fetch next from bcCMCE into @chkno, @amt, @clrdate, @seq
   
   	select @opencurs = 1
    
   	while @@fetch_status = 0
   	begin
    
   		select @clearerror = 0, @transtarted = 0, @exist = 0
   
   		--Does this item exist in CMDT?
   		--NEW
   		Select @exist = 1, @cmtranstype=CMTransType, @voidyn=Void, @chktotal=Amount, 
   		@cleardte = ClearDate, @clearedamt = ClearedAmt
   		from dbo.bCMDT with (nolock) 
   		where CMCo = @cmco and CMAcct = @cmacct and CMRef = @chkno
   
   		--25821  Process is not looking at CMRefSeq.  If CMRef is being used more then once, regardless
   		--of statement date, flagging this as an error.  User will need to manually clear item.
   		--mh 11/16/04  Issue 
   
   		select @numrows = @@rowcount
   
   		if @numrows > 1 
   		begin
   			select @errmsg = 'Unable to clear. More than 1 entry exists for this CMRef', @clearerror = 1
   			goto error
   		end
   		else if @numrows = 1
   		begin
   			--25821 Can only clear checks and deposits.  
   			if @cmtranstype <> 1 and @cmtranstype <> 2
   			begin
   				select @errmsg = 'CM Transaction Type must be ''1 - Check'' or ''2 - Deposit''', @clearerror = 1
   				goto error
   			end
   /*
   			if @exist <> 1
   			begin
   				select @errmsg = 'Unable to locate CM Reference Number', @clearerror = 1
   				goto error
   			end
   */
   			--if this item has already been cleared then raise an error.
   			if @cleardte is not null and @clearedamt is not null
   			begin
   				select @errmsg = 'This item was previously cleared.', @clearerror = 1
   				goto error
   			end
   
   			--If the void flag is yes and this item appears in CMCE then we have 
   			--a voided check that was cashed.  Need to flag it as an error.  Issue 20799
   			if @voidyn = 'Y'
   			begin
   				select @errmsg = 'This item has been marked as void in CM.', @clearerror = 1
   				goto error
   			end

			if exists(select 1 from PRVP where CMCo = @cmco and CMAcct = @cmacct and CMRef = @chkno)
			begin
				select @errmsg = 'This item was marked void in PR and not updated to CM.', @clearerror = 1
				goto error
			end  
   
   	 		if @cmtranstype=1 select @amt = (-1 * @amt)
   
   			if @chktotal<>@amt
   			begin
   				select @errmsg = 'Cleared amount differs from written amount', @clearerror = 1
   				goto error
   			end

   			BEGIN TRANSACTION	--DC #21652
   			select @commit = 1, @transtarted = 1	--DC #21652
           	update dbo.bCMDT set ClearedAmt = @amt, ClearDate = @clrdate, StmtDate = @stmtdate
    	    	where CMCo = @cmco and CMAcct = @cmacct and CMRef = @chkno and Amount = @amt 
   
   			if @@rowcount <> 1
   			begin
   				select @errmsg = 'Unable to clear this item.  Item must be cleared manually.', @clearerror = 1
   				goto error
   			end
   /*
   			error:
   			if @clearerror <> 0 
   			begin
   	 			select @errcount = @errcount + 1
   				update dbo.bCMCE set ErrorText = @errmsg where 
   	 			CMCo = @cmco and UploadDate = @upload and BankAcct = @cmacctnumb and ChkNo = @chkno					
   
   	 			if @@rowcount = 1 select @commit = 0
   				select @errmsg = ''
    			end
     			else
   	 		begin
   	   			delete bCMCE where CMCo = @cmco and UploadDate = @upload and BankAcct = @cmacctnumb and ChkNo = @chkno and Seq = @seq
   	 			if @@rowcount > 0
   				BEGIN
   					select @commit = 0
   					select @clrdcount = @clrdcount + 1
   				END
   			end
   		
   			if @transtarted = 1 
   			BEGIN
   				if @commit = 0 COMMIT TRANSACTION	
   				if @commit = 1 ROLLBACK TRANSACTION	
   			END
   */
   		end
   
   		--25821 - if @numrows = 0 then the CMCE record was not located in CMDT.  Need to write an error back to CMCE.  Also, see
   		--the code that writes the error back to CMCE, may need to restructure that too.
   		if @numrows = 0
   		begin
   			select @errmsg = 'Unable to locate CM Reference Number', @clearerror = 1
   			goto error
   		end
   
   		error:
   		if @clearerror <> 0 
   		begin
   			select @errcount = @errcount + 1
   			update dbo.bCMCE set ErrorText = @errmsg where 
    			CMCo = @cmco and UploadDate = @upload and BankAcct = @cmacctnumb and ChkNo = @chkno					
   
    			if @@rowcount = 1 select @commit = 0
   			select @errmsg = ''
   		end
   		else
    		begin
      			delete bCMCE where CMCo = @cmco and UploadDate = @upload and BankAcct = @cmacctnumb and ChkNo = @chkno and Seq = @seq
    			if @@rowcount > 0
   			BEGIN
   				select @commit = 0
   				select @clrdcount = @clrdcount + 1
   			END
   		end
   	
   		if @transtarted = 1 
   		BEGIN
   			if @commit = 0 COMMIT TRANSACTION	
   			if @commit = 1 ROLLBACK TRANSACTION	
   		END
   
       	fetch next from bcCMCE into @chkno, @amt, @clrdate, @seq
   	end    --1
        
    
    bspexit:
    
   	if @opencurs = 1
   	begin
   		close bcCMCE
   		deallocate bcCMCE
   	end
   
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMAutoReconcile] TO [public]
GO
