SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMFuelPostingGridFill]
   /****************************************************************************
   * CREATED BY: 	JM 1/20/99
   * MODIFIED BY: JM 12/21/99 - Per Issue 5739 and RH/DH, set current odo/hrs to zero and
   *               expanded number of columns filled in bEMBF.
   *               JM 1/27/00 - Added code to skip Equipment records in #MatchingEquip
   *               already in bEMBF for the batch so they don't get added again, either
   *               if user refreshes for same criteria or if the record was already added
   *               to bEMBF manually in grid.
   *              JM 2/29/00 - Per Issue 6475, removed default of GLTransAcct to
   *              when GLAcct not setup for Equip's Dept - force user to set up GLAcct for
   *              Dept.
   *              JM 6/13/00 - Changed PerECM return param to hardcoded to 'E' per RH
   *              DANF 06/19/00 - Added default from In unit pricing.
   *              DANF 08/30/00 - Only add equipment to batch that are not already in the batch.
   *              DANF 09/29/00 - Added restriction for FuelType
   *			 JM 10/21/02 - Ref Issue 19071 - GLOffsetAcct needs to come from INLC, INLS or INLM if INLoc specified
   *	JM 10/22/02 - Ref Issue 19071 - If INLoc specified, limited Equipment returned to those with FuelMatlCode at that INLoc
   *	TV 02/11/04 - 23061 added isnulls	
   *	TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
  *				TRL 02/04/2010 Issue 137916  change @description to 60 characters 
  * 
   * USAGE:
   *	Used by EMFuelPosting form to insert records into bEMBF that match Equipment
   *   specified by user in that form (see input params). Inserts following columns:
   *
   *       Co = input param
   *       Mth = input param
   *       BatchId = input param
   *       BatchSeq = auto sequenced here
   *       Source = input param
   *       Equipment = selected per user's input params & stored in temp table #MatchingEquip
   *       BatchTransType = 'A'
   *       EMTransType = input param
   *       EMGroup = input param
   *       CostCode = bEMEM.FuelCostCode
   *       EMCostType = bEMEM.FuelCostType
   *       ActualDate = input param (UsageDate)
   *       Description = bHQMT.Description
   *       GLCo = input param
   *       GLTransAcct = bEMDO.GLAcct or bEMDG.GLAcct for bEMEM.Department and bEMEM.FuelCostType
   *       GLOffsetAcct = bHQMC.GLAcct for bHQMT.Category or bEMCO.MatlMiscGLAcct
   *       MatlGroup = input param
   *       INCo = input param
   *       INLocation = input param
   *       Material = bEMEM.FuelMatlCode
   *       UM = bHQMT.StdUM
   *       Units = initialized to 0
   *       Dollars = initialized to 0
   *       UnitPrice = bHQMT.Price
   *       PerECM = bHQMT.CostECM --changed to hardcoded to 'E' per RH 6/13/00
   *       OffsetGLCo = bEMCO.GLCo
   *       MeterReadDate = input param (UsageDate)
   *       ReplacedHourReading = bEMEM.ReplacedHourReading
   *       PreviousHourMeter = bEMEM.HourReading
   *       CurrentHourMeter = initialized to 0
   *       PreviousTotalHourMeter = bEMEM.ReplacedHourReading + bEMEM.HourReading
   *       CurrentTotalHourMeter = initialized to PreviousTotalHourMeter
   *       ReplacedOdoReading = bEMEM.ReplacedOdoReading
   *       PreviousOdometer = bEMEM.OdoReading
   *       CurrentOdometer = initialized to 0
   *       PreviousTotalOdometer = bEMEM.ReplacedOdoReading + bEMEM.OdoReading
   *       CurrentTotalOdometer = initialized to PreviousTotalOdometer
   *       MeterMiles = initialized to 0
   *       MeterHrs = initialized to 0
   *       TaxCode = Inventory (later)
   *       TaxGroup = Inventory (later)
   *
   * INPUT PARAMETERS:
   *	EM Company
   *   BatchMth
   *   BatchId
   *   Source
   *   EMTransType
   *   EMGroup
   *	MatlGroup
   *   GLCo
   *   INCo
   *	UsageDate - for new fuel usage.
   *	INLocation - supply code for fuel (truck or depot).
   *   JCCo - (must be passed with Job)
   *   Job - (must be passed with JCCo)
   *	Location - optional criteria
   *	Category - optional criteria
   *	Department - optional criteria
   *	Shop - optional criteria
   *
   * OUTPUT PARAMETERS:
   *   None
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   (@emco bCompany = null,
   @batchmth bMonth = null,
   @batchid bBatchID = null,
   @source varchar(12) = null,
   @emtranstype varchar(12) = null,
   @emgroup bGroup = null,
   @matlgroup bGroup = null,
   @glco bCompany = null,
   @inco bCompany = null,
   @usagedate bDate = null,
   @inlocation bLoc = null,
   @jcco bCompany = null,
   @job bJob = null,
   @location varchar (10) = null,
   @category varchar(10) = null,
   @department varchar(10) = null,
   @shop varchar(20) = null,
   @taxgroup bGroup = null,
   @errmsg varchar(60) = null output)
   
   as
   set nocount on
   
   declare @batchseq smallint,
   	@currenttotalhourmeter bHrs,
   	@currenttotalodometer bHrs,
   	@equipment varchar(10),
   	@costcode bCostCode,
   	@emcosttype bEMCType,
   	@description bItemDesc /*137916*/,
   	@material bMatl,
       @gloffsetacct bGLAcct,
   	@gltransacct bGLAcct,
   	@maxbatchseq smallint,
       @perecm bECM,
   	@previoushourmeter bHrs,
   	@previousodometer bHrs,
   	@previoustotalhourmeter bHrs,
   	@previoustotalodometer bHrs,
   	@rcode int,
   	@replacedhourreading bHrs,
   	@replacedodoreading bHrs,
   	@sql1 varchar(255),
   	@sql2 varchar(255),
   	@sql3 varchar(255),
   	@taxcode bTaxCode,
   	@um bUM,
   	@unitprice numeric(12,5),
       	@priceecm bECM,
       	@msg varchar(60),
      	@embfinlocation bLoc,
      	@stocked bYN,
   	@taxable bYN,
       	@cnt smallint
   
   select @rcode = 0
   
   /* Note: params that cant be null are checked in the calling VB routine. */
   /* Create # table to hold list of Equipment to be returned to the
   VB application for display to user. */
   create table #MatchingEquip (Equipment varchar(10) null)/*,
   INLoc varchar(10) null,
   TaxCode varchar(10) null)*/
   
   /* Convert @inlocation to string = '' if it is null, else add enclosing quote marks. */
   /* if @inlocation is null
   	select @inlocation = 'null'
   else
   	select @inlocation = ''' + @inlocation + ''' */
   
   /* Fill #MatchingEquip per criteria. Enter BatchSeq = 0 and UnitPrice as 0 for this first pass, then update it from bHQMT.Price. */
   /*select @sql1 = 'insert into #MatchingEquip select Equipment from EMEM where EMCo = ' + convert(varchar(4),@emco) + ' and Type <> 'C' and Status <> 'I' and FuelType <>'N''
   select @sql2 = ''
   if @jcco is not null select @sql2 = @sql2 + ' and JCCo = ' + convert(varchar(12),@jcco)
   if @job is not null select @sql2 = @sql2 + ' and Job = '' + @job + '''
   if @location is not null select @sql2 = @sql2 + ' and Location = '' + @location + '''
   if @category is not null select @sql2 = @sql2 + ' and Category = '' + @category + '''
   if @department is not null select @sql2 = @sql2 + ' and Department = '' + @department + '''
   if @shop is not null select @sql2 = @sql2 + ' and Shop = '' + @shop + '''*/
   select @sql1 = 'insert into #MatchingEquip select Equipment from EMEM where EMCo = ' + isnull(convert(varchar(4),@emco),'') + ' and Type <> ''C'' and Status <> ''I'' and FuelType <> ''N'''
   select @sql2 = ''
   if @jcco is not null select @sql2 = isnull(@sql2,'') + ' and JCCo = ' + convert(varchar(12),@jcco)
   if @job is not null select @sql2 = isnull(@sql2,'') + ' and Job = ''' + @job + ''''
   if @location is not null select @sql2 = isnull(@sql2,'') + ' and Location = ''' + @location + ''''
   if @category is not null select @sql2 = isnull(@sql2,'') + ' and Category = ''' + @category + ''''
   if @department is not null select @sql2 = isnull(@sql2,'') + ' and Department = ''' + @department + ''''
   if @shop is not null select @sql2 = isnull(@sql2,'') + ' and Shop = ''' + @shop + ''''
   /* JM 10/22/02 - Ref Issue 19071 - If INLoc specified, limited Equipment returned to those with FuelMatlCode at that INLoc */
   if @inco is not null and @inlocation is not null  select @sql3 = ' and FuelMatlCode in (select Material from INMT where  INCo = ' + convert(varchar(8),@inco) + 
   	' and MatlGroup = ' + isnull(convert(varchar(8),@matlgroup),'') + ' and Active = ''' + 'Y' + ''' and Loc = ''' + @inlocation + ''')'
   exec (@sql1 + @sql2 + @sql3)
   
   /* Create pseudo-cursor on each Equipment in #MatchingEquip so we can update each
   records BatchSeq with @lastbatchseq + 1 and UnitPrice with Price from bHQMT. */
   select @equipment = min(Equipment) from #MatchingEquip
   while @equipment is not null
   	begin
   
   	/* Removed per Rob 1/27/00 - OK if routine brings up duplicates on re-Refresh. */
   	/* Skip if Equipment record already in bEMBF for the batch. */
   	/* if @currrowcount > 0
   		begin
   		select Equipment from bEMBF where Co = @emco and Mth = @batchmth and BatchId = @batchid and Equipment = @equipment
   		if @@rowcount <> 0
   			begin
   			select @alreadyingrid = @alreadyingrid + 1
   			goto getnextequip
   			end
   		end */
   
   	/* Get various info from bEMEM for @equipment. */
   	select @material = FuelMatlCode, @costcode = FuelCostCode, @emcosttype = FuelCostType, 
   		@previoushourmeter = HourReading, @previousodometer = OdoReading, 
   		@replacedhourreading = ReplacedHourReading, @replacedodoreading = ReplacedOdoReading,
   		@category = Category
   	from bEMEM where EMCo = @emco and Equipment = @equipment
   
   	/* If FuelCostCode not found in bEMEM, use bEMCO.FuelCostCode. */
   	if @costcode is null select @costcode = FuelCostCode from bEMCO where EMCo = @emco
   
   	/* If FuelCostType not found in bEMEM, use bEMCO.FuelCostType. */
   	if @emcosttype is null select @emcosttype = FuelCostType from bEMCO where EMCo = @emco
   
   	/* Get @desc from bHQMT for @material. */
   	select @taxable = null, @description=null, @stocked=null, @taxable=null
   	select @description = Description, @stocked = Stocked, @taxable = Taxable from bHQMT where MatlGroup = @matlgroup and Material = @material
   
   	/* If equip fuel is taxable, get TaxCode from INLM for INLocation */
   	/* Get TaxCode for INLocation, if applicable. */
   	if @taxable = 'Y' and @inlocation is not null
   		select @taxcode =TaxCode from bINLM where INCo = @inco and Loc = @inlocation
   	else
   		select @taxcode = null
   
   	/* Get @um from bEMEM.FuelCapUM. */
   	select @um = FuelCapUM from bEMEM where EMCo = @emco and Equipment = @equipment
   
   	select @embfinlocation = null
   	if @material is not null and @stocked = 'Y' select @embfinlocation = @inlocation
   
   	select @unitprice = 0, @perecm = 'E' --hardcoded to 'E' per RH 6/13/00
   
   	/* Get Unit Price */
   	exec @rcode =  bspEMMatUnitPrice @matlgroup, @inco, @embfinlocation, @material, @um, 'N', @unitprice output, @priceecm, @errmsg
   	/*if @rcode = 1
   		begin
   		select @errmsg='Miscellanous Material!'
   		If @valid = 'Y'
   		select @errmsg='Invalid Part Code!', @rcode=1
   		goto bspexit
   		end*/
   
   	/* Calculate previous total hour/odo info. */
   	select @previoustotalhourmeter = @previoushourmeter + @replacedhourreading, @previoustotalodometer = @previousodometer + @replacedodoreading
   	/* Set current total hour/odo info to same as previous since we are returning zero amounts in user inputs for odo and hours. */
   	select @currenttotalhourmeter = @previoustotalhourmeter, @currenttotalodometer = @previoustotalodometer
   
   	/* JM 10/21/02 - Ref Issue 19071 - GLOffsetAcct needs to come from INLC, INLS or INLM if INLoc specified. Commented out lines below marked with -- 
   	and replaced with section that does this job for that form. */
   	--/* Get GLOffsetAcct from bHQMC or bEMCO. */
   	select @gloffsetacct = null --make sure it is reset to null each time through the loop
   	--select @gloffsetacct = GLAcct from bHQMC where MatlGroup = @matlgroup and Category = (select Category from bHQMT where MatlGroup=@matlgroup and Material=@material)
   	--/* If not returned, get bEMCO.MatlMiscGLAcct. */
   	--/* if @gloffsetacct is null select @gloffsetacct = MatlMiscGLAcct from bEMCO where EMCo = @emco*/
   	 /* If user specified INCo and INLoc, get GLOffsetAcct from IN tables; otherwise get from HQMC or EMCO */
   	 if @inco is not null and @inlocation is not null
   	 	begin
   	 	/* Get OffsetGLAcct = EquipSalesGLAcct from INLC or INLS or INLM or error. */
   	 	select @gloffsetacct = EquipSalesGLAcct from bINLC where INCo = @inco and Loc = @inlocation 
   	 		and Co = @emco and MatlGroup = @matlgroup 
   	 		and Category = (select Category from bHQMT where MatlGroup = @matlgroup and Material = @material)
   	 	if @gloffsetacct is null
   	 		select @gloffsetacct = EquipSalesGLAcct from bINLS where INCo = @inco and Loc = @inlocation and Co = @emco
   	 	if @gloffsetacct is null
   	 		select @gloffsetacct = EquipSalesGLAcct from bINLM where INCo = @inco and Loc = @inlocation
   	 	if @gloffsetacct is null
   	 		begin
   	 		select @msg = 'Missing GLOffsetAcct for Inventory Sales to Equip!', @rcode = 1
   	 		goto bspexit
   	 		end
   	 	/* Validate the GLOffsetAcct as postable */
   	 	select @glco = GLCo from bINCO where INCo = @inco
   	 	exec @rcode = bspGLACfPostable @glco, @gloffsetacct, 'I', @msg output
   	 		if @rcode <> 0
   	 			begin
   	 			select @msg = 'GLOffsetAcct: ' + isnull(@msg,''), @rcode = 1
   	 			goto bspexit
   	 			end
   	 	end
   	 else
   	 	begin
   	 	/* Get GLOffsetAcct from bHQMC by Category */
   	  	select @gloffsetacct = GLAcct from bHQMC where MatlGroup = @matlgroup and Category = (select Category from bHQMT where MatlGroup=@matlgroup and Material=@material)
   	  	/* If not returned, get bEMCO.MatlMiscGLAcct. Note that Fuel Posting form will not allow bEMCO.MatlMiscGLAcct to be null. */
   	  	if @gloffsetacct is null select @gloffsetacct = MatlMiscGLAcct from bEMCO where EMCo = @emco
   	 	/* Validate the GLOffsetAcct as postable */
   	 	select @glco = GLCo from bEMCO where EMCo = @emco
   	 	exec @rcode = bspGLACfPostable @glco, @gloffsetacct, 'I', @msg output
   	 		if @rcode <> 0
   	 			begin
   	 			select @msg = 'GLOffsetAcct: ' + isnull(@msg,''), @rcode = 1
   	 			goto bspexit
   	 			end	
   	 	end
   
   
   	/* Get GLTransAcct from EMDO or EMDG. */
   	select @gltransacct = null --make sure it is reset to null each time through the loop
   	/* Get Department for @equipment from bEMEM. */
   	select @department = Department from bEMEM where EMCo = @emco and Equipment = @equipment
   
   	/* If GLAcct exists in bEMDO, use it. */
   	select @gltransacct = GLAcct from bEMDO where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostCode = @costcode
   
   	/* If GLAcct not in bEMDO, get the GLAcct in bEMDG. */
   	if @gltransacct is null or @gltransacct = ''
   	select @gltransacct = GLAcct from bEMDG where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostType = @emcosttype
   
   	/* If GLAcct still not found, use MatlMiscGLAcct in bEMCO. */
   	/* Removed 2/29/00 per Issue 6475 - If not found leave as null to force user to set up GLAcct for Dept after batch validation. */
   	/*if @gltransacct is null or @gltransacct = '' select @gltransacct = MatlMiscGLAcct from bEMCO where EMCo = @emco*/
   
   	/* Skip if the record is already in bEMBF for this Batch. */
   	select @cnt = count(*) from bEMBF where Co = @emco and Mth = @batchmth and BatchId = @batchid and Equipment = @equipment
   	If @cnt = 0
   		begin
   		/* Insert record from #MatchingEquip into bEMBF. */
   		/* Get next BatchSeq. */
   		select @batchseq = (select Max(BatchSeq) from bEMBF where Co = @emco and Mth = @batchmth and BatchId = @batchid) + 1
   		if @batchseq is null select @batchseq = 1
   		/* Make insert. */
   		/* 11/15/01 JM - Added insertion of Taxable status for Fuel to Asset column for display in grid since this column is not used for fuel posting batches. */
   		insert into bEMBF (Co, Mth, BatchId, BatchSeq, Source, Equipment, BatchTransType, EMTransType, EMGroup, CostCode, EMCostType, ActualDate, 
   			Description, GLCo, GLTransAcct, GLOffsetAcct, ReversalStatus, MatlGroup, INCo, INLocation, Material, UM, Units, Dollars, UnitPrice, PerECM, 
   			CurrentHourMeter, ReplacedHourReading, CurrentTotalHourMeter, PreviousHourMeter, PreviousTotalHourMeter, CurrentOdometer, 
   			ReplacedOdoReading, CurrentTotalOdometer, PreviousOdometer, PreviousTotalOdometer, TaxCode, TaxGroup, MeterReadDate, MeterMiles, MeterHrs) 
   		values (@emco, @batchmth, @batchid, @batchseq, @source, @equipment, 'A', @emtranstype, @emgroup, @costcode, @emcosttype, @usagedate, 
   			@description, @glco, @gltransacct, @gloffsetacct, 0, @matlgroup, @inco, @embfinlocation, @material, @um, 0, 0, @unitprice, @perecm, 
   			0, @replacedhourreading, @currenttotalhourmeter, @previoushourmeter, @previoustotalhourmeter, 0, @replacedodoreading, 
   			@currenttotalodometer,@previousodometer, @previoustotalodometer, @taxcode, @taxgroup, @usagedate, 0, 0)
   		end
   
   getnextequip:
   
   	/* Get the next Equipment from #MatchingEquip. */
   	select @equipment = min(Equipment) from #MatchingEquip where Equipment > @equipment
   
   end /* pseudo-cursor */
   
   bspexit:
   
   if @rcode<>0 select @errmsg=@msg
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMFuelPostingGridFill] TO [public]
GO
