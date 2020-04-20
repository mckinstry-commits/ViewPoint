SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPLBInsertExistingLine    Script Date: 8/28/99 9:36:00 AM ******/
   CREATE        procedure [dbo].[bspAPLBInsertExistingLine]
   /***********************************************************
    * CREATED BY: SE   9/13/96
    * MODIFIED By : SE 9/13/96 
    *               GR 8/13/99 added component type and component to insert into aplb
    *		 		MV 1/17/02 Issue 15833 BatchUserMemoInsertExisting
    *		 		MV 2/22/02 Issue 14164 - add paid lines back into APLB.
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *		 		MV 05/16/03 - #18763 - insert POPayTypeYN into bAPLB
    *				MV 12/01/03 - #23061 - isnull wrap
    *				MV 02/09/04 - #18769 PayCategory
    *				ES 03/11/04 - #23061 more isnul wrapping
	*				MV 02/09/09 - #123778 - insert Receiver# into bAPLB
	*				MV 08/08/11 - TK-07237 - AP project to use POItemLine
	*				MV 02/07/12 - TK-11877 - AP OnCost SubjToOnCostYN
     *				TL  06/20/12 - TK-15937 - Add SM Columns
	 *				GF 11/15/2012 TK-19327 SL Claim Work add column SLKeyID
	 *
    * USAGE:
    * This procedure is used by the AP Posting program to pull existing
    * transactions from bAPTL into bAPLB for editing. 
    *
    * Checks batch info in bHQBC, and transaction info in bAPTL and APTD.
    * Adds entry to the Item that it is in APLB for the seq passed in
    *
    * It will not allow to insert line if Any part of the transaction has been paid 
    * or broken out */
    
   	@co bCompany, @mth bMonth, @batchid bBatchID,
   	@aptrans bTrans, @line smallint, @seq int, @errmsg varchar(200) output
   
   as
   set nocount on
   declare @rcode int, @inuseby bVPUserName, @status tinyint,
   
   	@dtsource bSource, @inusebatchid bBatchID, @inusemth bMonth, @errtext varchar(100), @source bSource
   
   
   select @rcode = 0, @errtext = ''
   
   /* validate HQ Batch */
   exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, 'AP Entry', 'APHB', @errtext output, @status output
   if @rcode <> 0
      begin
       select @errmsg = @errtext, @rcode = 1
       goto bspexit   
      end
   
   if @status <> 0 
      begin
       select @errmsg = 'Invalid Batch status -  must be open!', @rcode = 1
       goto bspexit
      end
   
   /* Only invoice lines that have not been paid, or broken out can be pulled into a batch */
   /* first make sure the header is not in use */
   select @inusemth=InUseMth, @inusebatchid = InUseBatchId from bAPTH where APCo=@co and Mth=@mth and APTrans=@aptrans 
   if @@rowcount = 0 
   	begin
   	select @errmsg = 'The transaction :' + isnull(convert(varchar(6), @aptrans), '') 
   			+ ' cannot be found.' , @rcode = 3 --#23061
   	goto bspexit
   	end
   
   if @inusemth <> @mth or @inusebatchid <> @batchid
   	begin
   	/*select @errmsg = 'This Invoice is already in use by Batch #' + convert(varchar(8),@inusebatchid), @rcode = 1
   	goto bspexit*/
   	select @source=Source
   	       from HQBC 
   	       where Co=@co and BatchId=@inusebatchid and Mth=@inusemth
   	    if @@rowcount<>0
   	       begin
   		select @errmsg = 'Invoice already in use by ' +
   		      isnull(convert(varchar(2),DATEPART(month, @inusemth)), '') + '/' + 
   		      isnull(substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4), '') + 
   			' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + 
   			' - ' + 'Batch Source: ' + isnull(@source,''), @rcode = 1 --#23061
   
   		goto bspexit
   	       end
   	    else
   	       begin
   		select @errmsg='Invoice already in use by another batch!', @rcode=1
   		goto bspexit	
   	       end
   	end
   
   /* now make sure the line exists */
   if not exists ( select 1 from bAPTL with (nolock) where APCo=@co and Mth=@mth and APTrans=@aptrans and APLine=@line)
   	begin
   	 select @errmsg = 'Invoice line not found!', @rcode = 3
   	 goto bspexit
   	end
   
   
   if exists (select 1 from bAPTD d with (nolock) where d.APCo=@co and d.Mth=@mth and
                d.APTrans=@aptrans and d.APLine=@line and d.Status>3)	--include paid lines #14164
   	begin
   	select @errmsg = 'There are no open, on-hold or paid invoice lines to add.', @rcode = 1
   	goto bspexit
   	end
   
   if exists (select 1 from bAPTD d with (nolock) where d.APCo=@co and d.Mth=@mth and
                d.APTrans=@aptrans and d.APLine=@line group by d.APCo, d.Mth, d.APTrans,
                d.APLine, d.PayType having count(d.PayType) > 1) 
   	begin
   	select @errmsg = 'You cannot edit invoice lines that have been broken out!', @rcode = 1
   	goto bspexit
   	end
   
   /* now insert the line */
       insert into bAPLB(Co, Mth, BatchId, BatchSeq, APLine, BatchTransType, 
       	   LineType, PO, POItem, POItemLine, ItemType, SL, SLItem, JCCo, Job, PhaseGroup, Phase, JCCType,
       	   EMCo, WO, WOItem, Equip, EMGroup, CostCode, EMCType, CompType, Component,
   		   INCo, Loc, MatlGroup,Material, GLCo, GLAcct, Description, UM, Units, UnitCost, ECM,
   		   VendorGroup,Supplier, PayType, GrossAmt, MiscAmt, MiscYN, TaxGroup, TaxCode, TaxType, 
       	   TaxBasis, TaxAmt, Retainage, Discount, BurUnitCost, BECM,POPayTypeYN,PayCategory,Receiver#,SubjToOnCostYN,
		    SMCo,SMWorkOrder,Scope,SMCostType,SMPhaseGroup,SMPhase,SMJCCostType,
   
       	   OldLineType,  OldPO, OldPOItem, OldPOItemLine, OldItemType, OldSL, OldSLItem, OldJCCo, OldJob, OldPhaseGroup, OldPhase, OldJCCType,
       	   OldEMCo, OldWO, OldWOItem, OldEquip, OldEMGroup, OldCostCode, OldEMCType, OldCompType, OldComponent, 
       	   OldINCo, OldLoc, OldMatlGroup,OldMaterial, OldGLCo, OldGLAcct, OldDesc, OldUM, OldUnits, OldUnitCost,
   		   OldECM, OldVendorGroup,OldSupplier, OldPayType, OldGrossAmt, OldMiscAmt, OldMiscYN, OldTaxGroup, OldTaxCode,
   		   OldTaxType,OldTaxBasis, OldTaxAmt, OldRetainage, OldDiscount, OldBurUnitCost, OldBECM,OldPayCategory, OldSubjToOnCostYN,
		   OldSMCo,OldSMWorkOrder,OldScope,OldSMCostType,OldSMPhaseGroup,OldSMPhase,OldSMJCCostType
		   ----TK-19327
		   ,SLKeyID)
       select l.APCo, @mth, @batchid, @seq, l.APLine,'C', 
       	   l.LineType, l.PO, l.POItem, l.POItemLine, l.ItemType, l.SL, l.SLItem, l.JCCo, l.Job, l.PhaseGroup, l.Phase, l.JCCType,
       	   l.EMCo, l.WO, l.WOItem, l.Equip, l.EMGroup, l.CostCode, l.EMCType,  l.CompType, l.Component,
       	   l.INCo, l.Loc, l.MatlGroup, l.Material, l.GLCo, l.GLAcct, l.Description, l.UM, l.Units, l.UnitCost, l.ECM, 
       	   l.VendorGroup, l.Supplier, l.PayType, GrossAmt, l.MiscAmt, l.MiscYN, l.TaxGroup, l.TaxCode, l.TaxType, 
       	   l.TaxBasis, l.TaxAmt, l.Retainage, Discount, l.BurUnitCost, l.BECM,l.POPayTypeYN,l.PayCategory,l.Receiver#,l.SubjToOnCostYN,
		   l.SMCo,l.SMWorkOrder,l.Scope,l.SMCostType,l.SMPhaseGroup,l.SMPhase,l.SMJCCostType,

      	   l.LineType, l.PO, l.POItem, l.POItemLine, l.ItemType, l.SL, l.SLItem, l.JCCo, l.Job, l.PhaseGroup, l.Phase, l.JCCType,
       	   l.EMCo, l.WO, l.WOItem, l.Equip, l.EMGroup, l.CostCode, l.EMCType, l.CompType, l.Component,
   		   l.INCo, l.Loc,l.MatlGroup, l.Material, l.GLCo, l.GLAcct, l.Description, l.UM, l.Units, l.UnitCost,
   		   l.ECM,l.VendorGroup,l.Supplier, l.PayType, GrossAmt, l.MiscAmt, l.MiscYN, l.TaxGroup, l.TaxCode,
   		   l.TaxType, l.TaxBasis, l.TaxAmt, l.Retainage, Discount, l.BurUnitCost, l.BECM, l.PayCategory, l.SubjToOnCostYN,
		   l.SMCo,l.SMWorkOrder,l.Scope,l.SMCostType,l.SMPhaseGroup,l.SMPhase,l.SMJCCostType
		   ----TK-19327
		   ,l.SLKeyID
	   from bAPTL l   
       where l.APCo=@co and l.Mth=@mth and l.APTrans=@aptrans and l.APLine=@line
   	if @@rowcount > 0	-- update APLB with paidyn flag and handle user memos only if lines added to batch
   		begin
   		/* update Paidyn flag in bAPLB to 'Y' if detail is paid*/
   		if exists (select 1 from bAPTD with (nolock) where APCo=@co and Mth=@mth and APTrans=@aptrans
   			and APLine=@line and Status=3)
   			begin
   		     	update bAPLB set PaidYN='Y' where Co=@co and Mth=@mth and BatchId=@batchid and 
   				BatchSeq=@seq and APLine=@line
   			end
   		/* BatchUserMemoInsertExisting - update the user memo in the detail batch record */
        		exec @rcode =  bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq,
   			'AP Entry Detail', 0, @errmsg output
           	if @rcode <> 0
           		begin
               		select @errmsg = 'Unable to update User Memos in APLB', @rcode = 1
               		goto bspexit
               		end
   		end
   
   bspexit:
   	return @rcode
   	

GO
GRANT EXECUTE ON  [dbo].[bspAPLBInsertExistingLine] TO [public]
GO
