SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspEMVal_Meters_Main]
   /***********************************************************
   * CREATED BY: JM 5/23/99
   * MODIFIED By : GG 11/27/00 - changed datatype from bAPRef to bAPReference
   *		JM 6/28/01 - Ref Issue 13849 - Added rejection of EMBF record if any value to be
   *		inserted into bEMMR is null that is a NOT NULL in that table (except EMMR.EMTrans which
   *		is assigned in the posting routine and EMMR.PostingDate which comes from the front end.)
   *	09/17/01 JM - Changed creation method for temp tables from 'select * into' to discrete declaration
   *	of specific fields. Also changed inserts into temp tables to discrete declaration of fields. 
   *	Ref Issue 14227.
   *    12/16/03 22901 TV - Had to clean this up.
   *	TV 02/11/04 - 23061 added isnulls 
   *	GF 02/01/2010 - issue #132064 set previous hour meter and previous odometer to zero.
   *
   *
   *
   * USAGE:
   * 	Validates each entry in bEMBF for a selected EM Meters batch -
   *	must be called prior to posting the batch.
   *
   * 	After initial Batch and EM checks, bHQBC Status set to 1
   *	(validation in progress), bHQBE (Batch Errors) entries are deleted.
   *
   * 	Creates a psuedo-cursor on bEMBF to validate each entry
   *	individually.
   *
   * 	Errors in batch added to bHQBE using dbo.bspHQBEInsert.
   *
   * 	bHQBC Status updated to 2 if errors found, or 3 if OK to post
   *
   * INPUT PARAMETERS
   *	EMCo        EM Company
   *	Month       Month of batch
   *	BatchId     Batch ID to validate
   *
   * OUTPUT PARAMETERS
   *	@errmsg     if something went wrong
   *
   * RETURN VALUE
   *	0   Success
   *	1   Failure
   *****************************************************/
   @co bCompany,@mth bMonth,@batchid bBatchID,@errmsg varchar(255) output
   
   as
   
   set nocount on
   
   declare @actualdate bDate, @batchseq int, @batchtranstype char(1), @currenthourmeter bHrs, @currentodometer bHrs,
   	@currenttotalhourmeter bHrs, @currenttotalodometer bHrs, @dollars bDollar, @emtrans bTrans, @emtranstype varchar(10),
   	@equipment bEquip, @errorstart varchar(50),	@errtext varchar(255), @meterhrs bHrs, @metermiles bHrs,
   	@oldactualdate bDate, @oldalloccode tinyint, @oldapco bCompany, @oldapline bItem, @oldapref bAPReference,
   	@oldaptrans bTrans, @oldapvendor bVendor, @oldasset varchar(20), @oldbatchtranstype char(1), @oldcomponent bEquip,
   	@oldcomponenttypecode varchar(10), @oldcostcode bCostCode, @oldcurrentodometer bHrs, @oldcurrenthourmeter bHrs,
   	@oldcurrenttotalodometer bHrs, @oldcurrenttotalhourmeter bHrs, @olddescription bTransDesc, @olddollars bDollar,
   	@oldemcosttype bEMCType, @oldemgroup bGroup, @oldemtrans bTrans, @oldemtranstype varchar(10), @oldequipment bEquip,
   	@oldglco bCompany, @oldgloffsetacct bGLAcct, @oldgltransacct bGLAcct, @oldhours bHrs, @oldinco bCompany,
       @oldinlocation bLoc, @oldjcco bCompany, @oldjccosttype bJCCType, @oldjcphase bPhase, @oldjob bJob,
   	@oldmaterial bMatl, @oldmatlgroup bGroup, @oldmeterhrs bHrs, @oldmetermiles bHrs, @oldmeterreaddate bDate,
   	@oldoffsetglco bCompany, @oldorigemtrans bTrans, @oldorigmth bMonth, @oldpartsstatuscode varchar(10),
   	@oldperecm char(1), @oldphasegrp bGroup, @oldprco bCompany, @oldpremployee bEmployee, 
   	/*132064*/
   	--@oldprevioushourmeter bHrs,@oldprevioustotalhourmeter bHrs,
   	--@oldpreviousodometer bHrs,  @oldprevioustotalodometer bHrs,
   	/*132064*/
   	@oldrevcode bRevCode, @oldrevdollars bDollar, @oldreversalstatus tinyint, @oldrevrate bDollar,
   	@oldrevtimeunits bUnits, @oldrevtranstype varchar(20), @oldrevusedonequip bEquip, @oldrevusedonequipco bCompany,
   	@oldrevusedonequipgroup bGroup,@oldrevworkunits bUnits, @oldserialno varchar(20), @oldsource bSource,
   	@oldtaxamount bDollar, @oldtaxbasis bDollar, @oldtaxcode bTaxCode, @oldtaxgroup bGroup,	@oldtaxrate bRate,
   	@oldtimeum bUM, @oldtotalcost bDollar, @oldum bUM, @oldunitprice bUnitCost,	@oldunits bUnits,
   	@oldvendorgrp bGroup, @oldwoitem bItem, @oldworkorder bWO, @rcode int, @source bSource, @status tinyint,
   	@unitprice bUnitCost
   	/*132064*/
   	--@previoushourmeter bHrs,	@previousodometer bHrs,
   	--@previoustotalhourmeter bHrs, @previoustotalodometer bHrs, 
   	/*132064*/
   
   
   select @rcode = 0
   -- Verify parameters passed in. 
   if @co is null
   	begin
   	select @errmsg = 'Missing Batch Company!', @rcode = 1
   	goto bspexit
   	end
   if @mth is null
   	begin
   	select @errmsg = 'Missing Batch Month!', @rcode = 1
   	goto bspexit
   	end
   if @batchid is null
   	begin
   	select @errmsg = 'Missing BatchID!', @rcode = 1
   	goto bspexit
   	end
   
   /*Validate batch data, set HQ Batch status. clear HQ Batch Errors 
     and clear and refresh HQCC entries. Exit immediately if batch doesnt validate. */
   
   exec @rcode = dbo.bspEMVal_Meters_BatchVal @co, @mth, @batchid, @errmsg output
   if @rcode <> 0 goto bspexit
   
   declare btEMBFCursor cursor for
   select  BatchSeq, ActualDate, BatchTransType, CurrentHourMeter, CurrentOdometer, CurrentTotalHourMeter, CurrentTotalOdometer,
   		EMTrans, EMTransType, Equipment, MeterHrs, MeterMiles, OldActualDate, OldAllocCode, OldAPCo, OldAPLine,
   		OldAPRef, OldAPTrans, OldAPVendor, OldAsset, OldBatchTransType, OldComponent, OldComponentTypeCode,
   		OldCostCode, OldCurrentOdometer, OldCurrentHourMeter, OldCurrentTotalHourMeter, OldCurrentTotalOdometer,
   		OldDescription, OldDollars, OldEMCostType, OldEMGroup, OldEMTrans, OldEMTransType, OldEquipment, OldGLCo,
   		OldGLOffsetAcct, OldGLTransAcct, OldHours, OldINCo, OldINLocation, OldJCCo, OldJCCostType, OldJCPhase,
   		OldJob, OldMaterial, OldMatlGroup, OldMeterHrs, OldMeterMiles, OldMeterReadDate, OldOffsetGLCo,
   		OldOrigEMTrans, OldOrigMth, OldPartsStatusCode, OldPerECM, OldPhaseGrp, OldPRCo, OldPREmployee,
   		/*132064*/
   		--OldPreviousHourMeter, OldPreviousOdometer,
   		--OldPreviousTotalHourMeter, OldPreviousTotalOdometer,
   		/*132064*/ 
   		OldRevCode, OldRevDollars, OldReversalStatus, OldRevRate, OldRevTimeUnits, OldRevTransType,
   		OldRevUsedOnEquip, OldRevUsedOnEquipCo, OldRevUsedOnEquipGroup, OldRevWorkUnits, OldSerialNo,
   		OldSource, OldTaxAmount, OldTaxBasis, OldTaxCode, OldTaxGroup, OldTaxRate, OldTimeUM, OldTotalCost,
   		OldUM, OldUnitPrice, OldUnits, OldVendorGrp, OldWOItem, OldWorkOrder,  Source, UnitPrice
   		/*132064*/
   		--PreviousHourMeter,PreviousOdometer,
   		-- PreviousTotalHourMeter, PreviousTotalOdometer
   		/*132064*/ 
   		
   from bEMBF 
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   open btEMBFCursor
   FetchNext:
   fetch next from btEMBFCursor into 
       @batchseq, @actualdate, @batchtranstype,  @currenthourmeter,
   	@currentodometer,@currenttotalhourmeter, @currenttotalodometer,@emtrans,@emtranstype,
   	@equipment,@meterhrs,@metermiles,@oldactualdate,@oldalloccode, @oldapco, @oldapline,  @oldapref,
   	@oldaptrans, @oldapvendor,@oldasset, @oldbatchtranstype, @oldcomponent,
   	@oldcomponenttypecode, @oldcostcode, @oldcurrentodometer, @oldcurrenthourmeter,
   	@oldcurrenttotalhourmeter, @oldcurrenttotalodometer, @olddescription,@olddollars, @oldemcosttype,
   	@oldemgroup, @oldemtrans, @oldemtranstype, @oldequipment, @oldglco,@oldgloffsetacct, @oldgltransacct,
   	@oldhours,@oldinco,@oldinlocation,@oldjcco, @oldjccosttype,@oldjcphase, @oldjob, @oldmaterial, @oldmatlgroup, 
   	@oldmeterhrs,@oldmetermiles, @oldmeterreaddate, @oldoffsetglco, @oldorigemtrans, @oldorigmth, 
   	@oldpartsstatuscode,@oldperecm, @oldphasegrp, @oldprco, @oldpremployee, 
   	/*132064*/
   	--@oldprevioushourmeter, @oldprevioustotalhourmeter, 
   	--@oldpreviousodometer,@oldprevioustotalodometer, 
   	--/*132064*/
   	@oldrevcode, @oldrevdollars, @oldreversalstatus, @oldrevrate, @oldrevtimeunits, @oldrevtranstype, @oldrevusedonequip,
   	@oldrevusedonequipco, @oldrevusedonequipgroup, @oldrevworkunits, @oldserialno, @oldsource, @oldtaxamount,
   	@oldtaxbasis, @oldtaxcode, @oldtaxgroup, @oldtaxrate,@oldtimeum, @oldtotalcost, @oldum, @oldunitprice, 
   	@oldunits, @oldvendorgrp, @oldwoitem, @oldworkorder, @source,@unitprice 
   	/*132064*/
   	--@previoushourmeter, @previousodometer, 
    -- @previoustotalhourmeter, @previoustotalodometer 
   /*132064*/ 
     
   
   if @@fetch_status <> 0 goto FetchEnd
   	
 
   -- Setup @errorstart string.
   	select @errorstart = 'Seq ' + isnull(convert(varchar(9),@batchseq),'') + '-'
   	
       -- Validate BatchTransType. 
   	if @batchtranstype not in ('A','C','D')
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Invalid BatchTransType, must be A,C, or D.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	-- Validate EMTransType = 
   	if @emtranstype <> 'Equip'
   		begin
   		select @errtext = isnull(@errorstart,'') + isnull(@emtranstype,'') + ' is an invalid EMTransType.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	-- Verify UnitPrice not null. 
   	if @unitprice is null
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Invalid UnitPrice, must be not null.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   
   	-- Verify Equipment not null. 
   	if @equipment is null
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Invalid Equipment, must be not null.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	-- Verify ActualDate (EMMR.ReadingDate) not null. 
   	if @actualdate is null
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Invalid ActualDate, must be not null.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	-- Verify Source not null. 
   	if @source is null
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Invalid Source, must be not null.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   		
   /*132064*/		
   	-- Verify PreviousHourMeter not null. 
   	--if @previoushourmeter is null
   	--	begin
   	--	select @errtext = isnull(@errorstart,'') + 'Invalid PreviousHourMeter, must be not null.'
   	--	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	--	if @rcode <> 0
   	--		begin
   	--	    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   	--		goto bspexit
   	--		end
   	--	end
   	   	/*132064*/			
   	-- Verify PreviousTotalHourMeter not null. 
   	--if @previoustotalhourmeter is null
   	--	begin
   	--	select @errtext = isnull(@errorstart,'') + 'Invalid PreviousTotalHourMeter, must be not null.'
   	--	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	--	if @rcode <> 0
   	--		begin
   	--	    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   	--		goto bspexit
   	--		end
   	--	end	
   		
   	-- Verify CurrentHourMeter not null. 
   	if @currenthourmeter is null
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Invalid CurrentHourMeter, must be not null.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	-- Verify CurrentTotalHourMeter not null. 
   	if @currenttotalhourmeter is null
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Invalid CurrentTotalHourMeter, must be not null.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	-- Verify MeterHrs (EMMR.Hours) not null. 
   	if @meterhrs is null
   		begin
  
   		select @errtext = isnull(@errorstart,'') + 'Invalid MeterHrs, must be not null.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   		
   	/*132064*/		
   	-- Verify PreviousOdometer not null. 
   	--if @previousodometer is null
   	--	begin
   	--	select @errtext = isnull(@errorstart,'') + 'Invalid PreviousOdometer, must be not null.'
   	--	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	--	if @rcode <> 0
   	--		begin
   	--	    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   	--		goto bspexit
   	--		end
   	--	end
   	--   	/*132064*/			
   	---- Verify PreviousTotalOdometer not null. 
   	--if @previoustotalodometer is null
   	--	begin
   	--	select @errtext = isnull(@errorstart,'') + 'Invalid PreviousTotalOdometer, must be not null.'
   	--	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   	--	if @rcode <> 0
   	--		begin
   	--	    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   	--		goto bspexit
   	--		end
   	--	end
   		
   	-- Verify CurrentOdometer not null. 
   	if @currentodometer is null
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Invalid CurrentOdometer, must be not null.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	-- Verify CurrentTotalOdometer not null. 
   	if @currenttotalodometer is null
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Invalid CurrentTotalOdometer, must be not null.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   	-- Verify MeterMiles (EMMR.Miles) not null. 
   	if @metermiles is null
   		begin
   		select @errtext = isnull(@errorstart,'') + 'Invalid MeterMiles, must be not null.'
   		exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   		if @rcode <> 0
   			begin
   		    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   			goto bspexit
   			end
   		end
   
   
   	if @batchtranstype = 'A'
   		begin
           if @emtrans is not null
   			begin
   			select @errtext = isnull(@errorstart,'') + 'New entries may not ref a EMTrans.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   			    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   		-- Verify all 'old' values are null. 
   		if @oldactualdate is not null or
   			@oldalloccode is not null or
   			@oldapco is not null or
   			@oldapline is not null or
   			@oldapref is not null or
   			@oldaptrans is not null or
   			@oldapvendor is not null or
   			@oldasset is not null or
   			@oldbatchtranstype is not null or
   			@oldcomponent is not null or
   			@oldcomponenttypecode is not null or
   			@oldcostcode is not null or
   			@oldcurrentodometer is not null or
   			@oldcurrenthourmeter is not null or
   			@oldcurrenttotalhourmeter is not null or
   			@oldcurrenttotalodometer is not null or
   			@olddescription is not null or
   			@olddollars is not null or
   			@oldemcosttype is not null or
   			@oldemgroup is not null or
   			@oldemtrans is not null or
   			@oldemtranstype is not null or
   			@oldequipment is not null or
   			@oldglco is not null or
   			@oldgloffsetacct is not null or
   			@oldgltransacct is not null or
   			@oldhours is not null or
   			@oldinco is not null or
   			@oldinlocation is not null or
   			@oldjcco is not null or
   			@oldjccosttype is not null or
   			@oldjcphase is not null or
   			@oldjob is not null or
   			@oldmaterial is not null or
   			@oldmatlgroup is not null or
   			@oldmeterhrs is not null or
   			@oldmetermiles is not null or
   			@oldmeterreaddate is not null or
   			@oldoffsetglco is not null or
   			@oldorigemtrans is not null or
   			@oldorigmth is not null or
   			@oldpartsstatuscode is not null or
   			@oldperecm is not null or
   			@oldphasegrp is not null or
   			@oldprco is not null or
   			@oldpremployee is not null or
   			/*132064*/
   			--@oldprevioushourmeter is not null or
   			--@oldpreviousodometer is not null or
   			--@oldprevioustotalhourmeter is not null or
   			--@oldprevioustotalodometer is not null or
   			/*132064*/
   			@oldrevcode is not null or
   			@oldrevdollars is not null or
   			@oldreversalstatus is not null or
   			@oldrevrate is not null or
   			@oldrevtimeunits is not null or
   			@oldrevtranstype is not null or
   			@oldrevusedonequip is not null or
   			@oldrevusedonequipco is not null or
   			@oldrevusedonequipgroup is not null or
   			@oldrevworkunits is not null or
   			@oldserialno is not null or
   			@oldsource is not null or
   			@oldtaxamount is not null or
   			@oldtaxbasis is not null or
   			@oldtaxcode is not null or
   			@oldtaxgroup is not null or
   			@oldtaxrate is not null or
   			@oldtimeum is not null or
   			@oldtotalcost is not null or
   			@oldum is not null or
   			@oldunitprice is not null or
   			@oldunits is not null or
   			@oldvendorgrp is not null or
   			@oldwoitem is not null or
   			@oldworkorder is not null
   			begin
   			select @errtext = isnull(@errorstart,'') + 'Old info must be null for Add entries.'
   			exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
   			if @rcode <> 0
   				begin
   			    	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
   				goto bspexit
   				end
   			end
   	end 
       if @batchtranstype = 'A' or @batchtranstype = 'C'
   		exec @rcode = dbo.bspEMVal_Meters_AddedChanged @co, @mth, @batchid, @batchseq, @errmsg output
   		if @rcode <> 0 goto bspexit
   
       if @batchtranstype = 'C' or @batchtranstype = 'D'
   		exec @rcode = dbo.bspEMVal_Meters_ChangedDeleted @co, @mth, @batchid, @batchseq, @errmsg output
   		if @rcode <> 0 goto bspexit
   
   goto FetchNext
   FetchEnd:
   close btEMBFCursor
   deallocate btEMBFCursor
   
   
   -- Check HQ Batch Errors and update HQ Batch Control status. 
   if exists(select top 1 1 from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid)
   	select @status = 2 
   else
   	select @status = 3 
   
   update bHQBC
   set Status = @status
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount <> 1
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control status!', @rcode = 1
   	goto bspexit
   	end
   
   if @rcode <> 0 goto bspexit
   bspexit:
   	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Meters_Main]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Meters_Main] TO [public]
GO
