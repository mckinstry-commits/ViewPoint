SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPPBVal]
/****************************************************************************************
* CREATED BY: kb 09/18/97
* MODIFIED By : GG 04/30/99
*               JRE 06/09/99 - took out discount amount check between batch and APTD
*               GG 09/07/99 - added validation to compare bAPTB and bAPDB amounts
*				kb 10/17/99 - only check for CMRef uniqueness if PayMethod is not 'E'
*               EN 01/22/00 - expand dimension of @name & @phname to varchar(60) and include AddnlInfo in validation
*               kb 01/23/00 - added a check to make sure the cmrefseq field is not null when
*							  the paymethod = 'C'
*               GG 01/31/00 - changed GL distribution to update Cash account in CM GL Co# and make necessary
*                             interco journal entries.
*               GH 06/07/00 - changed Payment Journal error message
*			  	MV 10/09/02 - 18878 quoted identifier cleanup
*				MV 12/30/03 - #23266 - val EFTs in bCMDT if @cminterfacelvl = 1
*				MV 02/18/04 - #18769 - PayCategory / 23061 isnull wrap
*				MV 05/28/04 - #24708 - Pay Type validation when using Pay Category
*				GG 07/25/07 - #120561 - corrected bHQCC refresh
*				MV 03/13/08 - #127347 - International addresses - validate state/country
*               MV 07/03/08 - #128288 - GST Tax Expense GL Distributions
*				MV 09/02/09 - #130949 - Include 'I' - Import, in valid Check types
*				MV 01/29/10 - #136500 - Rename APTD.TaxAmount 'GSTtaxAmt'
*				MV 03/08/10 - #136500 - handle CA holdback GST expensing & payables
*				MV 10/25/11 - TK-09243 - return @crdRetgPSTGLAcct from bspHQTaxRateGetAll
*				MV 11/01/11	- TK-09243 - debit crdRetgPSTGLAcct
*				MV 11/10/11 - TK-09243 - corrected void to backout GST and PST
*				MV 11/15/11 - TK-09243 - Update JC Expense with diff between old PST and PST / corrected Retg Payables.
*				MV 11/16/11 - TK-09243 - Retg Payables when not expensing(taxbasis is not net of retention)	
*				KK 04/19/12 - B-08111  - Modified to include PayMethod "S" as per the Credit Service enhancement
*				MV 05/07/12 - TK-14680 - GL distributions don't balance when voiding Retg with GST.
*				KK 07/20/12 - D-05540  - Wrapped occurances of @tdPSTtaxamt,@tdGSTtaxamt old and new with ISNULL
*				MV 09/19/12 - D-05943/TK-17986 - Update bAPPG amount for intercompany AP GL with full amount (amt + GST/PST)
*										
* USAGE:
*	Validates an AP Payment Batch - must be called prior to posting the batch.
*
*	After initial Batch and AP checks, bHQBC Status set to 1 (validation in progress)
*	bHQBE (Batch Errors), bAPPG(GL Payment Dist), bCMDT(CM Detail)
*
* Inputs:
*  @co         AP Company
*  @mth        Batch Month - month paid
*  @batchid    Batch ID
*
* Output:
*  @errmsg     error message
*
* Return
*  @rcode      0 = success, 1 = failure
****************************************************************************************/
(@co bCompany, 
 @mth bMonth, 
 @batchid bBatchID, 
 @errmsg varchar(255) output)
    
AS
SET NOCOUNT ON
    
DECLARE @rcode int,					@status tinyint,				@apglco bCompany, 
		@payjrnl bJrnl,				@APCOdisctakenglacct bGLAcct,   @openPayHeader tinyint, 
		@seq int,					@cmco bCompany,					@cmacct bCMAcct, 
		@paymethod char(1),			@cmref bCMRef,					@cmrefseq tinyint, 
		@eftseq smallint,			@chktype char(1),				@vendorgroup bGroup, 
		@vendor bVendor,			@name varchar(60),				@addnlinfo varchar(60), 
		@address varchar(60),		@city varchar(30),				@state varchar(4), 
		@zip bZip,					@paiddate bDate,				@amount bDollar, 
		@voidyn bYN,				@overflowyn bYN,				@errorstart varchar(20), 
		@cmglco bCompany,			@errortext varchar(255),		@cmglacct bGLAcct, 
		@cashaccrual char(1),		@cmmth bMonth,					@stmtdate bDate, 
		@sourceco bCompany,			@source bSource,				@cmamount bDollar, 
		@cmvoid bYN,				@phvendor bVendor,				@phname varchar(60), 
		@phaddinfo varchar(60),		@phaddress varchar(60),			@phmth bMonth,			
		@phamount bDollar,			@phvoid bYN, 					@openTrans tinyint,		
		@expmth bMonth,				@aptrans bTrans,				@thvendor bVendor,		
		@openDetail tinyint,		@apline smallint, 
		@apseq tinyint,				@paytype tinyint,				@disctaken bDollar,
		@tdpaytype tinyint,			@tdamount bDollar,				@tddisc bDollar, 
		@tdstatus tinyint,			@glacct bGLAcct,				@lastdiscglacct bGLAcct,
		@glamt bDollar, 			@gldisc bDollar,				@postedglco bCompany, 
		@postedglacct bGLAcct, 		@glaccashaccrual char(1),		@offsetglacct bGLAcct, 
		@netamtopt bYN,				@cmpayee varchar(20),			@tbnet bDollar, 
		@dbnet bDollar,				@paycategory int,				@cminterfacelvl char(1), 
		@intercoapglacct bGLAcct,	@intercoarglacct bGLAcct,		@glco bCompany, 
		@disctakenglacct bGLAcct,	@APPCdisctakenglacct bGLAcct,	@country char(2),
		@tdGSTtaxamt bDollar,		@tdExpensingGstYN bYN,			@tdOldGSTtaxamt bDollar,
		@crdRetgGSTGLAcct bGLAcct,	@cmglamt bDollar,				@crdRetgPSTGLAcct bGLAcct, 
		@tdPSTtaxamt bDollar,		@tdOldPSTtaxamt bDollar,		@ExpenseGLAcct bGLAcct, 
		@PSTTaxDiff bDollar,		@GSTTaxDiff bDollar,			@APCreditServiceCMAcct bCMAcct
		
    -- GST declares
DECLARE @dbtGLAcct bGLAcct, 
		@dbtRetgGLAcct bGLAcct, 
		@taxgroup bGroup, 
		@taxcode bTaxCode
    
SELECT @rcode = 0
    
    --  validate HQ Batch
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'AP Payment', 'APPB', @errmsg output, @status output
    if @rcode <> 0 goto bspexit
    if @status < 0 or @status > 3
        begin
        select @errmsg = 'Invalid Batch status!', @rcode = 1
        goto bspexit
        end
    
    -- set HQ Batch status to 1 (validation in progress)
    update bHQBC
    set Status = 1
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
        begin
        select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
        goto bspexit
        end
    
    -- clear HQ Batch Errors
    delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
    
    -- clear Payment GL Distributions
    delete bAPPG where APCo = @co and Mth = @mth and BatchId = @batchid
    
    -- get info from AP Company
	SELECT @apglco = GLCo, 
		   @payjrnl = PayJrnl, 
		   @APCOdisctakenglacct = DiscTakenGLAcct, 
		   @netamtopt = NetAmtOpt,
		   @cminterfacelvl = CMInterfaceLvl,
		   @APCreditServiceCMAcct = CSCMAcct -- B-08111 Used for CM Account validation
    FROM bAPCO WHERE APCo = @co
    
    if @@rowcount = 0
        begin
        select @errortext = 'Invalid AP Co# associated with this Batch!'
        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        goto bspexit
        end
    -- validate for open month in AP GL Co#
    exec @rcode = bspHQBatchMonthVal @apglco, @mth, 'AP', @errmsg output
    if @rcode <> 0
        begin
       	select @errortext = isnull(@errmsg,'')
        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        goto bspexit
        end
    
    -- validate Payment Journal in AP GL Co#
    if not exists(select * from bGLJR where GLCo = @apglco and Jrnl = @payjrnl)
        begin
        select @errortext = isnull(@errorstart,'') + ' - Payment Journal:' + isnull(@payjrnl,'')
    		 + ',assigned in AP Company is not setup in GL Co# '
    		 + isnull(convert(varchar(4),@apglco),'')
        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        end

	-- validate State/Country 
	if @state is not null 
	begin
		exec @rcode = vspHQCountryStateVal @co,@country,@state, @errmsg output
		 if @rcode <> 0
			begin
       		select @errortext = isnull(@errmsg,'')
			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			goto bspexit
			end
	end

	 -- Clear HQ Close Control, will be reloaded during validation
    delete bHQCC
	where Co = @co and Mth = @mth and BatchId = @batchid and GLCo <> @apglco -- leave entry for AP GL Co#

    -- create a cursor to process all entries in the AP Payment Batch
    declare bcPayHeader cursor for
    select BatchSeq, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, ChkType,
     	VendorGroup, Vendor, Name, AddnlInfo, Address, City, State, Zip, PaidDate, Amount, VoidYN, Overflow,Country
    from bAPPB
    where Co = @co and Mth = @mth and BatchId = @batchid
    
    open bcPayHeader
    select @openPayHeader = 1
    
    PayHeader_loop:  -- loop through all Payment Batch Headers
        fetch next from bcPayHeader into @seq, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq, @chktype,
            @vendorgroup, @vendor, @name, @addnlinfo, @address, @city, @state, @zip, @paiddate, @amount, @voidyn,
			@overflowyn,@country
    
        if @@fetch_status <> 0 goto PayHeader_end
    
     	select @errorstart = 'Seq#' + isnull(convert(varchar(6),@seq),'')
    
        select @cmglco = GLCo
        from bCMCO where CMCo = @cmco
        if @@rowcount = 0
     		begin
     		select @errortext = isnull(@errorstart,'') + ' - Invalid CM Company!'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
            if @rcode <> 0 goto bspexit
            goto PayHeader_loop
     		end
    
        select @cmglacct = GLAcct
        from bCMAC
        where CMCo = @cmco and CMAcct = @cmacct
     	if @@rowcount = 0
     		begin
     		select @errortext = isnull(@errorstart,'') + ' - Invalid CM Account!'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
            goto PayHeader_loop
     		end
    
        -- if you want Cash posted in the AP GL Company activate the following line, if you want Cash
        -- posted in the CM GL Co# with intercompany journal entries created as needed, leave the
        -- following line commented out. GG 01/31/00
        --select @cmglco = @apglco
    
        -- if CM GL Co# <> AP GL Co# get intercompany accounts
        if @cmglco <> @apglco
            begin
            select @intercoarglacct = ARGLAcct, @intercoapglacct = APGLAcct
            from bGLIA
       		where ARGLCo = @cmglco and APGLCo = @apglco
       	    if @@rowcount = 0
       		    begin
       		    select @errortext = isnull(@errorstart,'') + ' - Intercompany Accounts not setup in GL. From:' +
       			       isnull(convert(varchar(3),@cmglco),'') + ' To: ' + isnull(convert(varchar(3),@apglco),'')
       		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		    if @rcode <> 0 goto bspexit
                goto PayHeader_loop
                end
       	    -- validate intercompany GL Accounts
          	exec @rcode = bspGLACfPostable @cmglco, @intercoarglacct, 'R', @errmsg output
           	if @rcode <> 0
                begin
       	        select @errortext = isnull(@errorstart,'') 
    				+ '- Intercompany AR Account:' 
    				+ isnull(@intercoarglacct,'') + ':  ' + isnull(@errmsg,'')
                exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		    if @rcode <> 0 goto bspexit
                goto PayHeader_loop
       	  	    end
       	    exec @rcode = bspGLACfPostable @apglco, @intercoapglacct, 'P', @errmsg output
           	if @rcode <> 0
        		begin
       		    select @errortext = isnull(@errorstart,'') 
    				+ '- Intercompany AP Account:'
    				+ isnull(@intercoapglacct,'') + ':  ' + isnull(@errmsg,'')
       		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		    if @rcode <> 0 goto bspexit
                goto PayHeader_loop
       	  	    end
            -- validate for open month in CM GL Co#
            exec @rcode = bspHQBatchMonthVal @cmglco, @mth, 'AP', @errmsg output
            if @rcode <> 0
                begin
       	        select @errortext = isnull(@errorstart,'') + ' - ' + isnull(@errmsg,'')
        	    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		    if @rcode <> 0 goto bspexit
                goto PayHeader_loop
                end
            -- validate Payment Journal in CM GL Co#
            if not exists(select * from bGLJR where GLCo = @cmglco and Jrnl = @payjrnl)
                begin
                select @errortext = isnull(@errorstart,'') 
    				+ ' - Payment Journal not setup in GL Co# ' +isnull(convert(varchar(4),@cmglco),'')
                exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		    if @rcode <> 0 goto bspexit
                goto PayHeader_loop
     		    end

			-- add HQ Close Control entry for CM GL Co#
			if not exists(select * from bHQCC (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @cmglco)
				begin
				insert bHQCC(Co, Mth, BatchId, GLCo)
				values (@co, @mth, @batchid, @cmglco)
				end
			end
    

        if @paiddate is null and @voidyn = 'N'
            begin
            select @errortext = isnull(@errorstart,'') + ' - Paid Date cannot be null!'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
            if @rcode <> 0 goto bspexit
            goto PayHeader_loop
     		end
    
        -- validate Vendor
        if not exists(select * from bAPVM where VendorGroup = @vendorgroup and Vendor = @vendor)
            begin
     		select @errortext = isnull(@errorstart,'') + ' - Invalid Vendor!'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
            goto PayHeader_loop
     		end
     		
		-- validate Pay Method
		IF @paymethod NOT IN ('C','E','S') -- B-08111: Added PayMethod credit service 'S'
		BEGIN
			SELECT @errortext = ISNULL(@errorstart,'') + ' - Payment method must be Check, EFT or Credit Service!'
			EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
			IF @rcode <> 0 GOTO bspexit
			GOTO PayHeader_loop
		END
		
		-- validate CM Account
		IF @paymethod = 'S' --Pay Method is Credit Service
		BEGIN
			--CMAcct on the tran does not match APCO CSCMAcct
			IF ISNULL(@APCreditServiceCMAcct,'') <> @cmacct 
			BEGIN
				SELECT @errortext = ISNULL(@errorstart,'') + ' - Credit Service CM Acct must match the Credit Service CM Acct in AP Company '
				GOTO PayHeader_loop
			END
		END
		ELSE --Pay Method is Check or EFT	
		BEGIN
			--Transaction has a CSCMAcct and should not
			IF @APCreditServiceCMAcct = @cmacct 
			BEGIN
				SELECT @errortext = ISNULL(@errorstart,'') + ' - Credit Service CM Acct can only be used with credit service transactions '
				GOTO PayHeader_loop
			END	
		END

		-- validate CMRef
        if @cmref is null
            begin
            select @errortext = isnull(@errorstart,'') + ' - CM Reference has not been assigned!'
            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
            goto PayHeader_loop
     		end
    
        if @paymethod = 'C'
            begin
            if @chktype not in ('C','M','P','I')
                begin
                select @errortext = isnull(@errorstart,'') + ' - Invalid check type!'
                exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		    if @rcode <> 0 goto bspexit
                goto PayHeader_loop
     		    end
            if @cmrefseq is null
                begin
                select @errortext = isnull(@errorstart,'') + ' - CM Reference Sequence must not be null when the paymethod is ''C''.'
                exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto PayHeader_loop
                end
            if @overflowyn = 'Y'
     			begin
     			select @errortext = isnull(@errorstart,'') + ' - Overflow must be printed first!'
     			exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto PayHeader_loop
     		    end
            -- validate in CM Detail
            select @cmmth = Mth, @stmtdate = StmtDate, @sourceco = SourceCo, @source = Source,
                    @cmamount = Amount, @cmpayee = Payee, @cmvoid = Void
                    from bCMDT
                    where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref
                    and CMRefSeq = @cmrefseq and CMTransType = 1
                if @@rowcount <> 0
                    begin
                    if @voidyn = 'N'
                        begin
                        select @errortext = isnull(@errorstart,'') + ' - Check and Seq# already exists in Cash Management.'
                        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	      	        if @rcode <> 0 goto bspexit
                        goto PayHeader_loop
     		            end
                    if @voidyn = 'Y' and @cminterfacelvl = 1
                        begin
                        if @cmvoid = 'Y'
                            begin
                            select @errortext = isnull(@errorstart,'') + ' - Already voided in Cash Management.'
                            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
         		            if @rcode <> 0 goto bspexit
                            goto PayHeader_loop
     		                end
                       if @stmtdate is not null
                           begin
                           select @errortext = isnull(@errorstart,'') + ' - Cannot void, check already cleared in Cash Management.'
                           exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     	                   if @rcode <> 0 goto bspexit
                           goto PayHeader_loop
     	                  end
                      if @cmmth <> @mth or @sourceco <> @co or @source <> 'AP Payment' or @cmamount <> -(@amount)
                        or @cmpayee <> convert(varchar(20),@vendor)
                            begin
                            select @errortext = isnull(@errorstart,'') + ' - Cannot void, Paid Mth, Source, Check Amount, and/or Vendor'
                            + ' does not match existing information in Cash Management.'
                            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
         		            if @rcode <> 0 goto bspexit
                            goto PayHeader_loop
     		                 end
                      end
    
                 end
            -- validate in AP Payment History
            select @phvendor = Vendor, @phname = Name, @phaddinfo = AddnlInfo, @phaddress = Address, @phmth = PaidMth,
                @phamount = Amount, @phvoid = VoidYN
            from bAPPH
            where CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C' and CMRef = @cmref and CMRefSeq = @cmrefseq
            if @@rowcount <> 0
                begin
                if @voidyn = 'N'
                    begin
                    select @errortext = isnull(@errorstart,'') + ' - Check and Seq# already exists in AP Payment History.'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		        if @rcode <> 0 goto bspexit
                    goto PayHeader_loop
     		        end
                if @voidyn = 'Y'
                  begin
                    if @phvoid = 'Y'
                        begin
    
                        select @errortext = isnull(@errorstart,'') + ' - Already voided in AP Payment History.'
                        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		            if @rcode <> 0 goto bspexit
                        goto PayHeader_loop
     		            end
                    if @phvendor <> @vendor or @phname <> @name or @phaddinfo <> @addnlinfo
                        or @phaddress <> @address or @phmth <> @mth
                        or @phamount <> @amount
                        begin
                        select @errortext = isnull(@errorstart,'') + ' - Cannot void, Vendor, Name, Additional Info, Address, Paid Mth, and/or Amount'
                            + ' does not match existing information in AP Payment History.'
                        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		            if @rcode <> 0 goto bspexit
                        goto PayHeader_loop
     		            end
                    end
                end
            end
    
        if @paymethod = 'E'
            begin
            if @eftseq is null
                begin
                select @errortext = isnull(@errorstart,'') + ' - EFT Sequence has not been assigned!'
                exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		    if @rcode <> 0 goto bspexit
                goto PayHeader_loop
     		    end
            -- validate in CM Detail
            select @cmmth = Mth, @stmtdate = StmtDate, @sourceco = SourceCo, @source = Source
            from bCMDT
            where CMCo = @cmco and CMAcct = @cmacct and CMRef = @cmref
                and CMRefSeq = 0 and CMTransType = 4        -- all EFTs use CM Reference Seq 0 in bCMDT
            if @@rowcount <> 0
                begin
                if @stmtdate is not null
                    begin
                    select @errortext = isnull(@errorstart,'') + ' - Already cleared in Cash Management.'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		        if @rcode <> 0 goto bspexit
                    goto PayHeader_loop
     		        end
                if @cmmth <> @mth or @sourceco <> @co or @source <> 'AP Payment'
                    begin
                    select @errortext = isnull(@errorstart,'') + ' - Paid Month or Source does not match existing'
                        + ' information in Cash Management.'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		        if @rcode <> 0 goto bspexit
                    goto PayHeader_loop
     		        end
                end
            else
                begin
                if @voidyn = 'Y' and @cminterfacelvl = 1	--#23266
                    begin
                    select @errortext = isnull(@errorstart,'') + ' - Cannot void, CM Reference does not'
                        + ' exist in Cash Management.'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		        if @rcode <> 0 goto bspexit
    
                    goto PayHeader_loop
     		        end
                end
            -- validate in AP Payment History
            select @phvendor = Vendor, @phname = Name, @phaddinfo = AddnlInfo, @phaddress = Address, @phmth = PaidMth,
                @phamount = Amount, @phvoid = VoidYN
    
            from bAPPH
            where CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'E' and CMRef = @cmref and EFTSeq = @eftseq
            if @@rowcount <> 0
                begin
          		if @voidyn = 'N'
                    begin
                    select @errortext = isnull(@errorstart,'') + ' - CM Reference and EFT Seq# already exists in AP Payment History.'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		        if @rcode <> 0 goto bspexit
                    goto PayHeader_loop
     		        end
                if @voidyn = 'Y'
                    begin
                    if @phvendor <> @vendor or @phname <> @name or @phaddinfo <> @addnlinfo or @phaddress <> @address or @phmth <> @mth
   
                        or @phamount <> @amount
                        begin
    
                        select @errortext = isnull(@errorstart,'') + ' - Cannot void, Vendor, Name, Additional Info, Address, Paid Mth, and/or Amount'
                            + ' does not match existing information in AP Payment History.'
                        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		            if @rcode <> 0 goto bspexit
                        goto PayHeader_loop
     		            end
                    end
                end
            else
                begin
                if @voidyn = 'Y'
                    begin
                    select @errortext = isnull(@errorstart,'') + ' - Cannot void, CM Reference and EFT Seq# does not'
                        + ' exist in AP Payment History.'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		        if @rcode <> 0 goto bspexit
                    goto PayHeader_loop
     		        end
                end
            end

		IF @paymethod = 'S'
		BEGIN
			-- validate in CM Detail
			SELECT @cmmth = Mth, 
				   @stmtdate = StmtDate, 
				   @sourceco = SourceCo, 
				   @source = Source
			FROM  bCMDT
			WHERE CMCo = @cmco 
				  AND CMAcct = @cmacct 
				  AND CMRef = @cmref
				  AND CMRefSeq = 0 
				  AND CMTransType = 4
			IF @@ROWCOUNT <> 0
			BEGIN
				IF @stmtdate IS NOT NULL
				BEGIN
					SELECT @errortext = ISNULL(@errorstart,'') + ' - Already cleared in Cash Management.'
					EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
					IF @rcode <> 0 GOTO bspexit
					GOTO PayHeader_loop
				END
				IF @cmmth <> @mth OR @sourceco <> @co OR @source <> 'AP Payment'
				BEGIN
					SELECT @errortext = ISNULL(@errorstart,'') 
							+ ' - Paid Month OR Source does not match existing information in Cash Management.'
					EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
					IF @rcode <> 0 GOTO bspexit
					GOTO PayHeader_loop
				END
			END
			ELSE
			BEGIN
				IF @voidyn = 'Y' AND @cminterfacelvl = 1
				BEGIN
					SELECT @errortext = ISNULL(@errorstart,'') 
							+ ' - Cannot void, CM Reference does not exist in Cash Management.'
					EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
					IF @rcode <> 0 GOTO bspexit
					GOTO PayHeader_loop
				END
			END
			-- validate in AP Payment History
			SELECT @phvendor = Vendor, 
				   @phname = Name, 
				   @phaddinfo = AddnlInfo,
				   @phaddress = Address, 
				   @phmth = PaidMth,
				   @phamount = Amount, 
				   @phvoid = VoidYN
			FROM  bAPPH
			WHERE CMCo = @cmco 
				  AND CMAcct = @cmacct 
				  AND PayMethod = 'S' 
				  AND CMRef = @cmref 
			IF @@ROWCOUNT <> 0
			BEGIN
				IF @voidyn = 'N'
				BEGIN
					SELECT @errortext = ISNULL(@errorstart,'') 
							+ ' - CM Reference already exists in AP Payment History.'
					EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
					IF @rcode <> 0 GOTO bspexit
					GOTO PayHeader_loop
				END
				IF @voidyn = 'Y'
				BEGIN
					IF @phvendor <> @vendor 
						OR @phname <> @name 
						OR @phaddinfo <> @addnlinfo 
						OR @phaddress <> @address 
						OR @phmth <> @mth
						OR @phamount <> @amount
					BEGIN
						SELECT @errortext = ISNULL(@errorstart,'')
								+ ' - Cannot void, Vendor, Name, Address, Paid Mth, and/or Amount'
								+ ' does not match existing information in AP Payment History.'
						EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
						IF @rcode <> 0 GOTO bspexit
						GOTO PayHeader_loop
					END
				END
			END
			ELSE
			BEGIN
				IF @voidyn = 'Y'
				BEGIN
					SELECT @errortext = ISNULL(@errorstart,'') 
							+ ' - Cannot void, CM Reference does not exist in AP Payment History.'
					EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg OUTPUT
					IF @rcode <> 0 GOTO bspexit
					GOTO PayHeader_loop
				END
			END
		END
		
        -- validate for uniqueness within Payment Batches, this is only in the case of Check or Credit Service
     	if exists(select * from bAPPB where Co = @co and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
    	    and PayMethod <>'E'
                and CMRef = @cmref and CMRefSeq = @cmrefseq
                and (Mth <> @mth or BatchId <> @batchid or BatchSeq <> @seq))
            begin
     		select @errortext = isnull(@errorstart,'') + ' - CM Reference and Seq# is not unique to this Payment Batch!'
     		exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		if @rcode <> 0 goto bspexit
            goto PayHeader_loop
     		end
    
        -- create a cursor to process all Payment Transactions
        declare bcTrans cursor for
        select ExpMth, APTrans, convert(numeric(12,2),(Gross - Retainage - PrevPaid - PrevDisc - Balance - DiscTaken))
        from bAPTB
        where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    
        open bcTrans
        select @openTrans = 1
    
        Trans_loop: -- loop through all Transaction for this Payment Header
            fetch next from bcTrans into @expmth, @aptrans, @tbnet
            if @@fetch_status <> 0 goto Trans_end
    
    		-- validate Transaction
     	    select @thvendor = Vendor
            from bAPTH
            where APCo = @co and Mth = @expmth and APTrans = @aptrans
            if @@rowcount = 0
                begin
     		    select @errortext = isnull(@errorstart,'') + ' - Invalid AP Transaction!'
     		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
                if @rcode <> 0 goto bspexit
                goto Trans_loop
         		end
            if @thvendor <> @vendor
     		    begin
     		    select @errortext = isnull(@errorstart,'') + ' - Payment Vendor does not match AP Transaction Header!'
     		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		    if @rcode <> 0 goto bspexit
                goto Trans_loop
     		    end
    
            -- check consistency of amounts between bAPTB and bAPDB
            select @dbnet = isnull(sum(Amount - DiscTaken),0)
            from bAPDB
            where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                and ExpMth = @expmth and APTrans = @aptrans
            if @tbnet <> @dbnet
                begin
                select @errortext = isnull(@errorstart,'') + ' - Payment Transaction totals do not match batch detail amounts!'
     		    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     		    if @rcode <> 0 goto bspexit
                goto Trans_loop
     		    end
    
            -- use a cursor to process Payment Detail for a Transaction
     		declare bcDetail cursor for
            select APLine, APSeq, PayType, Amount, DiscTaken, PayCategory
     		from bAPDB
            where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                and ExpMth = @expmth and APTrans = @aptrans
     		--order by PayType
    
      	  	open bcDetail
      	    select @openDetail = 1
    
            Detail_loop:    -- process a Payment Detail entry
                fetch next from bcDetail into @apline, @apseq, @paytype, @amount, @disctaken, @paycategory
    
     		    if @@fetch_status <> 0 goto Detail_end
    
                -- validate AP Trans Detail
     		    select @tdpaytype = PayType, 
     				   @tdamount = Amount, 
     				   @tddisc = DiscTaken, 
     				   @tdstatus = Status, 
     				   @tdGSTtaxamt = GSTtaxAmt,
					   @tdOldGSTtaxamt = OldGSTtaxAmt,
					   @tdExpensingGstYN = ExpenseGST,
					   @tdPSTtaxamt = PSTtaxAmt,
					   @tdOldPSTtaxamt = OldPSTtaxAmt 
                from bAPTD
                where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline and APSeq = @apseq
                if @@rowcount = 0
                    begin
     			    select @errortext = isnull(@errorstart,'') + ' - Invalid AP Transaction Detail Sequence!'
     			    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			    if @rcode <> 0 goto bspexit
                    goto Detail_loop
     			    end
     			    
     			-- get tax/gl information from bAPTL
                    SELECT @taxgroup = TaxGroup, @taxcode=TaxCode, @ExpenseGLAcct = GLAcct
                    FROM dbo.bAPTL with (nolock) 
                    WHERE APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline
                    -- get GST/PST GLAcct information
                    exec @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, null, null, null,
		                null,null,null,null,@dbtGLAcct output,@dbtRetgGLAcct output,null, null,
		                @crdRetgGSTGLAcct output, @crdRetgPSTGLAcct output
		                
                if @voidyn = 'N' and @tdstatus <> 1   -- hardcoded 'open' status
                    begin
                    select @errortext = isnull(@errorstart,'') + ' - Invalid Status. Transaction Detail must be ''open''!'
                exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			    if @rcode <> 0 goto bspexit
                    goto Detail_loop
     			    end
                if @voidyn = 'Y' and @tdstatus <> 3   -- hardcoded 'paid' status
                    begin
                    select @errortext = isnull(@errorstart,'') + ' - Invalid Status. Transaction Detail must be ''paid''!'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			    if @rcode <> 0 goto bspexit
                    goto Detail_loop
     			    end
                if @tdpaytype <> @paytype or @tdamount <> @amount /* or @tddisc <> @disctaken */
                    begin
                    select @errortext = isnull(@errorstart,'') + ' - Transaction Detail information does not match!'
                    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			    if @rcode <> 0 goto bspexit
                    goto Detail_loop
     			    end
    
                -- validate Pay Type and GL Payables Account
    			select @glacct = GLAcct
    	            from bAPPT where APCo=@co and PayType = @paytype
    	 		if @@rowcount = 0
                    begin
     			    select @errortext = isnull(@errorstart,'') + ' - Invalid Payable Type!'
     			    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			    if @rcode <> 0 goto bspexit
                    goto Detail_loop
                    end
    			--validate pay category
    			if @paycategory is not null
    				begin	
    				select top 1 1 from bAPPC where APCo=@co and PayCategory=@paycategory
    				if @@rowcount = 0
    					begin
    				 	select @errortext = isnull(@errorstart,'') + ' - Invalid Pay Category!'
    	 			    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    	 			    if @rcode <> 0 goto bspexit
    	                goto Detail_loop
    		            end
    				else
    					--validate paytype is in pay category
    					begin
    					exec @rcode = bspAPPayTypeValForPayCategory @co, @paycategory, @paytype, null,@errmsg output 
    					if @rcode <> 0
    						begin
    					 	select @errortext = isnull(@errorstart,'') + ' - Invalid PayType for PayCategory: '
    							+ isnull(convert(varchar(10),@paycategory),'')
    		 			    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    		 			    if @rcode <> 0 goto bspexit
    		                goto Detail_loop
    			            end
    					end
    				end
    			
                -- validate in AP GL Co#
     	        exec @rcode = bspGLACfPostable @apglco, @glacct, 'P', @errmsg output
                if @rcode <> 0
                    begin
     			    select @errortext = isnull(@errorstart,'') + isnull(@errmsg,'')
      			    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			    if @rcode <> 0 goto bspexit
                    goto Detail_loop
     			    end
    
     		    if @disctaken <> 0
     			    begin
     			    if @paycategory is null	-- using APCO glacct
    					begin
    	 				if @APCOdisctakenglacct is null
    	 				   begin
    	 				   select @errortext = isnull(@errorstart,'') + ' - Discount Taken GL Account not setup in AP Company!'
    	 				   exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    	 				   if @rcode <> 0 goto bspexit
    	                   goto Detail_loop
    	 				   end
    					else
    						select @disctakenglacct = @APCOdisctakenglacct
    					end
    				if @paycategory is not null -- using pay category glacct
    					begin
    					select @APPCdisctakenglacct = DiscTakenGLAcct from bAPPC with (nolock)
    						 where APCo=@co and PayCategory=@paycategory
    					if @APPCdisctakenglacct is null
    						begin
    	 				   	select @errortext = isnull(@errorstart,'') + ' - Discount Taken GL Account not setup in Pay Category: '
    							+ isnull(convert(varchar(10),@paycategory),'')
    	 				   	exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
    	 				   	if @rcode <> 0 goto bspexit
    	                   	goto Detail_loop
    	 				   	end
    					else
    						select @disctakenglacct = @APPCdisctakenglacct
    					end
    
                    if @lastdiscglacct is null or @lastdiscglacct <> @disctakenglacct
                        begin
                        -- validate in AP GL Co#
                        exec @rcode = bspGLACfPostable @apglco, @disctakenglacct, 'P', @errmsg output
                        if @rcode <> 0
                            begin
     			            select @errortext = isnull(@errorstart,'') + isnull(@errmsg,'')
      			            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			            if @rcode <> 0 goto bspexit
                            goto Detail_loop
     			            end
                        select @lastdiscglacct = @disctakenglacct
                        end
                    end
    
                -- ADD GL DISTRIBUTIONS
				IF isnull(@tdExpensingGstYN, 'N') = 'N' 
				BEGIN -- Normal GL dist
					-- if this is retainage payables GST/PST taxes are included, so may need to back out any increase in taxes.
					IF (
							@paycategory IS NULL AND @tdpaytype = (	SELECT RetPayType 
																	FROM dbo.bAPCO 
																	WHERE APCo=@co)
						)
						OR 
						(
							@paycategory IS NOT NULL AND @tdpaytype = (	SELECT RetPayType 
																		FROM dbo.bAPPC 
																		WHERE APCo=@co AND PayCategory = @paycategory)
						)
					BEGIN
						-- if there has been a change in PST tax rate when retainage was released calc the diff in tax amt
						-- when releasing holdback 'Apply current tax rate to holdback tax.' was checked, so PST/GST taxes were recalc'd
						IF ISNULL(@tdOldPSTtaxamt,0) <> 0 AND ((ISNULL(@tdOldPSTtaxamt,0) - ISNULL(@tdPSTtaxamt,0))<> 0)
						BEGIN
							SELECT @PSTTaxDiff =  (ISNULL(@tdOldPSTtaxamt,0) - ISNULL(@tdPSTtaxamt,0))
						END 
						-- if there has been a change in GST tax rate when retainagle was released calc the diff in tax amt
						IF ISNULL(@tdOldGSTtaxamt,0) <> 0 AND ((ISNULL(@tdOldGSTtaxamt,0) - ISNULL(@tdGSTtaxamt,0))<>0)
						BEGIN
							SELECT @GSTTaxDiff = (ISNULL(@tdOldGSTtaxamt,0) - ISNULL(@tdGSTtaxamt,0))
						END
						-- back out diff in PST/GST from retainage payables
						SELECT @glamt = @amount + (ISNULL(@PSTTaxDiff,0) + ISNULL(@GSTTaxDiff,0))
						SELECT @gldisc = @disctaken
						SELECT @cmglamt = @amount
					END
					ELSE
					BEGIN
						-- non retainage payables
						SELECT @glamt = @amount
						SELECT @gldisc = @disctaken
						SELECT @cmglamt = @amount
					END
					IF @voidyn = 'Y' SELECT @glamt = -(@glamt), @gldisc = -(@gldisc), @cmglamt = -(@cmglamt)
				END

				IF isnull(@tdExpensingGstYN, 'N') = 'Y' 
				BEGIN /* #136500 - CA/AUS GL dist with holdback/Retention GST/PST expensed when holdback is paid.
						 Holdback PST and/or GST is broken out from Holdback Payable into its own Holdback payable account
						 and credited when the transaction is posted, holdback GST is debited in a contra acct.  
						 When holdback is released and paid (is this process), Holdback GST payable is debited, contra is credited*/
					SELECT @glamt = (@amount - (ISNULL(@tdGSTtaxamt,0) + ISNULL(@tdPSTtaxamt,0)))
					SELECT @gldisc = @disctaken
					SELECT @cmglamt = @amount
						
					IF @voidyn = 'Y'
					BEGIN
						SELECT @glamt = -(@glamt), @gldisc = -(@gldisc), @cmglamt = -(@cmglamt)
					END
				END
                   
                -- Pay Type GL Account - debit if payment, credit if void
                update bAPPG set Amount = Amount + @glamt
                where APCo = @co and Mth = @mth and	BatchId = @batchid and GLCo = @apglco -- post to AP GL Co#
                    and GLAcct = @glacct and BatchSeq = @seq
                if @@rowcount = 0
     			begin
     	            insert bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
                        CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     			    values(@co, @mth, @batchid, @apglco, @glacct, @seq, @cmco, @cmacct, @paymethod,
     				   @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, @glamt, @paiddate)
     			end
    
                -- CM GL Account - credit if payment, debit if void
                update bAPPG set Amount = Amount - (@cmglamt - @gldisc)  --(@glamt - @gldisc)
                where APCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @cmglco   -- post to CM GL Co#
					and GLAcct = @cmglacct and BatchSeq = @seq
                if @@rowcount = 0
                begin
     			    insert bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
     				   CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     			    values(@co, @mth, @batchid, @cmglco, @cmglacct, @seq, @cmco, @cmacct, @paymethod,
     				   @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, -(@cmglamt - @gldisc) /*-(@glamt - @gldisc)*/, @paiddate)
     			end
    
                -- Intercompany GL entries if needed
                if @apglco <> @cmglco
                begin
                    -- Intercompany Receivable in CM GL Co# - debit if payment, credit if void
                    update bAPPG set Amount = Amount +  (@cmglamt - @gldisc) --(@glamt - @gldisc #136500)
                    where APCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @cmglco
                        and GLAcct = @intercoarglacct and BatchSeq = @seq
                    if @@rowcount = 0
                        begin
     			        insert bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
     				       CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     			        values(@co, @mth, @batchid, @cmglco, @intercoarglacct, @seq, @cmco, @cmacct, @paymethod,
     				       @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, (@cmglamt - @gldisc),/*(@glamt - @gldisc),*/ @paiddate)
     			        end
                    -- Intercompany Payable in AP GL Co# - credit if payment, credit if void
                    update bAPPG set Amount = Amount - (@cmglamt - @gldisc) -- (@glamt - @gldisc ) D-05943/TK-17986 
                    where APCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @apglco
                        and GLAcct = @intercoapglacct and BatchSeq = @seq
                    if @@rowcount = 0
                        begin
     			        insert bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
     				       CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     			        values(@co, @mth, @batchid, @apglco, @intercoapglacct, @seq, @cmco, @cmacct, @paymethod,
     				       @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, -(@cmglamt - @gldisc), @paiddate) --D-05943/TK-17986
     			        end
                 end
    
                -- Discount Taken GL Account - credit if payment, debit if void
     		    if @gldisc <> 0
     			    begin
     			    update bAPPG set Amount = Amount - @gldisc
                    where APCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @apglco   -- post to AP GL Co#
                        and GLAcct = @disctakenglacct and BatchSeq = @seq
     			    if @@rowcount = 0
     				   begin
     				   insert bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
     					  CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     				   values(@co, @mth, @batchid, @apglco, @disctakenglacct, @seq, @cmco, @cmacct, @paymethod,
     					  @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, -(@gldisc), @paiddate)
     				   end
     			    end

                -- GST Tax GL Account - move Retg GST Expense to GST Expense (ITC)
                -- if retgGST tax amount and paytype is retainage then move retg GST tax amount to GST Exp
                if (ISNULL(@tdGSTtaxamt,0) <> 0 or ISNULL(@tdPSTtaxamt,0) <> 0) 
					and ((@paycategory is null and @tdpaytype = (select RetPayType from bAPCO with (nolock) where APCo=@co))
						or (@paycategory is not null and @tdpaytype = (select RetPayType from bAPPC with (nolock)
                         where APCo=@co and PayCategory = @paycategory)))
                begin
                    -- If GST and retgGST is Expensed then move retgGST tax amount to GST Expense acct
                    if @dbtGLAcct is not null and @dbtRetgGLAcct is not null
                        begin
                        --validate GST Debit Tax GL Account
				        exec @rcode = bspGLACfPostable @apglco, @dbtGLAcct, null, @errmsg output
                            if @rcode <> 0
		    		        begin
     			            select @errortext = ISNULL(@errorstart,'') + ISNULL(@errmsg,'')
      			            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			            if @rcode <> 0 goto bspexit
                            goto Detail_loop
     			            end
					     exec @rcode = bspGLACfPostable @apglco, @dbtRetgGLAcct, null, @errmsg output
	    			        if @rcode <> 0
       				        begin
     			            select @errortext = ISNULL(@errorstart,'') + ISNULL(@errmsg,'')
      			            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			            if @rcode <> 0 goto bspexit
                            goto Detail_loop
     			            end
						if @crdRetgGSTGLAcct is not null
							begin
							exec @rcode = bspGLACfPostable @apglco, @crdRetgGSTGLAcct, null, @errmsg output
	    			        if @rcode <> 0
       							begin
     							select @errortext = ISNULL(@errorstart,'') + ISNULL(@errmsg,'')
      							exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     							if @rcode <> 0 goto bspexit
								goto Detail_loop
     							end
							end
						if @crdRetgPSTGLAcct is not null
							begin
							exec @rcode = bspGLACfPostable @apglco, @crdRetgPSTGLAcct, null, @errmsg output
	    			        if @rcode <> 0
       							begin
     							select @errortext = ISNULL(@errorstart,'') + ISNULL(@errmsg,'')
      							exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     							if @rcode <> 0 goto bspexit
								goto Detail_loop
     							end
							end

                        -- Retg GST GL Account - debit if payment, credit if void
                            if ISNULL(@voidyn,'N') = 'Y' 
                                select @glamt = case when ISNULL(@tdOldGSTtaxamt,0) = 0 
													 then ISNULL(@tdGSTtaxamt,0) 
													 else ISNULL(@tdOldGSTtaxamt,0) end --#136500
                            else
                                select @glamt = -(case when ISNULL(@tdOldGSTtaxamt,0) = 0 
													   then ISNULL(@tdGSTtaxamt,0) 
													   else ISNULL(@tdOldGSTtaxamt,0) end) --#136500
                            
                            update bAPPG set Amount = Amount + @glamt
                            where APCo = @co and Mth = @mth and	BatchId = @batchid and GLCo = @apglco 
                                and GLAcct = @dbtRetgGLAcct and BatchSeq = @seq
                            if @@rowcount = 0
     			                begin
     	                        insert bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
                                    CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     			                values(@co, @mth, @batchid, @apglco, @dbtRetgGLAcct, @seq, @cmco, @cmacct, @paymethod,
     				               @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, @glamt, @paiddate)
     			                end
     			                
                        -- GST GL Account - credit if payment, debit if void
		                    if isnull(@voidyn,'N') = 'Y' 
                                select @glamt = -(ISNULL(@tdGSTtaxamt,0))
                            else
                                select @glamt = ISNULL(@tdGSTtaxamt,0)
                                
                            update bAPPG set Amount = Amount + @glamt
                            where APCo = @co and Mth = @mth and	BatchId = @batchid and GLCo = @apglco 
                                and GLAcct = @dbtGLAcct and BatchSeq = @seq
                            if @@rowcount = 0
     			                begin
     	                        insert bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
                                    CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     			                values(@co, @mth, @batchid, @apglco, @dbtGLAcct, @seq, @cmco, @cmacct, @paymethod,
     				               @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, @glamt, @paiddate)
     			                end

						-- Holdback GST Payables GL Account - debit if payment, credit if void - #136500
							IF ISNULL(@tdExpensingGstYN, 'N') = 'Y' 
							BEGIN 
								IF @crdRetgGSTGLAcct is not null
								BEGIN
									IF ISNULL(@voidyn,'N') = 'Y' 
										select @glamt = -(case when ISNULL(@tdOldGSTtaxamt,0) = 0 
															   then ISNULL(@tdGSTtaxamt,0) 
															   else ISNULL(@tdOldGSTtaxamt,0) end) 
									ELSE
										select @glamt = case when ISNULL(@tdOldGSTtaxamt,0) = 0 
															 then ISNULL(@tdGSTtaxamt,0)
															 else ISNULL(@tdOldGSTtaxamt,0) end

									UPDATE dbo.bAPPG SET Amount = Amount + @glamt
									WHERE APCo = @co and Mth = @mth and	BatchId = @batchid and GLCo = @apglco -- post to AP GL Co#
										and GLAcct = @crdRetgGSTGLAcct and BatchSeq = @seq
									IF @@rowcount = 0
     								BEGIN
     									INSERT bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
											CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     									VALUES(@co, @mth, @batchid, @apglco, @crdRetgGSTGLAcct, @seq, @cmco, @cmacct, @paymethod,
     									   @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, @glamt, @paiddate)
     								END
     							END
     							
     							-- Debit PST holdback payables GL account.
     							IF @crdRetgPSTGLAcct IS NOT NULL 
     							BEGIN
     								IF ISNULL(@voidyn,'N') = 'Y' 
										SELECT @glamt = -(case when ISNULL(@tdOldPSTtaxamt,0) = 0 
															   then ISNULL(@tdPSTtaxamt,0) 
															   else ISNULL(@tdOldPSTtaxamt,0) end) 
									ELSE
										SELECT @glamt = case when ISNULL(@tdOldPSTtaxamt,0) = 0 
															 then ISNULL(@tdPSTtaxamt,0) 
															 else ISNULL(@tdOldPSTtaxamt,0) end

									UPDATE dbo.bAPPG SET Amount = Amount + @glamt
									WHERE APCo = @co and Mth = @mth and	BatchId = @batchid and GLCo = @apglco -- post to AP GL Co#
										and GLAcct = @crdRetgPSTGLAcct and BatchSeq = @seq
									IF @@ROWCOUNT = 0
     								BEGIN
     									INSERT bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
											CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     									VALUES(@co, @mth, @batchid, @apglco, @crdRetgPSTGLAcct, @seq, @cmco, @cmacct, @paymethod,
     									   @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, @glamt, @paiddate)
     								END
     							END
							END
							-- Post PST holdback tax amount difference to Job expense.
 							IF ISNULL(@tdOldPSTtaxamt,0) <> 0 AND ((ISNULL(@tdOldPSTtaxamt,0) - ISNULL(@tdPSTtaxamt,0))<>0)
 							BEGIN
 								IF ISNULL(@voidyn,'N') = 'Y' 
									SELECT @glamt = -((ISNULL(@tdPSTtaxamt,0) - ISNULL(@tdOldPSTtaxamt,0))) 
								ELSE
									SELECT @glamt = (ISNULL(@tdPSTtaxamt,0) - ISNULL(@tdOldPSTtaxamt,0))

								UPDATE dbo.bAPPG SET Amount = Amount + @glamt
								WHERE APCo = @co and Mth = @mth and	BatchId = @batchid and GLCo = @apglco -- post to AP GL Co#
									and GLAcct = @ExpenseGLAcct and BatchSeq = @seq
								IF @@ROWCOUNT = 0
 								BEGIN
 									INSERT bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
										CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
 									VALUES(@co, @mth, @batchid, @apglco, @ExpenseGLAcct, @seq, @cmco, @cmacct, @paymethod,
 									   @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, @glamt, @paiddate)
 								END
 							END
                    end
				end

                -- Cash Basis fools
                if @cashaccrual = 'C'
                    begin
                    -- get 'posted to' GL Account
                    select @postedglco = GLCo, @postedglacct = GLAcct
                    from bAPTL
                    where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline
                    if @@rowcount = 0
                        begin
                        select @errortext = isnull(@errorstart,'') + ' - Missing AP Transaction Line!'
     				    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
         		        if @rcode <> 0 goto bspexit
                        goto Detail_loop
     				    end
                    -- look for Offset Account (should be 'true' expense account)
                    select @glaccashaccrual = CashAccrual, @offsetglacct = CashOffAcct
                    from bGLAC
                    where GLCo = @postedglco and GLAcct = @postedglacct
                    if @@rowcount = 0
                        begin
                        select @errortext = isnull(@errorstart,'') + ' - Missing GL Account ' + isnull(@postedglacct,'')
     				    exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
         		        if @rcode <> 0 goto bspexit
                        goto Detail_loop
     				    end
                    if @glaccashaccrual = 'C'   -- posted Account is a Cash basis account
                        begin
                        -- validiate Offset GL Account
                        exec @rcode = bspGLACfPostable @postedglco, @offsetglacct, 'N', @errmsg output
                        if @rcode <> 0
                            begin
     			            select @errortext = isnull(@errorstart,'') + isnull(@errmsg,'')
      			            exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
     			            if @rcode <> 0 goto bspexit
                            goto Detail_loop
     			            end
    
                        -- reset amount, check for 'Net to Subledgers' option
                        select @glamt = @amount
                        if @netamtopt = 'Y' select @glamt = @amount - @disctaken
                        if @voidyn = 'Y' select @glamt = -(@glamt)
    
                        -- Offset GL Account - debit if payment, credit if void
                        update bAPPG set Amount = Amount + @glamt
                        where APCo = @co and Mth = @mth and	BatchId = @batchid and GLCo = @postedglco
                            and GLAcct = @offsetglacct and BatchSeq = @seq
                        if @@rowcount = 0
                            begin
     				        insert bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
     					       CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     				        values(@co, @mth, @batchid, @postedglco, @offsetglacct, @seq, @cmco, @cmacct, @paymethod,
     					       @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, @glamt, @paiddate)
     				        end
                        -- 'Posted to' GL Account - credit if payment, debit if void
                        update bAPPG set Amount = Amount - @glamt
                        where APCo = @co and Mth = @mth and	BatchId = @batchid and GLCo = @postedglco
                            and GLAcct = @postedglacct and BatchSeq = @seq
                        if @@rowcount = 0
                            begin
     				        insert bAPPG(APCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, CMCo, CMAcct, PayMethod,
     					       CMRef, CMRefSeq, EFTSeq, VendorGroup, Vendor, Name, Amount, PaidDate)
     				        values(@co, @mth, @batchid, @postedglco, @postedglacct, @seq, @cmco, @cmacct, @paymethod,
     					       @cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @name, -(@glamt), @paiddate)
     				        end
                        end
                    end
    
                goto Detail_loop            -- next Detail entry for this Payment
    
            Detail_end:
                close bcDetail
                deallocate bcDetail
                select @openDetail = 0
                goto Trans_loop         -- next Transaction for this Payment
    
        Trans_end:
            close bcTrans
            deallocate bcTrans
            select @openTrans = 0
            goto PayHeader_loop        -- next Payment Header entry
    
    PayHeader_end:
        close bcPayHeader
        deallocate bcPayHeader
        select @openPayHeader = 0
    
    -- make sure debits and credits balance
    select @glco = GLCo
    from bAPPG
    where APCo = @co and Mth = @mth and BatchId = @batchid
    group by GLCo
    having isnull(sum(Amount),0) <> 0
    if @@rowcount <> 0
        begin
        select @errortext =  'GL Company ' + isnull(convert(varchar(3), @glco),'') + ' entries don''t balance!'
        exec @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
        if @rcode <> 0 goto bspexit
        end
    
    --  check HQ Batch Errors and update HQ Batch Control status
    select @status = 3	/* valid - ok to post */
    if exists(select * from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
     	 select @status = 2	/* validation errors */
    update bHQBC set Status = @status
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount <> 1
    
        begin
     	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
     	goto bspexit
        end
    
    bspexit:
     	if @openDetail = 1
     		begin
      		close bcDetail
     		deallocate bcDetail
     		end
        if @openTrans = 1
            begin
            close bcTrans
            deallocate bcTrans
            end
        if @openPayHeader = 1
            begin
            close bcPayHeader
            deallocate bcPayHeader
            end
    
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPBVal] TO [public]
GO
