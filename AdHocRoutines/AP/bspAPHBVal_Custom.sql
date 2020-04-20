USE [Viewpoint]
GO

--sp_rename bspAPHBVal,bspAPHBVal_Original
--go


alter procedure [dbo].[bspAPHBVal]
/***********************************************************
* CREATED: SE 7/14/97
* MODIFIED: GG 07/07/99
*			EN 1/22/00 - expand dim of @payname and @oldpayname and validate OldPayAddInfo on add
*           GG 06/06/00 - validate Expense Journal
*           GR 11/09/00 - added validation for ap reference if ap reference unique flag is checked in company parameters
*           GG 11/27/00 - changed datatype from bAPRef to bAPReference
*		    TV 03/05/01 - Validate EM component codes
*           DANF 05/14/01 - Added clearing of PO Receipt Expense distribution tables.
*           MV 10/04/01 - 10997 - added addenda validation
*           MV 10/09/01 - modified addenda validation
*         	kb 10/24/1 - Issue #15028
*           tv 12/05/01 - issue 15379
*		    GG 01/21/02 - #14022 - skip check for APRef uniqueness if bAPHB.ChkRev = 'Y', cleanup
*	    	MV 03/26/02 - #14164 - validate paid header
*           CMW 04/03/02 - increased InvID from 5 to 10 char (issue # 16366)
*		  	MV 04/05/02 - #16530 - validate CMAcct
*		  	MV 04/09/02 - additional fed tax payment validation
*		  	kb 7/10/2 - issue #17890 validating CMAcct with apco instead of cmco
*			MV 08/05/02 - #15113 - change APRefUnqYN to APRefUnq,get APRefUnqOvr from bAPVM
*			   09/18/02 - 15113 - warn or prevent for all levels enhancement
*			kb 10/22/2 - issue #18878
*		  	MV	11/06/02 - 18037 - validate AddressSeq
*			MV 01/08/03 - 18720 - validate vendor for PO and SL when no lines in batch
*			MV 12/01/03 - #23061 - isnull wrap
*			ES 03/11/04 - #23061 more isnull wrap
*			GG 07/25/07 - #120561 - clear and reload bHQCC
*			MV 03/11/08 - #127347 Intl addresses
*			MV 10/22/08 - #129560 - validate vendor hold codes 
*			MV 11/19/09 - #136316 - don't validate Recurring invoice.
*			TJL 01/28/10 - #135440 - Don't allow NULL AP Reference values.
*			MV 08/12/10 - #140906 - Make sure PO GL debits and credits balance
*			MH 03/24/11 - TK-02798 SM Changes.
*			MV 07/18/11 - B-04686 - validate inv total against lines total for CA and AU
*			JVH 9/6/11 - TK-08137 - Capture costs for SM PO Items
*			EN 05/14/2012 - D-04590 Correct the formula used to compute total invoice amount for CA and AUS
*			DAN SO 01/23/2013 - TK-20815 - validate Recurring Invoice (catch here - not in post)
*
* USAGE:
* Validates each entry in bAPHB and bAPLB for a selected batch - must be called
* prior to posting the batch.
*
* Errors in batch added to bHQBE using bspHQBEInsert
*
* INPUT PARAMETERS
*   @co            APCo
*   @mth           Batch expense month
*   @batchid       Batch ID to validate
*
* OUTPUT PARAMETERS
*   @errmsg        error message
*
* RETURN VALUE
*   0              success
*   1              fail
*****************************************************/
    
      	@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
      as
    
      set nocount on
    
DECLARE @PrintDebug bit
SET @PrintDebug=0

      declare @rcode int, @errortext varchar(255), @inuseby bVPUserName, @status tinyint,
          	 @opencursorAPHB tinyint, @opencursorAPLB tinyint, @itemcount int, @deletecount int,
          	 @errorstart varchar(50), @glco bCompany, @vendorsort varchar(15), @apref bAPReference,
              @paycontrol varchar(10), @suppliersort varchar(15), @retpaytype tinyint, @retholdcode bHoldCode,
              @sortname varchar(15), @oldsortname varchar(15), @invtotyn bYN, @linestotal bDollar,
              @apglco bCompany, @expjrnl bJrnl, @ComponentTypeCode varchar(10), @LineType tinyint, @APLine smallint,
              @taxcode bTaxCode, @taxamt bDollar, @validcnt int,@aprefunqyn bYN,@validcnt2 int, 
              @HQCoCountry char(2), @TotGross bDollar, @TotRetg bDollar, @TotTax bDollar,
              @TotMisc bDollar --D-04590 5/14/2012
      -- bAPHB declares
      declare @seq int, @transtype char(1), @aptrans bTrans, @vendorgroup bGroup, @vendor bVendor,
            	 @description bDesc, @invdate bDate, @discdate bDate, @duedate bDate, @invtotal bDollar,
      	     @holdcode bHoldCode, @paymethod char(1), @cmco bCompany, @cmacct bCMAcct, @prepaidyn bYN,
              @prepaidmth bMonth, @prepaiddate bDate, @prepaidchk bCMRef, @v1099yn bYN, @v1099type varchar(10),
           	 @v1099box tinyint, @payoverrideyn bYN, @payname varchar(60), @oldvendorgroup bGroup, @oldvendor bVendor,
          	 @oldapref bAPReference, @olddescription bDesc, @oldinvdate bDate, @olddiscdate bDate, @oldduedate bDate,
          	 @oldinvtotal bDollar, @oldholdcode bHoldCode, @oldpaycontrol varchar(10), @oldpaymethod char(1),
          	 @oldcmco bCompany, @oldcmacct bCMAcct, @oldprepaidyn bYN, @oldprepaidmth bMonth, @oldprepaiddate bDate,
          	 @oldprepaidchk bCMRef, @oldv1099yn bYN, @oldv1099type varchar(10), @oldv1099box tinyint, @oldpayoverrideyn bYN,
          	 @oldpayname varchar(60), @oldpayaddinfo varchar(60),@oldpayaddress varchar(60), @oldpaycity varchar(30),
              @oldpaystate varchar(4), @oldpayzip bZip,@addendatypeid tinyint, @prco bCompany, @employee bEmployee,
              @dlcode bEDLCode,@taxformcode varchar (10),@taxperiodenddate bDate, @amounttype varchar (10),@addressseq tinyint,
    		 @amount bDollar, @amttype3 varchar (10),@amt3 bDollar, @invid char(10), @chkrev bYN, @headerpaidyn bYN, @oldcountry char(2),
			 @paystate varchar(4), @paycountry char(2)
   
      select @rcode = 0
    
    /* set open cursor flag to false */
    select @opencursorAPHB = 0, @opencursorAPLB = 0
    
    --Verify that the batch can be validated, set the batch status to validating and delete generic distributions
	EXEC @rcode = dbo.vspHQBatchValidating @BatchCo = @co, @BatchMth = @mth, @BatchId = @batchid, @Source = 'AP Entry', @TableName = 'APHB', @msg = @errmsg OUTPUT
	IF @rcode <> 0 GOTO bspexit
    
    /* clear EM Distributions Audit */
    delete bAPEM where APCo = @co and Mth = @mth and BatchId = @batchid
    
    /* clear GL Distributions Audit */
    delete bAPGL where APCo = @co and Mth = @mth and BatchId = @batchid
    
    /* clear Inventory Distributions Audit */
    delete bAPIN where APCo = @co and Mth = @mth and BatchId = @batchid
    
    /* clear Job Cost Distributions Audit */
    delete bAPJC where APCo = @co and Mth = @mth and BatchId = @batchid    
       
    /* clear PO JC Distribution Audit */
    delete bPORJ where POCo = @co and Mth = @mth and BatchId = @batchid
    
    /* clear PO GL Distribution Audit */
    delete bPORG where POCo = @co and Mth = @mth and BatchId = @batchid
    
    /* clear PO EM Distribution Audit */
    delete bPORE where POCo = @co and Mth = @mth and BatchId = @batchid
    
    /* clear PO IN Distribution Audit */
    delete bPORN where POCo = @co and Mth = @mth and BatchId = @batchid
    
    /*Clear any of the HQBatchLine records created for SM line types.*/
    DELETE dbo.vHQBatchLine WHERE Co = @co AND Mth = @mth AND BatchId = @batchid
    
	/* clear SM Disstribution Audit */
	delete vAPSM where APCo = @co and Mth = @mth and BatchId = @batchid         
    
	DELETE vGLEntry
	FROM dbo.vGLEntryBatch
		INNER JOIN dbo.vGLEntry ON vGLEntryBatch.GLEntryID = vGLEntry.GLEntryID
	WHERE vGLEntryBatch.Co = @co AND vGLEntryBatch.Mth = @mth AND vGLEntryBatch.BatchId = @batchid

    /* get Company info from APCO */
    select @apglco = GLCo, @expjrnl = ExpJrnl, @invtotyn = InvTotYN, @aprefunqyn = APRefUnqYN
    from bAPCO where APCo = @co
    if @@rowcount = 0
    	begin
        select @errmsg = 'Invalid AP Company #' + isnull(convert(varchar(3),@co), ''), @rcode = 1  --#23061
        goto bspexit
        end
    if @expjrnl is null
        begin
        select @errmsg = 'Must first assign an Expense Journal in AP Company!', @rcode = 1
        goto bspexit
        end
    -- validate Expense Journal in AP GL Co#
    if not exists(select * from bGLJR where GLCo = @apglco and Jrnl = @expjrnl)
        begin
        select @errmsg = 'Invalid Expense Journal ' + isnull(@expjrnl, '') + ' assigned in AP Company!', @rcode = 1  --#23061
        goto bspexit
        end
        
    -- Get HQCO default country V1# B-04686 
    SELECT @HQCoCountry = DefaultCountry
    FROM dbo.bHQCO
    WHERE HQCo=@co

	-- add HQ Close Control entries
	INSERT dbo.bHQCC(Co, Mth, BatchId, GLCo)
	SELECT @co, @mth, @batchid, @apglco
	UNION --Union will ensure a GLCo is only added once
	SELECT Co, Mth, BatchId, GLCo
	FROM dbo.bAPLB
    WHERE Co = @co AND Mth = @mth AND BatchId = @batchid
    
    /* declare cursor on AP Header Batch for validation */
    declare bcAPHB cursor for
    select BatchSeq, BatchTransType, APTrans, VendorGroup, Vendor, APRef, Description, InvDate,
    	DiscDate, DueDate, InvTotal, HoldCode, PayControl, PayMethod, CMCo, CMAcct, PrePaidYN,
    	PrePaidMth, PrePaidDate, PrePaidChk, V1099YN, V1099Type, V1099Box, PayOverrideYN, PayName,
    	OldVendorGroup, OldVendor, OldAPRef, OldDesc, OldInvDate, OldDiscDate, OldDueDate, OldInvTotal,
    	OldHoldCode, OldPayControl, OldPayMethod, OldCMCo, OldCMAcct, OldPrePaidYN, OldPrePaidMth,
    	OldPrePaidDate, OldPrePaidChk, Old1099YN, Old1099Type, Old1099Box, OldPayOverrideYN, OldPayName,
    	OldPayAddInfo, OldPayAddress, OldPayCity, OldPayState, OldPayZip, AddendaTypeId, PRCo, Employee,
    	DLcode, TaxFormCode, TaxPeriodEndDate, AmountType, Amount,AmtType3, Amount3, InvId, ChkRev, PaidYN,
    	AddressSeq,OldPayCountry,PayState,PayCountry
    from bAPHB
    where Co = @co and Mth = @mth and BatchId = @batchid
    
    /* open cursor */
    open bcAPHB
    select @opencursorAPHB = 1
    
    APHB_loop:
    	fetch next from bcAPHB into @seq, @transtype, @aptrans, @vendorgroup, @vendor, @apref,
    		@description, @invdate, @discdate, @duedate, @invtotal, @holdcode, @paycontrol,
      	 	@paymethod, @cmco, @cmacct, @prepaidyn, @prepaidmth, @prepaiddate, @prepaidchk,
            @v1099yn, @v1099type, @v1099box, @payoverrideyn, @payname, @oldvendorgroup, @oldvendor,
            @oldapref, @olddescription, @oldinvdate, @olddiscdate, @oldduedate, @oldinvtotal, @oldholdcode,
            @oldpaycontrol, @oldpaymethod, @oldcmco, @oldcmacct, @oldprepaidyn, @oldprepaidmth, @oldprepaiddate,
            @oldprepaidchk, @oldv1099yn, @oldv1099type, @oldv1099box, @oldpayoverrideyn, @oldpayname,
            @oldpayaddinfo, @oldpayaddress, @oldpaycity, @oldpaystate, @oldpayzip, @addendatypeid, @prco, @employee,
            @dlcode, @taxformcode, @taxperiodenddate, @amounttype, @amount,@amttype3, @amt3, @invid, @chkrev,
    	   @headerpaidyn, @addressseq,@oldcountry,@paystate,@paycountry
    
    	if @@fetch_status <> 0 goto APHB_end

		-- 2015.01.08 - LWO - Get UIMth and UISeq from APHB for error reporting
		DECLARE @APHBUIMth bMonth
		DECLARE @APHBUISeq INT
		DECLARE @APHBUIMsg VARCHAR(50)	
		SELECT @APHBUIMth = UIMth, @APHBUISeq=UISeq	FROM dbo.APHB WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND BatchSeq = @seq	
		SELECT 	@APHBUIMsg = ' [' + CONVERT(VARCHAR(10),@APHBUIMth,101) + ':' + CAST(@APHBUISeq AS VARCHAR(10)) + ']'
	    
    	/* validate AP Detail Batch info for each entry */
        select @errorstart = 'Seq#' + isnull(convert(varchar(6),@seq), '') + ' ' + @APHBUIMsg +--#23061
    
        -- validate transaction type
        if @transtype not in ('A','C','D')
            BEGIN
            select @errortext = isnull(@errorstart, '') + ' -  Invalid transaction type, must be ''A'',''C'', or ''D''.'  --#23061
    		goto APHB_error
            end
    
        -- Validate CMAcct - #16530
    	if @cmacct is not null
    	begin
    	select @validcnt = count(*) FROM bCMAC where CMCo = @cmco and CMAcct = @cmacct 
    	if @validcnt = 0
    		begin
    		select @errortext = isnull(@errorstart,'') + 'Invalid CM account' --#23061
    		goto APHB_error
    		end
    	end
    	-- validation specific to Add types of Invoice Header
        if @transtype = 'A'
            begin
            -- check Trans number to make sure it is null
            if @aptrans is not null
                begin
      	        select @errortext = isnull(@errorstart, '') + ' - New entries must have a null Transaction #!' --#23061
                goto APHB_error
                end
    
            if @oldvendorgroup is not null or @oldvendor is not null or @oldapref is not null
                or @olddescription is not null or @oldinvdate is not null or @olddiscdate is not null
                or @oldduedate is not null or @oldinvtotal is not null or @oldholdcode is not null
                or @oldpaycontrol is not null or @oldpaymethod is not null or @oldcmco is not null
                or @oldcmacct is not null or @oldprepaidyn is not null or @oldprepaidmth is not null
                or @oldprepaiddate is not null or @oldprepaidchk is not null or @oldv1099yn is not null
                or @oldv1099type is not null or @oldv1099box is not null or @oldpayoverrideyn is not null
                or @oldpayname is not null or @oldpayaddinfo is not null
                or @oldpayaddress is not null or @oldpaycity is not null
                or @oldpaystate is not null or @oldpayzip is not null or @oldcountry is not null
                begin
                select @errortext = isnull(@errorstart, '') + ' - all old values must be null in header for New entries!' --#23061
                goto APHB_error
                end
            end
    
        if @transtype in ('A','C')
    		begin
            -- validate Vendor
            select @vendorsort = convert(varchar(15),@vendor)
            exec @rcode = bspAPVendorVal @co, @vendorgroup, @vendorsort, 'Y', 'R', @msg = @errmsg output
            if @rcode <> 0
            	begin
      	     	select @errortext = isnull(@errorstart, '') + ': ' + isnull(@errmsg,'') --#23061
IF @PrintDebug=1 PRINT 'bspAPHBVal 2: '+@errortext
      	     	goto APHB_error
      	     	end
            -- get current Vendor Sort Name
            select @sortname = SortName
    	   from bAPVM
            where VendorGroup = @vendorgroup and Vendor = @vendor
			-- validate vendor holdcodes	
			select @validcnt = count (*) from bAPVH where VendorGroup=@vendorgroup and Vendor=@vendor
			if @validcnt > 0 
			begin
				select @validcnt2 = count (*) from bAPVH v with (nolock) join bHQHC h on v.HoldCode=h.HoldCode
					where v.VendorGroup=@vendorgroup and v.Vendor=@vendor
				if @validcnt <> @validcnt2
				begin
				select @errortext = isnull(@errorstart, '') + 'One or more Vendor HoldCodes are not on file!'
IF @PrintDebug=1 PRINT 'bspAPHBVal 3: '+@errortext
				goto APHB_error 
				end
			end
    
            -- get the total of all the lines
            exec @rcode= bspAPTHTotalGet @co, @mth, @batchid, @seq, @aptrans, @gross = @TotGross output,
				@freight = @TotMisc output, --D-04590 5/14/2012
				@salestax = @TotTax output, @retainage = @TotRetg output,@total = @linestotal output,
    			@msg = @errmsg output
            if @rcode <> 0
                begin
      	     	select @errortext = isnull(@errorstart, '') + ':' + isnull(@errmsg,'') --#23061
IF @PrintDebug=1 PRINT 'bspAPHBVal 4: '+@errortext
      	     	goto APHB_error
      	     	end
      	    
      	    -- Calculate linestotal for CA and AU -  V1# B-04686	
			IF @HQCoCountry <> 'US'
			BEGIN
				SELECT @linestotal = @TotGross + @TotTax + @TotMisc - @TotRetg --D-04590 5/14/2012
			END
			-- Validate the invoice total amount against the total of the lines
			if @linestotal <> @invtotal and @invtotyn = 'Y'
                begin
                select @errortext = isnull(@errorstart, '') + 'Total of invoice lines(' + isnull(convert(varchar(20),@linestotal), '') 
                      + ') does not match the invoice total posted in the header(' + isnull(convert(varchar(20),@invtotal), '') + ')!' --#23061
IF @PrintDebug=1 PRINT 'bspAPHBVal 5: '+@errortext
      	     	goto APHB_error
      	     	end
			           
      
			--validate AP Reference - Cannot be NULL		
    	    if @apref is null
    			begin
    			select @errortext = isnull(@errorstart, '') + 'AP Reference may not be NULL!' --#135440
      	     	goto APHB_error
    			end
    			
    	    -- If not NULL, AP Reference has to be unique per vendor or company     			
            if @aprefunqyn = 'Y' and @chkrev = 'N'	-- #14022
            	begin
                exec @rcode = bspAPHDRefUnique @co, @mth, @batchid, @seq, @vendor, @apref,@vendorgroup, @errmsg output
                if @rcode <> 0
                	begin
            		select @errortext = isnull(@errorstart, '') + ': ' + isnull(@errmsg,'') --#23061
IF @PrintDebug=1 PRINT 'bspAPHBVal 6: '+@errortext
      	      		goto APHB_error
      	      		end
    			end
    		
    		-- validate AddressSeq
    		if @addressseq is not null
    		begin
    		select 1 from bAPAA with(nolock) where VendorGroup=@vendorgroup and Vendor=@vendor and AddressSeq=@addressseq
    		if @@rowcount = 0
    			begin
    			select @errortext = isnull(@errorstart, '') + ' Address Sequence:' 
   				+ isnull(convert(varchar(3),@addressseq), '') + 'does not exist' --#23061
    	     	goto APHB_error
    	     	end
    		end

			--validate state/country
			if @paystate is not null or @paycountry is not null
				begin
				exec @rcode = vspHQCountryStateVal @co,@paycountry, @paystate, @errmsg output
				if @rcode <> 0
            		begin
        			select @errortext = isnull(@errorstart, '') + ': ' + isnull(@errmsg,'') 
IF @PrintDebug=1 PRINT 'bspAPHBVal 7: '+@errortext
  	      			goto APHB_error
  	      			end
				end
    
    		-- validate vendor change if PO or SL lines in bAPTL and no lines in bAPLB	- #18720 
    		if @transtype = 'C' and not exists (select 1 from bAPLB where Co=@co and Mth=@mth and BatchId=@batchid
    			and BatchSeq=@seq)
    		begin
    		exec @rcode = bspAPVendValPOSL @co, @mth, @batchid, @seq, @vendor,'APEntry',0,@errmsg output
    		if @rcode <> 0
    	       begin
    	       select @errortext = isnull(@errorstart, '') + ' ' + isnull(@errmsg,'') --#23061
IF @PrintDebug=1 PRINT 'bspAPHBVal 8: '+@errortext
    	       goto APHB_error
    	 	  end
    		end
              
    		-- validate EFT addenda info
    		if @addendatypeid > 0
    			begin
    	        if @addendatypeid = 1   --Fed tax payments
    	        	begin		--all tax payments require data in these fields
    	            	if @taxformcode is null or @taxformcode = '' or @taxperiodenddate is null
    	                 	or @taxperiodenddate = '' 
    	                 	begin
    	                 	select @errortext = isnull(@errorstart, '') + ' - Tax Payment addenda information is missing!' --#23061
    	                 	goto APHB_error
    	                 	end
    	              	if @taxformcode = '94105'	--this tax form requires amttype3 and amt3 to have data
    					begin
    					if @amttype3 is null or @amttype3 = '' or @amt3 is null
    						begin
    		                select @errortext = isnull(@errorstart, '') + ' - Tax Payment addenda information is missing!' --#23061
    		                goto APHB_error
    		                end
    					end
    			else	-- all other tax forms require data in these fields
    			if @amounttype is null or @amounttype = '' or @amount is null   
    				begin
                 	select @errortext = isnull(@errorstart, '') + ' - Tax Payment addenda information is missing!'  --#23061
                 	goto APHB_error
                 	end
    				end
    		
    			if @addendatypeid = 2   -- child support
    	             begin
    	             if @prco is null or @employee is null or @employee = '' or @dlcode is null
    	                 begin
    	                 select @errortext = isnull(@errorstart, '') + ' - Child support addenda information is missing!' --#23061
    	                 goto APHB_error
    	                 end
    	             end
    			end
    
    	-- validate remaining header information
       	     exec @rcode = bspAPHBHeaderVal	@co, @mth, @batchid, @errorstart, @holdcode, @paymethod,
             	@prepaidyn, @prepaiddate, @prepaidmth, @prepaidchk, @cmacct, @v1099yn, @v1099type,
                @v1099box, @errmsg output
             if @rcode <> 0 goto APHB_loop
             end
    
    	-- validate 'delete' entries
        if @transtype = 'D'
    	begin
            select @itemcount = count(*)
    		from bAPTL
    		where APCo = @co and Mth = @mth and APTrans = @aptrans
    
            select @deletecount = count(*)
            from bAPLB
            where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and BatchTransType = 'D'
            if @itemcount <> @deletecount
    			begin
                select @errortext = isnull(@errorstart, '') + ' - In order to delete an invoice all invoice lines must be in the current batch and marked for delete! ' --#23061
      	     	goto APHB_error
      	     	end
    
            select @deletecount = count(*)
            from bAPLB
            where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and BatchTransType <> 'D'
            if @deletecount <> 0
                begin
                select @errortext = isnull(@errorstart, '') + ' - In order to delete an invoice you cannot have any Add or Change lines!' --#23061
      	     	goto APHB_error
                end
            end
    
    	-- get Old Vendor Sort Name
        select @oldsortname = null
        if @transtype in ('C','D')
            begin
            select @oldsortname = SortName
            from bAPVM
            where VendorGroup = @oldvendorgroup and Vendor = @oldvendor
            if @@rowcount = 0
                begin
                select @errortext = isnull(@errorstart, '') + ' - Missing original Vendor from existing transaction!' --#23061
                goto APHB_error
                end
            end
    
		-- Commented out validation of Recurring Invoice.  If Recurring Invoice was deleted after posting it in a batch, validation will 
		-- throw an error.  Once the Recurring invoice is in a batch or posted, who cares if it's deleted. No logical reason to validate here.
    	------------------------------------------
    	-- TK-20815 -- catch here - not in Post -- This also takes into consideration the above comments
    	------------------------------------------
    	--Validate Recurring Invoices
    	if isnull(@invid, '') <> '' AND @transtype in ('A','C')
            begin
            if not exists(select 1 from bAPRH where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor and InvId = @invid)
            	begin
                select @errortext = isnull(@errorstart, '') + '  Invalid/Missing Recurring Invoice information for vendor ' 
   				+ isnull(convert(varchar(10),@vendor), '') --#23061
    				+ ' and invoice ID ' + isnull(convert(varchar(10),@invid), ''), @rcode = 1
                goto APHB_error
      	        end
            end
    
    	--validate paid header
    	if @headerpaidyn = 'Y'
    		-- Check that only allowable changes have been made.
    		begin
    		if @vendor <> @oldvendor or isnull(@discdate,'') <> isnull(@olddiscdate,'')
    			or isnull(@duedate,'') <> isnull(@oldduedate,'')
    			or isnull(@holdcode,'') <> isnull(@oldholdcode,'')
    			or isnull(@paycontrol,'') <> isnull(@oldpaycontrol,'')
    			or isnull(@paymethod,'') <> isnull(@oldpaymethod,'')
    			or @prepaidyn <>@oldprepaidyn
    			or isnull(@prepaidmth,'') <> isnull(@oldprepaidmth,'')
    			or isnull(@prepaiddate,'') <> isnull(@oldprepaiddate,'')
    			or isnull(@prepaidchk,'') <> isnull(@oldprepaidchk,'')
    			or @v1099yn <> @oldv1099yn
    			or isnull(@v1099type,'') <> isnull(@oldv1099type,'')
    			or isnull(@v1099box,0) <> isnull(@oldv1099box,0)
    			or @payoverrideyn <> @oldpayoverrideyn
    			or isnull(@payname,'') <> isnull(@oldpayname,'')
                	begin
                	select @errortext = isnull(@errorstart, '') + ' - Only AP Ref, Description and Invoice Date can be changed in a paid transaction!' --#23061
    
                	goto APHB_error
                	end
    		-- check that transtype isn't 'D'for a paidheader
    		if @transtype = 'D'
    		begin
    		select @errortext = isnull(@errorstart, '') + ' - A paid transaction cannot be deleted.!' --#23061
                	goto APHB_error
                	end
    		end
    
    	-- validate Lines
        exec @rcode = bspAPLBVal @co, @mth, @batchid, @seq, @transtype, @aptrans, @vendorgroup, @vendor,
    		@sortname, @oldvendorgroup, @oldvendor, @oldsortname, @apref, @oldapref, @description, @olddescription,
            @invdate, @oldinvdate, @errmsg output
        if @rcode <> 0  goto bspexit
    
        goto APHB_loop
    
    APHB_error:	-- record error in bHQBE and skip to next batch seq
		SELECT @errortext=@errortext+' '+ @APHBUIMsg
    	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    	if @rcode <> 0 goto bspexit
    	goto APHB_loop
    
    APHB_end:   -- finished with APHB entries
    	close bcAPHB
        deallocate bcAPHB
        select @opencursorAPHB = 0
    
      	-- make sure debits and credits balance
        select @glco = GLCo
        from bAPGL
        where APCo = @co and Mth = @mth and BatchId = @batchid
        group by GLCo
        having isnull(sum(TotalCost),0) <> 0
        if @@rowcount <> 0
    	BEGIN
            select @errortext =  'AP GL Company ' + isnull(convert(varchar(3), @glco), '') + ' entries do not balance!' --#23061
            SELECT @errortext=@errortext+' '+ @APHBUIMsg
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
            if @rcode <> 0 goto bspexit
            end

		-- make sure PO GL debits and credits balance - #140906
		SELECT @glco = GLCo
		FROM dbo.bPORG 
		WHERE POCo = @co AND Mth = @mth AND BatchId = @batchid
		GROUP BY GLCo
		HAVING ISNULL(SUM(TotalCost),0) <> 0
		IF @@rowcount <> 0
		BEGIN
			SELECT @errortext =  'PO GL Company ' + convert(varchar(3), @glco) + ' entries do not balance!'
			SELECT @errortext=@errortext+' '+ @APHBUIMsg
			EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			IF @rcode <> 0 GOTO bspexit
		END
    
    Update_status:
    	/* check HQ Batch Errors and update HQ Batch Control status */
        select @status = 3	/* valid - ok to post */
        if exists(select top 1 1 from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
        select @status = 2	/* validation errors */
    
        update bHQBC
        set Status = @status
        where Co = @co and Mth = @mth and BatchId = @batchid
    	if @@rowcount <> 1
            begin
      		select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
      		goto bspexit
      		end
    
    bspexit:
        if @opencursorAPHB = 1
      		begin
      		close bcAPHB
      		deallocate bcAPHB
      		end
    
        return @rcode
GO

--sp_recompile [bspAPHBVal]
--go

GRANT EXEC ON [bspAPHBVal] TO PUBLIC
go
