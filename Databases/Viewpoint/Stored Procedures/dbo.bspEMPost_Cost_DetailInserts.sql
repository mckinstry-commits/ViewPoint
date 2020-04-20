SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                                      procedure [dbo].[bspEMPost_Cost_DetailInserts]
     /***********************************************************
     * CREATED BY: JM 12/9/99 as consolidation of bspEMPost_Cost_EMMRInserts and
     *             bspEMPost_Cost_EMCDInserts
     *
     * MODIFIED By:JM 1/3/00 Added insert into Inventory detail file bINDT from bEMIN.
     *             Note 1/4/00 - RH stated the following regarding adding INTrans/INTransType
     *             to bEMBF for processing of records recalled into a batch for change or delete:
     *             ------------------------------------------------------------------------------
     *             'A parts posting from EM to IN creates a record in Inventory, but if we call the EM trans
     *             back up into a batch and change it, it will create two new IN transactions, one backing out
     *             the old amount, and one adding in the new amount. So now our EM trans is tied to three IN
     *             transactions. I checked with Gary to get his opinion and he saw no need to keep the IN Trans #
     *             in EM, and he is not storing the EM trans # in IN. Maybe something will change as IN is more
     *             fully developed, but at this time I don't think we need IN trans or trans type.'
     *             ------------------------------------------------------------------------------
     *            JM 2/22/00 Changed if statement that skips EMCD insert if Source = EMFuel and Units = 0 and
     *            Dollars = 0 to selects vs Source 'EMAdj' and EMTransType 'Fuel'. Changed error msg when not
     *            all records processed to include EMTransType.
     *            JM 3/3/00 - Made sure that update of EMMR was being done by EMBF.MeterTrans coming back from
     *            EMCD on Add Transaction.
     *            DANF 04/11/00 - Corrected changed of employee
     *            bc 06/06/00 - added code to update EMDS for depreciation purposes
     *            DANF 06/23/00 - Updated Update to Inventory.
     *            DANF 06/06/00 - Corrected update of tax amount.
     *             GG 11/27/00 - changed datatype from bAPRef to bAPReference
     *	            JM 6/5/01 - Ref Issue 13412 - Set @taxamount to 0 when Source = 'EMAdj' and EMTransType = 'Fuel'
     *             MV 06/07/01 - Issue 12769 BatchMemoUserUpdate
     *	JM 8/27/01 - Ref Issue 14064. Moved deletion of batch record out of 
     *	bspEMPost_Cost_DetailInserts to bottom of BatchSeq loop in bspEMPost_Cost_Main. 
     *	JM 09/25/01 - Ref Issue 14064 also - Forgot to remove check of bEMBF at very end
     *	of this procedure near comment line  -- Make sure batch is empty--   that runs a
     *	if exists(select * from bEMBF . . . this will always turn up a record since the deletion
     *	was moved to bspEMPost_Cost_Main.
     *	JM 11/07/901 - Added deletion of batch record back to this procedure from bspEMCost_Post_Main
     * 	TV/RM 02/22/02 Attachment Fix
     *	GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
     *             DANF 05/15/02 - #15907 - Correct Update to EMDS for AmtTaken
     *             DANF 07/24/02 - Added check for asset before updating EMDS..
     *             DANF 10/04/02 - Added check to update @components in EMDS - 18251
     *	JM 11-01-2002 Ref Issue 19145 - Added definition of @ddfhformname for 'EMAlloc' and 'EMDepr' sources.
     *   TV 12/18/03 23364 - Need to update EMWP with PartStatus
     *   TV 1/15/03 23364 - Forgot to check HQMT 
     *   TV 1/22/04 23364 Needed to reset value to null
     *   TV 1/22/04 23364 @partstatus needs to be Varchar(10)
     *	 tv 2/04/04 23628 - added isnulls to update statement
     *	TV 02/11/04 - 23061 added isnulls
     *    TV 12/04/03 18616 --reindex Attachments 
     *	TV 07/22/04 25192 - InuseBatchId gets set to null by the EMBF Delete trigger.
     *	TV 11/24/24 26305 - EM Cost Adjustment batch GL posting taking over an hour for 10,000 records	
     *	TV 8/17/05 28441 - EMCD.TaxType is null when EM transactions contain Taxcode and TaxAmount, probably should default to 2, for Use Tax.
	 *  GP 04/30/2008 - #128089 Changed EMMR insert and update statements to use @dateposted for PostingDate column in EMMR.
	 *	GP 05/26/2009 - #133434 Removed HQAT code
	 *	TRL 02/16/2010 #132064 Remove Previous Meter columns from EMMR update 
	 *
     * USAGE:
     * 	Called by bspEMPost_Cost_Main to insert validated entries into bEMMR and bEMCD.
     *
     * INPUT PARAMETERS
     *   	EMCo       	EM Co
     *   	Month      	Month of batch
     *   	BatchId    	Batch ID to validate
     *	    Source		Batch Source - 'EMAdj', 'EMParts', 'EMDepr', 'EMFuel'
     *
     * OUTPUT PARAMETERS
     *   	@errmsg     	If something went wrong
     *
     * RETURN VALUE
     *   	0   		Success
     *   	1   		fail
     *****************************************************/
     (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate, @errmsg varchar(255) output)
     
     as
     
     set nocount on
     
     declare @actualdate bDate, @alloccode tinyint, @apco bCompany, @apline int, @apref bAPReference, @aptrans bTrans,
     @apvendor bVendor, @asset varchar(20), @batchseq int, @batchtranstype char(1), @component bEquip, 
     @componenttypecode varchar(10), @costcode bCostCode, @currenthourmeter bHrs, @currentodometer bHrs,
     @currenttotalhourmeter bHrs, @currenttotalodometer bHrs, @ddfhformname varchar(30), @description bTransDesc,
     @dollars bDollar, @emcdemtransnew bTrans, @emcosttype bEMCType, @emgroup bGroup, @emmremtransnew bTrans,
     @emtrans bTrans, @emtranscurr bTrans, @emtranstype varchar(10), @equipment bEquip, @glco bCompany,
     @gloffsetacct bGLAcct, @gltransacct bGLAcct, @inco bCompany, @inlocation bLoc, @intranscurr bTrans,
     @intransnew bTrans, @intranstype varchar(10), @keyfield varchar(128), @material bMatl, @matlgroup bGroup,
     @metertrans bTrans, @msg varchar(255), @origemtrans bTrans, @origmth bMonth, @rcode int, @reversalstatus tinyint,
     @perecm bECM, @postedum bUM, @postedunits bUnits, @postedunitcost bDollar, @postedperecm bECM, @postedtotalcost bDollar,
     @prco bCompany, @premployee bEmployee, @previoushourmeter bHrs, @previousodometer bHrs, @previoustotalhourmeter bHrs, 
     @previoustotalodometer bHrs, @serialno varchar(20), @source bSource, @stdum bUM, @stkum bUM, @stkunits bUnits,
     @stkunitcost bDollar, @stkecm bECM, @stktotalcost bDollar, @pecm bECM, @totalprice bDollar, @taxamount bDollar,
     @taxbasis bDollar, @taxcode bTaxCode, @taxgroup bGroup, @taxrate bRate, @totalcost bDollar, @um bUM, @unitprice bUnitCost,
     @units bUnits, @updatekeyfield varchar(128), @vendorgrp bGroup, @woitem bItem, @workorder bWO, @guid uniqueIdentifier,
     @equipmentasset bEquip, @emwp_material bMatl, @partstatus Varchar(10),
     @oldcurrenthourmeter bHrs, @oldcurrentodometer bHrs
     
     select @rcode = 0
     
     -- Get the first BatchSeq for this batch from bEMBF for pseudo-cursor. 
     select @batchseq = min(BatchSeq)
     from bEMBF
     where Co = @co and Mth = @mth and BatchId = @batchid
     
      
     while @batchseq is not null
         begin
         -- make sure @emmremtransnew is null for each pass through the loop 
         select @emmremtransnew = null
         
         select @actualdate = ActualDate,
         	    @alloccode = AllocCode,
         	    @apco = APCo,
     			@apline = APLine,
     			@apref = APRef,
    		 	@aptrans = APTrans,
    		 	@apvendor = APVendor,
    		 	@asset = Asset,
    		 	@batchtranstype = BatchTransType,
    		 	@component = Component,
    		 	@componenttypecode = ComponentTypeCode,
    		 	@costcode = CostCode,
    		 	@currenthourmeter = isnull(CurrentHourMeter,0),
    		 	@currentodometer = isnull(CurrentOdometer,0),
    		 	@description = Description,
    		 	@dollars = isnull(Dollars,0),
    		 	@emcosttype = EMCostType,
    		 	@emgroup = EMGroup,
    		 	@emtranscurr = EMTrans,
    		 	@emtranstype = EMTransType,
    		 	@equipment = Equipment,
    		 	@glco = GLCo,
    		 	@gloffsetacct = GLOffsetAcct,
    		 	@gltransacct = GLTransAcct,
    		 	@inco = INCo,
    		 	@inlocation = INLocation,
    		  	@material = Material,
    		 	@matlgroup = MatlGroup,
         		@metertrans = MeterTrans,
    		 	@origemtrans = OrigEMTrans,
    		 	@origmth = OrigMth,
        		@partstatus = PartsStatusCode,
    		 	@perecm = PerECM,
    		 	@prco = PRCo,
    		 	@premployee = PREmployee,
    		 	@reversalstatus = ReversalStatus,
    		 	@serialno = SerialNo,
    		 	@source = Source,
    		 	@taxamount = isnull(TaxAmount,0),
    		 	@taxbasis = TaxBasis,
    		 	@taxcode = TaxCode,
    		 	@taxgroup = TaxGroup,
    		 	@taxrate = TaxRate,
    		 	@totalcost = TotalCost,
    		 	@um = UM,
    		 	@unitprice = isnull(UnitPrice,0),
    		 	@units = isnull(Units,0),
    		 	@vendorgrp = VendorGrp,
    		 	@woitem = WOItem,
    		 	@workorder = WorkOrder,
    			@stkum = INStkUM,
    			@stkunitcost = INStkUnitCost,
    			@stkecm = INStkECM,
                 @guid = UniqueAttchID,
                 
                 @oldcurrenthourmeter = OldCurrentHourMeter,
                 @oldcurrentodometer = OldCurrentOdometer
         from bEMBF
    
         where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@batchseq
    
         
         
         -- JM 11-01-2002 Ref Issue 19145 - Added definition of @ddfhformname for 'EMAlloc' and 'EMDepr' sources.
         select @ddfhformname =   case @source
                                  when 'EMAdj' then 'EMCostAdj'
                                  when 'EMParts' then 'EMWOPartsPosting'
                                  when 'EMTime' then 'EMWOTimeCards'
                                  when 'EMFuel' then 'EMFuelPosting' --added for Issue 12769 - BatchUserMemoUpdate
                                  when 'EMDepr' then 'EMCostAdj'
                                  when 'EMAlloc' then 'EMCostAdj'
                                  end
         
    	 
         if (select count(*) from bEMBF
             where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
             and ((isnull(CurrentHourMeter,0)> 0 ) or (isnull(CurrentOdometer,0) > 0))) = 0
             goto EMCDinsert 
         else
             begin
             
             -- Get OdoReading and HourReading from bEMEM to insert into bEMMR as 'previous' values,
             -- and then set current totals. 
             select  @previoushourmeter = isnull(HourReading,0),
              	           @previoustotalhourmeter = isnull(ReplacedHourReading,0) + isnull(HourReading,0),
              	           @currenttotalhourmeter = isnull(ReplacedHourReading,0) +  @currenthourmeter  ,
              	   
                  	@previousodometer = isnull(OdoReading,0),
                  	@previoustotalodometer = isnull(ReplacedOdoReading,0) + isnull(OdoReading,0),
                 	@currenttotalodometer = isnull(ReplacedOdoReading,0) + @currentodometer
             from bEMEM
             where EMCo = @co and Equipment = @equipment
             
             BEGIN TRANSACTION
             if @batchtranstype = 'A'
             	begin
             	
             	exec @emmremtransnew = bspHQTCNextTrans 'bEMMR', @co, @mth, @errmsg output
                 
             	if @emmremtransnew = 0
             		begin
             		ROLLBACK TRANSACTION
             		goto get_next_batchseq
             		end
             	else
             	    begin
             		-- Make sure Currents are 0 if they come in as null. 
                     select @currentodometer = isnull(@currentodometer,0)
                     select @currenthourmeter = isnull(@currenthourmeter,0)
             		
             		--INSERT INTO JerTemp(stuff)
             		--SELECT 
             		--'@currenthourmeter=' + CONVERT(varchar, @currenthourmeter) + ', ' +
             		--'@currenttotalhourmeter=' + CONVERT(varchar, @currenttotalhourmeter) + ', ' +
             		--'@previoushourmeter=' + CONVERT(varchar, @previoushourmeter) + ', ' +
             		--'@currentodometer=' + CONVERT(varchar, @currentodometer) + ', ' +
             		--'@currenttotalodometer=' + CONVERT(varchar, @currenttotalodometer) + ', ' +
             		--'@previousodometer=' + CONVERT(varchar, @previousodometer) + ', '
             		
                     -- Insert EM Meter Detail. 
             		insert bEMMR (EMCo, Mth, EMTrans, BatchId, Equipment, PostingDate, ReadingDate, Source, 
             		        PreviousHourMeter, 
             		        CurrentHourMeter,
                            PreviousTotalHourMeter, 
                            CurrentTotalHourMeter,
                             Hours,
                            PreviousOdometer,
                            CurrentOdometer,
             		        PreviousTotalOdometer,
             		        CurrentTotalOdometer, 
             		        Miles)
             		values (@co, @mth, @emmremtransnew, @batchid, @equipment, @dateposted, @actualdate, @source, 
             			   0,/*PreviouseHourMeter*/  /*@previoushourmeter 132064*/ 
             			   @currenthourmeter,/*CurrentHourMeter--Value entered from Batch Transaction*/
             			   0, /*@previoustotalhourmeter, 132064*/
             			   CASE WHEN @currenthourmeter =0 THEN  @previoustotalhourmeter ELSE @currenttotalhourmeter END,--derived from EMEM Replaced Meter + CurrentHourMeter from Batch Transaction
             			   @currenthourmeter - case @currenthourmeter when 0 then 0 else @previoushourmeter end,/*Hours*/
					    0,/*@previousodometer, 132064*/ 
					    @currentodometer, 0,/*@previoustotalodometer, 132064*/
					   CASE WHEN @currentodometer =0 THEN  @previoustotalodometer ELSE @currenttotalodometer END, --derived from EMEM Replaced Meter + CurrentOdometer from Batch Transaction
					    @currentodometer - case @currentodometer when 0 then 0 else @previousodometer end) /*Meters*/
				             
             		if @@rowcount = 0
             			begin
             			ROLLBACK TRANSACTION
             			goto EMCDinsert
             			end
      
             		end
             	end
             -- For changes, update existing EM Cost Detail Transaction. 
             if @batchtranstype = 'C'
             	begin
             
             	update bEMMR
             	set BatchId = @batchid,
             		Equipment = @equipment,
             		PostingDate = @dateposted,
             		ReadingDate = @actualdate,
             		Source = @source,
             		PreviousHourMeter = 0, /*@previoushourmeter 132064*/
             		PreviousTotalHourMeter =  0,  /*@previoustotalhourmeter*/
             		PreviousOdometer =  0, /*@previousodometer */
             		PreviousTotalOdometer =  0, /*@previoustotalodometer 132064*/
             		CurrentHourMeter = @currenthourmeter,
             		CurrentTotalHourMeter = @currenttotalhourmeter,
             		CurrentOdometer = @currentodometer,
                		CurrentTotalOdometer = @currenttotalodometer,
                	/*132064*/
                	Hours = Hours + (@currenthourmeter -@oldcurrenthourmeter),
                	Miles = Miles + (@currentodometer -@oldcurrentodometer)
             	where EMCo = @co and Mth = @mth and EMTrans = @metertrans
             	if @@rowcount = 0
             		begin
             		ROLLBACK TRANSACTION
             		goto EMCDinsert
             		end
   
              	end
             -- For deletions, delete existing EM Meter Transaction. 
             if @batchtranstype = 'D'
             	begin
             	delete bEMMR
             	where EMCo = @co and Mth = @mth and EMTrans = @metertrans
             	if @@rowcount = 0
             		begin
             		ROLLBACK TRANSACTION
             		goto EMCDinsert
             		end
   
              	end
         
         --  removed deletion of current row in bEMBF - ref Issue 5586
         -- 	delete from bEMBF
         -- 	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
         COMMIT TRANSACTION
         end
         
         EMCDinsert:
         
         -- Set @taxamount and @taxbasis to 0 for Fuel transactions 
         if @source = 'EMAdj' and @emtranstype = 'Fuel'
         select @taxamount = 0, @taxbasis = 0
         
         if @source = 'EMAdj' and @emtranstype = 'Fuel' and @units = 0 and @dollars = 0
         begin
         -- delete record with 0 amount without warning per DH 2/29/00 - Ref 2/29/00 rej to Issue 6208 
         delete from bEMBF where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
         goto get_next_batchseq 
         end
         
         if (isnull(@currenthourmeter,0) <> 0) or (isnull(@currentodometer,0)<> 0)
              select  @currenttotalhourmeter = isnull(ReplacedHourReading,0) + isnull(@currenthourmeter,0),
                      @currenttotalodometer = isnull(ReplacedOdoReading,0) + isnull(@currentodometer,0)
              from bEMEM
              where EMCo = @co and Equipment = @equipment
         
         BEGIN TRANSACTION
         -- For additions, add new EM Detail Transaction. 
         if @batchtranstype = 'A'
         	begin
     
         	-- Get next available transaction # for bEMCD. 
         	exec @emcdemtransnew = bspHQTCNextTrans 'bEMCD', @co, @mth, @errmsg output
         	if @emcdemtransnew = 0
         		begin
         		ROLLBACK TRANSACTION
         		select @rcode = 1
         		goto bspexit  --goto get_next_batchseq
         		end
         	else
         		begin
              			-- depreciation code needed to update EMDS 
         					-- Danf Added AmtTaken to Set Statement    
              			if @source = 'EMDepr' and isnull(@asset,'') <> ''
                			    begin
         					select @equipmentasset = @equipment
         					if isnull(@component,'')<>'' select @equipmentasset = @component
                                 begin
                    			    update bEMDS
                    			    set AmtTaken = AmtTaken + @dollars
                    			    from bEMDS
                    			    where EMCo = @co and Equipment = @equipmentasset and Asset = @asset and Month = @mth
             					if @@rowcount = 0
             						begin
             						insert into bEMDS (EMCo, Equipment, Asset, Month, AmtToTake, AmtTaken)
             						values            (@co, @equipmentasset, @asset, @mth, 0, @dollars)
             						if @@rowcount = 0
             							begin
             							ROLLBACK TRANSACTION
             							goto get_next_batchseq
             							end
             						end
             					end
                              end
     
         	    		-- Insert EM Detail. 
         	    		insert bEMCD (EMCo, Mth, EMTrans, BatchId, EMGroup, Equipment,
         	    			Component, ComponentTypeCode, Asset, WorkOrder, WOItem,
         	    			CostCode, EMCostType, PostedDate, ActualDate, Source,
         	    			EMTransType, Description, GLCo, GLTransAcct, GLOffsetAcct,
         	    			ReversalStatus, PRCo, PREmployee, APCo, APTrans, APLine,
         	    			VendorGrp, APVendor, APRef, MatlGroup, INCo, INLocation,
         	    			Material, SerialNo, UM, Units, Dollars, UnitPrice, PerECM,
         	    			TotalCost, AllocCode, TaxCode, TaxGroup, TaxBasis, TaxRate,
         	    			TaxAmount, MeterTrans, CurrentHourMeter, CurrentTotalHourMeter,
         	    			CurrentOdometer, CurrentTotalOdometer, INStkUM, INStkECM, INStkUnitCost,
                          UniqueAttchID, TaxType)
         	    		values (@co, @mth, @emcdemtransnew, @batchid, @emgroup, @equipment,
         	    			@component, @componenttypecode, @asset, @workorder, @woitem,
         	    			@costcode, @emcosttype, @dateposted, @actualdate, @source,
         	    			@emtranstype, @description, @glco, @gltransacct, @gloffsetacct,
         	    			@reversalstatus, @prco, @premployee, @apco, @aptrans, @apline,
         	    			@vendorgrp, @apvendor, @apref, @matlgroup, @inco, @inlocation,
         	    			@material, @serialno, @um, @units, (@dollars +@taxamount), @unitprice, @perecm,
         	    			@totalcost, @alloccode, @taxcode, @taxgroup, @taxbasis, @taxrate,
         	    			@taxamount, @emmremtransnew, isnull(@currenthourmeter,0), isnull(@currenttotalhourmeter,0),
         	    			isnull(@currentodometer,0), isnull(@currenttotalodometer,0), @stkum, @stkecm, @stkunitcost,
                          @guid, case when (@taxcode is not null )then 2 else null end)--TV 8/17/05 28441
         	    		if @@rowcount = 0
         	    			begin
         	    			ROLLBACK TRANSACTION
         	    			goto get_next_batchseq
         				end
         		else
         			begin
         			-- If new transaction is a reversing entry then flag the original entry as reversed. 
         			if @reversalstatus = 2
         				update bEMCD
         				set ReversalStatus = 3
         				where EMCo = @co and Mth = @origmth and EMTrans = @origemtrans
         			-- If new transaction is canceling reversing entry then	flag the original entry as not reversing. 
         			if @reversalstatus = 4
         				update bEMCD set ReversalStatus = 0
         				where EMCo = @co and Mth = @origmth
         					and EMTrans = @origemtrans
           				
   				end
   	
   				--TV 11/24/24 26305 - EM Cost Adjustment batch GL posting taking over an hour for 10,000 records	
   				update bEMGL 
   				set EMTrans = @emcdemtransnew
   				where EMCo = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@batchseq
          		end
          end
         
         -- For changes, update existing EM Cost Detail Transaction. 
         if @batchtranstype = 'C'
         	begin
         	update bEMCD
         	set BatchId = @batchid,
         		EMGroup = @emgroup,
         		Equipment = @equipment,
         		Component = @component,
         		ComponentTypeCode = @componenttypecode,
         		Asset = @asset,
         		WorkOrder = @workorder,
         		WOItem = @woitem,
         		CostCode = @costcode,
         		EMCostType = @emcosttype,
         		PostedDate = @dateposted,
         		ActualDate = @actualdate,
         		Source = @source,
         		EMTransType = @emtranstype,
         		Description = @description,
         		--InUseBatchID = null, TV 07/22/04 25192 - InuseBatchId gets set to null by the EMBF Delete trigger.
         		GLCo = @glco,
         		GLTransAcct = @gltransacct,
         		GLOffsetAcct = @gloffsetacct,
         		ReversalStatus = @reversalstatus,
         		PRCo = @prco,
         		PREmployee = @premployee,
         		APCo = @apco,
         		APTrans = @aptrans,
         		APLine = @apline,
         		VendorGrp = @vendorgrp,
         		APVendor = @apvendor,
         		APRef = @apref,
         		MatlGroup = @matlgroup,
         		INCo = @inco,
         		INLocation = @inlocation,
         		Material = @material,
         		SerialNo = @serialno,
         		UM = @um,
         		Units = @units,
         		Dollars = (@dollars + @taxamount),
         		UnitPrice = @unitprice,
         		PerECM = @perecm,
         		TotalCost = @totalcost,
         		AllocCode = @alloccode,
         		TaxCode = @taxcode,
         		TaxGroup = @taxgroup,
         		TaxBasis = @taxbasis,
         		TaxRate = @taxrate,
         		TaxAmount = @taxamount,
    			--tv 2/04/04 23628 - added isnulls to update statement
         		CurrentHourMeter = isnull(@currenthourmeter,0),
         		CurrentTotalHourMeter = isnull(@currenttotalhourmeter,0),
         		CurrentOdometer = isnull(@currentodometer,0),
         		CurrentTotalOdometer = isnull(@currenttotalodometer,0),
             	INStkUnitCost =  @stkunitcost,
             	INStkECM = @stkecm,
             	INStkUM = @stkum,
              UniqueAttchID = @guid
         	where EMCo = @co and Mth = @mth and EMTrans = @emtranscurr
         if @@rowcount = 0
         	begin
         	ROLLBACK TRANSACTION
         	goto get_next_batchseq
         	end
         
         end
         
         -- For deletions, delete existing EM Detail Transaction. 
         if @batchtranstype = 'D'
         	begin
         	delete bEMCD
         	where EMCo = @co and Mth = @mth and EMTrans = @emtranscurr
         	if @@rowcount = 0
         		begin
         		ROLLBACK TRANSACTION
         		goto get_next_batchseq
         		end
         	end
         
         --TV 12/18/03 23364 - Need to update EMWP with PartStatus
         --TV 1/15/03 23364 - Forgot to check HQMT 
         if @source = 'EMParts'
             begin
             select @emwp_material = null -- TV 1/22/04 23364 Needed to reset value to null
             select @emwp_material = HQMatl from bEMEP where EMCo = @co and Equipment = @equipment and 
                                            PartNo = @material
             
             if isnull(@emwp_material,'')= '' select @emwp_material = @material
             
   		if isnull(@partstatus,'') <> ''--only update when PartStatus is present.
   			begin
   	        update bEMWP
   	        set PartsStatusCode = @partstatus--f.PartsStatusCode
   	        from bEMBF f join bEMWP p on f.Co = p.EMCo and f.WorkOrder = p.WorkOrder and 
   	                                     f.WOItem = p.WOItem
   	        where f.Co = @co and f.Mth = @mth and f.BatchId = @batchid and f.BatchSeq = @batchseq and
   	              p.Material = @emwp_material
       		end 
   	     end
         
         
         --call bspBatchUserMemoUpdate to update user memos in bEMCD before deleting the batch record
           if @batchtranstype <> 'D'
           begin
               if @batchtranstype = 'A'
                   begin
                   update bEMBF set EMTrans = @emcdemtransnew
                   where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
                   end
               select @emtrans = case @batchtranstype when 'A' then @emcdemtransnew else @emtranscurr end
               exec @rcode = bspBatchUserMemoUpdate @co, @mth, @batchid, @batchseq, @ddfhformname, @errmsg output
               if @rcode <> 0
                   begin
                   select @errmsg = 'Unable to update User Memo in EMCD.', @rcode = 1
                   goto bspexit
                   end
            end
         
         	/* Delete current row from bEMBF and commit transaction. */
         delete from bEMBF where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
         
         COMMIT TRANSACTION
         
         get_next_batchseq:
         
         /* Get next BatchSeq for psuedo-cursor. */
         select @batchseq = min(BatchSeq)
         from bEMBF
         where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq > @batchseq
     end /* While loop on BatchSeq pseudo-cursor */
     
     
     
     bspexit:
     if @rcode<>0 select @errmsg=isnull(@errmsg,'')		--+ char(13) + char(10) + '[bspEMPost_Cost_DetailInserts]'
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMPost_Cost_DetailInserts] TO [public]
GO
