SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE      procedure [dbo].[bspSLCBVal]
   /************************************************************************
    * Created By:     ??
    * Modified By:    GF 08/24/2000
    *				GG 01/26/01 - fixed total cost calculations for change and delete entries
    *				TV 07/16/01 - #13968 - Fixed update to SLCA if ItemType is original
    *                DANF 09/05/02 - Added Phase Group to bspJobTypeVal
    *				MV 08/25/03 - #21916 - do JC distributions if units, costs = 0, performance enhancements 
    *				RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
    *				MV 09/03/04 - #25400 - change @description, @olddescription datatype to bItemDesc
    *				MV 12/15/04 - #26183 - fixed calc to bSLCA.ChangeCost for <>LS - updates JCCD TotCmtdCost, RemCmtdCost
    *				MV 11/09/05 - #30273 - for transtype 'change' back out 'old' from calc for ChangeCurCost in bSLCA -updates JCCD 
	*				DC 08/21/07 - #125312 - Changing units not correctly calculating remaining cost
	*				DC 07/09/08 - #128435 - Add Sales Taxes to SL
	*				DC 08/18/08 - #129402 - Committed cost SL change order that was changed,then deletd
	*				DC 04/30/09 - Modified sp to match the logic that PO Change Order uses for taxes
	*				DC 05/28/09 - #132626  - RE: #129812/132527 - incorrect units/amts in SLCA when adding SLChgOrder back in
	*				DC 12/28/09 - #130175 - SLIT needs to match POIT 
	*				DC 6/24/10 - #135813 - expand subcontract number
	*
    * Validates each entry in bSLCB for a select batch - must be called
    * prior to posting the batch.
    *
    * After initial Batch and PO checks, bHQBC Status set to 1 (validation in progress)
    *
    * bHQBE (Batch Errors), and bPOCA (JC Distribution Audit),
    * and bPOCI (IN Distribution Audit) entries are deleted.
    *
    * Creates a cursor on bSLCB to validate each entry individually.
    *
    * Errors in batch added to bHQBE using bspHQBEInsert
    *
    * JC distributions added to bSLCA
    *
    * bHQBC Status updated to 2 if errors found, or 3 if OK to post
    *
    * pass in Co, Month, and BatchId
    * returns 0 if successfull (even if entries addeed to bHQBE)
 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
   	@co bCompany, @mth bMonth, @batchid bBatchID, @source bSource, @errmsg varchar(255) output
 
   as
   set nocount on
 
DECLARE @opencursor tinyint, @rcode tinyint, @errortext varchar(255), @status tinyint,
	@seq int, @transtype char(1), @sltrans bTrans, @sl VARCHAR(30),  --bSL,   DC #135813
	@slitem bItem,
	@slchangeorder smallint, @appchangeorder varchar(10), @actdate bDate, @description
	bItemDesc, @um bUM, @changecurunits bUnits, @chgcurunitcost bUnitCost, @changecurcost bDollar, 
	@oldsl VARCHAR(30), -- bSL, DC #135813
	@oldslitem bItem, @oldslchangeorder smallint, @oldappchangeorder varchar(10), 
	@oldactdate bDate, @olddescription bItemDesc, @oldum bUM, @oldcurunits bUnits,
	@oldunitcost bUnitCost, @oldcurcost bDollar,
	@errorhdr varchar(30), @vendor bVendor, @itemtype int, @lastglmth bMonth, @vendorgroup bGroup,
	@addon tinyint, @lastsubmth bMonth, @addonPct bPct, @jcco bCompany, @job bJob, @phase bPhase,
	@PhaseGroup bGroup, @jcctype bJCCType, @glco bCompany, @glacct bGLAcct, @curunitcost bUnitCost,
	@wcretpct bPct, @smretpct bPct, @invunits bUnits, @invcost bDollar, @slitcurunits bUnits,
	@maxopen tinyint, @fy bMonth, @adj bYN, @jcum bUM, @umconv int, @errorstart varchar(255),
	@dovalidation int, @oldchangecurunits bUnits, @oldchgcurunitcost bUnitCost, @oldchangecurcost bDollar,
	--International Sales Tax  --DC #128435
	@taxgroup bGroup, @taxcode bTaxCode, @taxrate bRate, @gstrate bRate, @pstrate bRate, 
	--@oldtaxrate bRate, 
	--@oldgstrate bRate, 
	--@oldpstrate bRate, 	
	@taxphase bPhase, @taxjcct bJCCType,
	@HQTXdebtGLAcct bGLAcct, @oldHQTXdebtGLAcct bGLAcct, @origtax bDollar, @oldorigtax bDollar,
	--@oldtaxphase bPhase, 
	--@oldtaxct bJCCType, 
	--@valueadd bYN, 
	--@oldvalueadd bYN,  --DC #128435
	@SLCAchangecurunits bUnits, @SLCAchgcurunitcost bUnitCost, @SLCAchangecurcost bDollar,
	@SLCAoldchangecurunits bUnits, @SLCAoldchgcurunitcost bUnitCost, @SLCAoldchangecurcost bDollar
  
	/* set open cursor flag to false */
	SELECT @opencursor = 0, @dovalidation=1
 
	/* validate HQ Batch */
	EXEC @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'SLCB', @errmsg output, @status output
	IF @rcode <> 0
		BEGIN
       	SELECT @errmsg = @errmsg, @rcode = 1
       	goto bspexit
      	END
 
	IF @status < 0 or @status > 3
   		BEGIN
   		SELECT @errmsg = 'Invalid Batch status!', @rcode = 1
   		goto bspexit
   		END
 
	/* set HQ Batch status to 1 (validation in progress) */
	UPDATE bHQBC
   	SET Status = 1
   	WHERE Co = @co and Mth = @mth and BatchId = @batchid
	IF @@rowcount = 0 
   		BEGIN
   		SELECT @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   		goto bspexit
   		END
 
	/* clear HQ Batch Errors */
	DELETE bHQBE WHERE Co = @co and Mth = @mth and BatchId = @batchid
 
	/* clear SL JC Distribution Audit */ 
	DELETE bSLCA WHERE SLCo = @co and Mth = @mth and BatchId = @batchid
 
	/* declare cursor on SL Change Batch for validation */
	DECLARE bcSLCB cursor LOCAL FAST_FORWARD for 
		SELECT BatchSeq, BatchTransType, SLTrans, SL,
   			SLItem, SLChangeOrder, AppChangeOrder, ActDate, Description, UM, ChangeCurUnits, CurUnitCost, ChangeCurCost,
   			OldSL, OldSLItem, OldSLChangeOrder, OldAppChangeOrder, OldActDate, OldDescription,
   			OldUM, OldCurUnits, OldUnitCost, OldCurCost 
		FROM bSLCB WITH (NOLOCK) 
		WHERE Co = @co and Mth = @mth and BatchId = @batchid
  
	/* open cursor */
	open bcSLCB
 
	/* set open cursor flag to true */
	SELECT @opencursor = 1
 
	/* get first row */
	fetch next from bcSLCB into @seq, @transtype, @sltrans, @sl, 
		@slitem, @slchangeorder, @appchangeorder, @actdate, @description, @um, @changecurunits, @chgcurunitcost, @changecurcost,
   		@oldsl, @oldslitem, @oldslchangeorder, @oldappchangeorder, @oldactdate, @olddescription, 
   		@oldum, @oldcurunits, @oldunitcost, @oldcurcost
 
	/* loop through all rows */
	WHILE (@@fetch_status = 0)
   		BEGIN
   		SELECT @dovalidation=1
   		/* validate SL Change Batch info for each entry */
   		SELECT @errorhdr = 'Seq#' + convert(varchar(6),@seq)
   		SELECT @errorstart = @errorhdr
   		/* validate transaction type */
   		IF @transtype <> 'A' and @transtype <> 'C' and @transtype <> 'D'
   			BEGIN
   			SELECT @errortext = @errorhdr + ' -  Invalid transaction type, must be (A, C, or D).'
   			EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   			IF @rcode <> 0 goto bspexit
   			END
	 
   		/* validate SL# */
   		IF @sl is null
   			BEGIN
   			SELECT @errortext = @errorhdr + ' - SL# is missing!'
   			EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   			SELECT @dovalidation=0
   			IF @rcode <> 0 goto bspexit
   			END
   		SELECT @vendor=Vendor, @vendorgroup=VendorGroup 
   		FROM SLHD WITH (NOLOCK) 
   		WHERE SLCo=@co and SL=@sl
   		IF @@rowcount=0 
   			BEGIN
   			SELECT @errortext = @errorhdr + ' - Invalid SL#.' 
   			EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   			IF @rcode <> 0 goto bspexit 
   			END
	  
   		/* validate SL Item# and get item information */
   		SELECT @itemtype=ItemType, @addon=Addon, @addonPct=AddonPct, @um=UM, @jcco=JCCo, @job=Job,
   			@PhaseGroup=PhaseGroup, @phase=Phase, @jcctype=JCCType, @glco=GLCo, @glacct=GLAcct,
   			@wcretpct=WCRetPct, @smretpct=SMRetPct, @invunits=InvUnits, @invcost=InvCost,
   			@curunitcost=CurUnitCost, @slitcurunits=CurUnits,
			@taxgroup=TaxGroup, @taxcode=TaxCode,  --DC #128435
			@taxrate = TaxRate, @gstrate = GSTRate  --DC #130175
   		FROM SLIT WITH (NOLOCK)
   		WHERE SLCo=@co and SL=@sl and SLItem=@slitem
   		IF @@rowcount=0
   	 		BEGIN
   	 		SELECT @itemtype=SLItemType, @addon=SLAddon, @addonPct=SLAddonPct, @um=UM, @jcco=PMCo, @job=Project,
   				@PhaseGroup=PhaseGroup, @phase=Phase, @jcctype=CostType, @wcretpct=WCRetgPct,
   				@smretpct=SMRetgPct, @curunitcost=0, @slitcurunits=0
   			FROM PMSL WITH (NOLOCK) 
   			WHERE SLCo=@co and SL=@sl and SLItem=@slitem and InterfaceDate is null and SendFlag = 'Y'
   			IF @@rowcount = 0
   			   BEGIN
   			   SELECT @errortext = @errorhdr + ' = Invalid SL Item#.'
   			   EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   			   IF @rcode <> 0 goto bspexit
   			   SELECT @dovalidation=0
   			   END
   			END
	 
   		/*validation job info*/ 
   		EXEC @rcode = bspJobTypeVal @jcco, @PhaseGroup, @job, @phase, @jcctype, @jcum output, @errmsg output
   		IF @rcode <> 0
   			BEGIN
   	   		SELECT @errortext = @errorstart + '- ' + isnull(@errmsg,'') 
   	   		EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   			IF @rcode <> 0 goto bspexit
   	   		END
	 
   		/* check if um=jcum get conversion factor. If conversion doesn't exist, conversion factor=0 so units updated
   		   to jccp are 0 */
   		IF @um<>@jcum
   			BEGIN
   			SELECT @umconv=0
   			END
   		ELSE
   			BEGIN
   			SELECT @umconv=1
   			END
	 
		-- get Tax Rate, Phase, and Cost Type
		--SELECT @taxrate = 0, @oldtaxrate = 0  DC #130175
		SELECT @origtax = 0, @oldorigtax = 0

		--DC #128435
		/* Validate TaxCode by getting the accounts for the tax code */
		IF isnull(@taxcode,'') <> ''
			BEGIN						
			-- get Tax Rate
			SELECT @pstrate = 0  --DC #130175

			--DC #130175
			exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @oldactdate, NULL, NULL, NULL, NULL, 
				NULL, NULL, NULL, NULL, @oldHQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output
			IF @rcode <> 0
				BEGIN
				SELECT @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				IF @rcode <> 0 goto bspexit
				END
				
			--DC #130175
			exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @actdate, NULL /*@valueadd output*/, NULL, @taxphase output, @taxjcct output, 
				NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output
			IF @rcode <> 0
				BEGIN
				SELECT @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				IF @rcode <> 0 goto bspexit
				END
				
					
			SELECT @pstrate = (case when @gstrate = 0 then 0 else @taxrate - @gstrate end)			
						
			/*EXEC @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @oldactdate, null, @taxphase output, @taxjcct output, @errmsg output
			IF @rcode <> 0
				BEGIN
				SELECT @errortext = @errorstart + ' - ' + isnull(@errmsg,'')
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				IF @rcode <> 0 goto bspexit
				END*/
	                
			/*EXEC @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @oldactdate, @oldvalueadd output, @oldtaxrate output, @oldgstrate output, @oldpstrate output, 
				null, null, @oldHQTXdebtGLAcct output, null, null,	null, @errmsg output
			IF @rcode <> 0
				BEGIN
				SELECT @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @taxgroup),'')
				SELECT @errortext = @errortext + ' - TaxCode : ' + isnull(@taxcode,'') + ' - is not valid! - ' + @errmsg
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				IF @rcode <> 0 goto bspexit
				END     */      
				
			/*IF @oldgstrate = 0 and @oldpstrate = 0 and @oldvalueadd = 'Y'
				BEGIN
				-- We have an Intl VAT code being used as a Single Level Code
				IF (SELECT GST FROM bHQTX with (nolock) WHERE TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
					BEGIN
					SELECT @oldgstrate = @oldtaxrate
					END
				END*/
				                
			-- set Tax Phase and Cost Type
			IF @taxphase is null SELECT @taxphase = @phase
			IF @taxjcct is null SELECT @taxjcct = @jcctype
			
			/*EXEC @rcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @actdate, @valueadd output, @taxrate output, @gstrate output, @pstrate output, 
				null, null, @HQTXdebtGLAcct output, null, null, 
				null, @errmsg output
			IF @rcode <> 0
				BEGIN
				SELECT @errortext = @errorstart + 'Company : ' + isnull(convert(varchar(10),@co),'') + ' - Tax Group : ' + isnull(convert(varchar(3), @taxgroup),'')
				SELECT @errortext = @errortext + ' - TaxCode : ' + isnull(@taxcode,'') + ' - is not valid! - ' + @errmsg
				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
				IF @rcode <> 0 goto bspexit
				END*/
				
			/*IF @gstrate = 0 and @pstrate = 0 and @valueadd = 'Y'
				BEGIN
				-- We have an Intl VAT code being used as a Single Level Code
				IF (SELECT GST FROM bHQTX with (nolock) WHERE TaxGroup = @taxgroup and TaxCode = @taxcode) = 'Y'
					BEGIN
					SELECT @gstrate = @taxrate
					END
				END		*/	
			END /* tax code validation*/
	 
   		/* validation for Add types */
   		IF @transtype = 'A'
   			BEGIN
   			/* check SL Trans# */
   			IF @sltrans is not null
   				BEGIN
   				SELECT @errortext = @errorhdr + ' - (New) entries may not reference a SL Transaction #.'
   				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				IF @rcode <> 0 goto bspexit
   				END
	 
   			/* all old values should be null */ 
   			IF @oldsl is not null or @oldslitem is not null or @oldslchangeorder is not null or @oldappchangeorder is not null
   				or @oldactdate is not null or @olddescription is not null or @oldum is not null
   				or @oldcurunits is not null or @oldcurcost is not null
   				BEGIN
   				SELECT @errortext = @errorhdr + ' - Old info in batch must be null for Add entries.'
   				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				IF @rcode <> 0 goto bspexit
   				END
   			END
	 
   		/* validation for Change and Delete types */
   		IF @transtype = 'C' or @transtype = 'D'
   			BEGIN
   			/* get existing values from SLCD */
   			SELECT @oldslchangeorder=SLChangeOrder, @oldappchangeorder=AppChangeOrder, @oldactdate=ActDate,
   				@olddescription=Description, @oldchangecurunits=ChangeCurUnits,
   				@oldchgcurunitcost=ChangeCurUnitCost, @oldchangecurcost=ChangeCurCost 
   			FROM SLCD WITH (NOLOCK) 
   			WHERE SLCo = @co and Mth = @mth and SLTrans = @sltrans
   			IF @@rowcount = 0
   				BEGIN
   				SELECT @errortext = @errorhdr + ' - Missing SL Transaction#'
   				EXEC @rcode = bspHQBEInsert @co, @mth, @batchid, @errortext, @errmsg output
   				IF @rcode <> 0 goto bspexit
   				END
   			END
	 
   		/* update SL Change JC Distribution Audit */
  		IF not exists(SELECT TOP 1 1 FROM HQBE WITH (NOLOCK) WHERE Co=@co and Mth=@mth and BatchId=@batchid)
  			BEGIN
  	 		IF @transtype <> 'A'
   				BEGIN
   				/* insert 'old' entry */
				IF @dovalidation=1
   					BEGIN
					-- calculate the change to JC committed units and costs based on current POIT values
					-- and the old changes stored in POCB - result used for 'old' entry in POCA
					IF @um = 'LS'
						BEGIN
						SELECT @SLCAoldchangecurunits = 0
						SELECT @SLCAoldchgcurunitcost = 0
						SELECT @SLCAoldchangecurcost = -1 * @oldchangecurcost					
						END
					IF @um <> 'LS'
						BEGIN
						SELECT @SLCAoldchangecurunits = @oldchangecurunits
						SELECT @SLCAoldchgcurunitcost = @oldchgcurunitcost
						SELECT @SLCAoldchangecurcost = ((@slitcurunits - @oldchangecurunits) * (@curunitcost - @oldchgcurunitcost)) - (@slitcurunits * @curunitcost)					
						END
		 
					--DC #128435
					IF @oldHQTXdebtGLAcct is null
						BEGIN
						SELECT @oldorigtax = @SLCAoldchangecurcost * @taxrate  --@oldtaxrate  DC #130175 
						END
					ELSE
						BEGIN
						/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
						IF @taxrate <> 0  --DC #130175  @oldtaxrate
							BEGIN
							SELECT @oldorigtax = @SLCAoldchangecurcost * @pstrate  --DC #130175  @oldpstrate
							END
						END		 

					--DC #128435
   					-- add SL JC Distribution
					IF (@taxphase <> @phase or @taxjcct <> @jcctype) 
						BEGIN
   						INSERT INTO bSLCA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
   							BatchSeq, OldNew, SL, SLItem, VendorGroup, Vendor, SLChangeOrder,
  	 						AppChangeOrder, Description, ActDate, UM, 
  	 						ChangeUnits, 
  	 						ChangeUnitCost,
   							ChangeCost, 
   							JCUM, 
   							JCUnits,
   							TotalCmtdTax, RemCmtdTax)  --DC #130175)
						VALUES (@co, @mth, @batchid, @jcco, @job, @PhaseGroup, @phase, @jcctype,
   							@seq, 0, @sl, @slitem, @vendorgroup, @vendor, @oldslchangeorder, @oldappchangeorder,
   							@olddescription, @oldactdate, @um,
   							-1 * @SLCAoldchangecurunits,
   							-1 * @SLCAoldchgcurunitcost,
   							@SLCAoldchangecurcost, 
   							@jcum, 
   							Case when @um<>'LS' then -1 * @oldchangecurunits*@umconv else 0 end,
   							0,0)  --DC #130175
  	 						/* reverse sign on old amount */
   							IF @@rowcount = 0
   								BEGIN
  	 							SELECT @errmsg = 'Unable to update SL JC Distribution Audit!', @rcode=1
   								goto bspexit
   								END

						IF @oldorigtax <> 0
							BEGIN
   							insert into bSLCA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
   								BatchSeq, OldNew, SL, SLItem, VendorGroup, Vendor, SLChangeOrder,
  	 							AppChangeOrder, Description, ActDate, UM, 
  	 							ChangeUnits, 
  	 							ChangeUnitCost,
   								ChangeCost, 
   								JCUM, 
   								JCUnits,
   								TotalCmtdTax, RemCmtdTax)  --DC #130175)
   							values (@co, @mth, @batchid, @jcco, @job, @PhaseGroup, @taxphase, @taxjcct,
   								@seq, 0, @sl, @slitem, @vendorgroup, @vendor, @oldslchangeorder, @oldappchangeorder,
   								@olddescription, @oldactdate, @um, 
   								0,
   								0,
  	 							@oldorigtax, --DC #132626
  	 							@jcum, 
  	 							0,
  	 							@oldorigtax, @oldorigtax)  --DC #130175
  	 						/* reverse sign on old amount */
   							IF @@rowcount = 0
   								BEGIN
  	 							SELECT @errmsg = 'Unable to update SL JC Distribution Audit!', @rcode=1
   								goto bspexit
   								END
							END
						END
					ELSE
						BEGIN
   						INSERT INTO bSLCA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
   							BatchSeq, OldNew, SL, SLItem, VendorGroup, Vendor, SLChangeOrder,
  	 						AppChangeOrder, Description, ActDate, UM, 
  	 						ChangeUnits, 
  	 						ChangeUnitCost,
   							ChangeCost, 
   							JCUM, 
   							JCUnits,
   							TotalCmtdTax, RemCmtdTax)  --DC #130175))
   						VALUES (@co, @mth, @batchid, @jcco, @job, @PhaseGroup, @phase, @jcctype,
   							@seq, 0, @sl, @slitem, @vendorgroup, @vendor, @oldslchangeorder, @oldappchangeorder,
   							@olddescription, @oldactdate, @um, 
   							-1 * @SLCAoldchangecurunits,
   							-1 * @SLCAoldchgcurunitcost,
   							(@SLCAoldchangecurcost + @oldorigtax),  --DC #132626 						  	 					
   							@jcum, 
   							Case when @um<>'LS' then -1 * @oldchangecurunits*@umconv else 0 end,
   							@oldorigtax, @oldorigtax)  --DC #130175)					
  	 					/* reverse sign on old amount */
   						IF @@rowcount = 0
   							BEGIN
  	 						SELECT @errmsg = 'Unable to update SL JC Distribution Audit!', @rcode=1
   							goto bspexit
   							END
   						END
  	 				END
   				END
	 
  	 		IF @transtype <> 'D'
   				BEGIN
   				/* insert 'new' entry */ 			
				-- calculate the change to JC committed units and costs based on current POIT values
				-- and the changes stored in POCB - result used for 'new' entry in POCA
				IF @um = 'LS'
					BEGIN
					SELECT @SLCAchangecurunits = 0
					SELECT @SLCAchgcurunitcost = 0
					SELECT @SLCAchangecurcost = @changecurcost
					END

				IF @um <> 'LS'
					BEGIN
					SELECT @SLCAchangecurunits = @changecurunits
					SELECT @SLCAchgcurunitcost = @chgcurunitcost               
					IF @transtype = 'A'
						BEGIN
						SELECT @SLCAchangecurcost = ((@slitcurunits + @changecurunits) * (@chgcurunitcost+@curunitcost)) - (@slitcurunits * @curunitcost)					 
						END
					IF @transtype = 'C'	
						BEGIN						 
						SELECT @SLCAchangecurcost = ((@slitcurunits + (@changecurunits-@oldchangecurunits)) * (@curunitcost + (@chgcurunitcost - @oldchgcurunitcost))) - ((@slitcurunits - @oldcurunits) * @curunitcost)					 					 
						END
					END

	------------------
	--			select @origtax = @origcost * @taxrate		--Full TaxAmount:  This is correct whether US, Intl GST&PST, Intl GST only, Intl PST only		1000 * .155 = 155
	--			select @gsttaxamt = case @valueadd when 'Y' then (@origtax * @gstrate) / @taxrate else 0 end	--GST Tax Amount.  (Calculated)					(155 * .05) / .155 = 50
	--			select @psttaxamt = case @valueadd when 'Y' then @origtax - @gsttaxamt else 0 end	
	-------------------

				/* The code below is OK and I have left in place unless conditions change and we need more values.  In which case, 
				   we would need to adapt the code above.  There are two minor issues to the code below vs the code style above.
				   1)  We have no specific GST Tax value to work with.  (At this time it does not appear we need one.)
				   2)  The rounding error that may occur as a result of doing a direct application of pstrate to cost value
					   will be slightly different then the rest of PO processes where we use the code structure above.  (The above code
					   stucture assures that GST + PST always equal TotalTax despite rounding issues. */                
				IF @HQTXdebtGLAcct is null
					BEGIN
					/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
					   In any case:
					   a)  @taxrate is the correct value.  
					   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
					   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
					SELECT @origtax = @SLCAchangecurcost * @taxrate
					END
				ELSE
					BEGIN
					/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
					IF @taxrate <> 0
						BEGIN
						SELECT @origtax = @SLCAchangecurcost * @pstrate
						END
					END
	                 			   				
				--DC #128435
				-- add SL JC Distribution											
				IF (@taxphase <> @phase or @taxjcct <> @jcctype) 
					BEGIN
					INSERT INTO bSLCA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
 						BatchSeq, OldNew, SL, SLItem, VendorGroup, Vendor, SLChangeOrder,
						AppChangeOrder, Description, ActDate, UM, 
						ChangeUnits, 
						ChangeUnitCost,
						ChangeCost,
						JCUM, 
						JCUnits,
						TotalCmtdTax, RemCmtdTax)  --DC #130175
					VALUES (@co, @mth, @batchid, @jcco, @job, @PhaseGroup, @phase, @jcctype,
						@seq, 1, @sl, @slitem, @vendorgroup, @vendor, @slchangeorder, @appchangeorder,
						@description, @actdate, @um, 
						@SLCAchangecurunits,
						@SLCAchgcurunitcost, 
						@SLCAchangecurcost, 					
						@jcum, 										
						Case when @um<>'LS' then @changecurunits*@umconv else 0 end,
						0,0)  --DC #130175
 						/* reverse sign on old amount */
						IF @@rowcount = 0
							BEGIN
 							SELECT @errmsg = 'Unable to update SL JC Distribution Audit!', @rcode=1
							goto bspexit
							END

					IF @origtax <> 0
						BEGIN
						INSERT INTO bSLCA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
							BatchSeq, OldNew, SL, SLItem, VendorGroup, Vendor, SLChangeOrder,
 							AppChangeOrder, Description, ActDate, UM, ChangeUnits, ChangeUnitCost,
							ChangeCost, JCUM, JCUnits,
							TotalCmtdTax, RemCmtdTax)  --DC #130175)
						VALUES (@co, @mth, @batchid, @jcco, @job, @PhaseGroup, @taxphase, @taxjcct,
							@seq, 1, @sl, @slitem, @vendorgroup, @vendor, @slchangeorder, 
							@appchangeorder, @description, @actdate, @um, 0,0,
 							@origtax, @jcum, 0,
 							@origtax, @origtax)	--DC #130175				
 						/* reverse sign on old amount */
						IF @@rowcount = 0
							BEGIN
 							SELECT @errmsg = 'Unable to update SL JC Distribution Audit!', @rcode=1
							goto bspexit
							END
						END
					END
				ELSE
					BEGIN
					INSERT INTO bSLCA (SLCo, Mth, BatchId, JCCo, Job, PhaseGroup, Phase, JCCType,
 						BatchSeq, OldNew, SL, SLItem, VendorGroup, Vendor, SLChangeOrder,
						AppChangeOrder, Description, ActDate, UM, 
						ChangeUnits, 
						ChangeUnitCost,
						ChangeCost,
						JCUM, 
						JCUnits,
						TotalCmtdTax, RemCmtdTax)  --DC #130175
					VALUES (@co, @mth, @batchid, @jcco, @job, @PhaseGroup, @phase, @jcctype,
						@seq, 1, @sl, @slitem, @vendorgroup, @vendor, @slchangeorder, @appchangeorder,
						@description, @actdate, @um, 
						@SLCAchangecurunits,
						@SLCAchgcurunitcost,
						@SLCAchangecurcost + @origtax,					
						@jcum, 
						Case when @um<>'LS' then @changecurunits*@umconv else 0 end,
						@origtax, @origtax)  --DC #130175
 					/* reverse sign on old amount */
					IF @@rowcount = 0
						BEGIN
 						SELECT @errmsg = 'Unable to update SL JC Distribution Audit!', @rcode=1
						GOTO bspexit
						END
					END
   				END
  	 		END  	 	

   		fetch next from bcSLCB into @seq, @transtype, @sltrans, @sl, @slitem, @slchangeorder, @appchangeorder,
   			@actdate, @description, @um, @changecurunits, @chgcurunitcost, @changecurcost,
   			@oldsl, @oldslitem, @oldslchangeorder, @oldappchangeorder, @oldactdate, @olddescription, @oldum,
   			@oldcurunits, @oldunitcost, @oldcurcost
 
   		END
   		
	/* check HQ Batch Errors and update HQ Batch Control status */
	SELECT @status = 3	/* valid - ok to post */
	IF exists(SELECT TOP 1 1 FROM bHQBE WITH (NOLOCK) WHERE Co = @co and Mth = @mth and BatchId = @batchid)
		BEGIN
		SELECT @status = 2	/* validation errors */
		END
 
	UPDATE bHQBC
   	SET Status = @status
   	WHERE Co = @co and Mth = @mth and BatchId = @batchid
	IF @@rowcount <> 1
		BEGIN
		SELECT @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
		goto bspexit
		END
  
bspexit:
   
	IF @opencursor = 1
		BEGIN 
		close bcSLCB
		deallocate bcSLCB
		END
 
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLCBVal] TO [public]
GO
