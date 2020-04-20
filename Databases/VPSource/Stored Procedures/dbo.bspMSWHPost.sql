
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  procedure [dbo].[bspMSWHPost]
/***********************************************************
* Created By:	GG 02/12/01
* Modified By:	CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*				GF 03/27/2003 - #20785 - TransMth added to MSWD to allow payments in batch month or earlier.
*				GF 06/20/2003 - #20785 - update MSTD.APCo, APMth when APRef is not null.
*				GF 07/29/2003 - #21933 - speed improvements
*				GF 08/15/2003 - #22015 - added user memo update from MSWH into APTH
*				GF 12/04/2003 - issue #23139 - use new stored procedure to create user memo update statement.
*				GF 12/15/2004 - #18884, #20558, #25040 MS hauler payment enhancements
*				GF 02/22/2005 - issue #21765 - reset APVA audit flag to 'Y' after update.
*				GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
*				MH 09/17/2011 - TK-01835
*				MH 10/03/2011 - TK-01835 - Corrected update to AP.  Not correctly updating the header invoice
*										total after processing AP Lines.
*				MV 04/04/2012 - TK-13733 AP On-Cost SubjToOnCostYN, OnCostStatus
*				CHS	04/19/2012 - TK-14208 - added Pay Method for Credit Services
*				MV 05/09/2012  - TK-14787 APTD Amount should include tax if not use tax.  Insert GST/PST tax amts
*				GF 04/25/2013 TFS-48153 write back APTL KeyId to MSTD HaulAPTLKeyId
*				GF 05/15/2013 TFS-49547 need to update after each APTL entry, not after all lines added.
*
*
*
* Called from MS Batch Processing to post a validated
* batch of Hauler Payments.
*
* Posts haul vendor invoices to AP - inserts expense transactions
* Updates bMSTD - sets APRef, PayCode, PayRate, PayBasis, and PayTotal
*
* Calls bspMSWHPostGL to update account distributions to GL.
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
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
@dateposted bDate = null, @errmsg varchar(255) = null output)
as
set nocount on
    
   declare @rcode int, @status tinyint, @apco bCompany, @exppaytype tinyint, @apcmco bCompany, @openMSWHcursor tinyint,
        	@seq int, @vendorgroup bGroup, @vendor bVendor, @apref bAPReference, @invdate bDate, @description bDesc,
        	@duedate bDate, @holdcode bHoldCode, @paycontrol varchar(10), @cmco bCompany, @cmacct bCMAcct, 
    		@errorstart varchar(12), @v1099yn bYN, @v1099type varchar(10), @v1099box tinyint, @paymethod char(1), 
    		@aptdstatus tinyint, @aptrans bTrans, @openMSAPcursor tinyint, @glco bCompany, @glacct bGLAcct, 
    		@paycode bPayCode, @paytotal bDollar, @linedesc bDesc, @apline smallint, @numrows int, @Notes varchar(400),
      		@apthud_flag bYN, @join varchar(2000), @where varchar(2000), @update varchar(2000), @openMSWHTrans tinyint,
    		@sql varchar(8000), @mswh_count bTrans, @mswh_trans bTrans, @guid uniqueidentifier,
			@paycategory int, @paytype tinyint, @discoff bDollar, @discdate bDate, @taxgroup bGroup, @haulpaytaxtype tinyint,
			@haulpaytaxamt bDollar, @haulpaytaxcode bTaxCode, @SubjToOnCostYN bYN,
			@Eft char(1), @SeparatePayInvYN bYN, @VendorPaymethod char(1), @ApcoCsCmAcct bCMAcct, -- CHS TK-14206 
			@GSTTaxRate bRate, @PSTTaxRate bRate, @GSTTaxAmt bDollar, @PSTTaxAmt bDollar
			----TFS-48153
			,@APTL_KeyId BIGINT	
    
   select @rcode = 0, @openMSWHcursor = 0, @apthud_flag = 'N', @mswh_count = 0, @mswh_trans = 0, @openMSWHTrans = 0
   
   -- check for Posting Date
   if @dateposted is null
        begin
        select @errmsg = 'Missing posting date!', @rcode = 1
        goto bspexit
        end
    
   -- call bspUserMemoQueryBuild to create update, join, and where clause
   -- pass in source and destination. Remember to use views only unless working
   -- with a Viewpoint (bidtek) connection.
   exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'MSWH', 'APTH', @apthud_flag output,
    			@update output, @join output, @where output, @errmsg output
   if @rcode <> 0 goto bspexit
    
    
   -- validate HQ Batch
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'MS HaulPay', 'MSWH', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
        begin
        select @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
        goto bspexit
        end
   -- set HQ Batch status to 4 (posting in progress)
   update bHQBC
   set Status = 4, DatePosted = @dateposted
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
        begin
        select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
        goto bspexit
        end
   
   
   -- get MS Company info
   select @apco = APCo from bMSCO with (Nolock) where MSCo = @co
   if @@rowcount = 0
        begin
        select @errmsg = 'Invalid MS Co#!', @rcode = 1
        goto bspexit
        end
   
   
   
   
   -- need cursor on bMSWH for each distinct APCo
   declare bcMSWHTrans cursor LOCAL FAST_FORWARD for select distinct(APCo)
   from bMSWH where Co = @co and Mth = @mth and BatchId = @batchid
   group by APCo
   
   --open cursor
   open bcMSWHTrans
   select @openMSWHTrans = 1
   
   MSWHTrans_loop:
   fetch next from bcMSWHTrans into @apco
   
   if @@fetch_status = -1 goto MSWHTrans_end
   if @@fetch_status <> 0 goto MSWHTrans_loop
   
   -- get count of bMSWH rows that need a APTrans
   select @mswh_count = count(*) from bMSWH
   where Co=@co and Mth=@mth and BatchId=@batchid and APTrans is null and APCo=@apco
   -- only update HQTC and MSWH if there are MSWH rows that need updating
   if isnull(@mswh_count,0) <> 0
   	begin
   	-- get next available Transaction # for APTH
   	exec @aptrans = dbo.bspHQTCNextTransWithCount 'bAPTH', @apco, @mth, @mswh_count, @errmsg output
   	if @aptrans = 0
   		begin
   		select @errmsg = 'Unable to get AP transaction from HQTC!', @rcode = 1
   		goto bspexit
   		end
     
   	-- set @mswh_trans to last transaction from bHQTC as starting point for update
   	set @mswh_trans = @aptrans - @mswh_count
     	
   	-- update bMSWH and set APTrans
   	update bMSWH set @mswh_trans = @mswh_trans + 1, APTrans = @mswh_trans
   	where Co=@co and Mth=@mth and BatchId=@batchid and APTrans is null and APCo=@apco
   	-- compare count from update with MSWH rows that need to be updated
   	if @@rowcount <> @mswh_count
   		begin
   		select @errmsg = 'Error has occurred updating APTrans in MSWH batch!', @rcode = 1
   		goto bspexit
   		end
   
      	-- have now successfully updated APTrans to MSWH, now update distribution tables
      	-- update bMSWG
      	update bMSWG set APTrans = b.APTrans
      	from bMSWG a join bMSWH b on b.Co=a.MSCo and b.Mth=a.Mth and b.BatchId=a.BatchId and b.BatchSeq=a.BatchSeq
      	where a.MSCo=@co and a.Mth=@mth and a.BatchId=@batchid and b.Co=@co and b.Mth=@mth and b.BatchId=@batchid and b.APCo=@apco
   	end
   
   
   goto MSWHTrans_loop
   
   
   MSWHTrans_end:
   	if @openMSWHTrans = 1
   		begin
   		close bcMSWHTrans
   		deallocate bcMSWHTrans
   		set @openMSWHTrans = 0
   		end
   
   
   
   
   -- declare cursor on MS Hauler Worksheet Batch
   declare bcMSWH cursor LOCAL FAST_FORWARD
   for select BatchSeq, VendorGroup, HaulVendor, APRef, InvDate, InvDescription, DueDate,
        	HoldCode, PayControl, CMCo, CMAcct, APTrans, UniqueAttchID, APCo, PayCategory, 
   		PayType, DiscDate
   from bMSWH
   where Co = @co and Mth = @mth and BatchId = @batchid
    
   -- open cursor
   open bcMSWH
   set @openMSWHcursor = 1
    
   -- process through all entries in batch
   MSWH_loop:
   fetch next from bcMSWH into @seq, @vendorgroup, @vendor, @apref, @invdate, @description, @duedate,
            @holdcode, @paycontrol, @cmco, @cmacct, @aptrans, @guid, @apco, @paycategory, @paytype, @discdate
    
   if @@fetch_status = -1 goto MSWH_end
   if @@fetch_status <> 0 goto MSWH_loop
    
   select @errorstart = 'Seq# ' + convert(varchar(6),@seq)
   
   -- -- -- get AP Company info
   select @exppaytype = ExpPayType, @apcmco = CMCo, @ApcoCsCmAcct = CSCMAcct	-- CHS TK-14208
   from bAPCO with (Nolock) where APCo = @apco
   if @@rowcount = 0
   	begin
   	select @errmsg = @errorstart + ' - Invalid AP Co#!', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- if MSWH.PayType is not null use instead of APCo.ExpPayType
   if @paytype is not null set @exppaytype = @paytype
   
   
	   -- get Vendor info
		SELECT	@v1099yn = V1099YN, 
				@v1099type = V1099Type, 
				@v1099box = V1099Box,
				--@paymethod = case EFT when 'A' then 'E' else 'C' end,  -- default is check unless active EFT
				@SubjToOnCostYN = SubjToOnCostYN,
				@Eft = EFT, @VendorPaymethod = PayMethod	-- CHS TK-14208
		FROM dbo.bAPVM WITH (NOLOCK) 
		WHERE VendorGroup = @vendorgroup AND Vendor = @vendor
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @errmsg = @errorstart + ' - Invalid Vendor!', @rcode = 1
			GOTO bspexit
		END
		
		
		-- CHS TK-14206
		SELECT @SeparatePayInvYN = 'N'
		
		IF @VendorPaymethod = 'S'
			BEGIN
			SELECT @paymethod='S', @cmacct = @ApcoCsCmAcct
			END

 		ELSE IF @Eft='A'
			BEGIN
			SELECT @paymethod='E'
			END
			
		ELSE
			BEGIN
			SELECT @paymethod='C'
			END
    
        -- determine detail status - 1 = open, 2 = hold
        select @aptdstatus = 1
        if @holdcode is not null select @aptdstatus = 2   -- transaction is on hold
        -- check for Vendor Hold codes
        if exists(select 1 from bAPVH with (Nolock) where APCo = @apco and VendorGroup = @vendorgroup and Vendor = @vendor)
            select @aptdstatus = 2
    
        begin transaction   -- start a transaction, commit when all updates for this invoice are complete (except GL dist)
    
    --     -- get next AP Trans #
    --     exec @aptrans = bspHQTCNextTrans 'bAPTH', @apco, @mth, @errmsg output
    --     if @aptrans = 0 goto MSWH_error
    
        -- add AP Transaction Header
        insert bAPTH(APCo, Mth, APTrans, VendorGroup, Vendor, APRef, Description,
            InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl, PayMethod, CMCo, CMAcct,
            PrePaidYN, PrePaidProcYN, V1099YN, V1099Type, V1099Box, PayOverrideYN, OpenYN, BatchId,
            Purge, InPayControl, UniqueAttchID, SeparatePayYN)
        values(@apco, @mth, @aptrans, @vendorgroup, @vendor, @apref, @description,
            @invdate, @discdate, @duedate, 0, @holdcode, @paycontrol, @paymethod, isnull(@cmco,@apcmco), @cmacct,
            'N', 'N', @v1099yn, @v1099type, @v1099box, 'N', 'Y', @batchid, 'N', 'N', @guid, @SeparatePayInvYN)
        if @@rowcount <> 1
            begin
            select @errmsg = @errorstart + ' - unable to insert AP transaction header!'
            goto MSWH_error
            end
    
    --     -- update AP Trans# to GL distribution table
    --     update bMSWG set APTrans = @aptrans 
    -- 	where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    
        -- update Last Invoice Date in Vendor Master
        update bAPVM set LastInvDate = @invdate
        where VendorGroup = @vendorgroup and Vendor = @vendor and isnull(LastInvDate,'01/01/99') < @invdate
    
    	-- update User Memos
    	if @apthud_flag = 'Y'
    		begin
    		-- build joins and where clause
    	  	select @join = @join + ' and APTH.APCo = ' + convert(varchar(3),@apco)
    					+ ' and APTH.APTrans = ' + convert(varchar(10),@aptrans)
    	  	select @where = @where + ' and b.BatchSeq = ' + convert(varchar(10), @seq)
    					+ ' and APTH.APCo = ' + convert(varchar(3),@apco)
    					+ ' and APTH.APTrans = ' + convert(varchar(10), @aptrans)
    		-- create user memo update statement
    		select @sql = @update + @join + @where
    		exec (@sql)
    	  	end
    	  	
   	-- declare cursor on MS Worksheet AP Lines
   	--TK-01835 Include Haul Payment Tax data.
   	declare bcMSAP cursor LOCAL FAST_FORWARD
   	for select GLCo, GLAcct, PayCode, convert(numeric(12,2),sum(PayTotal)), convert(numeric(12,2),sum(DiscOff)),
   			HaulPayTaxType, HaulPayTaxCode, convert(numeric(12,2), sum(isnull(HaulPayTaxAmt,0))), TaxGroup
   	from bMSAP
   	where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   	group by GLCo, GLAcct, PayCode, HaulPayTaxType, HaulPayTaxCode, TaxGroup -- create a separate line per Haul Expense Acct and Pay Code
    
   	-- open MS Worksheet AP Line cursor
   	open bcMSAP
   	select @openMSAPcursor = 1
    
   	-- process each Line on the Invoice
   	MSAP_loop:
   	fetch next from bcMSAP into @glco, @glacct, @paycode, @paytotal, @discoff, @haulpaytaxtype,
   					@haulpaytaxcode, @haulpaytaxamt, @taxgroup
    
            if @@fetch_status = -1 goto MSAP_end
            if @@fetch_status <> 0 goto MSAP_loop
    
            -- get Pay Code description
            select @linedesc = Description
            from bMSPC with (Nolock) where MSCo = @co and PayCode = @paycode
            
            --Calc GST/PST tax amounts
            SELECT @GSTTaxRate = 0, @PSTTaxRate = 0,@GSTTaxAmt=0,@PSTTaxAmt = 0
            IF @haulpaytaxtype = 3 -- only need to do this nonsense for VAT tax codes.
            BEGIN
				-- get the taxcode(s)
				SELECT @GSTTaxRate = TaxRate,@PSTTaxRate = PSTRate FROM dbo.vfHQTaxRatesForPSTGST(@taxgroup, @haulpaytaxcode)
				IF @PSTTaxRate = 0
				BEGIN
					/* When @pstrate = 0:  Either VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate. */
					SELECT @GSTTaxAmt = @haulpaytaxamt 
				END
				ELSE
				BEGIN
					SELECT @GSTTaxAmt = CASE (@GSTTaxRate + @PSTTaxRate) WHEN 0 THEN 0 ELSE (@haulpaytaxamt * @GSTTaxRate) / (@GSTTaxRate + @PSTTaxRate)END	
					SELECT @PSTTaxAmt = @haulpaytaxamt - @GSTTaxAmt	
				END	
            END
    
            -- get next available line on new trans
            select @apline = isnull(max(APLine),0) + 1
            from bAPTL with (Nolock) 
            where APCo = @apco and Mth = @mth and APTrans = @aptrans

    
            -- add a new AP Line - expense type, no misc, tax, or discount
            INSERT dbo.bAPTL
				(
					APCo,		 Mth,			APTrans,
					APLine,		 LineType,		GLCo,
					GLAcct,		 Description,	Units,
					UnitCost,	 PayType,		GrossAmt,
					MiscAmt,	 MiscYN,		TaxBasis,
					TaxAmt,		 Retainage,		Discount,
					BurUnitCost, PayCategory,	TaxGroup,
					TaxType,	 TaxCode,		SubjToOnCostYN,
					OnCostStatus
                )
            VALUES
				(
					@apco,				@mth,				@aptrans,
					@apline,			3,					@glco,
					@glacct,			@linedesc,			0,
					0,					@exppaytype,		@paytotal,
					0,					'N',				@paytotal,
					@haulpaytaxamt,		0,					@discoff,
					0,					@paycategory,		@taxgroup,
					@haulpaytaxtype,	@haulpaytaxcode,	@SubjToOnCostYN,
					CASE @SubjToOnCostYN WHEN 'Y' THEN 0 ELSE NULL END
                )
            if @@rowcount <> 1
                begin
                select @errmsg = 'Unable to insert AP line into APTL!'
                goto MSWH_error
                end

----TFS-48153
SET @APTL_KeyId = SCOPE_IDENTITY()

            -- add AP Detail - Seq #1
            INSERT dbo.bAPTD
					(
						APCo,			Mth,			APTrans, 
						APLine,			APSeq,			PayType, 
						DiscOffer,		DiscTaken, 		DueDate,
						Status,			PayCategory,	GSTtaxAmt,
						TotTaxAmount,	ExpenseGST,		PSTtaxAmt,
						Amount
					)
            VALUES
					(
						@apco,			@mth,			@aptrans,
						@apline,		1,				@exppaytype, 
						@discoff,		@discoff,		@duedate,
						@aptdstatus,	@paycategory,	@GSTTaxAmt,
						@haulpaytaxamt,	'N',			@PSTTaxAmt,
						@paytotal + CASE @haulpaytaxtype WHEN 2 THEN 0 ELSE ISNULL(@haulpaytaxamt,0) END
					)
    
            -- add Hold Detail for posted Hold Code
            if @holdcode is not null
                insert into bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
                values(@apco, @mth, @aptrans, @apline, 1, @holdcode)
    
			-- add Hold Detail for all Vendor Hold Codes
			insert bAPHD(APCo, Mth, APTrans, APLine, APSeq, HoldCode)
			select d.APCo, d.Mth, d.APTrans, d.APLine, d.APSeq, v.HoldCode
			from bAPTD d with (nolock)
			join bAPVH v with (Nolock) on d.APCo = v.APCo
			where d.APCo = @apco and d.Mth = @mth and d.APTrans = @aptrans and d.APLine = @apline and d.APSeq = 1
				and v.VendorGroup = @vendorgroup and v.Vendor = @vendor
				and not exists(select top 1 1 from bAPHD d2 with (nolock) where d2.APCo = d.APCo and d2.Mth = d.Mth
				and d2.APTrans = d.APTrans and d2.APLine = d.APLine and d2.APSeq = d.APSeq and d2.HoldCode = v.HoldCode)
    
			-- update Invoice Total in Transaction Header
			update bAPTH set InvTotal = InvTotal + (@paytotal + isnull(@haulpaytaxamt, 0.00))
			where APCo = @apco and Mth = @mth and APTrans = @aptrans
			if @@rowcount <> 1
				begin
				select @errmsg = 'Unable to update Invoice total in AP Transaction Header!'
				goto MSWH_error
				end
    
            -- update Vendor Activity
            update bAPVA set InvAmt = InvAmt + @paytotal, AuditYN = 'N'
            where APCo = @apco and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
            if @@rowcount = 0
   				begin
             	insert into bAPVA(APCo, VendorGroup, Vendor, Mth, InvAmt, PaidAmt, DiscOff, DiscTaken, AuditYN)
       			values(@apco, @vendorgroup, @vendor, @mth, @paytotal, 0, @discoff, 0, 'N')
   				END
    		update bAPVA set AuditYN = 'Y'
   			where APCo = @apco and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
   
			---- TFS-48153 TFS-49547 update MS Trans Detail with APRef and Hauler Pay info
			update dbo.bMSTD set PayCode= xx.PayCode,
							 PayRate= xx.PayRate, 
							 PayBasis= xx.PayBasis, 
		    				 PayTotal= xx.PayTotal,
							 APCo = @apco,
							 APMth = @mth,
							 APRef= @apref,
							 HaulAPTLKeyID = @APTL_KeyId
			FROM
				(
				SELECT DISTINCT MSTD.KeyID, MSWD.PayCode, MSWD.PayRate, MSWD.PayBasis, MSWD.PayTotal
				FROM dbo.bMSTD MSTD
				INNER JOIN dbo.bMSWD MSWD ON MSWD.Co = MSTD.MSCo and MSWD.TransMth = MSTD.Mth and MSWD.MSTrans = MSTD.MSTrans
				INNER JOIN dbo.bMSAP MSAP ON MSAP.MSCo = MSWD.Co AND MSAP.Mth = MSWD.Mth AND MSAP.BatchId = MSWD.BatchId AND MSAP.BatchSeq = MSWD.BatchSeq AND MSAP.MSTrans=MSWD.MSTrans
				WHERE MSAP.MSCo = @co
					AND MSAP.Mth = @mth
					AND MSAP.BatchId = @batchid
					AND MSAP.BatchSeq = @seq
					AND MSAP.GLCo = @glco
					AND MSAP.GLAcct = @glacct
					AND MSAP.PayCode = @paycode
					AND ISNULL(MSAP.HaulPayTaxType, '') = ISNULL(@haulpaytaxtype, '')
					AND ISNULL(MSAP.HaulPayTaxCode, '') = ISNULL(@haulpaytaxcode, '')
					--AND MSAP.TaxGroup = @taxgroup
					) xx
			  WHERE xx.KeyID = dbo.bMSTD.KeyID


            -- remove MS AP Invoice Line (may be multiple rows)
            delete bMSAP
            where MSCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                and GLCo = @glco and GLAcct = @glacct and PayCode = @paycode
				----TFS-49547
				AND ISNULL(HaulPayTaxType, '') = ISNULL(@haulpaytaxtype, '')
				AND ISNULL(HaulPayTaxCode, '') = ISNULL(@haulpaytaxcode, '')
				--AND TaxGroup = @taxgroup

		goto MSAP_loop -- next AP Invoice Line




        MSAP_end:  -- finished with AP Invoice Lines
            close bcMSAP
            deallocate bcMSAP
            select @openMSAPcursor = 0


----TFS-48153 TFS-49547
            -- update MS Trans Detail with APRef and Hauler Pay info
        --    update bMSTD set APRef=@apref, PayCode=d.PayCode, PayRate=d.PayRate, PayBasis=d.PayBasis, 
    				--		 PayTotal=d.PayTotal, APCo=@apco, APMth=@mth
							 ------TFS-48153
							 --,HaulAPTLKeyID = @APTL_KeyId
        --    from bMSTD t
        --    join bMSWD d with (Nolock) on d.Co = t.MSCo and d.TransMth = t.Mth and d.MSTrans = t.MSTrans
        --    where d.Co = @co and d.Mth = @mth and d.BatchId = @batchid and d.BatchSeq = @seq
    
        --    select @numrows = @@rowcount
    
            -- remove Worksheet Detail
            delete bMSWD where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
            --if @numrows <> @@rowcount
            --    begin
            --    -- make sure number of Worksheet Detail rows deleted matches number of Trans Detail updated
            --    select @errmsg = 'Unable to update MS Transaction Detail with Hauler Payment information!'
            --    goto MSWH_error
            --    end
---- TFS-48153 TFS-49547

		-- make sure all AP Invoice Line distributions have been processed for this worksheet before deleting
		if exists(select 1 from bMSAP with (Nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid AND BatchSeq = @seq)
			begin
			select @errmsg = 'Unable to post all invoice lines to AP for batch seq: ' + dbo.vfToString(@seq)
			goto MSWH_error
			end

        -- remove Hauler Worksheet Batch Header
        delete bMSWH where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
        if @@rowcount <> 1
            begin
            select @errmsg = 'Unable to delete Hauler Worksheet Header entry!'
            goto MSWH_error
            end
    
            commit transaction
    
            goto MSWH_loop  -- get next Worksheet Header entry
    
    MSWH_error:       -- error during Invoice processing
        rollback transaction
        select @rcode = 1
        goto bspexit
    
    MSWH_end:   -- finished with Worksheet Headers
        close bcMSWH
        deallocate bcMSWH
        select @openMSWHcursor = 0
    
    --General Ledger update
    exec @rcode = dbo.bspMSWHPostGL @co, @mth, @batchid, @dateposted, @errmsg output
    if @rcode <> 0 goto bspexit
    
    -- make sure all AP Invoice Line distributions have been processed
    if exists(select 1 from bMSAP with (Nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
        begin
        select @errmsg = 'Not all Invoice Line updates to AP were posted - unable to close the batch!', @rcode = 1
        goto bspexit
        end
    -- make sure all Worksheet Batch Detail has been processed
    if exists(select 1 from bMSWD with (Nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
        begin
        select @errmsg = 'Not all Hauler Worksheet detail updates were posted - unable to close the batch!', @rcode = 1
        goto bspexit
        end
    -- make sure all Worksheet Batch Headers have been processed
    if exists(select 1 from bMSWH with (Nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
        begin
        select @errmsg = 'Not all Hauler Worksheet headers were posted - unable to close the batch!', @rcode = 1
        goto bspexit
        end
    -- make sure all GL Distributions have been processed
    if exists(select 1 from bMSWG with (Nolock) where MSCo = @co and Mth = @mth and BatchId = @batchid)
        begin
        select @errmsg = 'Not all updates to GL were posted - unable to close the batch!', @rcode = 1
        goto bspexit
        end
    
     -- set interface levels note string
        select @Notes=Notes from bHQBC with (Nolock) 
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
        from bMSCO a with (Nolock) where MSCo=@co
    
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
   
   
   
   bspexit:
       if @openMSWHcursor = 1
            begin
       	    close bcMSWH
       		deallocate bcMSWH
       		end
       if @openMSAPcursor = 1
            begin
       	    close bcMSAP
       		deallocate bcMSAP
       		end
    
        if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
        return @rcode


GO

GRANT EXECUTE ON  [dbo].[bspMSWHPost] TO [public]
GO
