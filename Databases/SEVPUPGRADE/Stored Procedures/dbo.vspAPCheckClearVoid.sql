SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE             proc [dbo].[vspAPCheckClearVoid]
   /***********************************************************
    * CREATED BY	: MV 01/21/09 
    * MODIFIED BY	: MV 07/02/09 - #134299 clear PaidDate 
	*
    * Called by the AP Check Print program to clear or void check numbers from sequences 
    * in an AP Payment Batch. 
    *
    *
    * INPUT PARAMETERS
    *  @apco               AP Company #
    *  @month              Batch Month
    *  @batchid            Payment BatchId
    *  @sendcmco           CM Company
    *  @cmacct             CM Account
    *  @begincheck         Beginning check #
    *  @void               'Y' = void check #s removed during reprint, 'N' = do not void check #s removed during reprint
    *  @voidmemo           Memo to record with voided checks
    *
    * OUTPUT PARAMETERS
    *  @msg                error message
    *
    * RETURN VALUE
    *   0                  success
    *   1                  failure
    *****************************************************/
   	(@apco bCompany = null, @month bMonth = null, @batchid bBatchID = null,
   	 @sendcmco bCompany = null, @cmacct bCMAcct = null,@begincheck bCMRef = null,
	 @endcheck bCMRef =null,@voidopt varchar(1), @voidmemo varchar(255) = null,@msg varchar(255) output)
       
   as
    
   set nocount on
    
	declare @rcode int,@opencursorAPPB int, @batchseq int, @seq int
	select @rcode = 0, @opencursorAPPB = 0
   -- parameter validation
   if @apco is null or @month is null or @batchid is null
   	begin
   	select @msg = 'Missing AP Co#, Month, and/or Batch ID#', @rcode = 1
   	goto bspexit
   	end



    -- create a cursor to process range of checks
    declare bcAPPBr cursor local fast_forward for
   	select b.BatchSeq 
   	from bAPPB b with (nolock)
   	where b.Co = @apco and b.Mth = @month and b.BatchId = @batchid 
       	and b.CMAcct = @cmacct and b.PayMethod = 'C' and b.ChkType = 'C'
   		and b.CMRef is not null and b.VoidYN = 'N' and (b.CMRef>= isnull(@begincheck,'')
		and b.CMRef <= isnull(@endcheck,'~~~~~~~~~~'))
   	order by b.CMRef		-- order by check number
   
   	-- open cursor
   	open bcAPPBr
   	select @opencursorAPPB = 1
   
   	void_loop:	-- process each payment to be voided
   		fetch next from bcAPPBr into @batchseq
   
   		if @@fetch_status <> 0 goto void_end
   
   		if @voidopt = 'V'	-- Void -check # will not be reused, must be added to payment batch as 'void'
   			begin
   	     	-- get next available Batch Seq#
   			select @seq = isnull(max(BatchSeq),0) + 1
   	        	from bAPPB with (nolock)
   	        	where Co = @apco and Mth = @month and BatchId = @batchid
   	
   	        -- add void entry
   	        	insert bAPPB(Co, Mth, BatchId, BatchSeq, CMCo, CMAcct, PayMethod,
   	        	CMRef, CMRefSeq, ChkType, VendorGroup, Vendor, Name, Address,
   	            City, State, Zip, PaidDate, Amount, Supplier, VoidYN, VoidMemo, ReuseYN, Overflow)
   			select Co, Mth, BatchId, @seq, CMCo, CMAcct, PayMethod,
   				CMRef, CMRefSeq, ChkType, VendorGroup, Vendor, Name, Address,
   				City, State, Zip, PaidDate, Amount, Supplier, 'Y', @voidmemo, 'N', 'N'
   			from bAPPB
   			where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq 
   	        	if @@rowcount <> 1
   				begin
   				select @msg = 'Unable to add voided check entry into Payment Batch.', @rcode = 1
   				goto bspexit
   				end
   			end

   		-- remove existing CM Reference #
       	update bAPPB
       	set CMRef = null, CMRefSeq = null, PaidDate = null
       	where Co = @apco and Mth = @month and BatchId = @batchid and BatchSeq = @batchseq
   		if @@rowcount <> 1
   			begin
   			select @msg = 'Unable to remove Check # from voided entry.', @rcode = 1
   			goto bspexit
   			end
   
   		goto void_loop
   
   	void_end:	
       	close bcAPPBr
           deallocate bcAPPBr
   		select @opencursorAPPB = 0
    
  
    
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPCheckClearVoid] TO [public]
GO
