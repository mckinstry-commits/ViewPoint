SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************* CREATED BY: *************************/
   CREATE     procedure [dbo].[bspMSHBPost]
    /***********************************************************
     * Created By:	GG 11/06/00
     * Modified By:	MV 06/15/01 - Issue 12769 BatchUserMemoUpdate
     *				CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
     *				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
     *				GF 12/04/2003 - issue #23139 - use new stored procedure to create user memo update statement.
     *				GF 07/22/2005 - issue #29343 - pay rate was missing from update statement for MSTD when changing MSLB line.
	 *				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
	 *				LG 05/04/11 - Issue 141281 - Added [bspBatchUserMemoUpdate] for performance.  MH reverted change.  Issues to research.
	 *				MV 09/07/11 - TK-08245 - Added Haul Tax fields to INSERT bMSTD
     *
     *
     * Called from MS Batch Processing form to post a validated
     * batch of Hauler Time Sheets.
     *
     * Updates MS Haul Header and Transaction detail.  Calls bspMSPostIN,
     * bspMSPostJC, bspMSPostEM, and bspMSPostGL to update other modules.
     *
     * INPUT PARAMETERS:
     *   @co             MS Co#
     *   @mth            Batch Month
     *   @batchid        Batch Id
     *   @dateposted     Posting date
     *
     * OUTPUT PARAMETERS
     *   @errmsg         error message if something went wrong
     *
     * RETURN
     *  0 = success, 1 = error
     *
     *****************************************************/
    (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
    as
    set nocount on
     
    declare @rcode int, @status tinyint, @openMSHBcursor tinyint, @openMSLBcursor tinyint, 
    		@errorstart varchar(10), @msg varchar(255)
     
    -- MSHB and MSLB declares
    declare @seq int, @transtype char(1), @haultrans bTrans, @saledate bDate, @haultype char(1), @vendorgroup bGroup,
     		@haulvendor bVendor, @truck bTruck, @driver varchar(30), @emco bCompany, @equipment bEquip, @emgroup bGroup,
     		@prco bCompany, @employee bEmployee, @haulline smallint, @mstrans bTrans, @linetranstype char(1),
     		@Notes varchar(400), @UniqueAttchID uniqueidentifier, @mshhud_flag bYN, @mstdud_flag bYN,
    		@h_join varchar(2000),  @h_where varchar(2000), @h_update varchar(2000), @l_join varchar(2000),
    		@l_where varchar(2000), @l_update varchar(2000), @sql varchar(8000), @mshb_count bTrans, 
    		@mshb_trans bTrans, @mslb_count bTrans, @mslb_trans bTrans
     
    select @rcode = 0, @openMSHBcursor = 0, @openMSLBcursor = 0, @mshhud_flag = 'N', @mstdud_flag = 'N',
    	   @mshb_count = 0, @mshb_trans = 0, @mslb_count = 0, @mslb_trans = 0
    
    
    -- check for Posting Date
    if @dateposted is null
          begin
          select @errmsg = 'Missing posting date!', @rcode = 1
          goto bspexit
          end
    
    -- call bspUserMemoQueryBuild to create update, join, and where clause
    -- pass in source and destination. Remember to use views only unless working
    -- with a Viewpoint (bidtek) connection. FOR MSHB -> MSHH
    exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'MSHB', 'MSHH', @mshhud_flag output,
    			@h_update output, @h_join output, @h_where output, @errmsg output
    if @rcode <> 0 goto bspexit
    
    -- call bspUserMemoQueryBuild to create update, join, and where clause
    -- pass in source and destination. Remember to use views only unless working
    -- with a Viewpoint (bidtek) connection. FOR MSLB -> MSTD
    exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'MSLB', 'MSTD', @mstdud_flag output,
    			@l_update output, @l_join output, @l_where output, @errmsg output
    if @rcode <> 0 goto bspexit
    
    
    
    -- validate HQ Batch
    exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS Haul', 'MSHB', @errmsg output, @status output
    if @rcode <> 0 goto bspexit
    if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
          begin
          select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
          goto bspexit
          end
     
    -- set HQ Batch status to 4 (posting in progress)
    update bHQBC set Status = 4, DatePosted = @dateposted
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
          begin
          select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
          goto bspexit
          end
    
    
    -- get count of MSHB rows that need a HaulTrans
    select @mshb_count = count(*) from bMSHB with (nolock)
    where Co=@co and Mth=@mth and BatchId=@batchid and BatchTransType = 'A' and HaulTrans is null
    -- only update HQTC and MSHB if there are MSHB rows that need updating
    if @mshb_count <> 0
      	begin
      	-- get next available Transaction # for bMSHH
      	exec @haultrans = dbo.bspHQTCNextTransWithCount 'bMSHH', @co, @mth, @mshb_count, @msg output
      	if @haultrans = 0
      		begin
      		select @errmsg = 'Unable to get MS Haul transaction from HQTC!', @rcode = 1
      		goto bspexit
      		end
      
      	-- set @mshb_trans to last transaction from bHQTC as starting point for update
      	set @mshb_trans = @haultrans - @mshb_count
      	
      	-- update bMSHB and set HaulTrans
      	update bMSHB set @mshb_trans = @mshb_trans + 1, HaulTrans = @mshb_trans
      	where Co=@co and Mth=@mth and BatchId=@batchid and BatchTransType = 'A' and HaulTrans is null
      	-- compare count from update with MSHB rows that need to be updated
      	if @@rowcount <> @mshb_count
      		begin
      		select @errmsg = 'Error has occurred updating HaulTrans in MSHB batch!', @rcode = 1
      		goto bspexit
      		end
      	end
    
    
    -- get count of MSLB rows that need a MSTrans
    select @mslb_count = count(*) from bMSLB with (nolock)
    where Co=@co and Mth=@mth and BatchId=@batchid and BatchTransType = 'A' and MSTrans is null
    -- only update HQTC and MSLB if there are MSLB rows that need updating
    if @mslb_count <> 0
      	begin
      	-- get next available Transaction # for MSTD
      	exec @mstrans = dbo.bspHQTCNextTransWithCount 'bMSTD', @co, @mth, @mslb_count, @msg output
      	if @mstrans = 0
      		begin
      		select @errmsg = 'Unable to get MS Ticket transaction from HQTC!', @rcode = 1
      		goto bspexit
      		end
      
      	-- set @mslb_trans to last transaction from bHQTC as starting point for update
      	set @mslb_trans = @mstrans - @mslb_count
      	
      	-- update bMSLB and set MSTrans
      	update bMSLB set @mslb_trans = @mslb_trans + 1, MSTrans = @mslb_trans
      	where Co=@co and Mth=@mth and BatchId=@batchid and BatchTransType = 'A' and MSTrans is null
      	-- compare count from update with MSLB rows that need to be updated
      	if @@rowcount <> @mslb_count
      		begin
      		select @errmsg = 'Error has occurred updating MSTrans in MSLB batch!', @rcode = 1
      		goto bspexit
      		end
    
      	-- have now successfully updated MSTrans to MSLB, now update distribution tables
      	-- update bMSGL
      	update bMSGL set MSTrans = b.MSTrans
      	from bMSGL a join bMSLB b with (nolock) on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId 
    		and b.BatchSeq=a.BatchSeq and b.HaulLine=a.HaulLine
      	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
      	-- update bMSJC
      	update bMSJC set MSTrans = b.MSTrans
      	from bMSJC a join bMSLB b with (nolock) on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId 
    		and b.BatchSeq=a.BatchSeq and b.HaulLine=a.HaulLine
      	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
      	-- update bMSEM
      	update bMSEM set MSTrans = b.MSTrans
      	from bMSEM a join bMSLB b with (nolock) on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId
    		and b.BatchSeq=a.BatchSeq and b.HaulLine=a.HaulLine
      	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
      	-- update bMSIN
      	update bMSIN set MSTrans = b.MSTrans
      	from bMSIN a join bMSLB b with (nolock) on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId 
    		and b.BatchSeq=a.BatchSeq and b.HaulLine=a.HaulLine
      	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and b.Co=@co and b.Mth=@mth
      	and b.BatchId=@batchid and b.BatchTransType='A'
      	end
    
    
    
    -- declare cursor on MS Time Sheet Header Batch
    declare bcMSHB cursor LOCAL FAST_FORWARD
    for select BatchSeq, BatchTransType, HaulTrans, SaleDate, HaulerType, VendorGroup,
          	HaulVendor, Truck, Driver, EMCo, Equipment, EMGroup, PRCo, Employee, 
    		UniqueAttchID, HaulTrans
    from bMSHB
    where Co = @co and Mth = @mth and BatchId = @batchid
     
    -- open MS Time Sheet Header Batch cursor
    open bcMSHB
    set @openMSHBcursor = 1
     
    -- process all entries in batch
    MSHB_loop:
    fetch next from bcMSHB into @seq, @transtype, @haultrans, @saledate, @haultype, @vendorgroup,
    		@haulvendor, @truck, @driver, @emco, @equipment, @emgroup, @prco, @employee, 
    		@UniqueAttchID, @haultrans
     
    if @@fetch_status = -1 goto MSHB_end
    if @@fetch_status <> 0 goto MSHB_loop
     
    select @errorstart = 'Seq# ' + convert(varchar(6),@seq)
     
    begin transaction       -- start a transaction, commit after header and lines fully processed
     
    -- **** New Haul Transactions ****
    if @transtype = 'A'	    -- new transaction
    	begin
    -- 	-- get next available Transaction # 
    -- 	exec @haultrans = dbo.bspHQTCNextTrans 'bMSHH', @co, @mth, @msg output
    -- 	if @haultrans = 0
    -- 		begin
    -- 		select @errmsg = @errorstart + ' ' + @msg, @rcode = 1
    -- 		goto posting_error
    -- 		end
     
    	-- add MS Haul Header
    	insert bMSHH(MSCo, Mth, HaulTrans, FreightBill, SaleDate, HaulerType, VendorGroup, HaulVendor,
                  Truck, Driver, EMCo, Equipment, EMGroup, PRCo, Employee, BatchId, Notes, UniqueAttchID)
    	select Co, Mth, @haultrans, FreightBill, SaleDate, HaulerType, VendorGroup, HaulVendor,
                  Truck, Driver, EMCo, Equipment, EMGroup, PRCo, Employee, BatchId, Notes, UniqueAttchID
    	from bMSHB with (nolock)
    	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    	if @@rowcount <> 1
    		begin
    		select @errmsg = @errorstart + ' - Unable to add Haul Header Transaction!', @rcode = 1
    		goto posting_error
    		end
     
    -- 	--update haultrans# in the batch header record for BatchUserMemoUpdate
    -- 	update bMSHB set HaulTrans = @haultrans
    -- 	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
     
    	-- create a cursor to update all Haul Lines for this transaction
    	declare bcMSLB cursor LOCAL FAST_FORWARD
    	for select HaulLine, MSTrans
    	from bMSLB
    	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     
    	-- open Haul Lines cursor
    	open bcMSLB
    	set @openMSLBcursor = 1
     
    	-- process all Haul Lines on this Seq (they have already been validated as new entries)
    	MSLB_loop:
    	fetch next from bcMSLB into @haulline, @mstrans
     
    	if @@fetch_status = -1 goto MSLB_end
    	if @@fetch_status <> 0 goto MSLB_loop
     
    -- 	-- get next available Transaction # for bMSTD
    -- 	exec @mstrans = dbo.bspHQTCNextTrans 'bMSTD', @co, @mth, @msg output
    -- 	if @mstrans = 0
    -- 		begin
    -- 		select @errmsg = @errorstart + ' ' + @msg, @rcode = 1
    -- 		goto posting_error
    -- 		end
    
    	-- add MS Transaction
    	insert bMSTD(MSCo, Mth, MSTrans, HaulTrans, SaleDate, Ticket, FromLoc, VendorGroup, MatlVendor, SaleType,
    			CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, Hold, JCCo, Job, PhaseGroup, INCo, ToLoc,
    			MatlGroup, Material, UM, GrossWght, TareWght, MatlUnits, UnitPrice, ECM,
    			MatlTotal, MatlCost, HaulerType, HaulVendor, Truck, Driver, EMCo, Equipment, EMGroup, PRCo, Employee,
    			TruckType, StartTime, StopTime, Loads, Miles, Hours, Zone, HaulCode, HaulPhase, HaulJCCType, HaulBasis,
    			HaulRate, HaulTotal, PayCode, PayBasis, PayRate, PayTotal, RevCode, RevBasis, RevRate, RevTotal, TaxGroup,
    			TaxCode, TaxType, TaxBasis, TaxTotal, DiscBasis, DiscRate, DiscOff, TaxDisc, Void, VerifyHaul, BatchId,
    			AuditYN, Purge, HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt)
    	select Co, Mth, @mstrans, @haultrans, @saledate, null, FromLoc, VendorGroup, MatlVendor, SaleType,
    			CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, Hold, JCCo, Job, PhaseGroup,
    			INCo, ToLoc, MatlGroup, Material, UM, 0, 0, 0, 0, 'E',
    			0, 0, @haultype, @haulvendor, @truck, @driver, @emco, @equipment, @emgroup, @prco, @employee,
    			TruckType, StartTime, StopTime, Loads, Miles, Hours, Zone, HaulCode, HaulPhase, HaulJCCType,
    			HaulBasis, HaulRate, HaulTotal, PayCode, PayBasis, PayRate, PayTotal, RevCode, RevBasis,
    			RevRate, RevTotal, TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, DiscBasis, DiscRate,
    			DiscOff, TaxDisc, 'N', 'Y', @batchid, 'Y','N',HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate,
     			HaulPayTaxAmt
    	from bMSLB with (nolock)
    	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and HaulLine = @haulline
    	if @@rowcount <> 1
    		begin
    		select @errmsg = @errorstart + ' - Unable to add Transaction Detail for Haul Line!', @rcode = 1
    		goto posting_error
    		end
    
    -- 	-- update MS Trans# to distribution tables
    -- 	update bMSGL set MSTrans = @mstrans where MSCo = @co and Mth = @mth and BatchId = @batchid
    --      			  and BatchSeq = @seq and HaulLine = @haulline
    -- 	update bMSJC set MSTrans = @mstrans where MSCo = @co and Mth = @mth and BatchId = @batchid
    --      			  and BatchSeq = @seq and HaulLine = @haulline
    -- 	update bMSEM set MSTrans = @mstrans where MSCo = @co and Mth = @mth and BatchId = @batchid
    --      			  and BatchSeq = @seq and HaulLine = @haulline
    -- 	update bMSIN set MSTrans = @mstrans where MSCo = @co and Mth = @mth and BatchId = @batchid
    --      			  and BatchSeq = @seq and HaulLine = @haulline
    --  
    -- 	--update MStrans# in the batch line record for BatchUserMemoUpdate
    -- 	update bMSLB set MSTrans = @mstrans
    -- 	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
     
    
    	if @mstdud_flag = 'Y'
      		begin
      		
      --		-- update where clause with MSTrans, create @sql and execute
    		set @sql = @l_update + @l_join + @l_where + ' and b.MSTrans = ' + convert(varchar(10),@mstrans) + ' and MSTD.MSTrans = ' + convert(varchar(10),@mstrans)
    		exec (@sql)
    		
    		-- ISSUE: #141281
    		--EXECUTE bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'MS Haul', @errmsg
    		
    		end
    
    	-- remove current Haul Line from batch
    	delete bMSLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and HaulLine = @haulline
    	if @@rowcount <> 1
    		begin
    		select @errmsg = @errorstart + ' Unable to remove MS Haul Line Batch entry.', @rcode = 1
    		goto posting_error
    		end
     
    	goto MSLB_loop  -- next Haul Line
     
    	MSLB_end:   -- all Haul Lines posted
    		close bcMSLB
    		deallocate bcMSLB
    		set @openMSLBcursor = 0
    
      	if @mshhud_flag = 'Y'
      		begin
      
			--		-- update where clause with HaulTrans, create @sql and execute
    		set @sql = @h_update + @h_join + @h_where + ' and b.HaulTrans = ' + convert(varchar(10), @haultrans) + ' and MSHH.HaulTrans = ' + convert(varchar(10),@haultrans)
    		exec (@sql)
    		
    		-- ISSUE: #141281
			--EXECUTE bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'MS Haul', @errmsg

    		end
    
    	-- remove current Haul Header from batch
    	delete bMSHB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    	if @@rowcount <> 1
    		begin
    		select @errmsg = @errorstart + ' Unable to remove MS Haul Header Batch entry.', @rcode = 1
    		goto posting_error
    		end
    	end
    
    
    --  *** Changed Haul Transactions ***
    if @transtype = 'C'
    	begin
    	update bMSHH    -- update existing Haul Trans
    	set FreightBill = b.FreightBill, SaleDate = b.SaleDate, HaulerType = b.HaulerType, VendorGroup = b.VendorGroup,
                  HaulVendor = b.HaulVendor, Truck = b.Truck, Driver = b.Driver, EMCo = b.EMCo, Equipment = b.Equipment,
                  EMGroup = b.EMGroup, PRCo = b.PRCo, Employee = b.Employee, BatchId = @batchid, InUseBatchId = null, 
   		  UniqueAttchID=b.UniqueAttchID, Notes = b.Notes
    	from bMSHB b with (nolock)
    	join bMSHH h on h.MSCo = b.Co and h.Mth = b.Mth and h.HaulTrans = b.HaulTrans
    	where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @seq
    	if @@rowcount <> 1
    		begin
    		select @errmsg = @errorstart + ' - Unable to update Haul Header Transaction!', @rcode = 1
    		goto posting_error
    		end
     
    	-- create a cursor to update all Haul Lines for this transaction
    	declare bcMSLB cursor LOCAL FAST_FORWARD
    	for select HaulLine, BatchTransType, MSTrans
    	from bMSLB
    	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     
    	-- open Haul Lines cursor
    	open bcMSLB
    	set @openMSLBcursor = 1
     
    	-- process all Haul Lines on this Seq (may contain add, change, or delete haul lines)
    	MSLB1_loop:
    	fetch next from bcMSLB into @haulline, @linetranstype, @mstrans
     
    	if @@fetch_status = -1 goto MSLB1_end
    	if @@fetch_status <> 0 goto MSLB1_loop
     
    	if @linetranstype = 'A'
    		begin
    -- 		-- get next available Transaction # for bMSTD
    -- 		exec @mstrans = dbo.bspHQTCNextTrans 'bMSTD', @co, @mth, @msg output
    -- 		if @mstrans = 0
    -- 			begin
    -- 			select @errmsg = @errorstart + ' ' + @msg, @rcode = 1
    -- 			goto posting_error
    -- 			end
     
    		-- add MS Transaction
    		insert bMSTD(MSCo, Mth, MSTrans, HaulTrans, SaleDate, Ticket, FromLoc, VendorGroup, MatlVendor, SaleType,
    				CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, Hold, JCCo, Job, PhaseGroup, INCo, ToLoc,
    				MatlGroup, Material, UM, GrossWght, TareWght, MatlUnits, UnitPrice, ECM,
    				MatlTotal, MatlCost, HaulerType, HaulVendor, Truck, Driver, EMCo, Equipment, EMGroup, PRCo, Employee,
    				TruckType, StartTime, StopTime, Loads, Miles, Hours, Zone, HaulCode, HaulPhase, HaulJCCType, HaulBasis,
    				HaulRate, HaulTotal, PayCode, PayBasis, PayRate, PayTotal, RevCode, RevBasis, RevRate, RevTotal, TaxGroup,
    				TaxCode, TaxType, TaxBasis, TaxTotal, DiscBasis, DiscRate, DiscOff, TaxDisc, Void, VerifyHaul, BatchId,
    				AuditYN, Purge, HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate, HaulPayTaxAmt)
    		select Co, Mth, @mstrans, @haultrans, @saledate, null, FromLoc, VendorGroup, MatlVendor, SaleType,
    				CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, Hold, JCCo, Job, PhaseGroup,
    				INCo, ToLoc, MatlGroup, Material, UM, 0, 0, 0, 0, 'E',
    				0,0, @haultype, @haulvendor, @truck, @driver, @emco, @equipment, @emgroup, @prco, @employee,
    				TruckType, StartTime, StopTime, Loads, Miles, Hours, Zone, HaulCode, HaulPhase, HaulJCCType,
    				HaulBasis, HaulRate, HaulTotal, PayCode, PayBasis, PayRate, PayTotal, RevCode, RevBasis,
    				RevRate, RevTotal, TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, DiscBasis, DiscRate,
    				DiscOff, TaxDisc, 'N', 'Y', @batchid, 'Y','N', HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate,HaulPayTaxAmt
    		from bMSLB with (nolock)
    		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and HaulLine = @haulline
    		if @@rowcount <> 1
    			begin
    			select @errmsg = @errorstart + ' - Unable to add Transaction Detail for Haul Line!', @rcode = 1
    			goto posting_error
    			end
    
    -- 		-- update MS Trans# to distribution tables
    -- 		update bMSGL set MSTrans = @mstrans where MSCo = @co and Mth = @mth and BatchId = @batchid
    --      			      and BatchSeq = @seq and HaulLine = @haulline
    -- 		update bMSJC set MSTrans = @mstrans where MSCo = @co and Mth = @mth and BatchId = @batchid
    --      			      and BatchSeq = @seq and HaulLine = @haulline
    -- 		update bMSEM set MSTrans = @mstrans where MSCo = @co and Mth = @mth and BatchId = @batchid
    --      			      and BatchSeq = @seq and HaulLine = @haulline
    -- 		update bMSIN set MSTrans = @mstrans where MSCo = @co and Mth = @mth and BatchId = @batchid
    --      			      and BatchSeq = @seq and HaulLine = @haulline
    --  
    -- 		-- update haultrans# in the batch line record for BatchUserMemoUpdate
    -- 		update bMSLB set MSTrans = @mstrans
    -- 		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
     
    		-- update MSTD user memos if any
    		if @mstdud_flag = 'Y'
    			begin
    			
      	--		-- update where clause with MSTrans, create @sql and execute
    			set @sql = @l_update + @l_join + @l_where + ' and b.MSTrans = ' + convert(varchar(10),@mstrans) + ' and MSTD.MSTrans = ' + convert(varchar(10),@mstrans)
    			exec (@sql)
    			
    			-- ISSUE: #141281
				--EXECUTE bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'MS Haul', @errmsg
    			
    			end
     
    		-- remove current Haul Line from batch
    		delete bMSLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and HaulLine = @haulline
    		if @@rowcount <> 1
    			begin
    			select @errmsg = @errorstart + ' Unable to remove Haul Line Batch entry.', @rcode = 1
    			goto posting_error
    			end
    		end
     
    	if @linetranstype = 'C'
    		begin
    		update bMSTD
    		set SaleDate = @saledate, FromLoc = b.FromLoc, VendorGroup = b.VendorGroup, MatlVendor = b.MatlVendor,
                      SaleType = b.SaleType, CustGroup = b.CustGroup, Customer = b.Customer, CustJob = b.CustJob,
                      CustPO = b.CustPO, PaymentType = b.PaymentType, CheckNo = b.CheckNo, Hold = b.Hold, JCCo = b.JCCo,
                      Job = b.Job, PhaseGroup = b.PhaseGroup, INCo = b.INCo, ToLoc = b.ToLoc, MatlGroup = b.MatlGroup,
                      Material = b.Material, UM = b.UM, HaulerType = @haultype, HaulVendor = @haulvendor, Truck = @truck,
                      Driver = @driver, EMCo = @emco, Equipment = @equipment, EMGroup = @emgroup, PRCo = @prco,
                      Employee = @employee, TruckType = b.TruckType, StartTime = b.StartTime, StopTime = b.StopTime,
                      Loads = b.Loads, Miles = b.Miles, Hours = b.Hours, HaulCode = b.HaulCode, HaulPhase = b.HaulPhase,
                      HaulJCCType = b.HaulJCCType, HaulBasis = b.HaulBasis, HaulRate = b.HaulRate, HaulTotal = b.HaulTotal,
                      PayCode = b.PayCode, PayBasis = b.PayBasis, PayRate = b.PayRate, PayTotal = b.PayTotal, RevCode = b.RevCode, RevBasis = b.RevBasis,
                      RevRate = b.RevRate, RevTotal = b.RevTotal, TaxGroup = b.TaxGroup, TaxCode = b.TaxCode, TaxType = b.TaxType,
                      TaxBasis = b.TaxBasis, TaxTotal = b.TaxTotal, DiscBasis = b.DiscBasis, DiscRate = b.DiscRate, DiscOff = b.DiscOff,
                      TaxDisc = b.TaxDisc, BatchId = @batchid, AuditYN = 'Y',HaulPayTaxType= b.HaulPayTaxType, HaulPayTaxCode= b.HaulPayTaxCode,
                      HaulPayTaxRate = b.HaulPayTaxRate,HaulPayTaxAmt = b.HaulPayTaxAmt
    		from bMSLB b with (nolock)
    		join bMSTD d on d.MSCo = b.Co and d.Mth = b.Mth and d.MSTrans = b.MSTrans
    		where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid and b.BatchSeq = @seq and b.HaulLine = @haulline
    		if @@rowcount <> 1
    			begin
    			select @errmsg = @errorstart + ' - Unable to update Transaction Detail with Haul Line info!', @rcode = 1
    			goto posting_error
    			end
     
    		-- update MSTD user memos if any
    		if @mstdud_flag = 'Y'
    			begin
      			
      	--		-- update where clause with MSTrans, create @sql and execute
    			set @sql = @l_update + @l_join + @l_where + ' and b.MSTrans = ' + convert(varchar(10),@mstrans) + ' and MSTD.MSTrans = ' + convert(varchar(10),@mstrans)
    			exec (@sql)
    			
    			-- ISSUE: #141281
				--EXECUTE bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'MS Haul', @errmsg
    			
    			end
     
    		-- remove current Haul Line from batch
    		delete bMSLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and HaulLine = @haulline
    		if @@rowcount <> 1
    			begin
    			select @errmsg = @errorstart + ' Unable to remove Haul Line Batch entry.', @rcode = 1
    			goto posting_error
    			end
    		end
     
    	if @linetranstype = 'D'
    		begin
    		-- remove current Haul Line from batch - this must be done before the bMSTD entry
    		-- is deleted so that the delete trigger on bMSTB can unlock the transaction
    		delete bMSLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and HaulLine = @haulline
    		if @@rowcount <> 1
    			begin
    			select @errmsg = @errorstart + ' Unable to remove Haul Line Batch entry.', @rcode = 1
    			goto posting_error
    			end
    
    		-- delete transaction detail
    		delete bMSTD where MSCo = @co and Mth = @mth and MSTrans = @mstrans
    		if @@rowcount <> 1
    			begin
    			select @errmsg = @errorstart + ' - Unable to delete Transaction Detail associated with Haul Line!', @rcode = 1
    			goto posting_error
    			end
    		end
     
    	goto MSLB1_loop  -- next Haul Line
     
    	MSLB1_end:   -- all Haul Lines deleted
    		close bcMSLB
    		deallocate bcMSLB
    		set @openMSLBcursor = 0
    
    	if @mshhud_flag = 'Y'
      		begin
      		
			--		-- update where clause with HaulTrans, create @sql and execute
    		set @sql = @h_update + @h_join + @h_where + ' and b.HaulTrans = ' + convert(varchar(10), @haultrans) + ' and MSHH.HaulTrans = ' + convert(varchar(10),@haultrans)
    		exec (@sql)
    		
    		-- ISSUE: #141281
			--EXECUTE bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'MS Haul', @errmsg
    		
    		end
     
    	-- remove current Haul Header from batch
    	delete bMSHB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    	if @@rowcount <> 1
    		begin
    		select @errmsg = @errorstart + ' Unable to remove MS Haul Header Batch entry.', @rcode = 1
    		goto posting_error
    		end
    	end
     
    
    -- **** Delete Haul Transaction and Lines ****
    if @transtype = 'D'
    	begin
    	-- create a cursor to delete all Haul Lines for this transaction
    	declare bcMSLB cursor LOCAL FAST_FORWARD
    	for select HaulLine, MSTrans
    	from bMSLB 
    	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     
    	-- open Haul Lines cursor
    	open bcMSLB
    	set @openMSLBcursor = 1
     
    	-- process all Haul Lines on this Seq (already validated, all are delete entries)
    	MSLB2_loop:
    	fetch next from bcMSLB into @haulline, @mstrans
     
    	if @@fetch_status = -1 goto MSLB2_end
    	if @@fetch_status <> 0 goto MSLB2_loop
     
    	-- remove current Haul Line from batch - this must be done before the bMSTD entry
    	-- is deleted so that the delete trigger on bMSTB can unlock the transaction
    	delete bMSLB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and HaulLine = @haulline
    	if @@rowcount <> 1
    		begin
    		select @errmsg = @errorstart + ' Unable to remove Haul Line Batch entry.', @rcode = 1
    		goto posting_error
    		end
    
    	-- delete transaction detail for Haul Line
    	delete bMSTD where MSCo = @co and Mth = @mth and MSTrans = @mstrans
    	if @@rowcount <> 1
    		begin
    		select @errmsg = @errorstart + ' - Unable to delete Transaction Detail associated with Haul Line!', @rcode = 1
    		goto posting_error
    		end
     
    	goto MSLB2_loop  -- next Haul Line
     
    	MSLB2_end:   -- all Haul Lines deleted
    		close bcMSLB
    		deallocate bcMSLB
    		set @openMSLBcursor = 0
     
    	-- remove current Haul Header from batch - this must be done before the bMSHH entry
    	-- is deleted so that the delete trigger on bMSHB can unlock the transaction
    	delete bMSHB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    	if @@rowcount <> 1
    		begin
    		select @errmsg = @errorstart + ' Unable to remove MS Haul Header Batch entry.', @rcode = 1
    		goto posting_error
    		end
    
    	-- remove Haul Header transaction
    	delete bMSHH where MSCo = @co and Mth = @mth and HaulTrans = @haultrans
    	if @@rowcount <> 1
    		begin
    		select @errmsg = @errorstart + ' Unable to delete Haul Header Transactions entry.', @rcode = 1
    		goto posting_error
    		end
    	end
     
    -- finished with Header Batch entry and all Lines
    commit transaction
   
   --Refresh indexes for this transaction if attachments exist
   if @UniqueAttchID is not null
   	begin
   	exec dbo.bspHQRefreshIndexes null, null, @UniqueAttchID, null
   	end
   
    goto MSHB_loop  -- next batch entry
   
   
   
   posting_error:       -- error during processing
    	rollback transaction
    	goto bspexit
     
    MSHB_end:			-- no more Transactions to process
    	close bcMSHB
    	deallocate bcMSHB
    	set @openMSHBcursor = 0
     
    --Inventory update
    exec @rcode = dbo.bspMSPostIN @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
    -- make sure all IN Distributions have been processed
    if exists(select 1 from bMSIN with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to Inventory were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
     
    --Job Cost update
    exec @rcode = dbo.bspMSPostJC @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
    -- make sure all JC Distributions have been processed
    if exists(select 1 from bMSJC with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to Job Cost were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
     
    --Equipment Revenue update
    exec @rcode = dbo.bspMSPostEM @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
    -- make sure all EM Distributions have been processed
    if exists(select 1 from bMSEM with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to EM were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
    if exists(select 1 from bMSRB with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all Revenue breakdown updates to EM were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
     
    --General Ledger update
    exec @rcode = dbo.bspMSPostGL @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
    -- make sure all JC Distributions have been processed
    if exists(select 1 from bMSGL with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
    	begin
    	select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
    	goto bspexit
    	end
     
    -- set interface levels note string
    select @Notes=Notes from bHQBC with (nolock) 
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
    select @Notes=@Notes +
             'AR Interface Level set at: ' + convert(char(1), a.ARInterfaceLvl) + char(13) + char(10) +
             'EM Interface Level set at: ' + convert(char(1), a.EMInterfaceLvl) + char(13) + char(10) +
             'GL Invoice Interface Level set at: ' + convert(char(1), a.GLInvLvl) + char(13) + char(10) +
             'GL Ticket Interface Level set at: ' + convert(char(1), a.GLTicLvl) + char(13) + char(10) +
             'IN Sales Interface Level set at: ' + convert(char(1), a.INInterfaceLvl) + char(13) + char(10) +
             'IN Production Interface Level set at: ' + convert(char(1), a.INProdInterfaceLvl) + char(13) + char(10) +
             'JC Interface Level set at: ' + convert(char(1), a.JCInterfaceLvl) + char(13) + char(10)
    from bMSCO a with (nolock) where MSCo=@co
     
    -- delete HQ Close Control entries
    delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
     
    -- set HQ Batch status to 5 (posted)
    update bHQBC set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
    	goto bspexit
    	end
    
    
    
    bspexit:
    	if @openMSLBcursor = 1
    		begin
    		close bcMSLB
    		deallocate bcMSLB
    		end
    	if @openMSHBcursor = 1
    		begin
    		close bcMSHB
    		deallocate bcMSHB
    		end
     
    	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
    	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspMSHBPost] TO [public]
GO
