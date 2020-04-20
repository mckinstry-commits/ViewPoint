SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspAPPBPost]
/***********************************************************
* CREATED BY: kb 9/19/97
* MODIFIED By : GG 05/24/99
*               GG 10/07/99 Fix for null GL Description Control
*               kb 11/23/99 - Fixed so CM is only updated for voids when the
*                              CMInterfaceLvl is 1 (not when it is 0)
*               kb 11/30/99 - Made further fix so if you didn't have update to CM
*                              flags turned on when you posted the payment but then
*                              you did when you voided it it won't keep you from
*                              posting your void if it can't find a CM transaction to update
*               EN 01/22/00 - expand dimension of @name to varchar(60) and include AddnlInfo in initialization
*               kb 03/08/00 - When reprinting and marking old check as void in CM it was
*							   writing out the CMDT void record with the VoidYN flag as 'N' should by 'Y' issue #6571
*               GG 11/27/00 - changed datatype from bAPRef to bAPReference
*               MV 05/30/00 - #12769 added BatchUserMemoUpdate for user memos on posting forms
*               kb 07/25/01 - #13736
*             danf 10/23/01 - Added box 14-18 for 1099
*               kb 02/08/02 - #16089
*			    GG 03/19/02 - #16702 - UserMemo update fix, cleanup
*              CMW 04/04/02 - added HQBC update for interface flags (issue # 16692)
*				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*             DANF 10/04/04 - #18807 - Correct update of amount updated to APFT to include dicount taken
*               kb 10/28/02 - #18878 - fix double quotes
*				MV 10/06/03 - #20912 - update UniqueAttchId to bPPH
*				MV 12/30/03 - #23266 - update bCMDT for EFT and ReUseYN=N
*				MV 03/11/04 - #18616 - refresh attachment indexes
*				ES 03/11/04 - #23061 - isnull wrapping
*				MV 03/29/05 - #27359 - refresh APTH attachment indexes
*				MV 03/12/08 - #127347 - International addresses
*				MV 09/10/08 - #128288 - update bAPPD with sum of TotTaxAmount from bAPDB
*				GP 10/30/08 - #130576 - changed text datatype to varchar(max)
*				MV 09/24/09 - #132819 - if EFT is a single vendor update CMDT with vendor name (description) and vendor # (payee)
*				KK 04/19/12 - B-08111 - Modified to include PayMethod "S" as per the Credit Service enhancement
*				
* USAGE:
*	Posts a validated AP Payment Batch using bAPPB, bAPTB, bAPDB and bAPPG.
*	Updates AP Payment History (bAPPH, bAPPD), Transaction Header and Detail (bAPTH, bAPTD),
*	CM Detail (bCMDT), and GL Transactions (bGLDT).
*
* INPUT PARAMETERS
*	@co             AP Company
*	@mth            Batch Month - payment month
*	@batchid        Batch ID
*	@dateposted     Date Posted - used for GL transactions
*
* OUTPUT PARAMETERS
*	@msg            error message
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/

(@co bCompany, 
 @mth bMonth, 
 @batchid bBatchID, 
 @dateposted bDate, 
 @msg varchar(255) output)
    
AS
SET NOCOUNT ON
    
DECLARE @rcode int, @payjrnl bJrnl, @glpayinterfacelvl tinyint, @glpaydetaildesc varchar(60),
    	@glpaysummarydesc varchar(60), @cminterfacelvl tinyint, @status tinyint,
    	@openAPPB tinyint, @seq int, @cmco bCompany, @cmacct bCMAcct, @paymethod char(1), @cmref bCMRef,
    	@cmrefseq tinyint, @eftseq smallint, @chktype char(1), @vendorgroup bGroup, @vendor bVendor,
    	@name varchar(60), @addnlinfo varchar(60), @address varchar(60), @city varchar(30), @state varchar(4), @zip bZip, @paiddate bDate,
    	@netamt bDollar, @supplier bVendor, @voidyn bYN, @voidmemo varchar(255), @reuseyn bYN, @cmglco bCompany,
    	@cmglacct bGLAcct, @cmtrans bTrans, @openAPTB tinyint, @expmth bMonth, @aptrans bTrans, @apref bAPReference,
    	@description bDesc, @invdate bDate, @gross bDollar, @retainage bDollar, @prevpaid bDollar, @prevdisc bDollar,
    	@balance bDollar, @disctaken bDollar, @v1099yn bYN, @v1099type varchar(10), @v1099box tinyint, @prepaidyn bYN,
    	@year int, @date varchar(10), @yemo bMonth, @openAPDB tinyint, @apline smallint, @apseq tinyint, @amount bDollar,
    	@discoff bDollar, @openAPTBvoid tinyint, @openAPDBvoid tinyint, @glref bGLRef,@uniqueattchid uniqueidentifier,
    	@openAPPG tinyint, @glco bCompany, @glacct bGLAcct, @gltrans bTrans, @sortname varchar(15),@eftamt bDollar,
    	@desccontrol varchar(60), @desc varchar(60), @findidx int, @found varchar(30), @apcmco bCompany, @Notes varchar(256),
   		@apthuniqueattchid uniqueidentifier, @country char(2), @tottaxamount bDollar, @vendorcount int, @1099AddressSeq tinyint
    
SELECT  @rcode = 0, @vendorcount = 0
    
    -- get AP Company info
    select @payjrnl = PayJrnl, @glpayinterfacelvl = GLPayInterfaceLvl,
     	@glpaydetaildesc = GLPayDetailDesc, @glpaysummarydesc = GLPaySummaryDesc,
     	@cminterfacelvl = CMInterfaceLvl, @apcmco = CMCo
    from bAPCO where APCo = @co
    if @@rowcount = 0
    	begin
    	select @msg = 'Invalid AP Company.', @rcode = 1
    	goto bspexit
    	end
    
    -- check for date posted
    if @dateposted is null
    	begin
    	select @msg = 'Missing batch posting date.', @rcode = 1
    	goto bspexit
    	end
    
    -- validate HQ Batch
    exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'AP Payment', 'APPB', @msg output, @status output
    if @rcode <> 0 goto bspexit
    if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
        begin
        select @msg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''.', @rcode = 1
        goto bspexit
        end
    
    -- set HQ Batch status to 4 (posting in progress)
    update bHQBC
    set Status = 4, DatePosted = @dateposted
    where Co = @co and Mth = @mth and BatchId = @batchid
    if @@rowcount = 0
    	begin
     	select @msg = 'Unable to update HQ Batch Control information.', @rcode = 1
     	goto bspexit
     	end
    
    -- create cursor to process all Payment Batch Header entries
    declare bcAPPB cursor for
    select BatchSeq, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, ChkType, VendorGroup,
     	Vendor, Name, AddnlInfo, Address, City, State, Zip, PaidDate, Amount, Supplier, VoidYN,
    	VoidMemo, ReuseYN, UniqueAttchID, Country
    from bAPPB
    where Co = @co and Mth = @mth and BatchId = @batchid
    
    open bcAPPB
    select @openAPPB = 1
    
    APPB_loop:        -- loop through Payment Batch Header entries
     	fetch next from bcAPPB into @seq, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq,
    	    @chktype, @vendorgroup, @vendor, @name, @addnlinfo, @address, @city, @state, @zip, @paiddate, @netamt,
    	    @supplier, @voidyn, @voidmemo, @reuseyn,@uniqueattchid,@country
    
     	if @@fetch_status <> 0  goto APPB_end
    
    	if @voidyn = 'N' select @cmco = @apcmco	-- use current CM Co# for all payments, use posted CM Co# with voids

		-- get Vendor count for EFT Payee in CMDT
		select @vendorcount = count(distinct Vendor)
		from dbo.bAPPB (nolock)
		where Co = @co and Mth = @mth and BatchId = @batchid and CMCo=@cmco and CMAcct=@cmacct and PayMethod='E'
		group by Co,Mth,BatchId, CMCo, CMAcct, PayMethod
		
		-- set vendorcount to 1 for Credit Service payments to get the correct vendor name and number to insert into APPH
		IF @paymethod = 'S'
		BEGIN
			SELECT @vendorcount = 1
		END
    
     	-- get GL Account from CM Account
     	select @cmglco = c.GLCo, @cmglacct = a.GLAcct
     	from bCMAC a
     	join bCMCO c on c.CMCo = a.CMCo
     	where a.CMCo = @cmco and a.CMAcct = @cmacct
     	if @@rowcount = 0
         	begin
         	select @msg = 'Missing CM Account ' + isnull(convert(varchar(10),@cmacct), ''), @rcode = 1  --#23061
         	goto bspexit
         	end
    
         --if @paymethod = 'C' select @eftseq = 0  
         -- make sure EFT Seq is always 0 on all checks and Credit Service payments
		 IF @paymethod IN ('C', 'S')
		 BEGIN
			SELECT @eftseq = 0
		 END
		 
         begin transaction
    
         if @voidyn = 'N'
             begin
             -- add a header entry into AP Payment History
    	    insert bAPPH (APCo, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, VendorGroup,
             Vendor, Name, AddnlInfo, Address, City, State, Zip, ChkType, PaidMth, PaidDate, Amount,
    		    Supplier, VoidYN, PurgeYN, BatchId,UniqueAttchID, Country)
    	    values (@co, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq, @vendorgroup,
    		    @vendor, @name, @addnlinfo, @address, @city, @state, @zip, @chktype, @mth, @paiddate,
    		    @netamt, @supplier, 'N', 'N', @batchid, @uniqueattchid, @country)
    
             -- update Cash Management
             IF @cminterfacelvl = 1  -- interface level must equal 1 to update
        	 BEGIN
        		if @paymethod = 'C'    -- Check
                begin
                    -- get next available transaction #
                    exec @cmtrans = bspHQTCNextTrans 'bCMDT', @cmco, @mth, @msg output
        		    if @cmtrans = 0 goto posting_error
                    -- add Check entry to CM Detail
        			insert into bCMDT(CMCo, Mth, CMTrans, CMAcct, CMTransType, SourceCo, Source, ActDate,
                        PostedDate, Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, Payee, GLCo,
                        CMGLAcct, Void, Purge)
        			values(@cmco, @mth, @cmtrans, @cmacct, 1, @co, 'AP Payment', @paiddate, @dateposted,
        				convert(varchar(30),@name), -(@netamt), 0, @batchid, @cmref, @cmrefseq, convert(varchar(20),@vendor), @cmglco,
                        @cmglacct, 'N', 'N')
                end

    			IF @paymethod IN ('E', 'S')
				BEGIN
        			-- if EFT already exists in CM Detail, update Amount (check and EFT amts stored as negatives in CM)
        			-- Credit service will never hit this
            		UPDATE bCMDT SET Amount = Amount - @netamt, BatchId = @batchid
                 	WHERE CMCo = @cmco 
                 		  AND Mth = @mth 
                 		  AND CMAcct = @cmacct 
                 		  AND CMTransType = 4
                 		  AND CMRef = @cmref 
                 		  AND CMRefSeq = 0 
                 		  AND StmtDate IS NULL
    			    IF @@rowcount = 0
					BEGIN
                     	-- add new EFT/Credit Service transaction to CM Detail
    				    EXEC @cmtrans = bspHQTCNextTrans 'bCMDT', @cmco, @mth, @msg OUTPUT
    				    IF @cmtrans = 0 GOTO posting_error
                         -- add EFT/Credit Service entry to CM Detail
      	  			    INSERT INTO bCMDT(CMCo, Mth, CMTrans, CMAcct, CMTransType, 
      	  								  SourceCo, Source, ActDate, PostedDate, 
      	  								  Description, 
      	  								  Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, 
      	  								  Payee, 
      	  								  GLCo, CMGLAcct, Void, Purge)
      	  						   VALUES(@cmco, @mth, @cmtrans, @cmacct, 4, 
      	  								  @co, 'AP Payment', @paiddate, @dateposted,
										  CASE @vendorcount WHEN 1 THEN convert(varchar(30),isnull(@name,'')) ELSE 'EFT Payment' END,
      	  								  -(@netamt), 0, @batchid, @cmref, 0,
										  CASE @vendorcount WHEN 1 THEN convert(varchar(20),@vendor) ELSE '' END,
										  @cmglco, @cmglacct,'N', 'N')
        			END
				END
      		END -- End update to Cash Management
    
    		-- create cursor to process Payment Batch Transactions for this Payment
            declare bcAPTB cursor for
            select ExpMth, APTrans, APRef, Description, InvDate, Gross, Retainage, PrevPaid,
                PrevDisc, Balance, DiscTaken
            from bAPTB
            where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    
            open bcAPTB
            select @openAPTB = 1
    
            APTB_loop:        -- loop through Payment Batch Trans entries
                fetch next from bcAPTB into @expmth, @aptrans, @apref, @description, @invdate,
                   	@gross, @retainage, @prevpaid, @prevdisc, @balance, @disctaken
    
                if @@fetch_status <> 0  goto APTB_end

				--Sum TotTaxAmount from bAPDB for update to Pay History Detail
				select @tottaxamount= sum(isnull(TotTaxAmount,0)) from bAPDB 
				where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and ExpMth = @expmth and  APTrans = @aptrans 

    			-- add entry to AP Payment History Detail
             	insert bAPPD (APCo, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, Mth, APTrans,
                     APRef, Description, InvDate, Gross, Retainage, PrevPaid, PrevDiscTaken, Balance, DiscTaken, TotTaxAmount)
    	        values(@co, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq, @expmth, @aptrans,
    		        @apref, @description, @invdate, @gross, @retainage, @prevpaid, @prevdisc, @balance, @disctaken, @tottaxamount)
    
    			-- get AP Trans Header info - used for 1099 and PrePaid updates
    	         select @v1099yn = V1099YN, @v1099type = V1099Type, @v1099box = V1099Box, @prepaidyn = PrePaidYN,
   				@apthuniqueattchid=UniqueAttchID
    	         from bAPTH
    	         where APCo = @co and Mth = @expmth and APTrans = @aptrans
    	         if @@rowcount = 0
    	             begin
    	             select @msg = 'Missing AP Transaction Header.'
    	             goto posting_error
    	             end
    
                 select @year = datepart(year, @mth) -- paid month year
                 select @date = '12/1/' + isnull(convert(varchar(4),@year), '')  --#23061
                 select @yemo = convert(smalldatetime,@date,101) -- year ending date used for 1099 updates
    
                 -- create a cursor to process Trans detail paid on this payment
                 declare bcAPDB cursor for
                 select APLine, APSeq, Amount, DiscTaken
                 from bAPDB
                 where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                     and ExpMth = @expmth and APTrans = @aptrans
    
                 open bcAPDB
                 select @openAPDB = 1
    
                 APDB_loop:        -- loop through Payment Batch Detail entries
                  	fetch next from bcAPDB into @apline, @apseq, @amount, @disctaken
    
                    if @@fetch_status <> 0  goto APDB_end
    
                    -- update paid information to AP Transaction Detail
    	            update bAPTD
                    set PaidMth = @mth, PaidDate = @paiddate, CMCo = @cmco, CMAcct = @cmacct, CMRef = @cmref,
                    	CMRefSeq = @cmrefseq, EFTSeq = @eftseq, Status = 3, PayMethod = @paymethod,
                        DiscTaken = @disctaken
    	       	    where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline and APSeq = @apseq
    
                    -- get Discount Offered from AP Trans Detail - used to update Vendor Activity
                    select @discoff = isnull(DiscOffer,0)
                    from bAPTD
                    where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline and APSeq = @apseq
    
                    -- update Vendor Activity for Paid Month
    				update bAPVA
                    set PaidAmt = PaidAmt + @amount, DiscOff = DiscOff + @discoff,
                    	DiscTaken = DiscTaken + @disctaken, AuditYN = 'N'   -- no audit on system updates
                    where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
                    if @@rowcount = 0
                    	begin
    	                insert bAPVA(APCo, VendorGroup, Vendor, Mth, InvAmt, PaidAmt, DiscOff, DiscTaken, AuditYN)
    	                values(@co, @vendorgroup, @vendor, @mth, 0, @amount, @discoff, @disctaken, 'N')
    	                end
    				-- reset audit flag
                    update bAPVA
                    set AuditYN = 'Y'
                    where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
                    if @@rowcount = 0
                    	begin
            	        select @msg = 'Unable to update AP Vendor Activity.'
                        goto posting_error
                        end
                        
   
                    -- update 1099 totals
                    if @v1099type is not null
    					begin
    					update bAPFT
                        set Box1Amt = Box1Amt + Case when @v1099box = 1 then @amount - @disctaken else 0 end,
        		        	Box2Amt = Box2Amt+ Case when @v1099box = 2 then @amount - @disctaken else 0 end,
        		            Box3Amt = Box3Amt+ Case when @v1099box = 3 then @amount - @disctaken else 0 end,
        		            Box4Amt = Box4Amt+ Case when @v1099box = 4 then @amount - @disctaken else 0 end,
        		          	Box5Amt = Box5Amt+ Case when @v1099box = 5 then @amount - @disctaken else 0 end,
        		            Box6Amt = Box6Amt+ Case when @v1099box = 6 then @amount - @disctaken else 0 end,
        		            Box7Amt = Box7Amt+ Case when @v1099box = 7 then @amount - @disctaken else 0 end,
    		                Box8Amt = Box8Amt+ Case when @v1099box = 8 then @amount - @disctaken else 0 end,
    		                Box9Amt = Box9Amt+ Case when @v1099box = 9 then @amount - @disctaken else 0 end,
    		                Box10Amt = Box10Amt+ Case when @v1099box = 10 then @amount - @disctaken else 0 end,
    		                Box11Amt = Box11Amt+ Case when @v1099box = 11 then @amount - @disctaken else 0 end,
    		                Box12Amt = Box12Amt+ Case when @v1099box = 12 then @amount - @disctaken else 0 end,
    		                Box13Amt = Box13Amt+ Case when @v1099box = 13 then @amount - @disctaken else 0 end,
                            Box14Amt = Box14Amt+ Case when @v1099box = 14 then @amount - @disctaken else 0 end,
    		                Box15Amt = Box15Amt+ Case when @v1099box = 15 then @amount - @disctaken else 0 end,
    		                Box16Amt = Box16Amt+ Case when @v1099box = 16 then @amount - @disctaken else 0 end,
    		                Box17Amt = Box17Amt+ Case when @v1099box = 17 then @amount - @disctaken else 0 end,
    		                Box18Amt = Box18Amt+ Case when @v1099box = 18 then @amount - @disctaken else 0 end,
                            AuditYN = 'N'	-- do not audit system updates
        		        where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor
                            and YEMO = @yemo and V1099Type = @v1099type
    					if @@rowcount = 0
    						begin
                            insert bAPFT(APCo, VendorGroup, Vendor, YEMO, V1099Type, Box1Amt, Box2Amt, Box3Amt,
                            	Box4Amt, Box5Amt, Box6Amt, Box7Amt, Box8Amt, Box9Amt, Box10Amt, Box11Amt, Box12Amt,
    			                Box13Amt, Box14Amt, Box15Amt, Box16Amt, Box17Amt, Box18Amt, AuditYN)
    						select @co, @vendorgroup, @vendor, @yemo, @v1099type,
    							Case when @v1099box = 1 then @amount - @disctaken else 0 end,
        		        		Case when @v1099box = 2 then @amount - @disctaken else 0 end,
    	    		            Case when @v1099box = 3 then @amount - @disctaken else 0 end,
    	    		            Case when @v1099box = 4 then @amount - @disctaken else 0 end,
    	    		          	Case when @v1099box = 5 then @amount - @disctaken else 0 end,
    	    		            Case when @v1099box = 6 then @amount - @disctaken else 0 end,
    	    		            Case when @v1099box = 7 then @amount - @disctaken else 0 end,
    			                Case when @v1099box = 8 then @amount - @disctaken else 0 end,
    			                Case when @v1099box = 9 then @amount - @disctaken else 0 end,
    			                Case when @v1099box = 10 then @amount - @disctaken else 0 end,
    			                Case when @v1099box = 11 then @amount - @disctaken else 0 end,
    			                Case when @v1099box = 12 then @amount - @disctaken else 0 end,
    			                Case when @v1099box = 13 then @amount - @disctaken else 0 end,
    	                        Case when @v1099box = 14 then @amount - @disctaken else 0 end,
    			                Case when @v1099box = 15 then @amount - @disctaken else 0 end,
    			                Case when @v1099box = 16 then @amount - @disctaken else 0 end,
    			                Case when @v1099box = 17 then @amount - @disctaken else 0 end,
    			                Case when @v1099box = 18 then @amount - @disctaken else 0 end, 'N'
    						end
    					-- reset audit flag
    					update bAPFT
                        set AuditYN = 'Y'
    		            where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor
                        and YEMO = @yemo and V1099Type = @v1099type
    					if @@rowcount = 0
    						begin
        	        		select @msg = 'Unable to update AP 1099 Vendor Totals.', @rcode = 1
                    		goto posting_error
                    		end
                        end
    
               	-- delete Payment Batch Detail
                 delete bAPDB
                 where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                     and ExpMth = @expmth and APTrans = @aptrans and APLine = @apline and APSeq = @apseq
   	
   
                 goto APDB_loop      -- next Transaction Detail entry
    
             	APDB_end:   -- finished with Paid Detail for the current Transaction
    	             close bcAPDB
    	             deallocate bcAPDB
    	             select @openAPDB = 0
    	
    
    			-- update Transaction Header
             	if @chktype = 'P'   -- prepaid
                   	begin
                    update bAPTH
                    set PrePaidProcYN = 'Y'
                    where APCo = @co and Mth = @expmth and APTrans = @aptrans
    				if @@rowcount = 0
    					begin
        	        	select @msg = 'Unable to update AP Prepaid processing status in Transaction Header.'
                    	goto posting_error
                    	end
                  	end
    
                -- check for fully paid Transaction
               	if not exists(select 1 from bAPTD where APCo = @co and Mth = @expmth and APTrans = @aptrans
                    and Status < 3)
                 	begin
                    update bAPTH
                    set OpenYN = 'N'
                    where APCo = @co and Mth = @expmth and APTrans = @aptrans
   
    				if @@rowcount = 0
    					begin
        	        	select @msg = 'Unable to update AP ''Open'' status in Transaction Header.'
   
                    	goto posting_error
                    	end
                    end
    
                -- remove Payment Batch Transaction
                delete bAPTB
                where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                	and ExpMth = @expmth and APTrans = @aptrans
   
   			--#27359 - Refresh indexes for APTH if attachment exists
    				if @apthuniqueattchid is not null
    					begin
    					exec dbo.bspHQRefreshIndexes null, null, @apthuniqueattchid, null
    					end
    
                 goto APTB_loop      -- next Transaction entry
    
             APTB_end:   -- finnished with Transactions on the current Payment
                 close bcAPTB
                 deallocate bcAPTB
                 select @openAPTB = 0
    
                 -- update user memos in bAPPH before deleting the detail batch record
                exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AP PayEdit', @msg output
                if @rcode <> 0 goto posting_error
    
    	         -- remove Payment Batch Header
    	         delete bAPPB
    	         where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    
    	         commit transaction      -- commit the transaction after all updates have been performed
    
    	         goto APPB_loop      -- next Payment Header
    
       		end
    
    	if @voidyn = 'Y'   -- voids
    		begin
            -- create cursor to process Payment Batch Transactions for this Void
            declare bcAPTBvoid cursor for
            select ExpMth, APTrans, Description, InvDate, Gross, Retainage, PrevPaid,
                 PrevDisc, Balance, DiscTaken
            from bAPTB
            where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    
            open bcAPTBvoid
            select @openAPTBvoid = 1
    
            APTBvoid_loop:      -- loop through Payment Batch Trans entries
                 fetch next from bcAPTBvoid into @expmth, @aptrans, @description, @invdate, @gross,
                     @retainage, @prevpaid, @prevdisc, @balance, @disctaken
    
                 if @@fetch_status <> 0  goto APTBvoid_end
    
                 -- get AP Trans Header info - used for 1099 and PrePaid updates
                 select @v1099yn = V1099YN, @v1099type = V1099Type, @v1099box = V1099Box,
                 @prepaidyn = PrePaidYN
                 from bAPTH
                 where APCo = @co and Mth = @expmth and APTrans = @aptrans
                 if @@rowcount = 0
                     begin
                     select @msg = 'Missing AP Transaction Header.', @rcode = 1
                     goto posting_error
                     end
    
                 select @year = datepart(year, @mth) -- paid month year
                 select @date = '12/1/' + isnull(convert(varchar(4),@year), '') --#23061
                 select @yemo = convert(smalldatetime,@date,101) -- year ending date used for 1099 updates
    
                 -- create a cursor to process Trans detail paid on this payment
                 declare bcAPDBvoid cursor for
                 select APLine, APSeq, Amount, DiscTaken
                 from bAPDB
                 where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                     and ExpMth = @expmth and APTrans = @aptrans
    
                 open bcAPDBvoid
                 select @openAPDBvoid = 1
    
                 APDBvoid_loop:        -- loop through Payment Batch Detail entries
                     fetch next from bcAPDBvoid into @apline, @apseq, @amount, @disctaken
    
                     if @@fetch_status <> 0  goto APDBvoid_end
                     -- remove paid information and reopen AP Transaction Detail
        	         update bAPTD
                     set PaidMth = null, PaidDate = null, CMCo = null, CMAcct = null, CMRef = null,
                         CMRefSeq = null, EFTSeq = null, Status = 1, PayMethod = null
        	       	    where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline and APSeq = @apseq
        	            if @@rowcount = 0
        		           begin
        		           select @msg = 'Unable to remove paid information from AP Transaction Detail.', @rcode = 1
                        	goto posting_error
        		           end
    
                     -- get Discount Offered from AP Trans Detail - used to update Vendor Activity
                     select @discoff = isnull(DiscOffer,0)
                     from bAPTD
                     where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline and APSeq = @apseq
    
                     -- update Vendor Activity
    				update bAPVA
                    set PaidAmt = PaidAmt - @amount, DiscOff = DiscOff - @discoff,
                         DiscTaken = DiscTaken - @disctaken, AuditYN = 'N'   -- no audit on system updates
                    where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
    				if @@rowcount = 0
                    	insert bAPVA(APCo, VendorGroup, Vendor, Mth, InvAmt, PaidAmt, DiscOff, DiscTaken, AuditYN)
        	            select @co, @vendorgroup, @vendor, @mth, 0, -(@amount), -(@discoff), -(@disctaken), 'N'
    				-- reset audit flag
    				update bAPVA
                    set AuditYN = 'Y'
                    where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor and Mth = @mth
    				if @@rowcount = 0
    					begin
                     	select @msg = 'Unable to update AP 1099 Vendor Totals.'
                     	goto posting_error
                     	end
    
                    -- update 1099 totals
                    if @v1099type is not null
        	        	begin
    					update bAPFT
                        set Box1Amt = Box1Amt + Case when @v1099box = 1 then -(@amount - @disctaken) else 0 end,
        		            Box2Amt = Box2Amt+ Case when @v1099box = 2 then -(@amount - @disctaken) else 0 end,
        		            Box3Amt = Box3Amt+ Case when @v1099box = 3 then -(@amount - @disctaken) else 0 end,
        		            Box4Amt = Box4Amt+ Case when @v1099box = 4 then -(@amount - @disctaken) else 0 end,
        		            Box5Amt = Box5Amt+ Case when @v1099box = 5 then -(@amount - @disctaken) else 0 end,
        		            Box6Amt = Box6Amt+ Case when @v1099box = 6 then -(@amount - @disctaken) else 0 end,
        		            Box7Amt = Box7Amt+ Case when @v1099box = 7 then -(@amount - @disctaken) else 0 end,
        		            Box8Amt = Box8Amt+ Case when @v1099box = 8 then -(@amount - @disctaken) else 0 end,
        		            Box9Amt = Box9Amt+ Case when @v1099box = 9 then -(@amount - @disctaken) else 0 end,
        		            Box10Amt = Box10Amt+ Case when @v1099box = 10 then -(@amount - @disctaken) else 0 end,
        		            Box11Amt = Box11Amt+ Case when @v1099box = 11 then -(@amount - @disctaken) else 0 end,
        		            Box12Amt = Box12Amt+ Case when @v1099box = 12 then -(@amount - @disctaken) else 0 end,
        		            Box13Amt = Box13Amt+ Case when @v1099box = 13 then -(@amount - @disctaken) else 0 end,
                            Box14Amt = Box14Amt+ Case when @v1099box = 14 then -(@amount - @disctaken) else 0 end,
        		            Box15Amt = Box15Amt+ Case when @v1099box = 15 then -(@amount - @disctaken) else 0 end,
        		            Box16Amt = Box16Amt+ Case when @v1099box = 16 then -(@amount - @disctaken) else 0 end,
        		            Box17Amt = Box17Amt+ Case when @v1099box = 17 then -(@amount - @disctaken) else 0 end,
        		            Box18Amt = Box18Amt+ Case when @v1099box = 18 then -(@amount - @disctaken) else 0 end,
                         	AuditYN = 'N'
        		        where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor
                         	and YEMO = @yemo and V1099Type = @v1099type
    					if @@rowcount = 0
    						begin
                            insert bAPFT(APCo, VendorGroup, Vendor, YEMO, V1099Type,Box1Amt, Box2Amt, Box3Amt,
                            	Box4Amt, Box5Amt, Box6Amt, Box7Amt, Box8Amt, Box9Amt, Box10Amt, Box11Amt, Box12Amt,
    			                Box13Amt, Box14Amt, Box15Amt, Box16Amt, Box17Amt, Box18Amt, AuditYN)
    						select @co, @vendorgroup, @vendor, @yemo, @v1099type,
    							Case when @v1099box = 1 then -(@amount - @disctaken) else 0 end,
        		        		Case when @v1099box = 2 then -(@amount - @disctaken) else 0 end,
    	    		            Case when @v1099box = 3 then -(@amount - @disctaken) else 0 end,
    	    		            Case when @v1099box = 4 then -(@amount - @disctaken) else 0 end,
    	    		          	Case when @v1099box = 5 then -(@amount - @disctaken) else 0 end,
    	    		            Case when @v1099box = 6 then -(@amount - @disctaken) else 0 end,
    	    		            Case when @v1099box = 7 then -(@amount - @disctaken) else 0 end,
    			                Case when @v1099box = 8 then -(@amount - @disctaken) else 0 end,
    			                Case when @v1099box = 9 then -(@amount - @disctaken) else 0 end,
    			                Case when @v1099box = 10 then -(@amount - @disctaken) else 0 end,
    			                Case when @v1099box = 11 then -(@amount - @disctaken) else 0 end,
    			                Case when @v1099box = 12 then -(@amount - @disctaken) else 0 end,
    			                Case when @v1099box = 13 then -(@amount - @disctaken) else 0 end,
    	                        Case when @v1099box = 14 then -(@amount - @disctaken) else 0 end,
    			                Case when @v1099box = 15 then -(@amount - @disctaken) else 0 end,
    			                Case when @v1099box = 16 then -(@amount - @disctaken) else 0 end,
    			                Case when @v1099box = 17 then -(@amount - @disctaken) else 0 end,
    			                Case when @v1099box = 18 then -(@amount - @disctaken) else 0 end, 'N'
    						end
    					-- reset audit flag
    					update bAPFT
                        set AuditYN = 'Y'
    		            where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor
                        and YEMO = @yemo and V1099Type = @v1099type
    					if @@rowcount = 0
    						begin
        	        		select @msg = 'Unable to update AP 1099 Vendor Totals.', @rcode = 1
                    		goto posting_error
                    		end
                        end
    
                     -- delete Payment Batch Detail
                     delete bAPDB
                     where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                        and ExpMth = @expmth and APTrans = @aptrans and APLine = @apline
                         and APSeq = @apseq
    
       goto APDBvoid_loop      -- next Transaction Detail entry
    
                     APDBvoid_end:   -- finished with Paid Detail for the current Transaction
                         close bcAPDBvoid
                         deallocate bcAPDBvoid
                         select @openAPDBvoid = 0
    
                        -- reopen AP Transaction Header
                        update bAPTH
                        set OpenYN = 'Y', PrePaidYN = 'N', PrePaidSeq = null, PrePaidProcYN = 'N',
                            PrePaidMth = null, PrePaidDate = null, PrePaidChk = null
                        where APCo = @co and Mth = @expmth and APTrans = @aptrans
    					if @@rowcount = 0
    						begin
        	        		select @msg = 'Unable reopen AP Transaction Header.', @rcode = 1
                    		goto posting_error
                    		end
    
                         -- don't reset PrePaidProcYN flag on void
    
                         -- remove AP Payment History Detail
                         delete bAPPD
                         where APCo = @co and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
                             and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq and Mth = @expmth
                             and APTrans = @aptrans
    
                         -- remove Payment Batch Transaction
                         delete bAPTB
                         where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                             and ExpMth = @expmth and APTrans = @aptrans
    
                         goto APTBvoid_loop
    
                     APTBvoid_end:   -- finished with Transactions for the current voided Payment
                         close bcAPTBvoid
                         deallocate bcAPTBvoid
                         select @openAPTBvoid = 0
    
            -- updates to AP Payment History Header and CM Detail depends on ReuseYN & Pay Method
    
						if @reuseyn = 'Y'
						begin
                             -- # will be reused, remove Payment History Header
                             delete bAPPH
                             where APCo = @co and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
                             and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq
                             if @@rowcount = 0
                                 begin
                                 select @msg = 'Unable to remove voided AP Payment History Header.'
                                 goto posting_error
                                 end
                             if @paymethod = 'C'
                                 begin
                                 -- remove Check entry from CM Detail
                                 if @cminterfacelvl<>0
                                     begin
                                     delete bCMDT
                                     where CMCo = @cmco and Mth = @mth and CMAcct = @cmacct and CMTransType = 1
                                         and CMRef = @cmref and CMRefSeq = @cmrefseq
                                     end
                                end
    
                            if @paymethod = 'E'
                                begin
                				-- backout paid amount from existing EFT entry in CM Detail
                                if @cminterfacelvl <> 0
                                     begin
                                  update bCMDT
                                     set Amount = Amount + @netamt, BatchId = @batchid   -- EFT amts stored as negatives
                                     where CMCo = @cmco and Mth = @mth and CMAcct = @cmacct and CMTransType = 4
                                         and CMRef = @cmref and CMRefSeq = @cmrefseq
                                     -- remove CM Detail if EFT total is 0.00
                                     delete bCMDT
                                     where CMCo = @cmco and Mth = @mth and CMAcct = @cmacct and CMTransType = 4
                                         and CMRef = @cmref and CMRefSeq = @cmrefseq and Amount = 0
                                     end
                        		end
							-- remove Credit Service entry from CM Detail
							IF @paymethod = 'S'	AND @cminterfacelvl <> 0
							BEGIN
								UPDATE bCMDT
                                SET Amount = Amount + @netamt, BatchId = @batchid   -- Credit Svc amts stored as negatives
                                WHERE CMCo = @cmco 
									AND Mth = @mth 
									AND CMAcct = @cmacct 
									AND CMTransType = 4
                                    AND CMRef = @cmref 
                                 -- remove CM Detail if Credit Svc total is 0.00 after update
								DELETE bCMDT
								WHERE CMCo = @cmco 
									AND Mth = @mth 
									AND CMAcct = @cmacct 
									AND CMTransType = 4
									AND CMRef = @cmref
									AND Amount = 0
							END
						END -- end reuseyn is Y flag
							
                        if @reuseyn = 'N'
                            begin
                            -- # will not be reused, update Payment History Header
                            update bAPPH
                            set VoidYN = 'Y', VoidMemo = @voidmemo, InUseMth = null, InUseBatchId = null,
                             	BatchId = @batchid
                            where APCo = @co and CMCo = @cmco and CMAcct = @cmacct and PayMethod = @paymethod
                                and CMRef = @cmref and CMRefSeq = @cmrefseq and EFTSeq = @eftseq
                            if @@rowcount = 0
                                begin
                                insert bAPPH(APCo, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, VendorGroup,
           							Vendor, Name, AddnlInfo, Address, City, State, Zip, ChkType, PaidMth, PaidDate, Amount,
                                    Supplier, VoidYN, VoidMemo, PurgeYN, BatchId,UniqueAttchID,Country)
                                values(@co, @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq, @vendorgroup,
                                     @vendor, @name, @addnlinfo, @address, @city, @state, @zip, @chktype, @mth, @paiddate, @netamt,
                                     @supplier, 'Y', @voidmemo, 'N', @batchid,@uniqueattchid, @country)
                                 end
							
                            -- update void to CM Detail
                            if @cminterfacelvl<>0 and @paymethod = 'C'
                                begin
                                update bCMDT
                                set Void = 'Y', BatchId = @batchid
                                where CMCo = @cmco and Mth = @mth and CMAcct = @cmacct and CMTransType = 1  -- must be check
                                    and CMRef = @cmref and CMRefSeq = @cmrefseq
                                if @@rowcount = 0
                                    begin
                                    exec @cmtrans = bspHQTCNextTrans 'bCMDT', @cmco, @mth, @msg output
        				            if @cmtrans = 0 goto posting_error
                                    insert bCMDT(CMCo, Mth, CMTrans, CMAcct, CMTransType, SourceCo, Source, ActDate,
                                        PostedDate, Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, Payee,
                                        GLCo, CMGLAcct, Void, Purge)
        			                values(@cmco, @mth, @cmtrans, @cmacct, 1, @co, 'AP Payment', @paiddate, @dateposted,
                                        convert(varchar(30),@name), -(@netamt), 0, @batchid, @cmref, @cmrefseq, convert(varchar(20),@vendor),
                                        @cmglco, @cmglacct, 'Y', 'N')
                                   end
                                end
    						/* #23266 - ReUseYN can be 'N' for EFT's only if all Sequences are being voided. So update bCMDT */
    						if @cminterfacelvl<>0 and @paymethod = 'E'	
                                begin
                                update bCMDT
                                set Void = 'Y', BatchId = @batchid
                                where CMCo = @cmco and Mth = @mth and CMAcct = @cmacct and CMTransType = 4 -- EFT and Credit Service share transtype = 4
                                    and CMRef = @cmref and CMRefSeq = 0
    							if @@rowcount = 0	
                                    begin
                                    exec @cmtrans = bspHQTCNextTrans 'bCMDT', @cmco, @mth, @msg output
        				        	if @cmtrans = 0 goto posting_error
    								--get total amount from bAPPB
    								select @eftamt =  sum(Amount) from bAPPB with (nolock)
    									where Co = @co and Mth = @mth and BatchId = @batchid and CMRef=@cmref and PayMethod='E' 
                                    insert bCMDT(CMCo, Mth, CMTrans, CMAcct, CMTransType, SourceCo, Source, ActDate,
                                        PostedDate, Description, Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, Payee,
                                        GLCo, CMGLAcct, Void, Purge)
        			                values(@cmco, @mth, @cmtrans, @cmacct, 4, @co, 'AP Payment', @paiddate, @dateposted,
                                        convert(varchar(30),@name), -(@eftamt), 0, @batchid, @cmref, @cmrefseq, convert(varchar(20),@vendor),
                                        @cmglco, @cmglacct, 'Y', 'N') 
                                   end
                                end
                                
							IF @cminterfacelvl <> 0 AND @paymethod = 'S'	
                            BEGIN
								UPDATE bCMDT
								SET Void = 'Y', BatchId = @batchid
								WHERE CMCo = @cmco 
									AND Mth = @mth 
									AND CMAcct = @cmacct 
									AND CMTransType = 4  -- EFT and Credit Service share transtype = 4
									AND CMRef = @cmref 
									AND CMRefSeq = 0
								IF @@ROWCOUNT = 0	
                                BEGIN
									EXEC @cmtrans = bspHQTCNextTrans 'bCMDT', @cmco, @mth, @msg OUTPUT
    				        		IF @cmtrans = 0 GOTO posting_error
									INSERT bCMDT(CMCo, Mth, CMTrans, CMAcct, CMTransType, 
												SourceCo, Source, ActDate, PostedDate, 
												Description, 
												Amount, ClearedAmt, BatchId, CMRef, CMRefSeq, 
												Payee,
												GLCo, CMGLAcct, Void, Purge)
    								VALUES(@cmco, @mth, @cmtrans, @cmacct, 4, 
    											@co, 'AP Payment', @paiddate, @dateposted,
												convert(varchar(30),@name), 
												-(@netamt), 0, @batchid, @cmref, @cmrefseq, 
												convert(varchar(20),@vendor),
												@cmglco, @cmglacct, 'Y', 'N')
								END
							END
                        end	
    
                        -- update user memos in bAPPH before deleting the detail batch record
                        exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'AP PayEdit', @msg output
     					if @rcode <> 0 goto posting_error
    
                        -- remove Payment Batch Header
                        delete bAPPB
                        where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
                        if @@rowcount = 0
                            begin
                            select @msg = 'Unable to delete payment batch header',@rcode = 1
                            goto posting_error
                            end
    
                   	commit transaction
    
    				--#18616 - Refresh indexes for this header if attachments exist
    				if @uniqueattchid is not null
    					begin
    					exec dbo.bspHQRefreshIndexes null, null, @uniqueattchid, null
    					end
    
                    goto APPB_loop      -- next Payment Header
             end
    
    	posting_error:
    	    rollback transaction
    		select @rcode = 1
    
    		goto bspexit
    
     APPB_end:    -- finished with Payment Batch updates to AP and CM
         if @openAPPB = 1
             begin
             close bcAPPB
             deallocate bcAPPB
             select @openAPPB = 0
             end
       if @openAPTB = 1
             begin
             close bcAPTB
             deallocate bcAPTB
             select @openAPTB = 0
             end
         if @openAPDB = 1
             begin
             close bcAPDB
             deallocate bcAPDB
             select @openAPDB = 0
             end
         if @openAPTBvoid = 1
             begin
             close bcAPTBvoid
             deallocate bcAPTBvoid
             select @openAPTBvoid = 0
             end
         if @openAPDBvoid = 1
             begin
             close bcAPDBvoid
             deallocate bcAPDBvoid
             select @openAPDBvoid = 0
         end
    
    
    -- GL Update for AP Payment Batch
    if @glpayinterfacelvl = 0	 -- no update
    	begin
    	delete bAPPG where APCo = @co and Mth = @mth and BatchId = @batchid
    	goto gl_update_end
    	end
    
    -- set GL Reference using Batch Id - right justified 10 chars
    select @glref = space(10-datalength(isnull(convert(varchar(10),@batchid), ''))) + isnull(convert(varchar(10),@batchid), '')  --#23061
    
    if @glpayinterfacelvl = 1	 -- Summary - update GL with one entry per GL Co/GLAcct, unless GL Acct flagged for detail
    	begin
        -- create a 'summary' cursor
        declare bcAPPG cursor for
        select c.GLCo, c.GLAcct, convert(numeric(12,2),sum(c.Amount))
        from bAPPG c
        join bGLAC g on c.GLCo = g.GLCo and c.GLAcct = g.GLAcct
        where c.APCo = @co and c.Mth = @mth and c.BatchId = @batchid and g.InterfaceDetail = 'N'
        group by c.GLCo, c.GLAcct
    
        open bcAPPG
        select @openAPPG = 1
    
        gl_summary_posting_loop:
         	fetch next from bcAPPG into @glco, @glacct, @amount
    
        	if @@fetch_status <> 0 goto gl_summary_posting_end
    
        	begin transaction
    
        	-- get next available transaction # for GLDT
    	    exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @msg output
    	    if @gltrans = 0 goto gl_summary_posting_error
    
    
    	    insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source, ActDate, DatePosted,
             	Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
         	values(@glco, @mth, @gltrans, @glacct, @payjrnl, @glref, @co, 'AP Payment', @dateposted,
             	@dateposted, @glpaysummarydesc, @batchid, @amount, 0, 'N', null, 'N')
    		if @@rowcount = 0 goto gl_summary_posting_error
    
            -- remove GL Distributions from batch
            delete bAPPG
            where APCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
            if @@rowcount = 0 goto gl_summary_posting_error
    
    		commit transaction
    
            goto gl_summary_posting_loop
    
        gl_summary_posting_error:	-- error occured within transaction - rollback any updates and continue
            rollback transaction
        	goto gl_summary_posting_loop
    
        gl_summary_posting_end:	   -- no more rows to process
            close bcAPPG
           	deallocate bcAPPG
            select @openAPPG = 0
    
     	end
    
    -- Detail update to GL for everything remaining in bAPPG
    declare bcAPPG cursor for
    select g.GLCo, g.GLAcct, g.BatchSeq, g.CMCo, g.CMAcct, g.PayMethod, g.CMRef, g.CMRefSeq,
     	g.EFTSeq, g.VendorGroup, g.Vendor, v.SortName, g.Amount, g.PaidDate
    from bAPPG g
    join bAPVM  v on v.VendorGroup = g.VendorGroup and v.Vendor = g.Vendor
    where g.APCo = @co and g.Mth = @mth and g.BatchId = @batchid
    
    open bcAPPG
    select @openAPPG = 1
    
    gl_detail_posting_loop:
         fetch next from bcAPPG into @glco, @glacct, @seq, @cmco, @cmacct, @paymethod,
        		@cmref, @cmrefseq, @eftseq, @vendorgroup, @vendor, @sortname, @amount, @paiddate
    
        if @@fetch_status <> 0 goto gl_detail_posting_end
    
        begin transaction
    
        -- parse out Description fro detail update
        select @desccontrol = isnull(rtrim(@glpaydetaildesc),'')
    
       	select @desc = ''
    
        while (@desccontrol <> '')
            begin
            select @findidx = charindex('/',@desccontrol)
            if @findidx = 0
                 begin
                	select @found = @desccontrol
        		    select @desccontrol = ''
        		    end
             else
        		    begin
            		select @found = substring(@desccontrol,1,@findidx-1)
        		    select @desccontrol = substring(@desccontrol,@findidx+1,60)
                 end
    
        		if @found = 'CMCo' select @desc = @desc + '/' + isnull(convert(varchar(3), @cmco), '') --#23061
             if @found = 'CM Acct#' select @desc = @desc + '/' + isnull(convert(varchar(4), @cmacct), '')
             if @found = 'Vendor' select @desc = @desc + '/' + isnull(convert(varchar(6), @vendor), '')
            	if @found = 'SortName' select @desc = @desc + '/' +  isnull(@sortname, '')
            	if @found = 'Check#' select @desc = @desc + '/' + isnull(convert(varchar(10), @cmref), '')
        		if @found = 'Paid Date' select @desc = @desc + '/' + isnull(convert(varchar(20), @paiddate, 107), '')
             end
    
         	-- get next available transaction # for GLDT
    	    exec @gltrans = bspHQTCNextTrans 'bGLDT', @glco, @mth, @msg output
    	    if @gltrans = 0 goto gl_detail_posting_error
    
    	    insert bGLDT(GLCo, Mth, GLTrans, GLAcct, Jrnl, GLRef, SourceCo, Source,
    			ActDate, DatePosted, Description, BatchId, Amount, RevStatus, Adjust, InUseBatchId, Purge)
    		values(@glco, @mth, @gltrans, @glacct, @payjrnl, @glref, @co, 'AP Payment', @paiddate,
             	@dateposted, @desc, @batchid, @amount, 0, 'N', null, 'N')
    		if @@rowcount = 0 goto gl_detail_posting_error
    
          	-- remove GL distributions from batch
          	delete bAPPG
            where APCo = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco and GLAcct = @glacct
                 and BatchSeq = @seq
            if @@rowcount = 0 goto gl_detail_posting_error
    
    		commit transaction
    
        	goto gl_detail_posting_loop
    
        gl_detail_posting_error:	-- error occured within transaction - rollback any updates and continue
        	rollback transaction
    		select @rcode = 1
        	goto bspexit
    
        gl_detail_posting_end:	-- no more rows to process
        	 close bcAPPG
             deallocate bcAPPG
             select @openAPPG = 0
    
    gl_update_end:
    	-- make sure GL Distributions is empty
        if exists(select 1 from bAPPG where APCo = @co and Mth = @mth and BatchId = @batchid)
          	begin
            select @msg = 'Not all updates to GL were posted - unable to close batch!', @rcode = 1
            goto bspexit
        	end
    	-- make sure all Payment Batch audit tables are empty
    	if exists(select 1 from bAPPB where Co = @co and Mth = @mth and BatchId = @batchid)
    	    begin
    	    select @msg = 'Not all payments were posted - unable to close batch!', @rcode = 1
    	    goto bspexit
    	    end
    	if exists(select 1 from bAPTB where Co = @co and Mth = @mth and BatchId = @batchid)
    	  	begin
    	    select @msg = 'Not all payment transactions were posted - unable to close batch!', @rcode = 1
    	    goto bspexit
    	    end
    	if exists(select * from bAPDB where Co = @co and Mth = @mth and BatchId = @batchid)
    	    begin
    	    select @msg = 'Not all payment detail was posted - unable to close batch!', @rcode = 1
    	    goto bspexit
    	    end
    
        -- set interface levels note string
        select @Notes=Notes from bHQBC
        where Co = @co and Mth = @mth and BatchId = @batchid
        if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
        select @Notes=@Notes +
            'GL Expense Interface Level set at: ' + isnull(convert(char(1), a.GLExpInterfaceLvl), '') + char(13) + char(10) +
            'GL Payment Interface Level set at: ' + isnull(convert(char(1), a.GLPayInterfaceLvl), '') + char(13) + char(10) +
            'CM Interface Level set at: ' + isnull(convert(char(1), a.CMInterfaceLvl), '') + char(13) + char(10) +
            'EM Interface Level set at: ' + isnull(convert(char(1), a.EMInterfaceLvl), '') + char(13) + char(10) +
            'IN Interface Level set at: ' + isnull(convert(char(1), a.INInterfaceLvl), '') + char(13) + char(10) +
            'JC Interface Level set at: ' + isnull(convert(char(1), a.JCInterfaceLvl), '') + char(13) + char(10)  --#23061
        from bAPCO a where APCo=@co
    
    	-- delete HQ Close Control entries
    	delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
    
    	-- set HQ Batch status to 5 (posted)
    	update bHQBC
    	set Status = 5, DateClosed = getdate(),  Notes = convert(varchar(max),@Notes)
    	where Co = @co and Mth = @mth and BatchId = @batchid
    	if @@rowcount = 0
    		begin
    	    select @msg = 'Unable to update HQ Batch Control information!', @rcode = 1
    	    goto bspexit
    	    end
    
    bspexit:
    	if @openAPPB = 1
       		begin
        	close bcAPPB
            deallocate bcAPPB
            end
         if @openAPTB = 1
             begin
             close bcAPTB
             deallocate bcAPTB
           end
         if @openAPDB = 1
             begin
             close bcAPDB
             deallocate bcAPDB
             end
         if @openAPTBvoid = 1
             begin
             close bcAPTBvoid
             deallocate bcAPTBvoid
             end
         if @openAPDBvoid = 1
             begin
             close bcAPDBvoid
             deallocate bcAPDBvoid
             end
        if @openAPPG = 1
        	begin
        	close bcAPPG
        	deallocate bcAPPG
        	end
    
    	if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[bspAPPBPost]'
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPBPost] TO [public]
GO
