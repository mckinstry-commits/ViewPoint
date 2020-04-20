SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMCDReversalsInit    Script Date: 1/28/2002 10:04:48 AM ******/
   
   
   
   
   
   
   
   
   CREATE            procedure [dbo].[bspEMCDReversalsInit]
   /***********************************************************
    * CREATED BY: JM 6/8/01 - Cloned from bspJCCDReversalsInit
    *
    * MODIFIED By :TV 02/11/04 - 23061 added isnulls
	*			  :TRL 01/10/07 Issue 125261 Add EMAlloc to reversals
    *
    * USAGE: This procedure is used by the EM Post Outstanding entries to initialize
    * 	reversal transactions from bEMCD into bEMBF for editing.
    *
    *	Checks batch info in bHQBC, and transaction info in bEMCD.
    * 	Adds entry to next available Seq# in bEMBF
    *
    *	 Pulls transaction in the OrigMth that are marked 1(reversal), and aren't
    * 	already in a batch.
    *
    * 	bEMBF insert trigger will update InUseBatchID in bEMCD
    *
    * INPUT PARAMETERS
    *	Co         	JC Co to pull from
    *   	Mth        	Month of batch
    *   	BatchId    	Batch ID to insert transaction into
    *   	OrigMth    	Original month to pull reversal transactions from.
    *   	TransDate  	Transaction date to add new entries with
    *
    * OUTPUT PARAMETERS
    *
    * RETURN VALUE
    *	0   	success
    *   	1   	fail
    *****************************************************/
   
   @emco bCompany, @batchmth bMonth, @batchid bBatchID, @origmth bMonth, @newactualdate bDate, @errmsg varchar(255) output
   
   as
   set nocount on
   declare 	@actualdate bDate,
   	@alloccode tinyint,
   	@apco bCompany,
   	@apline int,
   	@apref bAPReference,
   	@aptrans bTrans,
   	@apvendor bVendor,
   	@asset varchar(20),
   	@component bEquip,
   	@componenttypecode varchar(10),
   	@costcode bCostCode,
   	@currenthourmeter bHrs,
   	@currentodometer bHrs,
   	@currenttotalhourmeter bHrs,
   	@currenttotalodometer bHrs,
   	@description bDesc,
   	@dollars bDollar,
   	@emcosttype bEMCType,
   	@emgroup bGroup,
   	@emtrans bTrans,
   	@emtranstype varchar(10),
   	@equipment bEquip,
   	@errtext varchar(255),
   	@glco bCompany,
   	@gltransacct bGLAcct,
   	@gloffsetacct bGLAcct,
   	@inco bCompany,
   	@inlocation bLoc,
   	@instkecm bECM,
   	@instkum bUM,
   	@instkunitcost bUnitCost,
   	@material bMatl,
   	@matlgroup bGroup,
   	@metertrans bTrans,
   	@originalmth bMonth,
   	@perecm bECM,
   	@prco bCompany,
   	@premployee bEmployee,
   	@rcode int,
   	@recsinitialized int,
   	@seq int,
   	@serialno varchar(20),
   	@status tinyint,
   	@taxamount bDollar,
   	@taxbasis bDollar,
   	@taxcode bTaxCode,
   	@taxgroup bGroup,
   	@taxrate bRate,
   	@totalcost bDollar,
   	@um bUM,
   	@unitprice bUnitCost,
   	@units bUnits,
   	@vendorgrp bGroup,
   	@woitem bItem,
   	@workorder bWO,
	--add for Issue 125261
	@emsource varchar(10)
   
   select @rcode = 0, @recsinitialized = 0
   
   /* make sure that the original month is less than the reversal month */
   if @origmth >= @batchmth
   	begin
   	select @errmsg = 'Original month must come before batch month!', @rcode = 1
   	goto error
   	end
   
   /* validate HQ Batch */
   exec @rcode = dbo.bspHQBatchProcessVal @emco, @batchmth, @batchid, 'EMAdj', 'EMBF', @errtext output, @status output
   if @rcode <> 0
   	begin
       	select @errmsg = @errtext, @rcode = 1
       	goto error
      	end
   
   if @status <> 0
   	begin
   	select @errmsg = 'Invalid Batch status -  must be Open!', @rcode = 1
   	goto error
   	end
   
   /* spin through EMCD using pseudo cursor */
   -- get first month
   select @originalmth=min(Mth) from dbo.EMCD with(nolock)
   where EMCo=@emco and Mth<=@origmth 
    --	and InUseBatchID is null and Source = 'EMAdj' and ReversalStatus = 1
   	and InUseBatchID is null and Source IN ('EMAdj','EMAlloc') and ReversalStatus = 1
   while @originalmth is not null
   	begin
   	-- get EMTrans for the month
   	select @emtrans=min(EMTrans) from dbo.EMCD with(nolock)
   	where EMCo=@emco and Mth=@originalmth and Mth<=@origmth 
   		and InUseBatchID is null and Source In ('EMAdj','EMAlloc') and ReversalStatus = 1
   
   	while @emtrans is not null
   		begin
   
   		select @emtranstype=EMTransType,  @componenttypecode=ComponentTypeCode, @equipment=Equipment,
   			@component=Component, @asset=Asset, @emgroup=EMGroup, @costcode=CostCode, 
   			@emcosttype=EMCostType, @description=Description, @glco=GLCo, @gltransacct=GLTransAcct, 
   			@gloffsetacct=GLOffsetAcct, @prco= PRCo, @premployee=PREmployee, @apco=APCo, 
   			@aptrans=APTrans, @apline=APLine, @vendorgrp=VendorGrp, @apvendor=APVendor, 
   			@apref=APRef, @workorder=WorkOrder, @woitem=WOItem, @matlgroup=MatlGroup, 
   			@inco=INCo, @inlocation=INLocation, @material=Material, @serialno=SerialNo, @um=UM, 
   			@units=Units, @dollars=(Dollars-TaxAmount), @unitprice=UnitPrice,@perecm= PerECM, 
   			@totalcost=TotalCost, @metertrans=MeterTrans, @currenthourmeter=CurrentHourMeter, 
   			@currenttotalhourmeter=CurrentTotalHourMeter, @currentodometer=CurrentOdometer, 
   			@currenttotalodometer=CurrentTotalOdometer, @taxcode=TaxCode, @taxgroup=TaxGroup, 
   			@taxbasis=TaxBasis, @taxrate=TaxRate, @taxamount=TaxAmount, @alloccode=AllocCode,
   			@instkecm=INStkECM, @instkunitcost=INStkUnitCost, @instkum=INStkUM, @emsource=Source
   		from dbo.EMCD with(nolock)
   		where EMCo=@emco and Mth = @originalmth and EMTrans=@emtrans
   
   		/* get next available sequence # for this batch */
   		select @seq = isnull(max(BatchSeq),0)+1 from dbo.EMBF with(nolock) where Co = @emco and Mth = @batchmth and BatchId = @batchid
   
   		/* Add new transaction to batch with same GLAccts but negative amt and ReversalStatus of 2(Reversing).
   		  All old values should be set to 0 and transaction should be setup as an add. */
   		  insert into bEMBF (Co, Mth, BatchId, BatchSeq, Source, Equipment, EMTrans, BatchTransType,
   			EMTransType, ComponentTypeCode, Component, Asset, EMGroup, CostCode,
   			EMCostType, ActualDate, Description, GLCo, GLTransAcct, GLOffsetAcct,
   			ReversalStatus, OrigMth, OrigEMTrans, PRCo, PREmployee, APCo, APTrans, APLine, 
   			VendorGrp, APVendor, APRef, WorkOrder, WOItem, MatlGroup, INCo, INLocation, Material,
   			SerialNo, UM, Units, Dollars, UnitPrice, PerECM, TotalCost, MeterTrans,
   			CurrentHourMeter,CurrentTotalHourMeter, CurrentOdometer, CurrentTotalOdometer,
   		            	TaxCode,TaxGroup, TaxBasis, TaxRate, TaxAmount, AllocCode,
   			INStkECM, INStkUnitCost, INStkUM)
   		values (@emco, @batchmth, @batchid, @seq, @emsource, @equipment, null,'A',
   			@emtranstype, @componenttypecode, @component, @asset, @emgroup, @costcode,
   			@emcosttype, @newactualdate, @description, @glco, @gltransacct, @gloffsetacct,
   			2, @originalmth, @emtrans, @prco, @premployee, @apco, @aptrans, @apline, @vendorgrp,
   			@apvendor, @apref, @workorder, @woitem, @matlgroup, @inco, @inlocation, @material,
   			@serialno, @um, (-1*@units), (-1*@dollars), @unitprice, @perecm, (-1*@totalcost), @metertrans,
   			@currenthourmeter, @currenttotalhourmeter, @currentodometer, @currenttotalodometer,
   			@taxcode, @taxgroup, (-1*@taxbasis), @taxrate, (-1*@taxamount), @alloccode,
   			@instkecm, @instkunitcost, @instkum)
   
   		select @recsinitialized = @recsinitialized + 1
   
   		/* get next transaction */
   		select @emtrans=min(EMTrans) from dbo.EMCD with(nolock)
   		where EMCo=@emco and Mth=@originalmth and Mth<=@origmth and EMTrans>@emtrans 
   			--and InUseBatchID is null and Source='EMAdj' and ReversalStatus=1
			and InUseBatchID is null and Source In ('EMAdj','EMAlloc') and ReversalStatus=1
   		end
   
   	/* get next original mth */
   	select @originalmth=min(Mth) from dbo.EMCD with(nolock)
   		where EMCo=@emco  and Mth>@originalmth and Mth<=@origmth
   		   --and InUseBatchID is null and Source='EMAdj' and ReversalStatus=1
			and InUseBatchID is null and Source IN('EMAdj','EMAlloc') and ReversalStatus=1
   	end
   
   bspexit:
   
   select @rcode = 0, @errmsg = isnull(convert(varchar(10), @recsinitialized),'') + ' reversing entries initialized!'
   return @rcode
   
   error:
   
   select @errmsg = isnull(@errmsg,'') + ' - reversals not initialized.'
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMCDReversalsInit] TO [public]
GO
