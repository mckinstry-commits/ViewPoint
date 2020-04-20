SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************/
CREATE procedure [dbo].[bspMSTBPost]
/***********************************************************
* Created:  GG 10/21/00
* Modified: RM 03/01/01 - To update 'changed' column in bMSTD
*			RM 03/02/01 - To update 'reasoncode' column in bMSTD
*			GF 04/23/2001 - issue #13175 - wrap isnull around numerics, add @@rowcount check after insert
*			RM 04/24/01 - Update MSTD with reason code before delete
*           MV 07/09/01 BatchMemoUserUpdate
*           CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*			GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*           TV 06/05/02 - Move attchment to trans table.
*			GG 07/18/02 = #18001 - update MSTrans back to bMSTB for user memo update
*			allenn 08/26/02 - Allow 'MS Addons' source for issue 17737
*			GF 07/23/03 - issue #21933 - speed improvement clean up.
*			GF 10/03/2003 - issue #22648 - update MSTB with MSTrans at once, not per each insert.
*			GF 11/26/2003 - issue #23139 - use new stored procedure to create user memo update statement.
*			GF 02/06/2004 - issue #23715 - missing zone from update statement into MSTD when in change mode.
*			GF 09/24/2004 - issue #25628 - changed user memo update from a exec statement to sp_executesql
*			GF 03/27/2007 - issue #124190 - changed ShipAddress to 60 characters
*			CHS 03/14/2008 - issue #127082 - international addresses
*			GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*			DAN SO 10/12/2009 - Issue #129350 - post Surcharges and delete MSSurcharges
*			LG 05/04/11 - Issue 141281 - Added [bspBatchUserMemoUpdate] for performance.
*			MH 08/21/11 - B04189/TK-07787
*
* Called from MS Batch Processing form to post a validated
* batch of tickets.
*
* Updates MS Transaction detail and calls bspMSPostIN,
* bspMSPostJC, bspMSPostEM, and bspMSPostGL
* to update other modules.
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
      
     declare @rcode int, @status tinyint, @opencursor tinyint, @errorstart varchar(10), @msg varchar(255)
      
     -- MSTB declares
     declare @seq int, @transtype char(1), @mstrans bTrans, @saledate bDate, @fromloc bLoc, @ticket bTic,
     		@vendorgroup bGroup, @matlvendor bVendor, @saletype char(1), @custgroup bGroup, @customer bCustomer,
     		@custjob varchar(20), @custpo varchar(20), @paymenttype char(1), @checkno bCMRef, @hold bYN, @jcco bCompany,
     		@job bJob, @phasegroup bGroup, @inco bCompany, @toloc bLoc, @matlgroup bGroup, @material bMatl, @matlum bUM,
     		@matlphase bPhase, @matljcct bJCCType, @grosswght bUnits, @tarewght bUnits, @wghtum bUM, @matlunits bUnits,
     		@unitprice bUnitCost, @ecm bECM, @matltotal bDollar, @matlcost bDollar, @haultype char(1), @haulvendor bVendor,
     		@truck bTruck, @driver varchar(30), @emco bCompany, @equipment bEquip, @emgroup bGroup, @prco bCompany,
     		@employee bEmployee, @trucktype varchar(10), @starttime smalldatetime, @stoptime smalldatetime, @loads smallint,
     		@miles bUnits, @hrs bHrs, @zone varchar(10), @haulcode bHaulCode, @haulphase bPhase, @hauljcct bJCCType,
     		@haulbasis bUnits, @haulrate bUnitCost, @haultotal bDollar, @paycode bPayCode, @paybasis bUnits, @payrate bUnitCost,
     		@paytotal bDollar, @revcode bRevCode, @revbasis bUnits, @revrate bUnitCost, @revtotal bDollar, @taxgroup bGroup,
     		@taxcode bTaxCode, @taxtype tinyint, @taxbasis bDollar, @taxtotal bDollar, @discbasis bUnits, @discrate bUnitCost,
     		@discoff bDollar, @taxdisc bDollar, @void bYN,@changed bYN,@reasoncode bReasonCode,@shipaddress varchar(60),
     		@city varchar(20),@state varchar(4), @zip bZip, @country varchar(2), @Notes varchar(400), @UniqueAttchID uniqueIdentifier,
     		@mstdud_flag bYN, @join varchar(1000), @where varchar(1000), @update varchar(2000), 
   			@sql nvarchar(4000), @paramsin nvarchar(200), @mstb_count bTrans, @mstb_trans bTrans,
   			@BatchSurchargeKeyID bigint, @SurchargeCode smallint, @SurchargeBasis bUnits, @SurchargeRate bUnitCost, 
   			@SurchargeTotal bDollar, @DetailSurchargeKeyID bigint, @MSTBKeyID bigint, @MSTDKeyID bigint,
   			@haulpaytaxtype tinyint, @haulpaytaxcode bTaxCode, @haulpaytaxrate bUnitCost, @haulpaytaxamt bDollar
    
   
   select @rcode = 0, @opencursor = 0, @mstdud_flag = 'N', @mstb_count = 0, @mstb_trans = 0
   
   -- check for Posting Date
   if @dateposted is null
            begin
            select @errmsg = 'Missing posting date!', @rcode = 1
            goto bspexit
            end
      
   -- call bspUserMemoQueryBuild to create update, join, and where clause
   -- pass in source and destination. Remember to use views only unless working
   -- with a Viewpoint (bidtek) connection.
   exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'MSTB', 'MSTD', @mstdud_flag output,
   			@update output, @join output, @where output, @errmsg output
   if @rcode <> 0 goto bspexit
     
   
     -- validate HQ Batch
     exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS Tickets', 'MSTB', @errmsg output, @status output
     if @rcode =1 
     	begin
     	exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS Addons', 'MSTB', @errmsg output, @status output
     	end
     if @rcode <> 0 goto bspexit
     if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
            begin
            select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress!)', @rcode = 1
            goto bspexit
            end
 
		
	--------------------------
	-- CREATE @KeyIDs TABLE --
	--------------------------
	-- ISSUE: #129350 --
	-- CREATE TABLE --
	DECLARE @MSKeyID TABLE
		(		
			BatchKeyID	bigint,
			DetailKeyID	bigint
		)

	--------------------------------------------------
	-- LOAD TABLE WITH PARENT KEY IDs OF SURCHARGES --
	--------------------------------------------------
	-- ISSUE: #129350 --
	INSERT INTO @MSKeyID (BatchKeyID)
		SELECT	DISTINCT(SurchargeKeyID)
		  FROM	MSTB b WITH (NOLOCK)
		 WHERE	SurchargeKeyID IS NOT NULL

      
      
        -- set HQ Batch status to 4 (posting in progress)
        update bHQBC
        set Status = 4, DatePosted = @dateposted
        where Co = @co and Mth = @mth and BatchId = @batchid
        if @@rowcount = 0
            begin
            select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
            goto bspexit
            end   
     
     -- get count of MSTB rows that need a MSTrans
     select @mstb_count = count(*) from bMSTB with (nolock)
     where Co=@co and Mth=@mth and BatchId=@batchid and BatchTransType = 'A' and MSTrans is null
     -- only update HQTC and MSTB if there are MSTB rows that need updating
     if @mstb_count <> 0
     	begin
     	-- get next available Transaction # for MS Trans Detail
     	exec @mstrans = dbo.bspHQTCNextTransWithCount 'bMSTD', @co, @mth, @mstb_count, @msg output
     	if @mstrans = 0
     		begin
     		select @errmsg = 'Unable to get MS Ticket transaction from HQTC!', @rcode = 1
     		goto bspexit
     		end
     
     	-- set @mstb_trans to last transaction from bHQTC as starting point for update
     	set @mstb_trans = @mstrans - @mstb_count
     	
     	-- update bMSTB and set MS Trans
     	update bMSTB set @mstb_trans = @mstb_trans + 1, MSTrans = @mstb_trans
     	where Co=@co and Mth=@mth and BatchId=@batchid and BatchTransType = 'A' and MSTrans is null
     	-- compare count from update with MSTB rows that need to be updated
     	if @@rowcount <> @mstb_count
     		begin
     		select @errmsg = 'Error has occurred updating MSTrans in MSTB Ticket batch!', @rcode = 1
     		goto bspexit
     		end
     
     	-- have now successfully updated MSTrans to MSTB, now update distribution tables
     	-- update bMSGL
     	update bMSGL set MSTrans = b.MSTrans
     	from bMSGL a join bMSTB b with (nolock) on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
     	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.HaulLine = 0 and b.Co=@co and b.Mth=@mth
     	and b.BatchId=@batchid and b.BatchTransType='A'
     	-- update bMSJC
     	update bMSJC set MSTrans = b.MSTrans
     	from bMSJC a join bMSTB b with (nolock) on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
     	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.HaulLine = 0 and b.Co=@co and b.Mth=@mth
     	and b.BatchId=@batchid and b.BatchTransType='A'
     	-- update bMSEM
     	update bMSEM set MSTrans = b.MSTrans
     	from bMSEM a join bMSTB b with (nolock) on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
     	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.HaulLine = 0 and b.Co=@co and b.Mth=@mth
     	and b.BatchId=@batchid and b.BatchTransType='A'
     	-- update bMSIN
     	update bMSIN set MSTrans = b.MSTrans
     	from bMSIN a join bMSTB b with (nolock) on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
     	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and a.HaulLine = 0 and b.Co=@co and b.Mth=@mth
   
     	and b.BatchId=@batchid and b.BatchTransType='A'
     	-- update bMSPA
     	update bMSPA set MSTrans = b.MSTrans
     	from bMSPA a join bMSTB b with (nolock) on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
     	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and b.Co=@co and b.Mth=@mth
     	and b.BatchId=@batchid and b.BatchTransType='A'
     
     	end
     
     
      
     -- declare cursor on MS Ticket Batch
     declare Ticket cursor LOCAL FAST_FORWARD 
     for select BatchSeq, BatchTransType, MSTrans, SaleDate, FromLoc, Ticket, VendorGroup, MatlVendor, SaleType,
            CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, Hold, JCCo, Job, PhaseGroup, INCo, ToLoc,
            MatlGroup, Material, UM, MatlPhase, MatlJCCType, isnull(GrossWght,0), isnull(TareWght,0), WghtUM, isnull(MatlUnits,0),
            isnull(UnitPrice,0), ECM, isnull(MatlTotal,0), isnull(MatlCost,0), HaulerType, HaulVendor, Truck, Driver, EMCo, Equipment,
            EMGroup, PRCo, Employee, TruckType, StartTime, StopTime, isnull(Loads,0), isnull(Miles,0), isnull(Hours,0), Zone, HaulCode,
            HaulPhase, HaulJCCType, isnull(HaulBasis,0), isnull(HaulRate,0), isnull(HaulTotal,0), PayCode, isnull(PayBasis,0),
            isnull(PayRate,0), isnull(PayTotal,0), RevCode, isnull(RevBasis,0), isnull(RevRate,0), isnull(RevTotal,0), TaxGroup,
            TaxCode, TaxType, isnull(TaxBasis,0), isnull(TaxTotal,0), isnull(DiscBasis,0), isnull(DiscRate,0), isnull(DiscOff,0),
            isnull(TaxDisc,0), Void, Changed, ReasonCode, ShipAddress, City, State, Zip, Country, UniqueAttchID, 
            SurchargeKeyID, SurchargeCode, KeyID, HaulPayTaxType, HaulPayTaxCode, isnull(HaulPayTaxRate,0), isnull(HaulPayTaxAmt,0)
     from bMSTB
     where Co = @co and Mth = @mth and BatchId = @batchid
      
     -- open MS Ticket Batch cursor
     open Ticket
     select @opencursor = 1
      
     -- process through all entries in batch
     Ticket_loop:
     fetch next from Ticket into @seq, @transtype, @mstrans, @saledate, @fromloc, @ticket, @vendorgroup, @matlvendor,
     		@saletype, @custgroup, @customer, @custjob, @custpo, @paymenttype, @checkno, @hold, @jcco, @job, @phasegroup,
     		@inco, @toloc, @matlgroup, @material, @matlum, @matlphase, @matljcct, @grosswght, @tarewght, @wghtum, 
     		@matlunits, @unitprice, @ecm, @matltotal, @matlcost, @haultype, @haulvendor, @truck, @driver, @emco, 
     		@equipment, @emgroup, @prco, @employee, @trucktype, @starttime, @stoptime, @loads, @miles, @hrs, @zone, 
     		@haulcode, @haulphase, @hauljcct, @haulbasis, @haulrate, @haultotal, @paycode, @paybasis, @payrate, @paytotal,
     		@revcode, @revbasis, @revrate, @revtotal, @taxgroup, @taxcode, @taxtype, @taxbasis, @taxtotal, @discbasis, 
     		@discrate, @discoff, @taxdisc, @void, @changed, @reasoncode, @shipaddress, @city, @state, @zip, @country, @UniqueAttchID, 
     		@BatchSurchargeKeyID, @SurchargeCode, @MSTBKeyID, @haulpaytaxtype, @haulpaytaxcode, @haulpaytaxrate, @haulpaytaxamt
      
     
     if @@fetch_status = -1 goto Ticket_end
     if @@fetch_status <> 0 goto Ticket_loop
     
     select @errorstart = 'Seq# ' + convert(varchar(6),@seq)
      
     begin transaction       -- start a transaction, commit after fully processed
     				       
	-- ******************* --
	-- ADD A NEW MS TICKET --
	-- ******************* --
	-- ISSUE: #129350 --	       
     if @transtype = 'A'	    -- new transaction
     	begin
     	     	
     	  	--------------------------
			-- SET SURCHARGE VALUES --
			--------------------------
			IF @BatchSurchargeKeyID IS NOT NULL
				BEGIN
					SET @SurchargeBasis =  ISNULL(@matlunits,0) 
					SET @SurchargeRate  =  ISNULL(@unitprice,0) 
					SET @SurchargeTotal = ISNULL(@matltotal,0) 
					SELECT @DetailSurchargeKeyID = DetailKeyID FROM @MSKeyID WHERE BatchKeyID = @BatchSurchargeKeyID
				END
				
				--			
         
     	-- add MS Transaction
     	insert bMSTD(MSCo, Mth, MSTrans, HaulTrans, SaleDate, Ticket, FromLoc, VendorGroup, MatlVendor, SaleType,
     			CustGroup, Customer, CustJob, CustPO, PaymentType, CheckNo, Hold, JCCo, Job, PhaseGroup, INCo, ToLoc,
     			MatlGroup, Material, UM, MatlPhase, MatlJCCType, GrossWght, TareWght, WghtUM, MatlUnits, UnitPrice, 
     			ECM, MatlTotal, MatlCost, HaulerType, HaulVendor, Truck, Driver, EMCo, Equipment, EMGroup, PRCo, 
     			Employee, TruckType, StartTime, StopTime, Loads, Miles, Hours, Zone, HaulCode, HaulPhase, HaulJCCType, 
     			HaulBasis, HaulRate, HaulTotal, PayCode, PayBasis, PayRate, PayTotal, RevCode, RevBasis, RevRate, 
     			RevTotal, TaxGroup, TaxCode, TaxType, TaxBasis, TaxTotal, DiscBasis, DiscRate, DiscOff, TaxDisc, 
     			Void, VerifyHaul, BatchId, AuditYN, Purge, Changed,ReasonCode,ShipAddress,City,State,Zip,Country, 
     			UniqueAttchID, SurchargeKeyID, SurchargeCode, HaulPayTaxType, HaulPayTaxCode, HaulPayTaxRate,
     			HaulPayTaxAmt) ---- REMOVED SURCHARGE VALUES GF
     	values(@co, @mth, @mstrans, null, @saledate, @ticket, @fromloc, @vendorgroup, @matlvendor, @saletype, 
     			@custgroup, @customer, @custjob, @custpo, @paymenttype, @checkno, @hold, @jcco, @job, @phasegroup, @inco, 
     			@toloc, @matlgroup, @material, @matlum, @matlphase, @matljcct, @grosswght, @tarewght, @wghtum,
     			isnull(@matlunits,0), @unitprice, @ecm, @matltotal, @matlcost, @haultype, @haulvendor, @truck, @driver, 
     			@emco, @equipment, @emgroup, @prco, @employee, @trucktype, @starttime, @stoptime, @loads, @miles, 
     			@hrs, @zone, @haulcode, @haulphase, @hauljcct, @haulbasis, @haulrate, @haultotal, @paycode, @paybasis, 
     			@payrate, @paytotal, @revcode, @revbasis, @revrate, @revtotal, @taxgroup, @taxcode, @taxtype, 
     			@taxbasis, @taxtotal, @discbasis, @discrate, @discoff, @taxdisc, @void, 'N', @batchid, 'Y', 'N', 
     			@changed, @reasoncode, @shipaddress, @city, @state, @zip, @country, @UniqueAttchID, 
     			@DetailSurchargeKeyID, @SurchargeCode, @haulpaytaxtype, @haulpaytaxcode, @haulpaytaxrate, 
     			@haulpaytaxamt) ---- REMOVED SURCHARGE VALUES GF
     	if @@rowcount <> 1
     		begin
     		select @errmsg = @errorstart + ' Unable to insert MS Ticket Detail entry.', @rcode = 1
     		goto Ticket_error
     		end

     	if @mstdud_flag = 'Y'
     		begin
     		
			---- update where clause with MSTrans, create @sql and execute
   --			set @sql = @update + @join + @where + ' and b.MSTrans = ' + convert(varchar(10), @mstrans) + ' and MSTD.MSTrans = ' + convert(varchar(10),@mstrans)
	   
   --			set @paramsin = N'@co tinyint, @mth bMonth, @batchid int, @mstrans int'
   --			EXECUTE sp_executesql @sql, @paramsin, @co, @mth, @batchid, @mstrans
   --			 -- -- 		exec (@sql)
   
			-- ISSUE: #141281
			EXECUTE bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'MS Tickets', @errmsg
	   		
   			end
   
		----------------------------------------------------
		-- UPDATE @MSKeyID TABLE WITH NEW KeyID FROM MSTD --
		----------------------------------------------------
		-- ISSUE: #129350 --
		IF EXISTS(SELECT DetailKeyID FROM @MSKeyID WHERE BatchKeyID = @MSTBKeyID)
			BEGIN
				UPDATE @MSKeyID
				   SET DetailKeyID = SCOPE_IDENTITY()
				 WHERE BatchKeyID = @MSTBKeyID	 
			END
   
     	-- remove current Transaction from batch
     	delete bMSTB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     	if @@rowcount = 0
     		begin
     		select @errmsg = @errorstart + ' Unable to remove MS Ticket Batch entry.', @rcode = 1
     		goto Ticket_error
     		end

     	commit transaction
   
   	--Refresh indexes for this transaction if attachments exist
   	if @UniqueAttchID is not null
   		begin
   		exec dbo.bspHQRefreshIndexes null, null, @UniqueAttchID, null
   		end
   
     	goto Ticket_loop
     	end
   
   
   	-- ******************* --
	-- CHANGE AN MS TICKET --
	-- ******************* --
	-- ISSUE: #129350 --
   if @transtype = 'C'	    -- update existing transaction
     	begin
     	
			------------------------------------------------
			-- UPDATE @MSKeyID TABLE WITH KeyID FROM MSTD --
			------------------------------------------------
			-- ISSUE: #129350 --
			IF EXISTS(SELECT DetailKeyID FROM @MSKeyID WHERE BatchKeyID = @MSTBKeyID)
				BEGIN
					UPDATE @MSKeyID
					   SET DetailKeyID = (SELECT KeyID FROM bMSTD WITH (NOLOCK) WHERE MSCo = @co
																				  AND Mth = @mth
																				  AND MSTrans = @mstrans)
					 WHERE BatchKeyID = @MSTBKeyID	 
				END
     	
     	
     		update bMSTD
     			set SaleDate = @saledate, Ticket = @ticket, FromLoc = @fromloc, VendorGroup = @vendorgroup, MatlVendor = @matlvendor,
						SaleType = @saletype, CustGroup = @custgroup, Customer = @customer, CustJob = @custjob, CustPO = @custpo,
						PaymentType = @paymenttype, CheckNo = @checkno, Hold = @hold, JCCo = @jcco, Job = @job, PhaseGroup = @phasegroup,
						INCo = @inco, ToLoc = @toloc, MatlGroup = @matlgroup, Material = @material, UM = @matlum, MatlPhase = @matlphase,
						MatlJCCType = @matljcct, GrossWght = @grosswght, TareWght = @tarewght, WghtUM = @wghtum, MatlUnits = @matlunits,
						UnitPrice = @unitprice, ECM = @ecm, MatlTotal = @matltotal, MatlCost = @matlcost, HaulerType = @haultype,
						HaulVendor = @haulvendor, Truck = @truck, Driver = @driver, EMCo = @emco, Equipment = @equipment,
						EMGroup = @emgroup, PRCo = @prco, Employee = @employee, TruckType = @trucktype, StartTime = @starttime,
						StopTime = @stoptime, Loads = @loads, Miles = @miles, Hours = @hrs, Zone = @zone, HaulCode = @haulcode, HaulPhase = @haulphase,
						HaulJCCType = @hauljcct, HaulBasis = @haulbasis, HaulRate = @haulrate, HaulTotal = @haultotal,
						PayCode = @paycode, PayBasis = @paybasis, PayRate=@payrate,PayTotal = @paytotal, RevCode = @revcode, RevBasis = @revbasis,
						RevRate = @revrate, RevTotal = @revtotal, TaxGroup = @taxgroup, TaxCode = @taxcode, TaxType = @taxtype,
						TaxBasis = @taxbasis, TaxTotal = @taxtotal, DiscBasis = @discbasis, DiscRate = @discrate, DiscOff = @discoff,
						TaxDisc = @taxdisc, Void = @void, BatchId = @batchid, InUseBatchId = null, AuditYN = 'Y', Purge = 'N', 
     					Changed = @changed,ReasonCode = @reasoncode, ShipAddress = @shipaddress, City = @city,State = @state,
     					Zip = @zip, Country = @country, UniqueAttchID = @UniqueAttchID, HaulPayTaxType = @haulpaytaxtype, 
     					HaulPayTaxCode = @haulpaytaxcode, HaulPayTaxRate = @haulpaytaxrate, HaulPayTaxAmt = @haulpaytaxamt
     		from bMSTD
     		where MSCo = @co and Mth = @mth and MSTrans = @mstrans
     		if @@rowcount <> 1
     			begin
     			select @errmsg = @errorstart + ' Unable to update existing MS Transaction Detail.', @rcode = 1
     			goto Ticket_error
     			end
   
   	
     		if @mstdud_flag = 'Y'
     			begin
     			
    -- 			-- update where clause with MSTrans, create @sql and execute
   	--			set @sql = @update + @join + @where + ' and b.MSTrans = ' + convert(varchar(10), @mstrans) + ' and MSTD.MSTrans = ' + convert(varchar(10),@mstrans)
	   
   	--			set @paramsin = N'@co tinyint, @mth bMonth, @batchid int, @mstrans int'
   	--			EXECUTE sp_executesql @sql, @paramsin, @co, @mth, @batchid, @mstrans
				---- -- -- 		exec (@sql)
				
				-- ISSUE: #141281
				EXECUTE bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'MS Tickets', @errmsg
				
   				end
   
     		-- remove current Transaction from batch
     		delete bMSTB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     		if @@rowcount <> 1
     			begin
     			select @errmsg = @errorstart + ' Unable to remove MS Ticket Batch entry.', @rcode = 1
     			goto Ticket_error
     			end
   
     		commit transaction
   
   			--Refresh indexes for this transaction if attachments exist
   			if @UniqueAttchID is not null
   				begin
   				exec dbo.bspHQRefreshIndexes null, null, @UniqueAttchID, null
   				end
   
     		goto Ticket_loop
     		
     	end --if @transtype = 'C'
     
     
     
   	-- ******************* --
	-- DELETE AN MS TICKET --
	-- ******************* --
	-- ISSUE: #129350 --
   if @transtype = 'D'     -- delete existing transaction
     	begin
     		-- remove current Transaction from batch - this must be done before the MSTD entry
     		-- is deleted so that the delete trigger on bMSTB can unlock the transaction
     		delete bMSTB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
     		if @@rowcount <> 1
     			begin
     			select @errmsg = @errorstart + ' Unable to remove MS Ticket Batch entry.', @rcode = 1
     			goto Ticket_error
     			end
           
			--update the reason code in MSTD so that it will show up in MSTX when the ticket is deleted.
			update bMSTD set ReasonCode = @reasoncode
     		from bMSTD where MSCo = @co and Mth = @mth and MSTrans = @mstrans
     		
     		--------------------------------------------------
     		-- UPDATE REASON CODE FOR ASSOCIATED SURCHARGES --
     		--------------------------------------------------
     		-- ISSUE: #129350 --   		
--     		SELECT @MSTDKeyID = KeyID
--     		  FROM bMSTD
--     		 WHERE MSCo = @co and Mth = @mth and MSTrans = @mstrans
--     		
--     		UPDATE bMSTD
--     		   SET ReasonCode = @reasoncode
--     		  FROM bMSTD
--     		 WHERE SurchargeKeyID = @MSTDKeyID
     		 
     		 
   			-- remove MS Transaction
   			delete bMSTD where MSCo = @co and Mth = @mth and MSTrans = @mstrans
   			if @@rowcount <> 1
     			begin
     			select @errmsg = @errorstart + ' Unable to remove MS Transaction entry.', @rcode = 1
     			goto Ticket_error
     			end
     			
--     		----------------------------------
--     		-- REMOVE ASSOCIATED SURCHARGES --
--     		----------------------------------
--     		-- ISSUE: #129350 --
--     		DELETE bMSTD
--     		 WHERE SurchargeKeyID = @MSTDKeyID
     		
      
     		commit transaction
			goto Ticket_loop  -- next batch entry
			
       end --if @transtype = 'D'
     
     
     
     Ticket_error:       -- error during processing
     	rollback transaction
     	goto bspexit
     
     
     Ticket_end:			-- no more Transactions to process
     	close Ticket
     	deallocate Ticket
     	select @opencursor = 0
      
     --Inventory update (Auto production and sales/purchases)
     exec @rcode = dbo.bspMSPostIN @co, @mth, @batchid, @dateposted, @errmsg output
     if @rcode <> 0 goto bspexit
     
     -- make sure all Auto Production distributions have been processed
     if exists(select 1 from bMSPA with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
            begin
            select @errmsg = 'Not all auto production updates to Inventory were posted - unable to close the batch!', @rcode = 1
            goto bspexit
            end
     
     -- make sure all IN Distributions have been processed
     if exists(select 1 from bMSIN with (nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
            begin
            select @errmsg = 'Not all sales and purchase updates to Inventory were posted - unable to close the batch!', @rcode = 1
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
            select @errmsg = 'Not all updates to EM were posted - unable to close the batch!', @rcode = 1
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
     update bHQBC
     set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
     where Co = @co and Mth = @mth and BatchId = @batchid
     if @@rowcount = 0
     	begin
     	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
     	goto bspexit
     	end
      
     
	-------------------------------------------------------
	-- REMOVE ASSOCIATED RECORDS FROM MSSurcharges TABLE --
	-------------------------------------------------------
	-- ISSUE: #129350 --
	DELETE bMSSurcharges 
	 WHERE Co = @co 
	   AND Mth = @mth 
	   AND BatchId = @batchid
     
     
   bspexit:
     	if @opencursor = 1
     		begin
     		close Ticket
     		deallocate Ticket
     		set @opencursor = 0
     		end
      
     	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTBPost] TO [public]
GO
