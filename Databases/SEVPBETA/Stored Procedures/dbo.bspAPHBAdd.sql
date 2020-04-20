SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[bspAPHBAdd]
/***********************************************************
* CREATED BY:	kb 07/18/97
* MODIFIED By:	kb 04/01/99
* MODIFIED By:	kb 12/31/99 - changed section for unapproved invoices to check
*                             required fields so that it is in a separate stored procedure.
*				EN 01/22/00 - expand dimension of @payname from 30 to 60 and include additional payname info when add to bAPHB
*				GR 05/10/00 - added docname column to insert into bAPHB
*				GR 09/20/00 - added document attachments
*				GR 10/23/00 - changed the numrows added to APHB into the select instead of incrementing the count by one if source
*                            is unapproved
*				GG 11/27/00 - changed datatype from bAPRef to bAPReference
*				kb 01/10/01 - issue #11866
*				je 01/16/01 - issue #11953
*				GG 04/20/01 - rewrite to remove cursor, fix transaction rollback errors, improve validation, fix update to bHQAT, etc.
*				TV 07/03/01 - Delete the attachments from HQAT issue 12940
*				MV 08/02/01 - Issue 14220 BatchUserMemoUpdateAPHBadd
*				MV 08/02/01 - Issue 14231 changed operator to '>' for Adding recurring invoices to batch.
*				TV 10/03/01 - Reseting attachments back to Unapproved.   12940
*				TV 10/25/01 - Formatting of the keyfield was fallowing the same format through out. Issue 15030
*                            Replacing 'Mth = '' with 'Mth='' so they can delete entries
*				SR 12/03/01 - Issue 15394 - MonthlyYN recurring invoices were still posting in same month
*				MV 12/04/01 - Issue 15489 - include AddendaTypeId from Vendor master in bAPHB inserts
*				kb 02/12/02 - issue #16252
*				TV/RM 02/20/02 - redesigned attachments
*				CMW 04/03/02 - Increased InvId from 5 to 10 char (issue # 16366)
*				TV 04/08/02 - Added note transfer from UI to Batch
*				MV 09/17/02 - #18596 added PrePaidProcYN = 'N' to bAPHB insert for unapproved and recurring.            
*				kb 10/28/2 - issue #18878 - fix double quotes
*				MV 11/01/02 - 18037 - insert AddressSeq into bAPHB for recurr and unapproved invoices
*				MV 02/05/03 - #20281 - Recurring and UnAppInv APLB insert error message
*				MV 03/24/03 - #20814 - insert CompType and Component into bAPLB for recur and unapp.
*				MV 06/09/03 - #21392 - add TaxAmt to @invtotal for recurring. 07/08/03 - Rej 1 fix.
*				MV 08/04/03 - #21959 - don't update batchusermemos if no header/lines added to AP
*				MV 08/04/03 - #22012 - don't add to AP batch if header has no lines.
*				MV 11/26/03 - #23061 - isnull wrap
*				MV 12/05/03 - #22990 - get separatepay flag from bAPVM for recurring, performance enhancements
*				MV 12/16/03 - #23001 - enhance SL/PO in use check
*				MV 02/23/04 - #18769 - PayCategory
*				MV 06/10/04 - #24663 - return badrow count, return BatchInUse msg w/o stopping processing - APUI & APRI
*				MV 06/30/04 - #24974/#22078 - if no payterms in recurr set duedate = invdate, fixed total invoice amt calc.
*				MV 02/06/07 - #122332 validate APRL job status, get closed GLAcct for closed jobs
*				MV 05/25/07 - #124359 check if POItem or SLItem exists in POIT or SLIT return msg if not
*				MV 06/05/07 - #122334 - select by PayControl for Unapproved invoices.
*				MV 08/30/07 - #120608 - copy notes from bAPRH to bAPHB
*				MV 09/17/07 - #27744 - Delete Recurring by vendor and InvId
*				MV 10/08/07 - #125632 - Use @xinvdate if PayTerms DueOpt=3 (none)
*				GF 12/17/07 - issue #25569 separate post closed job flags in JCCO enhancement
*				MV 01/08/08 - #29702 - restrict by responsible person for Unapproved
*				DC 01/30/08 - #126458 - Add warning if POIT has an invalid Tax Code
*				MV 03/11/08 - #127347 International Addresses
*				MV 07/29/08 - #128205 update bAPHB with additional address fields for Recurring 
*				MV 07/29/08 - #129187 validate PO taxcode only if PO Item has a taxcod
*				MV 08/12/08 - #128288 VAT TaxType
*				MV 11/10/08 - #131009 if line ReviewerGroup is null select on header ReviewerGroup.
*				MV 02/09/09 - #123778 - update bAPLB with bAPUL Receiver#
*				TJL 02/23/09 - #129889 - SL Claims and Certifications.
*				MV 06/01/09 - #133431 - commented out update to HQAT of form name and table name per issue #127603
*				MV 09/10/09 - #135447 - moved 'responsible person' check to start of Unapproved cursor to get valid count of badrows.
*				GP 06/28/10 - #135813 change bSL to varchar(30) 
*				GF 08/04/11 - TK-07144 expand PO
*				MH 08/09/11	- TK-07482 Replace MiscellaneousType with SMCostType
*				CHS 08/10/11 - B-05526 added POItemLine
*				MV 10/13/11 - TK-09070 insert POItemLine into bAPLB for recurring.
*				JG 01/25/12 - TK-12012 - Added SMJCCostType and SMPhaseGroup
*				KK 01/20/12 - TK-10814 do not allow separate payment when pay method is credit service
*				MV 04/09/12	- TK-13733 update bAPLB with SubjToOnCostYN
*				MV 04/10/12 - TK-13733 Fixed update to bAPLB for SubjToOnCostYN
*				ECV 06/12/12 - TK-15657 Added missing column SMPhase to copy from bAPUL to bAPLB.
* USAGE:
*     Called from the AP Recurring and Unapproved Invoice posting forms to add
*     or remove entries from an AP Entry batch
*
*  INPUT PARAMETERS
*   @co           AP Co#
*   @mth          Batch Month
*   @batchid      Batch ID#
*   @xvendor      Vendor restriction - used by both types of invoices
*   @xfreq        Frequencies to restrict by - Recurring Invoices only
*   @xinvdate     Invoice date - Recurring Invoices only
*   @beginv       Beginning Invoice restriction - Recurring Invoices only
*   @endinv       Ending Invoice restriction - Recurring Invoices only
*   @beginseq     Beginning UI Seq# restriction - Unapproved Invoices only
*   @endseq       Ending UI Seq# restriction - Unapproved Invoices only
*   @xuimth       Unapproved Invoice Month restriction - Unapproved Invoices only
*   @addordelete  'D' - Delete batch entries meeting selection criteria
*                 'A' - Add batch records meeting selection criteria
*     			  'R' - Delete current record (from grid) from APHB
*   @source       'U' - Unapproved Invoices
*	              'R' - Recurring Invoices
*
* OUTPUT PARAMETERS
*   @numrows      # of batch entries added to deleted
*   @badrows      not used
*   @msg          error message if error occurs
*
* RETURN VALUE
*   @rcode        0 = success, 1 = error
*****************************************************/
(@co bCompany = NULL, 
 @mth bMonth = NULL, 
 @batchid bBatchID = NULL, 
 @xvendor bVendor = NULL,
 @xfreq varchar(200) = NULL, 
 @xinvdate bDate = NULL, 
 @beginv varchar(10) = NULL, 
 @endinv varchar(10) = NULL,
 @beginseq smallint = NULL, 
 @endseq smallint = NULL, 
 @xuimth bMonth = NULL, 
 @addordelete char(1) = NULL,
 @source varchar(1) = NULL, 
 @xpaycontrol varchar(10) = NULL, 
 @responsibleperson varchar(3) = NULL,
 @numrows int output,
 @badrows int output, 
 @msg varchar(255) output)

AS
SET NOCOUNT ON

DECLARE @rcode int, @openAPRH tinyint, @vendorgroup bGroup, @vendor bVendor, @invid varchar(10), @description bDesc,
		@payterms bPayTerms, @holdcode bHoldCode, @monthly bYN, @invday tinyint, @paycontrol varchar(10),
		@paymethod char(1), @cmco bCompany, @cmacct bCMAcct, @v1099yn bYN, @v1099type varchar(10),
		@v1099box tinyint, @lastmth bMonth, @lastseq smallint, @invtodate bDollar, @expdate bDate, @invlimit bDollar,
		@invtotal bDollar, @newdate bDate, @duedate bDate, @discdate bDate, @discrate bRate, @newrefseq int,
		@apref bAPReference, @seq int, @errmsg varchar(60), @hqatseq int, @openHQATChange int, @addendatypeid tinyint,
		@separatepayyn bYN, @notes varchar(max), @addressseq tinyint, @miscamt bDollar, @taxamt bDollar, @dueopt int 

DECLARE @openAPUI tinyint, @uimth bMonth, @uiseq smallint, @invdate bDate, @payoverrideyn bYN, @payname varchar(60),
        @payaddinfo varchar(60), @payaddress varchar(60), @paycity varchar(30), @paystate varchar(4), @payzip bZip,
        @guid uniqueidentifier, @poslline smallint, @posllinetype tinyint, @po VARCHAR(30), @sl varchar(30), @poslsource bSource,
   		@inusemth bMonth, @inusebatchid bBatchID,@line int,@linetype tinyint,@opencursor tinyint, @jcco bCompany, 
		@job bJob,@phasegroup int, @phase bPhase, @jcctype int,@postclosedjobs bYN, @status tinyint, @contract bContract,
		@dept bDept,@glacct bGLAcct,@closedGLAcct bGLAcct, @poslitem int, @poslitemline int, @postsoftclosedjobs bYN, @paycountry char(2)
   
   
   select @rcode = 0, @numrows = 0, @badrows = 0  -- # of entries added to batch
	if @responsibleperson = '' 
		begin
		select @responsibleperson = NULL
		end
  
   if @co is NULL or @mth is null or @batchid is null
       begin
       select @msg = 'Missing AP Co#, Month, and/or BatchID#!', @rcode = 1
       goto bspexit
       end
   
   if @source not in ('U','R') or @source is null
       begin
       select @msg = 'Invalid Source, must be (U) or (R)!', @rcode = 1
       goto bspexit
       end
   
   if @addordelete not in ('D','A','R') or @addordelete is null
       begin
       select @msg = 'Invalid processing option, must be (D), (A), or (R)!', @rcode = 1
       goto bspexit
       end
   
	if @xpaycontrol is not null 
		begin
		select @xpaycontrol = @xpaycontrol + '%'
		end
   
   
   -- delete all unapproved or recurring invoices from the batch
   if @addordelete = 'D'
       begin
    	if @source = 'U'    -- unapproved invoices
    		begin
		   --Handle switching back the old Attachments TV 10/02/01
--		   update bHQAT set FormName='APUnappInv', TableName = 'APUI'
--		   from bHQAT t join bAPHB b
--		   on t.UniqueAttchID = b.UniqueAttchID
--		   where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid
	   
		   -- delete batch lines
			delete bAPLB
		   from bAPLB l
		   join bAPHB h on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId and h.BatchSeq = l.BatchSeq
		   where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid
			   and h.UIMth is not null and h.UISeq is not null -- identifies unapproved invoices
		   -- delete batch headers
			delete bAPHB
		   where Co = @co and Mth = @mth and BatchId = @batchid and UIMth is not null and UISeq is not null
		   goto bspexit
		end
   
   		if @source = 'R'    -- recurring invoices
    		begin
           -- delete batch lines
    		delete bAPLB
           from bAPLB l
           join bAPHB h on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId and h.BatchSeq = l.BatchSeq
           where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid and h.Vendor = @xvendor and h.InvId=@beginv
           -- delete batch headers
    		delete from bAPHB
           where Co = @co and Mth = @mth and BatchId = @batchid and Vendor = @xvendor and InvId=@beginv
			select @numrows = @@rowcount   -- # of transaction deleted
    		goto bspexit
    		end
    	end
   if @xfreq = ''
		begin
		select @xfreq = null
		end
   -- delete a range of unapproved or recurring invoices from the batch
   if @addordelete = 'R'
    	begin
    	if @source = 'U'    -- unapproved invoices (restrict on UIMth, Vendor, and Seq#)
    		begin
   
--           update bHQAT set FormName='APUnappInv', TableName = 'APUI'
--           from bHQAT t join bAPHB b
--           on t.UniqueAttchID = b.UniqueAttchID
--           where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid
   
           -- delete batch lines
    		delete bAPLB
           from bAPLB l
           join bAPHB h on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId and h.BatchSeq = l.BatchSeq
           where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid
               and h.UIMth = isnull(@xuimth,h.UIMth) and h.UISeq >= isnull(@beginseq,0) and h.UISeq <= isnull(@endseq,9999)
           -- delete batch headers
    		delete bAPHB
           where Co = @co and Mth = @mth and BatchId = @batchid
               and UIMth = isnull(@xuimth,UIMth) and UISeq >= isnull(@beginseq,0) and UISeq <= isnull(@endseq,9999)
           select @numrows = @@rowcount   -- # of transactions deleted
    		goto bspexit
    		end
   
    	if @source = 'R'    -- recurring invoices
    		begin
           -- delete lines
    		delete bAPLB
           from bAPLB l
          	join bAPHB h on h.Co = l.Co and h.Mth = l.Mth and h.BatchId = l.BatchId and h.BatchSeq = l.BatchSeq
           where h.Co = @co and h.Mth = @mth and h.BatchId = @batchid
               and h.Vendor = isnull(@xvendor,h.Vendor) and h.InvId >= isnull(@beginv,h.InvId) and h.InvId <= isnull(@endinv,h.InvId)
           -- delete headers
    		delete bAPHB
           where Co = @co and Mth = @mth and BatchId = @batchid
               and Vendor = isnull(@xvendor,Vendor) and InvId >= isnull(@beginv,InvId) and InvId<=isnull(@endinv,InvId)
   
    		select @numrows = @@rowcount   -- # of transaction deleted
   
    		goto bspexit
    		end
    	end
   
    if @addordelete = 'A'    -- adding recurring or unapproved invoices to the batch
    	begin
    	if @source = 'R'    -- recurring
    		begin
           -- create a cursor on recurring invoices eligible for posting
    		declare bcAPRH cursor LOCAL FAST_FORWARD for
    		select VendorGroup, Vendor, InvId, Description, PayTerms, HoldCode, MnthlyYN, InvDay,
                  PayControl, PayMethod, CMCo, CMAcct, V1099YN, V1099Type, V1099Box, LastMth, LastSeq,
                  InvToDate, ExpDate, InvLimit, UniqueAttchID, AddressSeq, Notes
    		from bAPRH WITH (NOLOCK)
           where APCo = @co and Vendor = isnull(@xvendor,Vendor)
               and	InvId >= isnull(@beginv,InvId) and InvId <= isnull(@endinv,InvId)
    			and (charindex(','+ Frequency + ',',@xfreq) > 0 or @xfreq is null)
    			and (MnthlyYN = 'N' /*or @beginv = @endinv*/ --SR ISSUE 15394
   			 or (MnthlyYN = 'Y' and (LastMth < @mth or LastMth is null)))
               and (isnull(ExpDate,@xinvdate) >= @xinvdate ) --#14231 
           order by VendorGroup, Vendor, InvId
   
    		-- open cursor
    		open bcAPRH
    		select @openAPRH = 1
   
    		next_APRH:
               fetch next from bcAPRH into @vendorgroup, @vendor, @invid, @description, @payterms,
                   @holdcode, @monthly, @invday, @paycontrol, @paymethod, @cmco, @cmacct, @v1099yn,
                   @v1099type, @v1099box, @lastmth, @lastseq, @invtodate, @expdate, @invlimit, @guid,
   					@addressseq, @notes
   
               if @@fetch_status <> 0 goto end_APRH
   
               -- skip if already in a current month batch
               if exists (select TOP 1 1 from bAPHB WITH (NOLOCK) where Co = @co and Mth = @mth and VendorGroup = @vendorgroup
                       and Vendor = @vendor and InvId = @invid) goto next_APRH
   
               -- skip if header has no lines #21959 and #22012
   			select top 1 1 from bAPRL WITH (NOLOCK) where APCo = @co and VendorGroup = @vendorgroup
   				and Vendor = @vendor and InvId = @invid
   			if @@rowcount = 0 
   				begin
   			 	select @badrows = @badrows + 1
   			 	goto next_APRH
   			 	end
   
   			-- #22078/#24974 - get total invoice amount	
   			select @miscamt = isnull(sum(MiscAmt),0) from bAPRL WITH (NOLOCK)
     	            where APCo = @co and VendorGroup = @vendorgroup 
     				and Vendor = @vendor and InvId = @invid and MiscYN = 'Y'
     
     			select @taxamt = isnull(sum(TaxAmt),0) from bAPRL WITH (NOLOCK)
     	            where APCo = @co and VendorGroup = @vendorgroup 
     				and Vendor = @vendor and InvId = @invid and TaxType <> 2
   
     			select @invtotal = isnull(sum(GrossAmt),0) from bAPRL WITH (NOLOCK)
     					 where APCo = @co and VendorGroup = @vendorgroup
     					 and Vendor = @vendor and InvId = @invid
     			select @invtotal = @invtotal + @miscamt + @taxamt
      			if @invtodate + @invtotal > @invlimit and @invlimit <> 0  goto next_APRH
   
   -- 			select @miscamt = sum(MiscAmt) from bAPRL WITH (NOLOCK)
   -- 	            where APCo = @co and VendorGroup = @vendorgroup 
   -- 				and Vendor = @vendor and InvId = @invid and MiscYN = 'Y'
   -- 
   -- 			select @taxamt = sum(TaxAmt) from bAPRL WITH (NOLOCK)
   -- 	            where APCo = @co and VendorGroup = @vendorgroup 
   -- 				and Vendor = @vendor and InvId = @invid and TaxType = 1
   -- 			
   -- 			select @invtotal = isnull(sum(GrossAmt),0) + isnull(@miscamt,0) + isnull(@taxamt,0)
   -- 			            from bAPRL WITH (NOLOCK) where APCo = @co and VendorGroup = @vendorgroup
   -- 						 and Vendor = @vendor and InvId = @invid
   --  			if @invtodate + @invtotal > @invlimit and @invlimit <> 0  goto next_APRH
   
   
               -- reset Invoice, Discount, and Due dates for Monthly Invoices that have an assigned Invoice Day
               select @newdate = @xinvdate
    			if @monthly = 'Y' and @invday > 0 select @newdate = DATEADD(day, @invday - 1, @mth)  -- new invoice date
   
   			-- get Discount and Due dates based on Payment Terms
   			 -- if no payterms default duedate to invdate
   			if isnull(@payterms,'') = '' 
     				begin
     					select @duedate = @newdate, @discdate = null
     				end
     			else	-- get Discount and Due dates based on Payment Terms
     				begin
     	 			exec @rcode = bspHQPayTermsDateCalc @payterms, @newdate, @discdate output, @duedate output,
     	 			    @discrate output, @errmsg output
     	 			if @rcode <> 0
     	 				begin
     	 				select @msg = 'Vendor: ' + isnull(convert(varchar(8),@vendor),'')
    					 + ' Invoice Id: ' + isnull(@invid,'')
    					 + ' - ' + isnull(@errmsg,''), @rcode = 1
                    	goto bspexit
     					end
					-- DueOpt 3 will return a null due date, use invoice date for due date
     				if @duedate is null
     					begin
						-- get DueOpt       
						SELECT @dueopt = DueOpt	FROM dbo.bHQPT with (nolock) WHERE PayTerms = @payterms
						if @dueopt = 3
							begin
     						select @duedate = @newdate
     						end
						else
							begin
							select @msg = 'Vendor: ' + isnull(convert(varchar(8),@vendor),'') 
    						+ ' Invoice Id: ' + isnull(@invid,'')
							+ ' - Unable to set Due Date from Payment Terms.', @rcode = 1
     						goto bspexit	
							end
     	 				end
     				end
   --  			exec @rcode = bspHQPayTermsDateCalc @payterms, @newdate, @discdate output, @duedate output,
   --  			    @discrate output, @errmsg output
   --  			if @rcode <> 0
   --  				begin
   --  				select @msg = 'Vendor: ' + isnull(convert(varchar(8),@vendor),'')
   -- 					 + ' Invoice Id: ' + isnull(@invid,'')
   -- 					 + ' - ' + isnull(@errmsg,''), @badrows = @badrows + 1
   -- 				goto next_APRH	--bspexit
   --  				end
   --  			if @duedate is null
   --  				begin
   --  				select @msg = 'Vendor: ' + isnull(convert(varchar(8),@vendor),'') 
   -- 					+ ' Invoice Id: ' + isnull(@invid,'')
   --                     + ' - Unable to set Due Date from Payment Terms.', @badrows = @badrows + 1
   --  				goto next_APRH	--bspexit
   --  				end
   
   				-- PO/SL inuse check before doing insert
   				-- PO
   				select @poslline = Line, @inusemth = InUseMth, @inusebatchid = InUseBatchId, @po=a.PO
   					from bAPRL a WITH (NOLOCK) join POHD p WITH (NOLOCK) on a.APCo=p.POCo and a.PO=p.PO
   					where APCo = @co and a.VendorGroup = @vendorgroup and a.Vendor = @vendor
   					 and InvId = @invid and a.LineType=6 and p.InUseMth is not null and p.InUseBatchId is not null
   					if @@rowcount > 0 and (@mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid))
   					begin
   						select @poslsource = Source from bHQBC where Co=@co and Mth=@inusemth and BatchId=@inusebatchid
   					 	select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'') 
   								+ ' Invoice: ' + isnull(@invid,'') 
   								+ ' Line: ' + isnull(convert(varchar(3),@poslline),'')
   								+ ' PO: ' + isnull(@po,'') + ' is already in use by Batch: '
   					  			+ isnull(convert(varchar(6),@inusebatchid),'') + ' in month '
   					  			+ isnull(convert(varchar(8),@inusemth),'')	
   								+ ' Source: ' + isnull(@poslsource,''), @badrows = @badrows + 1
   					 	goto next_APRH
   				 	end
   
   				-- SL
   				select @poslline = Line, @inusemth = InUseMth, @inusebatchid = InUseBatchId, @sl=a.SL
   					from bAPRL a WITH (NOLOCK) join SLHD s WITH (NOLOCK) on a.APCo=s.SLCo and a.SL=s.SL
   					where APCo = @co and a.VendorGroup = @vendorgroup and a.Vendor = @vendor and 
   						InvId = @invid and a.LineType=7 and s.InUseMth is not null and s.InUseBatchId is not null
   					if @@rowcount > 0 and (@mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid))
   					begin	
   						select @poslsource = Source from bHQBC where Co=@co and Mth=@inusemth and BatchId=@inusebatchid 	 			
   						select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'') 
   							+ ' Invoice: ' + isnull(@invid,'') 
   							+ ' Line: ' + convert(varchar(3),isnull(@poslline,''))
   							+ ' Subcontract: ' + isnull(@sl,'') + ' is already in use by Batch: '
   				  			+ isnull(convert(varchar(6),@inusebatchid),'') + ' in Month: '
   							+ isnull(convert(varchar(8),@inusemth,1),'')	
   							+ ' Source: ' + isnull(@poslsource,''),@badrows = @badrows + 1
   					 	goto next_APRH
   					end
   
   	   		 -- get AddendaTypeId from Vendor master - #15489, SeparatePayYN #22990
   		   		SELECT @addendatypeid = AddendaTypeId, 
   	    			   @separatepayyn = SeparatePayInvYN, 
   	    			   @payname=Name
				FROM bAPVM WITH (NOLOCK) WHERE VendorGroup=@vendorgroup AND Vendor=@vendor
				--Do not separate payments if the pay method is credit service. 10814
				IF @paymethod = 'S' SELECT @separatepayyn = 'N'

			-- Get addtional address info 
				if isnull(@addressseq,0) > 0 
					begin
					select @payaddinfo=Address2, @payaddress= Address, @paycity=City, @paystate=State, @payzip=Zip,@paycountry=Country
					from bAPAA where VendorGroup=@vendorgroup and Vendor=@vendor and AddressSeq=@addressseq
					end
				else
					begin
					select @payname=null --don't need payname if there's no address seq
					end
   
               -- increment Last Posted Seq# and assign AP Reference
    			select @newrefseq = @lastseq + 1, @apref = @invid + '-' + convert(varchar(10),@newrefseq)
   
               -- get next available batch seq#
    			select @seq = isnull(max(BatchSeq),0) + 1
               from bAPHB WITH (NOLOCK)
               where Co = @co and Mth = @mth and BatchId = @batchid
   
    			begin transaction
   
               -- add batch header
    			insert bAPHB (Co, Mth, BatchId, BatchSeq, BatchTransType, VendorGroup, Vendor, Description,
    				InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl, PayMethod, CMCo, CMAcct,
    				PrePaidYN, PrePaidProcYN, V1099YN, V1099Type, V1099Box, PayOverrideYN, InvId, APRef,
   				AddendaTypeId, UniqueAttchID,AddressSeq, SeparatePayYN, PayName,PayAddInfo,PayAddress,PayCity,
				PayState, PayZip,PayCountry,Notes)
               values(@co, @mth, @batchid, @seq, 'A', @vendorgroup, @vendor, @description,
    				@newdate, @discdate, @duedate, @invtotal, @holdcode, @paycontrol, @paymethod, @cmco, @cmacct,
                   'N','N', @v1099yn, @v1099type, @v1099box, 'N', @invid, @apref, @addendatypeid, @guid,
   				 @addressseq,isnull(@separatepayyn,'N'),@payname,@payaddinfo,@payaddress,@paycity,@paystate,
					@payzip,@paycountry, @notes)
   			if @@rowcount = 0
   				begin
   				select @msg = 'Unable to add bAPHB header for Vendor: ' + isnull(convert(varchar(10),@vendor),'') +
   					 ' Invoice: ' + isnull(@invid,''), @rcode = 1
   				goto error_APRH
                   end				
   			   				      
   			-- loop through APRL lines
			 declare bcAPRLInsert cursor LOCAL FAST_FORWARD for
				select Line,LineType,JCCo,Job,PhaseGroup,Phase,JCCType,GLAcct from bAPRL with (nolock) 
				where APCo = @co and VendorGroup=@vendorgroup and Vendor=@vendor and InvId=@invid 
	    
				open bcAPRLInsert
				select @opencursor = 1

				APRL_loop:
				fetch next from bcAPRLInsert into @line,@linetype,@jcco,@job,@phasegroup,@phase,@jcctype,@glacct
	    
				if @@fetch_status <> 0 goto APRL_end

				-- validate job lines for closed job
				if @linetype = 1 -- Job 
				begin
					select @postclosedjobs = PostClosedJobs, @postsoftclosedjobs = PostSoftClosedJobs
					from bJCCO where JCCo = @jcco 
					select @status=JobStatus,@contract=Contract from bJCJM where JCCo=@jcco and Job=@job
					-- validate for posting to closed jobs
					if @postsoftclosedjobs = 'N' and @status = 2
						begin
						select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'') 
   							+ ' Invoice: ' + isnull(@invid,'') 
   							+ ' Line: ' + convert(varchar(3),isnull(convert(varchar(3),@line),''))
							+ ' Job: ' + isnull(@job,'') + ' is soft-closed. Cannot post to closed Jobs.' 
						goto APRL_loop
						end

					if @postclosedjobs = 'N' and @status = 3
						begin
						select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'') 
   							+ ' Invoice: ' + isnull(@invid,'') 
   							+ ' Line: ' + convert(varchar(3),isnull(convert(varchar(3),@line),''))
							+ ' Job: ' + isnull(@job,'') + ' is hard-closed. Cannot post to closed Jobs.' 
						goto APRL_loop
						end

					if @postclosedjobs = 'Y' and @status = 3
					begin
						-- get the department
						select @dept = Department from bJCCM where JCCo=@jcco and Contract=@contract
						-- get closed GLAcct from phase in Dept override 
						select @closedGLAcct = null
						select @closedGLAcct=ClosedExpAcct from bJCDO where JCCo=@jcco and Department=@dept 
							and PhaseGroup=@phasegroup and Phase=@phase
						if @closedGLAcct is not null
							begin
							select @glacct = @closedGLAcct
							end
						else -- get closed GLAcct from Costtype  
							begin
							select @closedGLAcct=ClosedExpAcct from bJCDC where JCCo=@jcco and Department=@dept
								and PhaseGroup=@phasegroup and CostType=@jcctype
								if @closedGLAcct is not null 
									begin
									select @glacct = @closedGLAcct
									end
								else
									begin
									select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'') 
   										+ ' Invoice: ' + isnull(@invid,'') 
   										+ ' Line: ' + convert(varchar(3),isnull(convert(varchar(3),@line),'')) 
										+ ' Missing closed GL Acct for Job: ' + isnull(@job,'') + ' Phase: ' 
										+ isnull(@phase,'') + ' CT: ' + isnull(convert(varchar(5),@jcctype),'')
									goto APRL_loop
									end
							end 
					end
				end   
               -- insert batch lines
               insert bAPLB (Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, LineType,
                   PO, POItem, POItemLine, ItemType, SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType,
                   EMCo, WO, WOItem, Equip, EMGroup, CostCode, EMCType,CompType, Component,
   				INCo, Loc, MatlGroup,Material, GLCo, GLAcct, Description, UM, Units,
   				UnitCost, ECM, VendorGroup,Supplier, PayType, GrossAmt, MiscYN, MiscAmt,
   				TaxGroup, TaxCode, TaxType,TaxBasis, TaxAmt, Retainage, Discount, PayCategory)
               select @co, @mth, @batchid, @seq, @line, 'A', LineType,
                   PO, POItem,1, ItemType, SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType,
                   EMCo, WO, WOItem, Equip, EMGroup, CostCode, EMCType,CompType, Component,
   				INCo, Loc, MatlGroup,Material, GLCo, @glacct, Description, UM, Units,
   				UnitCost, ECM, @vendorgroup,Supplier, PayType, GrossAmt, MiscYN, MiscAmt,
   				TaxGroup, TaxCode, TaxType,TaxBasis, TaxAmt, Retainage, Discount, PayCategory
               from bAPRL WITH (NOLOCK)
               where APCo = @co and VendorGroup = @vendorgroup and Vendor = @vendor 
				and InvId = @invid and Line=@line
--				if @@error	<> 0
--   				begin
--   				select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'')
--   					 + ' Invoice: ' + isnull(@invid,'')
--   					 + ' ' + isnull(@msg,''), @rcode = 1
--                   end	
				goto APRL_loop	
    
			APRL_end:
			if @opencursor = 1
			begin   
				close bcAPRLInsert
    			deallocate bcAPRLInsert
    			select @opencursor = 0
			end

			-- delete if header has no lines 
   			if not exists(select * from APLB with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq)
   				begin
				rollback transaction
   			 	goto next_APRH
   			 	end
			else -- finish up current APRH and commit the transaction
				BEGIN
				--BatchUserMemoUpdateAPHBadd - header
   	            exec @rcode =  bspBatchUserMemoUpdateAPHBadd @co, @mth, @batchid, @seq, 'APRH',@msg output
   	             if @rcode <> 0
   					 begin
   					   select @msg = 'Unable to update Recuring User Memos in APHB', @rcode = 1
   					   goto error_APRH
   					 end
               --BatchUserMemoUpdateAPHBadd - lines
               exec @rcode =  bspBatchUserMemoUpdateAPHBadd @co, @mth, @batchid, @seq, 'APRL',@msg output
                if @rcode <> 0
					  begin
					  select @msg = 'Unable to update Recurring User Memos in APLB', @rcode = 1
					  goto error_APRH
					  end
		
				-- update Last Posted Seq# in Recurring Invoice Header
    			update bAPRH
               set LastSeq = @newrefseq
               where APCo = @co and VendorGroup = @vendorgroup and	Vendor = @vendor and @invid = InvId
               if @@rowcount <> 1
                   begin
                   select @msg = 'Unable to update Last Seq# in Recurring Invoice Header.', @rcode = 1
                   goto error_APRH
                   end
				END         
			   
               commit transaction  -- header and all lines added, APRH updated
   
    			select @numrows = @numrows + 1 -- # of invoices added to batch
   
               goto next_APRH  -- next recurring invoice
   
           error_APRH: -- handle error during transaction
               rollback transaction
               goto bspexit
   
           end_APRH:   -- finished with recurring invoices
               close bcAPRH
               deallocate bcAPRH
   
               select @openAPRH = 0
    		end

   
       -- Add eligible unapproved invoices
    	if @source = 'U'
    		begin
    		-- create cursor on unapproved invoices
    		declare bcAPUI cursor LOCAL FAST_FORWARD for
		    select UIMth, UISeq, VendorGroup, Vendor, InvDate, DueDate, PayMethod 
    		from bAPUI WITH (NOLOCK) 
			where APCo = @co and UIMth = isnull(@xuimth,UIMth)
               and UISeq >= isnull(@beginseq,0) and UISeq <= isnull(@endseq,9999)
               and Vendor = isnull(@xvendor,Vendor)
			   and isnull(PayControl,'') like isnull(@xpaycontrol, isnull(PayControl,''))
               and InUseMth is null and InUseBatchId is null   -- skip if already in a batch
            order by UIMth, UISeq
   
    		-- open cursor
    		open bcAPUI
    		select @openAPUI = 1
   
    		next_APUI:
               fetch next from bcAPUI into @uimth, @uiseq, @vendorgroup, @vendor, @invdate, @duedate, @paymethod
   
               if @@fetch_status <> 0 goto end_APUI

			-- If selecting by Responsible Person, check if the APUL Line's ReviewerGroup's responsible person = @responsibleperson
			-- if there is no line RG use header RG. 
			if @responsibleperson is not null
			begin
				select 1 from bAPUR r WITH (NOLOCK) 
					join bAPUL l on r.APCo=l.APCo and r.UIMth=l.UIMth and r.UISeq=l.UISeq and r.Line=l.Line
					join bAPUI i on i.APCo=l.APCo and i.UIMth=l.UIMth and i.UISeq=l.UISeq  
					join vHQRG g WITH (NOLOCK) on isnull(l.ReviewerGroup,i.ReviewerGroup)=g.ReviewerGroup 
				where g.ResponsiblePerson=@responsibleperson 
					and	r.APCo=@co and r.UIMth=@uimth and r.UISeq=@uiseq and r.Line <> -1
				if @@rowcount = 0
				begin
				goto next_APUI
				end
			end
   
               -- check required header info
               if @vendor is null or @invdate is null or @duedate is null or @paymethod is null
   			 begin
   			 select @badrows = @badrows + 1
   			 goto next_APUI
   			 end
   
               -- must have an unapproved reviewer entry
               if not exists(select top 1 1 from bAPUR WITH (NOLOCK) where APCo = @co and UIMth = @uimth and UISeq = @uiseq
   							and ExpMonth is null and APTrans is null)
   			 begin
   			 select @badrows = @badrows + 1
   			 goto next_APUI
   			 end
   
   			-- a header must have at least one line #22012
   			select top 1 1 from bAPUL WITH (NOLOCK) where APCo = @co and UIMth = @uimth and UISeq = @uiseq
   			if @@rowcount = 0
   				begin
   			 	select @badrows = @badrows + 1
   			 	goto next_APUI
   			 	end
   
               -- all reviewer entries must be approved 
               if exists(select top 1 1 from bAPUR WITH (NOLOCK) where APCo = @co and UIMth = @uimth and
   				 UISeq = @uiseq  and Line <> -1	and ExpMonth is null and APTrans is null and ApprvdYN <> 'Y') 
   				begin
   			 	select @badrows = @badrows + 1
   			 	goto next_APUI
   			 	end
   
               -- check required line info
               if exists(select top 1 1 from bAPUL l WITH (NOLOCK)
				   join bAPUI i WITH (NOLOCK) on i.APCo = l.APCo and i.UIMth = l.UIMth and i.UISeq = l.UISeq
                   where i.APCo = @co and i.UIMth = @uimth and i.UISeq = @uiseq
                   and (l.GLCo is null or l.GLAcct is null))    -- missing GL info
   				begin
   			 	select @badrows = @badrows + 1
   			 	goto next_APUI
   			 	end
   
               if exists(select top 1 1 from bAPUL l WITH (NOLOCK) 
               join bAPUI i WITH (NOLOCK) on i.APCo = l.APCo and i.UIMth = l.UIMth and i.UISeq = l.UISeq
                   where i.APCo = @co and i.UIMth = @uimth and i.UISeq = @uiseq
                   and ((l.LineType = 1 or (l.LineType = 6 and l.ItemType = 1) or l.LineType = 7)
                  and (l.JCCo is null or l.Job is null or l.PhaseGroup is null or l.Phase is null
                       or l.JCCType is null)))   -- missing JC info
   					begin
   				 	select @badrows = @badrows + 1
   				 	goto next_APUI
   				 	end
               if exists(select top 1 1 from bAPUL l WITH (NOLOCK) 
               join bAPUI i WITH (NOLOCK)  on i.APCo = l.APCo and i.UIMth = l.UIMth and i.UISeq = l.UISeq
                   where i.APCo = @co and i.UIMth = @uimth and i.UISeq = @uiseq
                   and ((l.LineType = 4 or (l.LineType = 6 and (l.ItemType = 4 or l.ItemType = 5)) or l.LineType = 5)
                       and (l.EMCo is null or l.Equip is null or l.EMGroup is null or l.CostCode is null
                           or l.EMCType is null))) -- missing EM info
   					begin
   				 	select @badrows = @badrows + 1
   				 	goto next_APUI
   				 	end
   
               if exists(select top 1 1 from bAPUL l WITH (NOLOCK) 
               join bAPUI i WITH (NOLOCK) on i.APCo = l.APCo and i.UIMth = l.UIMth and i.UISeq = l.UISeq
                   where i.APCo = @co and i.UIMth = @uimth and i.UISeq = @uiseq
                   and ((l.LineType = 2 or (l.LineType = 6 and l.ItemType = 2))
                       and (l.INCo is null or l.Loc is null or l.Material is null)))   -- missing IN info
   					begin
   				 	select @badrows = @badrows + 1
   				 	goto next_APUI
   				 	end
               if exists(select top 1 1 from bAPUL l WITH (NOLOCK) join bAPUI i WITH (NOLOCK) on i.APCo = l.APCo and i.UIMth = l.UIMth and i.UISeq = l.UISeq
                   where i.APCo = @co and i.UIMth = @uimth and i.UISeq = @uiseq
                   and (((l.LineType = 5 or (l.LineType = 6 and l.ItemType = 5)) and (l.WO is null or l.WOItem is null)) -- missing WO info
                       or (l.LineType = 6 and (l.PO is null or l.POItem is null or l.POItemLine is null))  -- missing PO info - CHS 08/10/2011	- B-05526
                       or (l.LineType = 7 and (l.SL is null or l.SLItem is null))))  -- missing SL info
   					begin
   				 	select @badrows = @badrows + 1
   				 	goto next_APUI
   				 	end
   			-- PO/SL in use check before doing insert 
   			-- PO
   			select @poslline = Line, @inusemth = InUseMth, @inusebatchid = InUseBatchId, @po=a.PO
   				from bAPUL a with (nolock)join POHD p with (nolock)	on a.APCo=p.POCo and a.PO=p.PO
   				where a.APCo = @co and UIMth = @uimth and UISeq = @uiseq and LineType=6
   				 and p.InUseMth is not null and p.InUseBatchId is not null
   				if @@rowcount > 0 and (@mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid))
   					begin
   					select @poslsource = Source from bHQBC where Co=@co and Mth=@inusemth and BatchId=@inusebatchid
   			 		select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'') 
   						+ ' UIMth: ' + isnull(convert(varchar(8),@uimth,1),'')
   						+ ' UISeq: ' + isnull(convert(varchar(3),@uiseq),'') 
   						+ ' Line: ' + isnull(convert(varchar(3),@poslline),'')
   						+ ' PO: ' + isnull(@po,'') + ' is already in use by Batch: '
   			  			+ isnull(convert(varchar(6),@inusebatchid),'') + ' in month '
   			  			+ isnull(convert(varchar(8),@inusemth,1),'')	
   						+ ' Source: ' + isnull(@poslsource,''), @badrows = @badrows + 1
              			goto next_APUI
   			 		end
			-- Check if PO Item exists
			select @poslline = Line, @po=PO, @poslitem=POItem, @poslitemline=POItemLine from APUL where APCo=@co and UIMth=@uimth and UISeq=@uiseq and LineType=6
				and not exists(select * from POItemLine i join APUL l on i.POCo=l.APCo and i.PO=l.PO and i.POItemLine=l.POItemLine
					where l.APCo=@co and l.UIMth=@uimth and l.UISeq=@uiseq)
				if @@rowcount > 0 
				begin
				select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'') 
   						+ ' UIMth: ' + isnull(convert(varchar(8),@uimth,1),'')
   						+ ' UISeq: ' + isnull(convert(varchar(3),@uiseq),'') 
   						+ ' Line: ' + isnull(convert(varchar(3),@poslline),'')
   						+ ' PO: ' + isnull(@po,'') 
						+ ' PO Item: ' + isnull(convert(varchar(3),@poslitem),'') 
						+ ' PO Item Line: ' + isnull(convert(varchar(3),@poslitemline),'') 
						+ ' does not exist in POItemLine.', @badrows = @badrows + 1
              			goto next_APUI
				end

			-- if PO item has a taxcode validate it
			if exists (select * from POItemLine i 
			join APUL l on i.POCo=l.APCo and i.PO=l.PO and i.POItem=l.POItem  and i.POItemLine=l.POItemLine
				where APCo=@co and UIMth=@uimth and UISeq=@uiseq and LineType=6 and i.TaxCode is not null)
			begin
			-- DC 01/30/08 - #126458 Check if PO Item has a valid tax code
			select @poslline = Line, @po=PO, @poslitem=POItem, @poslitemline=POItemLine  
			from APUL where APCo=@co and UIMth=@uimth and UISeq=@uiseq and LineType=6
--				and TaxCode is not null 
				and not exists(select * from POItemLine i join APUL l on i.POCo=l.APCo and i.PO=l.PO and i.POItem=l.POItem and i.POItemLine=l.POItemLine
								join HQTX t on i.TaxGroup = t.TaxGroup and i.TaxCode = t.TaxCode
								where l.APCo=@co and l.UIMth=@uimth and l.UISeq=@uiseq)
				if @@rowcount > 0 
				begin
				select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'') 
   						+ ' UIMth: ' + isnull(convert(varchar(8),@uimth,1),'')
   						+ ' UISeq: ' + isnull(convert(varchar(3),@uiseq),'') 
   						+ ' Line: ' + isnull(convert(varchar(3),@poslline),'')
   						+ ' PO: ' + isnull(@po,'') 
						+ ' PO Item: ' + isnull(convert(varchar(3),@poslitem),'') 
						+ ' PO Item Line: ' + isnull(convert(varchar(3),@poslitemline),'') 
						+ ' has an invalid Tax Code.', @badrows = @badrows + 1
              			goto next_APUI
				end
			end
			
   			-- SL
   			select @poslline = Line, @inusemth = InUseMth, @inusebatchid = InUseBatchId, @sl=a.SL
   				from bAPUL a with (nolock)join SLHD s with (nolock)	on a.APCo=s.SLCo and a.SL=s.SL
   				where a.APCo = @co and UIMth = @uimth and UISeq = @uiseq and LineType=7
   				 and s.InUseMth is not null and s.InUseBatchId is not null
   				if @@rowcount > 0 and (@mth <> isnull(@inusemth,@mth) or @batchid <> isnull(@inusebatchid,@batchid))
   		            begin	
   					select @poslsource = Source from bHQBC where Co=@co and Mth=@inusemth and BatchId=@inusebatchid 	 			
   					select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'') 
   						+ ' UIMth: ' + isnull(convert(varchar(8),@uimth,1),'')
   						+ ' UISeq: ' + isnull(convert(varchar(3),@uiseq),'') 
   						+ ' Line: ' + isnull(convert(varchar(3),@poslline),'')
   						+ ' Subcontract: ' + isnull(@sl,'') + ' is already in use by Batch: '
   			  			+ isnull(convert(varchar(6),@inusebatchid),'') + ' in Month: '
   						+ isnull(convert(varchar(8),@inusemth,1),'')	
   						+ ' Source: ' + isnull(@poslsource,''), @badrows = @badrows + 1
              			goto next_APUI
   			 		end
			-- Check if SL Item exists
			select @poslline = Line, @sl=SL, @poslitem=SLItem 
			from APUL 
			where APCo=@co and UIMth=@uimth and UISeq=@uiseq and LineType=7
				and not exists(select * from SLIT i join APUL l on i.SLCo=l.APCo and i.SL=l.SL and i.SLItem=l.SLItem
					where l.APCo=@co and l.UIMth=@uimth and l.UISeq=@uiseq)
				if @@rowcount > 0 
				begin
				select @msg = 'Vendor: ' + isnull(convert(varchar(10),@vendor),'') 
   						+ ' UIMth: ' + isnull(convert(varchar(8),@uimth,1),'')
   						+ ' UISeq: ' + isnull(convert(varchar(3),@uiseq),'') 
   						+ ' Line: ' + isnull(convert(varchar(3),@poslline),'')
   						+ ' SL: ' + isnull(@sl,'') 
						+ ' SL Item: ' + isnull(convert(varchar(3),@poslitem),'') 
						+ ' does not exist in SLIT.', @badrows = @badrows + 1
              			goto next_APUI
				end
  
            -- passed validation, get next available batch seq#
			select @seq = isnull(max(BatchSeq),0) + 1
			from bAPHB WITH (NOLOCK)
			where Co = @co and Mth = @mth and BatchId = @batchid

    		begin transaction
   
			-- insert batch header, insert trigger will update bAPUI 'inusebatch' info
			insert bAPHB(Co, Mth, BatchId, BatchSeq, BatchTransType, VendorGroup, Vendor, APRef,
				Description, InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl, PayMethod,
				CMCo, CMAcct, PrePaidYN,PrePaidProcYN, V1099YN, V1099Type, V1099Box, PayOverrideYN, PayName, PayAddInfo,
				PayAddress, PayCity, PayState, PayZip,PayCountry, UIMth, UISeq, SeparatePayYN, UniqueAttchID,AddressSeq, Notes,
				SLKeyID)
			select @co, @mth, @batchid, @seq, 'A',  VendorGroup, Vendor, APRef,
				Description, InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl, PayMethod,
				CMCo, CMAcct, 'N','N', V1099YN, V1099Type, V1099Box, PayOverrideYN, PayName, PayAddInfo,
				PayAddress, PayCity, PayState, PayZip, PayCountry,UIMth, UISeq, SeparatePayYN, UniqueAttchID,AddressSeq, Notes,
				SLKeyID
			from bAPUI WITH (NOLOCK)
			where APCo = @co and UIMth = @uimth and UISeq = @uiseq
			if @@rowcount <> 1
				begin
				select @msg = 'Unable to add AP Batch Header', @rcode = 1
				goto error_APRH
				end
   			else	-- #21959
   				begin
   	            --BatchUserMemoUpdateAPHBadd
   	            exec @rcode =  bspBatchUserMemoUpdateAPHBadd @co, @mth, @batchid, @seq, 'APUI',@msg output
   	             if @rcode <> 0
   	             begin
   	               select @msg = 'Unable to update Unapproved User Memos in APHB', @rcode = 1
   	               goto error_APRH
   	               end
   				end
   
                -- insert batch lines
    			INSERT dbo.bAPLB 
    				(
    					Co,				Mth,			BatchId,		BatchSeq,
    					APLine,			BatchTransType, LineType,		PO,
    					POItem,			POItemLine,		SL,				ItemType,
    					SLItem,			JCCo,			Job,			PhaseGroup,
    					Phase,			JCCType,		EMCo,			WO,
    					WOItem,			Equip,			EMGroup,		CostCode,
    					EMCType,		CompType,		Component,		INCo,
    					Loc,			MatlGroup,		Material,		GLCo, 
    					GLAcct,			Description,	UM,				Units, 
    					UnitCost,		ECM,			VendorGroup,	Supplier,
    					PayType,		GrossAmt,		MiscYN,			MiscAmt, 
    					TaxGroup,		TaxCode,		TaxType,		TaxBasis,
    					TaxAmt,			Retainage,		Discount,		Notes,
    					PayCategory,	Receiver#,		SLDetailKeyID,	SLKeyID,
    					SMCo,			SMWorkOrder,	Scope,			SMCostType,
						SMJCCostType,	SMPhaseGroup,	SMPhase
					)
				SELECT	@co,			@mth,			@batchid,		@seq, 
						Line,			'A',			LineType,		PO, 
						POItem,			POItemLine,		SL,				case LineType when 6 then ItemType else null end, -- issue #11866 - ItemType on POs only
						SLItem,			JCCo,			Job,			PhaseGroup,
						Phase,			JCCType,		EMCo,			WO, 
						WOItem,			Equip,			EMGroup,		CostCode, 
						EMCType,		CompType,		Component,		INCo, 
						Loc,			MatlGroup,		Material,		GLCo, 
						GLAcct,			Description,	UM,				Units, 
						UnitCost,		ECM,			@vendorgroup,	Supplier,
						PayType,		GrossAmt,		MiscYN,			MiscAmt, 
						TaxGroup,		TaxCode,		TaxType,		TaxBasis, 
						TaxAmt,			Retainage,		Discount,		Notes, 
						PayCategory,	Receiver#,		SLDetailKeyID,	SLKeyID,
						SMCo,			SMWorkOrder,	Scope,			SMCostType,
						SMJCCostType,	SMPhaseGroup,	SMPhase
    			FROM dbo.bAPUL l  
				WHERE l.APCo = @co AND l.UIMth = @uimth AND l.UISeq = @uiseq
   			if @@rowcount > 0	-- #21959	
   			begin
   				-- update SubjToOnCost per business logic:
   				--	1. if bAPVM has a value in OnCostCostType that matches the JC CostType in the line then SubjToOnCostYN = Y.  This
   				--		assumes the logic that any line with a Job value MUST have a JC Cost Type.
   				--	2. if the line does not have a Job value/JC Cost Type value BUT bAPVM SubjToOnCostYN = Y then SubjToOnCostYN = Y in the line.
   				UPDATE dbo.bAPLB
   				SET SubjToOnCostYN = 'Y'
   				FROM dbo.bAPLB l
   				JOIN dbo.bAPHB h ON l.Co=h.Co AND l.Mth=h.Mth AND l.BatchId=h.BatchId AND l.BatchSeq=h.BatchSeq
   				JOIN dbo.bAPVM m ON m.VendorGroup = h.VendorGroup AND m.Vendor=h.Vendor
   				WHERE l.Co=@co AND l.Mth=@mth AND l.BatchId=@batchid AND l.BatchSeq=@seq	
   					AND 
						(
							(	-- job type line with vendor ct
								l.JCCType IS NOT NULL AND m.OnCostCostType IS NOT NULL AND l.JCCType = m.OnCostCostType
							)
						OR
							(	-- job type line with no vendor ct
								l.JCCType IS NOT NULL AND m.OnCostCostType IS NULL AND m.SubjToOnCostYN = 'Y'
							)
						OR
							(	-- non job type line
								l.JCCType IS NULL AND l.Job IS NULL AND m.SubjToOnCostYN = 'Y'
							)
						)
   					
               --BatchUserMemoUpdateAPHBadd
               exec @rcode =  bspBatchUserMemoUpdateAPHBadd @co, @mth, @batchid, @seq, 'APUL',@msg output
                if @rcode <> 0
                begin
                  select @msg = 'Unable to update Unapproved User Memos in APLB', @rcode = 1
                  goto error_APRH
                end
   			end
               -- this code is for document attachments, the form name and keyfield of HQAT table has to be updated
               -- if any attachments exists in this batch. The update to bHQAT must be done in order to show all
               -- all the attachments in APEntry program
   
--                update bHQAT set FormName='APEntry', TableName = 'APHB'
--                from bHQAT t join bAPHB b
--                on t.UniqueAttchID = b.UniqueAttchID
--                where b.Co = @co and b.Mth = @mth and b.BatchId = @batchid
   
               commit transaction
   
          select @numrows = @numrows + 1  -- # of invoices added to batch
   
    		    goto next_APUI   -- next unapproved invoice
   
           end_APUI:   -- finished with unapproved invoices
               close bcAPUI
               deallocate bcAPUI
               select @openAPUI = 0
    		end
       end
   
   bspexit:
       if @openAPRH = 1
    		begin
    		close bcAPRH
     		deallocate bcAPRH
    		end
       if @openAPUI = 1
           begin
           close bcAPUI
           deallocate bcAPUI
           end
   
    	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspAPHBAdd] TO [public]
GO
