SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE     procedure [dbo].[bspAPHBInsertExistingTrans]
/***********************************************************
* CREATED BY:	SE  09/15/1996
* MODIFIED By : GG	05/26/1998 - GR 06/29/99
* MODIFIED BY : GR	07/21/1999 - changed to get the source from bHQBC based on inusemth
*                 of bAPTH instead of mth
*				GR	08/13/1999 - added comptype and component to insert into APLB
*				GR	05/10/2000 - added DocName to insert into APHB
*				MV	06/29/2001 - Issue 12769 BatchUserMemoInsertExisting
*				MV	08/31/2001 - #10997 EFT tax and child support payment addendas
*				kb	10/24/2001 - Issue #15028
*				MV	12/21/2001 - Issue #15692 insert APTH addenda values into APHB addenda fields
*				GG	01/03/2002 - #15777 - execute proc to handle APTL user memos only if lines added to batch
*				GG	01/21/2002 - #14022 - update bAPHB.ChkRev
*				MV	02/19/2002 - #14164 - Allow paid transactions and lines into APHB, APLB, flagged as PaidYN='Y'
*				TV	04/09/2002 - added the passing of Notes column back to APHB
*				kb	05/14/2002 - issue #14164
*				kb	05/28/2002 - issue #14160
*				TV	05/29/2002 - pass UniqueAttchID  back to APHB     
*				GH	07/11/2002 - 'Only AP Ref, Description and Invoice Date can be changed in a paid transaction' error on new transactions.
*                             problem with where clause on APHB.PaidYN update
*				kb	10/28/2002 - issue #18878 - fix double quotes
*				MV	11/01/2002 - #18037 insert AddressSeq, OldAddressSeq into bAPHB from bAPTH
*				MV	05/16/2003 - #18763 insert POPayTypeYN into bAPLB from bAPTL
*				MV	11/26/2003 - #23061 isnull wrap
*				GF	12/10/2003 - issue #23067 - change way user memos are updated into batch tables.
*				MV	02/09/2004 - #18769 Pay Category
*				GG	01/19/2007 - #123614 - fix join to bAPTL when updating PaidYN flag
*				TJL 03/25/2008 - #127347 Intl addresses
*				MV	02/12/2009 - #123778 - insert Receiver# into bAPLB from bAPTL 
*				MH	03/21/2011 - TK-02793/TK-02796
*				MV	08/08/2011 - TK-07237 AP project to use POItemLine
*				MH	08/09/2011 - TK-07482 Replace MiscellaneousType with SMCostType
*				CHS	01/27/2012 - TK-11876 - AP On-Cost
*			JG 01/23/2012  - TK-11971 - Added JCCostType and PhaseGroup
*				MV 03/22/12 - TK-13268 AP OnCost SchemeID, MembershipNbr.
*				TL 04/12/12 - TK-13994 Add column SMPhase
*				GF 11/15/2012 TK-19327 SL Claim Work add column SLKeyID
*
* USAGE:
* This procedure is used by the AP Posting program to pull existing transactions
 * from bAPTH into bAPHB for editing.
 *
 * Checks batch info in bHQBC, and transaction info in bAPTL,bAPTD.
 * Adds entry to next available Seq# in bAPHB
 *
 * bAPBH insert trigger will update InUseBatchId in bAPTH
 *
 * INPUT PARAMETERS
 *	@co         	AP Company #
 *  @mth        	Batch Month
 *  @batchid    	Batch ID to insert transaction into
 *  @aptrans		AP Transaction to pull
 *  @includelines  	'Y' = pull all available lines, 'N' = pull header only
 *
 * OUTPUT PARAMETERS
 *	@errmsg		Error message
 *
 * RETURN VALUE
 *   0   success
 *   1   fail
 *****************************************************/
    @co bCompany, @mth bMonth, @batchid bBatchID, @aptrans bTrans, @includelines bYN,
    @errmsg varchar(200) output
   
   as
   set nocount on
   
   declare @rcode int, @inuseby bVPUserName, @status tinyint, @dtsource bSource,
    		@inusebatchid bBatchID, @inusemth bMonth, @seq int, @errtext varchar(60),
    		@source bSource, @openyn bYN, @paidyn bYN, @inpaycontrol bYN, @user bVPUserName,
   		@aphbud_flag bYN, @aplbud_flag bYN, @h_join varchar(2000), @h_where varchar(2000), 
   		@h_update varchar(2000), @l_join varchar(2000), @l_where varchar(2000), @l_update varchar(2000),
   		@sql varchar(8000)
     
   
   select @rcode = 0, @aphbud_flag = 'N', @aplbud_flag = 'N'
   
   -- call bspUserMemoQueryBuild to create update, join, and where clause
   -- pass in source and destination. Remember to use views only unless working
   -- with a Viewpoint (bidtek) connection.
   exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'APTH', 'APHB', @aphbud_flag output,
   			@h_update output, @h_join output, @h_where output, @errmsg output
   if @rcode <> 0 goto bspexit
   
   -- call bspUserMemoQueryBuild to create update, join, and where clause
   -- pass in source and destination. Remember to use views only unless working
   -- with a Viewpoint (bidtek) connection.
   exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'APTL', 'APLB', @aplbud_flag output,
   			@l_update output, @l_join output, @l_where output, @errmsg output
   if @rcode <> 0 goto bspexit
   
   
    -- validate HQ Batch
    exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'AP Entry', 'APHB', @errtext output, @status output
    if @rcode <> 0
    	begin
        select @errmsg = isnull(@errtext,''), @rcode = 1
        goto bspexit
        end
    if @status <> 0
    	begin
        select @errmsg = 'Invalid Batch status -  must be ''open''!', @rcode = 1
        goto bspexit
        end
   
    -- all Invoices's can be pulled into a batch as long as it's InUseFlag is set to null
    select @inusebatchid = InUseBatchId, @inusemth = InUseMth, @inpaycontrol = InPayControl
    from bAPTH with (nolock)
    where APCo = @co and Mth = @mth and APTrans = @aptrans
    if @@rowcount = 0
      	begin
      	select @errmsg = 'The AP Transaction :' + isnull(convert(varchar(6),@aptrans), '') --#23061
   			 + ' cannot be found.' , @rcode = 1
      	goto bspexit
      	end
    if @inusebatchid is not null
    	begin
        select @source = Source from bHQBC
        where Co = @co and BatchId = @inusebatchid  and Mth = @inusemth
     	select @errmsg = 'Transaction already in use by ' +
      	    isnull(convert(varchar(2),DATEPART(month, @inusemth)), '') + '/' +  --#23061
      		   isnull(substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4), '') +
      		   ' Batch # ' + isnull(convert(varchar(6),@inusebatchid), '') + ' - Batch Source: ' + isnull(@source,''), @rcode = 1
      	    goto bspexit
    	end
   
     if @inpaycontrol = 'Y'
       begin
       select @user = UserId from bAPWH where APCo = @co and Mth = @mth and APTrans = @aptrans
       select @errmsg = 'Transaction exists in a payment control workfile for user - ' 
         + isnull(@user,'') + ' so it cannot be added to the transaction entry batch', @rcode = 1
       goto bspexit
       end
   
    -- check whether the transaction has been paid
    select @openyn = OpenYN
    from bAPTH with (nolock)
    where APCo = @co and Mth = @mth and APTrans = @aptrans
    select @paidyn = case @openyn when 'N' then 'Y' else 'N' end
   
    -- get next available sequence # for this batch
    select @seq = isnull(max(BatchSeq),0) + 1
    from bAPHB with (nolock)
    where Co = @co and Mth = @mth and BatchId = @batchid
   
    -- add Transaction to batch
    insert into bAPHB (Co, Mth, BatchId, BatchSeq, BatchTransType, APTrans, VendorGroup, Vendor,
    	APRef, Description, InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl,
        PayMethod, CMCo, CMAcct, PrePaidYN, PrePaidMth, PrePaidDate, PrePaidChk, PrePaidSeq,
    	PrePaidProcYN, V1099YN, V1099Type, V1099Box, PayOverrideYN, PayName, PayAddress, PayCity,
        PayState, PayZip, PayCountry, InvId, UIMth, UISeq, DocName,OldVendorGroup, OldVendor,OldAPRef, OldDesc,
        OldInvDate, OldDiscDate, OldDueDate, OldInvTotal,OldHoldCode, OldPayControl, OldPayMethod,
        OldCMCo, OldCMAcct, OldPrePaidYN, OldPrePaidMth,OldPrePaidDate, OldPrePaidChk, OldPrePaidSeq,
        OldPrePaidProcYN, Old1099YN, Old1099Type,Old1099Box, OldPayOverrideYN, OldPayName, OldPayAddress,
    	OldPayCity, OldPayState, OldPayZip, OldPayCountry, OldDocName, AddendaTypeId,PRCo, Employee, DLcode, TaxFormCode,
    	TaxPeriodEndDate,AmountType, Amount, AmtType2, Amount2,AmtType3,Amount3, OldAddendaTypeId, OldPRCo,
    	OldEmployee, OldDLcode,OldTaxFormCode, OldTaxPeriodEndDate, OldAmountType, OldAmount, OldAmtType2,
    	OldAmount2,OldAmtType3, OldAmount3, SeparatePayYN, ChkRev, PaidYN, Notes, UniqueAttchID, AddressSeq,
   		OldAddressSeq, SLKeyID) ----TK-19327
    Select APCo, @mth, @batchid, @seq, 'C', APTrans, VendorGroup, Vendor, APRef,
    	Description, InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl,
    	PayMethod, CMCo, CMAcct, PrePaidYN, PrePaidMth, PrePaidDate, PrePaidChk, PrePaidSeq,
    	PrePaidProcYN, V1099YN, V1099Type, V1099Box, PayOverrideYN, PayName, PayAddress, PayCity,
    	PayState, PayZip, PayCountry, InvId, null, null, DocName,VendorGroup, Vendor, APRef,
    	Description, InvDate, DiscDate, DueDate, InvTotal, HoldCode, PayControl,
    	PayMethod, CMCo, CMAcct, PrePaidYN, PrePaidMth, PrePaidDate, PrePaidChk, PrePaidSeq,
    	PrePaidProcYN, V1099YN, V1099Type, V1099Box, PayOverrideYN, PayName, PayAddress, PayCity,
    	PayState, PayZip, PayCountry, DocName, AddendaTypeId, PRCo,Employee, DLcode, TaxFormCode,TaxPeriodEndDate,
    	AmountType, Amount, AmtType2, Amount2, AmtType3, Amount3,AddendaTypeId, PRCo,Employee, DLcode,TaxFormCode,
    	TaxPeriodEndDate,AmountType, Amount, AmtType2, Amount2, AmtType3, Amount3, SeparatePayYN, ChkRev,@paidyn,
		Notes,UniqueAttchID, AddressSeq, AddressSeq, SLKeyID ----TK-19327
    from bAPTH
    where APCo=@co and Mth=@mth and APTrans=@aptrans
    if @@rowcount <> 1
    	begin
      	select @errmsg = 'Unable to add entry to AP Entry Batch!', @rcode = 1
      	goto bspexit
      	end
   
   if @aphbud_flag = 'Y'
   	begin
   	set @sql = @h_update + @h_join + @h_where 
   				+ ' and b.APTrans= ' + isnull(convert(varchar(10), @aptrans), '')  --#23061
   				+ ' and APHB.APTrans = ' + isnull(convert(varchar(10),@aptrans), '')
   				+ ' and APHB.BatchSeq = ' + isnull(convert(varchar(10),@seq), '')
   	exec (@sql)
   	end
   
   -- -- BatchUserMemoInsertExisting - update the user memo in the batch record
   -- exec @rcode = dbo.bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'AP Entry', 0, @errmsg output
   -- if @rcode <> 0
   -- 	begin
   -- 	select @errmsg = 'Unable to update User Memos in APHB', @rcode = 1
   -- 	goto bspexit
   -- 	end
   
   
   
    if @includelines = 'Y'
    	begin
    	insert bAPLB(Co, Mth, BatchId, BatchSeq, APLine, BatchTransType,
    		LineType, PO, POItem, POItemLine, ItemType, SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType,
    		EMCo, WO, WOItem, Equip, EMGroup, CostCode, EMCType, CompType, Component, INCo, Loc, MatlGroup,
    		Material, GLCo, GLAcct, Description, UM, Units, UnitCost, ECM, VendorGroup,
    		Supplier, PayType, GrossAmt, MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType,
    		TaxBasis, TaxAmt, Retainage, Discount, BurUnitCost, BECM,POPayTypeYN,PayCategory,Receiver#,
    		OldLineType,  OldPO, OldPOItem, OldPOItemLine, OldItemType, OldSL, OldSLItem, OldJCCo, OldJob, OldPhaseGroup, OldPhase, OldJCCType,
    		OldEMCo, OldWO, OldWOItem, OldEquip, OldEMGroup, OldCostCode, OldEMCType, OldCompType, OldComponent,
    		OldINCo, OldLoc, OldMatlGroup, OldMaterial, OldGLCo, OldGLAcct, OldDesc, OldUM, OldUnits, OldUnitCost,
    		OldECM, OldVendorGroup, OldSupplier, OldPayType, OldGrossAmt, OldMiscAmt, OldMiscYN, OldTaxGroup, OldTaxCode, OldTaxType,
    		OldTaxBasis, OldTaxAmt, OldRetainage, OldDiscount, OldBurUnitCost, OldBECM,OldPayCategory, Notes,
    		SMCo, SMWorkOrder, Scope, SMCostType, SMStandardItem, OldSMCo, OldSMWorkOrder, OldScope, 
    		OldSMCostType, OldSMStandardItem, APTLKeyID, SMJCCostType, OldSMJCCostType, SMPhaseGroup, OldSMPhaseGroup,SMPhase, OldSMPhase,
    		OldSubjToOnCostYN, ocApplyMth, ocApplyTrans, ocApplyLine, ATOCategory, SubjToOnCostYN,ocSchemeID,ocMembershipNbr
			----TK-19327
			,SLKeyID)
    	select l.APCo, @mth, @batchid, @seq, l.APLine,'C',
          	l.LineType, l.PO, l.POItem, l.POItemLine, l.ItemType, l.SL, l.SLItem, l.JCCo, l.Job, l.PhaseGroup, l.Phase, l.JCCType,
          	l.EMCo, l.WO, l.WOItem, l.Equip, l.EMGroup, l.CostCode, l.EMCType, l.CompType, l.Component, l.INCo, l.Loc,
          	l.MatlGroup, l.Material, l.GLCo, l.GLAcct, l.Description, l.UM, l.Units, l.UnitCost, l.ECM, l.VendorGroup,
          	l.Supplier, l.PayType, GrossAmt, l.MiscAmt, l.MiscYN, l.TaxGroup, l.TaxCode, l.TaxType,
          	l.TaxBasis, l.TaxAmt, l.Retainage, Discount, l.BurUnitCost, l.BECM, l.POPayTypeYN,l.PayCategory,l.Receiver#,
         	l.LineType, l.PO, l.POItem, l.POItemLine, l.ItemType, l.SL, l.SLItem, l.JCCo, l.Job, l.PhaseGroup, l.Phase, l.JCCType,
          	l.EMCo, l.WO, l.WOItem, l.Equip, l.EMGroup, l.CostCode, l.EMCType, l.CompType, l.Component, l.INCo, l.Loc,
          	l.MatlGroup, l.Material, l.GLCo, l.GLAcct, l.Description, l.UM, l.Units, l.UnitCost, l.ECM, l.VendorGroup,
          	l.Supplier, l.PayType, GrossAmt, l.MiscAmt, l.MiscYN, l.TaxGroup, l.TaxCode, l.TaxType,
          	l.TaxBasis, l.TaxAmt, l.Retainage, Discount, l.BurUnitCost, l.BECM,l.PayCategory,l.Notes,
          	l.SMCo, l.SMWorkOrder, l.Scope, l.SMCostType, l.SMStandardItem,l.SMCo, l.SMWorkOrder, 
          	l.Scope, l.SMCostType, l.SMStandardItem, l.KeyID, l.SMJCCostType, l.SMJCCostType, l.SMPhaseGroup, l.SMPhaseGroup,l.SMPhase, l.SMPhase,
          	l.SubjToOnCostYN, l.ocApplyMth, l.ocApplyTrans, l.ocApplyLine, l.ATOCategory, l.SubjToOnCostYN, l.ocSchemeID,l.ocMembershipNbr
			----TK-19327
			,l.SLKeyID
    	from bAPTL l   /* only pull lines that have all APTD lines open, and only have one TD line per transaction */
    	where l.APCo=@co and l.Mth=@mth and l.APTrans=@aptrans
               and not exists (select * from bAPTD d where d.APCo=l.APCo and d.Mth=l.Mth and
                   d.APTrans=l.APTrans and d.APLine=l.APLine and d.Status>3)	--#14164 pull in paid lines
               and not exists (select * from bAPTD d where d.APCo=l.APCo and d.Mth=l.Mth and
                   d.APTrans=l.APTrans and d.APLine=l.APLine group by d.APCo, d.Mth, d.APTrans,
                   d.APLine, d.PayType having count(d.PayType) > 1)
    	if @@rowcount > 0	-- update PaidYN flag or handle user memos only if lines added to batch
    		begin
    		-- Issue 14164 set PaidYN flag in APLB to 'Y' if APTD.Status=3
    		update bAPLB set PaidYN = 'Y' where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and
    			APLine in (select d.APLine from bAPTD d join bAPTL l on d.APCo=l.APCo and d.Mth=l.Mth and
                  		d.APTrans=l.APTrans and d.APLine=l.APLine where l.APCo=@co and l.Mth=@mth and
                   		l.APTrans=@aptrans and d.APLine=l.APLine and d.Status=3)
    		if @@rowcount > 0   --update PaidYN flag in bAPHB if any lines are paid.
    			begin
    			update bAPHB set PaidYN = 'Y' where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
    			end
   
   		if @aplbud_flag = 'Y'
   			begin
   			set @sql = @l_update + @l_join + @l_where + ' and APLB.BatchSeq = ' + isnull(convert(varchar(10),@seq), '') -- #23061
   			exec (@sql)
   			end
   
   --  		-- BatchUserMemoInsertExisting - update the user memo in APLB
   --       	exec @rcode = dbo.bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'AP Entry Detail', 0, @errmsg output
   --  	    if @rcode <> 0
   -- 			begin
   -- 			select @errmsg = 'Unable to update User Memos in bAPLB', @rcode = 1
   -- 			goto bspexit
   -- 			end
   
   		end
   	end
   
   
   
   bspexit:
      	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspAPHBInsertExistingTrans] TO [public]
GO
