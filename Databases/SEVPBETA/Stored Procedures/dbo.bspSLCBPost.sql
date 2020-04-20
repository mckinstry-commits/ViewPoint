SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************************/
   CREATE   procedure [dbo].[bspSLCBPost]
   /************************************************************************
   * Posts a validated batch of SLCB entries
   *
   * Modified: GG 04/22/99     (SQL 7.0)
   *           GR 08/18/00 Added notes to insert into SLCD table Issue#9470
   *           GR 09/25/00 Added document attachments code
   *           GF 02/10/2001 - change the update to PMSL interface date to be more restrictive
   *           GF 03/23/2001 - fix to interface update from source PM Interface, wrap or in ()
   *           MV 06/15/01   - Issue 12769 - BatchUserMemoUpdate
   *           GF 07/09/2001 - Fix for updating notes, the join clause was incorrect.
   *           GF 07/10/2001 - Issue #13913, set interface date to null, SendFlag to 'N' when deleting and exists in PMSL.
   *           TV/RM 02/22/02 - Attachment Fix
   *           CMW 03/15/02 - issue # 16503 JCCP column name changes.
   *           CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
   *			GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
   *			GG 06/11/02 - #17564 - insert bJCCD.PostedUnits = 0
   *			MV 08/26/03 - #21916 - insert JCCD even if curunits, costs = 0, performance enhancements
   *			RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
   *			RT 12/03/03 - issue 18616, reindex attachments when posting type A or C batches.
   *			GF 01/15/2003 - issue #20976 - added PMSLSeq to SLCB table for updates back to PM for pending change orders.
   *			ES 04/07/04 - #24219 make sure notes update properly and simplify code
   *			MV 05/24/04 - #24662 - clear InUseBatchId, InUseMth in bSLIT before deleting from bSLCB.
   *			MV 09/03/04 - #25400 - change @description datatype from bDesc to bItemDesc
   *			GF 12/21/2004 - issue #26539 update PMSL.SLItemDescripton when updating PMSL record.
   *			MV 05/31/05 - #28778 - back out old amounts from SLIT when deleting a change order.
	*			DC 07/16/08 - #128435 - Add Taxes to SL for international
	*			DC 10/23/08 - #130749 - Remove Committed Cost flag
   *			GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
   *			DC 11/11/08 - #130029 - JCCD tax amounts doesn't match SLIT after tax rate change
   *			DC 04/30/09 - Modified sp to match the logic that PO Change Order uses for taxes
   *			DC 05/15/09 - #133440 - Ensure stored procedures/triggers are using the correct attachment delete proc
   *			DC 7/8/09  - #134205 - SL Change Order - Add JC Committed Tax to SLCD
   *			DC 12/29/09 - #130175 - SLIT needs to match POIT
   *			DC 06/24/10 - #135813 - expand subcontract number
   *			GF 04/23/2011 - TK-04407 issue #143372
   *
   *
   * pass in Co#, Month, Batch ID#, and Posting Date
   *
   * deletes successfully posted bSLCB rows
   * clears bHQCC when complete
   *
   * returns 1 and message if error
   ************************************************************************/   
   (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @source bSource, @errmsg varchar(255) output)
   
     as
     set nocount on
   
DECLARE @rcode int, @opencursor tinyint, @tablename char(20),
	@inuseby bVPUserName, @status tinyint, @adj bYN, @seq int, --DC #130749  @cmtddetailtojc bYN,     	
	@transtype char(1), @lastseq int, @sltrans bTrans, @changecurunits bUnits, 
	@chgcurunitcost bUnitCost, @changecurcost bDollar, @sl VARCHAR(30), --bSL,  DC #135813
	@slitem bItem, @oldnew tinyint, @slchangeorder smallint, @appchangeorder varchar(10), 
	@actdate bDate, @um bUM, @description bItemDesc, @jcco bCompany,
	@jctrans bTrans, @job bJob, @phase bPhase, @phasegroup bGroup, @jcctype bJCCType,
	@vendorgroup bGroup, @vendor bVendor, @jcum bUM, @jcunits bUnits, @errors varchar(30),
	@count int, @oldcurunits bUnits, @oldunitcost bUnitCost, @oldcurcost bDollar, @pmco bCompany,
	@errflag char(1), @keyfield varchar(128), @updatekeyfield varchar(128), @deletekeyfield varchar(128),
	@guid uniqueIdentifier, @Notes varchar(256), @pmslseq int,
	@chgtotax bDollar,  --DC #128435
	@taxgroup bGroup, @taxcode bTaxCode, @taxrate bRate,  --DC #128435
	--@taxphase bPhase, @taxjcct bJCCType,   DC #130175
	@HQTXdebtGLAcct bGLAcct,
	@chgtojccmtdtax bDollar,  --DC #134205
	@slcaopencursor tinyint  --DC #130175
	
    --DC #130029 Tax declares TK-04407 #143372
DECLARE @retcode INT, @retmsg VARCHAR(255), @gstrate bRate, @pstrate bRate  --DC #130029
--DECLARE @valueadd char(1)  DC #130175
DECLARE @totalcmtdtax bDollar, @remcmtdtax bDollar  --DC #130175   
   
	SELECT @rcode = 0, @retcode = 0
   
	/* set open cursor flag to false */
	SELECT @opencursor = 0,
			@slcaopencursor = 0  --DC#130175
	   
	/* check for date posted */
	IF @dateposted is null
		BEGIN   
		SELECT @errmsg = 'Missing posting date!', @rcode = 1
		goto bspexit
		END
		
     /* select @source='SL Change' - Changed @source to be an input parameter */
     /* validate HQ Batch */
     exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'SLCB', @errmsg output, @status output
     IF @rcode <> 0
     	BEGIN
        SELECT @errmsg = @errmsg, @rcode = 1
        goto bspexit
		END
   
     IF @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
     	BEGIN
     	SELECT @errmsg = 'Invalid Batch status -  must be (valid - OK to post) or (posting in progress)!', @rcode = 1
     	goto bspexit
     	END
   
     /* set HQ Batch status to 4 (posting in progress) */
     UPDATE bHQBC
     SET Status = 4, DatePosted = @dateposted
     WHERE Co = @co and Mth = @mth and BatchId = @batchid
      
     IF @@rowcount = 0
     	BEGIN
     	SELECT @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
     	goto bspexit   
     	END
     	   
	/* declare cursor on SL Change Batch for posting */
	declare bcSLCB cursor LOCAL FAST_FORWARD for 
		SELECT BatchSeq, BatchTransType, SLTrans, SL, SLItem,
			SLChangeOrder, AppChangeOrder, ActDate, Description, UM, ChangeCurUnits,
			CurUnitCost, ChangeCurCost, OldCurUnits, OldUnitCost, OldCurCost, UniqueAttchID, PMSLSeq,
			ChgToTax,  --DC #128435
			ChgToJCCmtdTax  --DC #134205
		FROM bSLCB WITH (NOLOCK) 
		WHERE Co = @co and Mth = @mth and BatchId = @batchid 
   
	/* open cursor */
	open bcSLCB
   
	/* set open cursor flag to true */
	SELECT @opencursor = 1
   
	/* loop through all rows in this batch */
	posting_loop:
	fetch next from bcSLCB into @seq, @transtype, @sltrans, @sl, @slitem, 
		@slchangeorder, @appchangeorder, @actdate, @description, @um, @changecurunits, 
		@chgcurunitcost, @changecurcost, @oldcurunits, @oldunitcost, @oldcurcost, @guid, @pmslseq,
		@chgtotax,  --DC #128435
		@chgtojccmtdtax  --DC #134205
   
	IF @@fetch_status = -1 goto jcposting_loop
   
	IF @@fetch_status <> 0 goto posting_loop
   
	IF (@lastseq=@seq)
		BEGIN
		SELECT @errmsg='Same Seq repeated, cursor error.', @rcode=1
		goto bspexit
		END

	--DC #128435
	--Get tax info from SLIT
	SELECT @taxgroup = TaxGroup, @taxcode = TaxCode,
			@taxrate = TaxRate, @gstrate = GSTRate  --DC #130175
	FROM SLIT WITH (NOLOCK)
	WHERE SL = @sl and SLItem = @slitem and SLCo = @co
   
	BEGIN transaction
 	IF @transtype = 'A'	/* add new SL change detail transactions */
		BEGIN
 		/* get next available transaction # for SLCD */
 		SELECT @tablename = 'bSLCD'
 		exec @sltrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
		IF @sltrans = 0
			BEGIN
 			SELECT @errors = isnull(@errors,'') + ' T:' + isnull(convert(varchar(5), @seq),''), @errflag ='p'
   		   	goto posting_error
 		   	END

 		/* insert SL Change Detail */
 		INSERT bSLCD (SLCo, Mth, SLTrans, SL, SLItem, SLChangeOrder, AppChangeOrder, ActDate,
 			Description, UM, ChangeCurUnits, ChangeCurUnitCost, ChangeCurCost, PostedDate,
 			BatchId, InUseBatchId, UniqueAttchID, Notes, 
			ChgToTax, --DC #128435
			ChgToJCCmtdTax)  --DC #134205
 		SELECT @co, @mth, @sltrans, @sl, @slitem, @slchangeorder, @appchangeorder, @actdate,
 			@description, @um, @changecurunits, @chgcurunitcost, @changecurcost, @dateposted,
 			@batchid, null, @guid, Notes, 
			@chgtotax,  --DC #128435
			@chgtojccmtdtax  --DC #134205
		FROM bSLCB WITH (NOLOCK)
		WHERE Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@seq 

 		IF @@rowcount = 0
			BEGIN
   		    SELECT @errors = isnull(@errors,'') + ' A:' + isnull(convert(varchar(5), @seq),''), @errflag ='p'
   		    goto posting_error
			END

		--update sltrans# in the batch record for BatchUserMemoUpdate
		UPDATE bSLCB 
		SET SLTrans = @sltrans
		WHERE Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq

		-- get Tax Rate
		SELECT @pstrate = 0  --DC #130175

		--DC #130175
		----TK-04407 #143372
		exec @retcode = vspHQTaxRateGet @taxgroup, @taxcode, @actdate, NULL, NULL, NULL, NULL, 
			NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @retmsg output
				
		SELECT @pstrate = (case when @gstrate = 0 then 0 else @taxrate - @gstrate end)					

 		UPDATE bSLIT
 		SET CurUnits=CurUnits+@changecurunits, 
 			CurUnitCost=CurUnitCost+@chgcurunitcost,
			CurCost= Case when @um='LS' then CurCost+@changecurcost else (CurUnits+@changecurunits)*(CurUnitCost+@chgcurunitcost) end,
			CurTax = (Case when @um='LS' then CurCost+@changecurcost else (CurUnits+@changecurunits)*(CurUnitCost+@chgcurunitcost) end) * @taxrate, 
			JCCmtdTax = (Case when @um='LS' then CurCost+@changecurcost else (CurUnits+@changecurunits)*(CurUnitCost+@chgcurunitcost) end) * (case when @HQTXdebtGLAcct is null then @taxrate else @pstrate end),    			     			
			JCRemCmtdTax = (Case when @um='LS' then (CurCost-InvCost)+@changecurcost else ((CurUnits-InvUnits)+@changecurunits)*(CurUnitCost+@chgcurunitcost) end) * (case when @HQTXdebtGLAcct is null then @taxrate else @pstrate end)   --DC #130175
		WHERE SLCo=@co and SL=@sl and SLItem=@slitem

 		END
   
 	IF @transtype = 'C'	/* update existing SL transaction */
 		BEGIN
 		UPDATE bSLCD
 		SET SLChangeOrder = @slchangeorder, AppChangeOrder=@appchangeorder, ActDate = @actdate,
 			Description = @description, UM = @um, ChangeCurUnits=@changecurunits,
 			ChangeCurUnitCost=@chgcurunitcost, ChangeCurCost=@changecurcost,
 			BatchId = @batchid, InUseBatchId = null, UniqueAttchID = @guid, Notes = b.Notes,
			ChgToTax = @chgtotax,  --DC #128435
			ChgToJCCmtdTax = @chgtojccmtdtax  --DC #134205
		FROM bSLCD d 
			join bSLCB b on d.SLCo=b.Co and d.Mth = b.Mth and b.SLTrans=d.SLTrans
 		WHERE b.Co = @co and b.Mth = @mth and b.SLTrans = @sltrans

		--DC #130175
		-- get Tax Rate
		SELECT @pstrate = 0  --DC #130175

		--DC #130175
		----TK-04407 #143372
		exec @retcode = vspHQTaxRateGet @taxgroup, @taxcode, @actdate, NULL, NULL, NULL, NULL, 
			NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @retmsg output
				
		SELECT @pstrate = (case when @gstrate = 0 then 0 else @taxrate - @gstrate end)			

 		UPDATE bSLIT
		SET CurUnits=CurUnits+@changecurunits-@oldcurunits,
 			CurUnitCost=CurUnitCost+@chgcurunitcost-@oldunitcost,
 			CurCost= Case when @um='LS' then CurCost+@changecurcost-@oldcurcost else (CurUnits+@changecurunits-@oldcurunits)*(CurUnitCost+@chgcurunitcost-@oldunitcost) end,
			CurTax = (Case when @um='LS' then CurCost+@changecurcost-@oldcurcost else (CurUnits+@changecurunits-@oldcurunits)*(CurUnitCost+@chgcurunitcost-@oldunitcost) end)*@taxrate, 
 			JCCmtdTax = (Case when @um='LS' then CurCost+@changecurcost-@oldcurcost else (CurUnits+@changecurunits-@oldcurunits)*(CurUnitCost+@chgcurunitcost-@oldunitcost) end)*(case when @HQTXdebtGLAcct is null then @taxrate else @pstrate end),  --DC #128435                
 			JCRemCmtdTax = (Case when @um='LS' then (CurCost-InvCost)+@changecurcost-@oldcurcost else ((CurUnits-InvUnits)+@changecurunits-@oldcurunits)*(CurUnitCost+@chgcurunitcost-@oldunitcost) end)*(case when @HQTXdebtGLAcct is null then @taxrate else @pstrate end)  --DC #130175                
 		WHERE SLCo=@co and SL=@sl and SLItem=@slitem
 		IF @@rowcount = 0
			BEGIN
			SELECT @errors = isnull(@errors,'') + ' C:' + isnull(convert(varchar(5), @seq),''), @errflag ='p'
			goto posting_error
			END

        -- check bPMSL for interfaced record and update if possible
        IF exists(SELECT TOP 1 1 from bPMSL WITH (NOLOCK) where SLCo=@co and SLMth=@mth and SLTrans=@sltrans)
            BEGIN
            UPDATE bPMSL 
            SET SubCO=@slchangeorder, Units=@changecurunits, SLItemDescription=@description,
				Amount= Case when @um='LS' then @changecurcost else (@changecurunits*UnitCost) end, Notes = b.Notes
			FROM bPMSL d 
				join bSLCB b on d.SLCo=b.Co and d.SLMth=b.Mth and d.SLTrans=b.SLTrans
			WHERE d.SLCo=@co and d.SLMth=@mth and d.SLTrans=@sltrans
			END

 		END
      
	IF @transtype = 'D'	/* delete existing SL transaction */
		BEGIN
		DELETE bSLCD WHERE SLCo = @co and Mth = @mth and SLTrans = @sltrans
		IF @@rowcount = 0
			BEGIN
			SELECT @errors = isnull(@errors,'') + ' D:' + isnull(convert(varchar(5), @seq),''), @errflag ='p'
			goto posting_error
			END
			
		--DC #130175
		-- get Tax Rate
		SELECT @pstrate = 0  --DC #130175

		--DC #130175
		----TK-04407 #143372 changed to use @retcode and @retmsg possible that there is no tax for 
		---- the deleted transaction. The old method of using @rcode set the batch process flag
		---- like an error occurred when there really was none. As you can see we are not doing
		---- any error trapping if we cannot find a valid tax rate from the procedure.
		exec @retcode = vspHQTaxRateGet @taxgroup, @taxcode, @actdate, NULL, NULL, NULL, NULL, 
			NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @retmsg output
				
		SELECT @pstrate = (case when @gstrate = 0 then 0 else @taxrate - @gstrate end)				

		UPDATE bSLIT
		SET CurUnits=CurUnits-@oldcurunits,	--#28778
			CurUnitCost=CurUnitCost-@oldunitcost,
			CurCost= Case when @um='LS' then CurCost-@oldcurcost else (CurUnits-@oldcurunits)*(CurUnitCost-@oldunitcost) end,
			CurTax = (Case when @um='LS' then CurCost-@oldcurcost else (CurUnits-@oldcurunits)*(CurUnitCost-@oldunitcost) end) * @taxrate,  --DC #128435
			JCCmtdTax = (Case when @um='LS' then CurCost-@oldcurcost else (CurUnits-@oldcurunits)*(CurUnitCost-@oldunitcost) end) * (case when @HQTXdebtGLAcct is null then @taxrate else @pstrate end),  --DC #128435     			     			
			JCRemCmtdTax = (Case when @um='LS' then CurCost-@oldcurcost else (CurUnits-@oldcurunits)*(CurUnitCost-@oldunitcost) end) * (case when @HQTXdebtGLAcct is null then @taxrate else @pstrate end)  --DC #130175     			     			
		WHERE SLCo = @co and SL = @sl and SLItem = @slitem

		-- update bPMSL set interface date to null for deleted record
		UPDATE bPMSL 
		SET InterfaceDate=null, SendFlag='N', SLMth = null, SLTrans = null
		WHERE SLCo=@co and SLMth=@mth and SLTrans=@sltrans
		----IF @@rowcount = 0
		----   BEGIN
		----   -- look for older PMSL records to update
		----   UPDATE bPMSL 
		----   SET InterfaceDate=null, SendFlag='N', SLMth = null, SLTrans = null
		----   WHERE SLCo=@co and SL=@sl and SLItem=@slitem and SendFlag='Y' and InterfaceDate is not null and (RecordType='C' and ACO=@appchangeorder)
		----   END
		   
		END
      
	IF @source = 'PM Intface'
		BEGIN
		-- now update PMSL with interface date, where items are in slcb
		SELECT @pmco=JCCo from bSLCA WITH (NOLOCK) where SLCo = @co and Mth = @mth and BatchId = @batchid
		-- update interface date for change order records
		UPDATE bPMSL 
		SET InterfaceDate=@dateposted, SLMth=@mth, SLTrans=@sltrans
		WHERE PMCo=@pmco and SLCo=@co and SL=@sl and SLItem=@slitem and InterfaceDate is null and SendFlag='Y' and Vendor is not null and Seq=@pmslseq
		END
   
	/* call bspBatchUserMemoUpdate to update user memos in bSLCD before deleting the batch record */
	IF @transtype in ('A', 'C')
		BEGIN
   	    exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @seq, 'SL ChgOrder', @errmsg output
   	    IF @rcode <> 0 goto posting_error   
   	    END
   
	/* #24662 - clear InUseBatchId, Mth in bSLIT before deleting from bSLCB */
	UPDATE bSLIT 
	SET InUseBatchId=null, InUseMth=null 
	FROM bSLIT s 
		join bSLCB c on s.SLCo=c.Co and s.SL=c.SL and s.SLItem=c.SLItem 
	WHERE c.Co=@co and c.Mth=@mth and c.BatchId=@batchid and c.BatchSeq=@seq
   
 	/* delete current row from cursor */
 	DELETE bSLCB WHERE Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
	IF @@rowcount = 0
		BEGIN
		rollback transaction
		SELECT @errmsg = 'Error removing batch sequence ' + isnull(convert(varchar(10), @seq),'') + ' from batch.'
		goto bspexit
		END
   
	/* commit transaction */
	commit transaction
   
   	--issue 18616
   	IF @transtype in ('A','C')
   		BEGIN
   		IF @guid is not null
   			BEGIN
   			exec @rcode = bspHQRefreshIndexes null, null, @guid, null
   			END
   		END
   
	SELECT @count=count(1) FROM bSLCA WITH (NOLOCK) WHERE SL=@sl
	IF @count=0
		BEGIN
		UPDATE bSLHD
		SET InUseBatchId=null, InUseMth=null 
		WHERE SLCo=@co and SL=@sl
		END
   
	goto posting_loop
      
	jcposting_loop:
   
	/* declare cursor on SL Change JC Distribution Batch for posting */
	declare bcSLCA cursor LOCAL FAST_FORWARD for 
		SELECT JCCo, Job, PhaseGroup, Phase, JCCType,
		BatchSeq, OldNew, SL, SLItem, VendorGroup, Vendor, SLChangeOrder, AppChangeOrder,
		Description, ActDate, UM, ChangeUnits,	ChangeUnitCost, ChangeCost, JCUM, JCUnits,
		TotalCmtdTax, RemCmtdTax  --DC #130175
		FROM bSLCA WITH (NOLOCK) 
		WHERE SLCo = @co and Mth = @mth and BatchId = @batchid 
      
	/* open cursor */
	open bcSLCA
      
	/* set open cursor flag to true */
	SELECT @slcaopencursor = 1
      
	/* loop through all rows in this batch */
	jcposting_loopa:
	fetch next from bcSLCA into @jcco, @job, @phasegroup, @phase, @jcctype, @seq, @oldnew, @sl, @slitem,   
     		@vendorgroup, @vendor, @slchangeorder, @appchangeorder, @description, @actdate, @um,
     		@changecurunits, @chgcurunitcost, @changecurcost, @jcum, @jcunits,
     		@totalcmtdtax, @remcmtdtax --DC #130175
   
	IF @@fetch_status = -1 goto posting_loop_end
   
	IF @@fetch_status<>0 goto jcposting_loopa
   
	IF (@lastseq=@seq)
     	BEGIN   
      	SELECT @errmsg='Same Seq repeated, cursor error.', @rcode=1, @errflag ='j'
     	goto bspexit
     	END
   
	BEGIN transaction
     		/* get next available transaction # for JCCD */
	SELECT @tablename = 'bJCCD'
	exec @jctrans = bspHQTCNextTrans @tablename, @jcco, @mth, @errmsg output
	IF @sltrans = 0
		BEGIN
		SELECT @errors = isnull(@errors,'') + ' T:' + isnull(convert(varchar(5), @seq),''), @errflag ='j'
		goto posting_error
		END
   
	/* insert JC Detail */
	INSERT bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate, ActualDate,
			JCTransType, Source, Description, BatchId, PostedUM, PostedUnits, PostTotCmUnits, PostRemCmUnits,
			UM, TotalCmtdUnits, TotalCmtdCost, RemainCmtdUnits, RemainCmtdCost,
			VendorGroup, Vendor, APCo, SL, SLItem,
			TotalCmtdTax, RemCmtdTax)
	VALUES (@jcco, @mth, @jctrans, @job, @phasegroup, @phase, @jcctype, @dateposted, @actdate,
			'SL', @source, @description, @batchid, @um, 0, @changecurunits, @changecurunits,
			@jcum, @jcunits, @changecurcost, @jcunits, @changecurcost,
			@vendorgroup, @vendor, @co, @sl, @slitem,
			@totalcmtdtax, @remcmtdtax)  --DC #130175
	IF @@rowcount = 0
		BEGIN
		SELECT @errors = isnull(@errors,'') + ' A:' + isnull(convert(varchar(5), @seq),''), @errflag ='j'
		goto posting_error
		END
				     	
	/* delete current row from cursor */
	DELETE bSLCA 
	WHERE SLCo=@co and Mth=@mth and BatchId=@batchid and JCCo=@jcco and Job=@job and
		PhaseGroup=@phasegroup and Phase=@phase and JCCType=@jcctype and BatchSeq=@seq and OldNew=@oldnew
   
	IF @@rowcount <> 1
		BEGIN
     	rollback transaction
		SELECT @errmsg = 'Error removing batch sequence ' + isnull(convert(varchar(10), @seq),'') + ' from batch.'
      	goto bspexit
     	END
   
	SELECT @count=count(1) FROM bSLCA WITH (NOLOCK) WHERE SL=@sl
	IF @count=0
		BEGIN
		UPDATE bSLHD
		SET InUseBatchId=null, InUseMth=null 
		WHERE SLCo=@co and SL=@sl
		END
   
     /* commit transaction */   
     commit transaction
     goto jcposting_loopa
   
     posting_error:		/* error occured within transaction - rollback any updates and continue */
     	rollback transaction
     	IF @errflag = 'p' goto posting_loop
     	IF @errflag = 'j' goto jcposting_loopa
   
     posting_loop_end:	/* no more rows to process */
     	/* make sure batch is empty */
      
	IF exists(SELECT TOP 1 1 from bSLCB WITH (NOLOCK) where Co = @co and Mth = @mth and BatchId = @batchid)
		BEGIN
		SELECT @errmsg = isnull(@errors,'') + 'Not all batch entries were posted - unable to close batch!', @rcode = 1
		goto bspexit
		END
   
	-- set interface levels note string
	SELECT @Notes=Notes FROM bHQBC WITH (NOLOCK) WHERE Co = @co and Mth = @mth and BatchId = @batchid
	IF @Notes is NULL SELECT @Notes='' else SELECT @Notes=@Notes + char(13) + char(10)
	SELECT @Notes=@Notes + 'JC Interface set at: Y' --DC #130749  + isnull(convert(char(1), a.CmtdDetailToJC),'') + char(13) + char(10)  DC #130749
       --DC #130749  from bSLCO a WITH (NOLOCK) where SLCo=@co
   
	/* delete HQ Close Control entries */
	DELETE bHQCC WHERE Co = @co and Mth = @mth and BatchId = @batchid
   
	/* clear SL Change JC Audit entries */
	DELETE bSLCA WHERE SLCo = @co and Mth = @mth and BatchId = @batchid
   
	/* set HQ Batch status to 5 (posted) */
	UPDATE bHQBC
	SET Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
	WHERE Co = @co and Mth = @mth and BatchId = @batchid
	IF @@rowcount = 0
		BEGIN
		SELECT @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
		goto bspexit
		END   
      
bspexit:
   	IF @opencursor = 1
   		BEGIN
		close bcSLCB
		deallocate bcSLCB
		END
	IF @slcaopencursor = 1
		BEGIN
		close bcSLCA
		deallocate bcSLCA
		END
   
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLCBPost] TO [public]
GO
