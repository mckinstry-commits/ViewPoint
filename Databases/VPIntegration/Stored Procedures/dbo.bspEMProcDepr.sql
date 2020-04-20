SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspEMProcDepr]
   /***********************************************************
    * CREATED BY  : AE 2/9/99
    * MODIFIED By : bc 06/06/00  made it work like it's supposed to
    *               JM 2/3/00 Changed definition of @EMGroup to bHQCO.EMGroup from bEMCO.EMGroup.
    *               ae 02/15/00  Fixed issue 6232
    *               ae 3/7/00 Fixed issue 6393
    *               ae 5/10/00 FYBegMth restriction added. and Issue 6248
    *               bc 01/15/02 - issue #15907
    *               danf 05/07/02 - Fixing gl account defaults for Components....
    *               danf 05/16/02 - Removed Fully Depr section per rejection of #15907
    *				 JM 7/10/02 - Changed Source inserted into EMBF from 'EMAdj' to 'EMDepr'
    *				 JM 7/11/02 - Added INStkUnitCost = 0 and UnitPrice = 0 to bEMBF insert statements since
    *							  those fields are not nullable
    *				 DANF 11/08/02 - 18869 When Asset number is 20 characters the description will not hold asset number.
    *				 DANF 11/09/02 - Corrected GLOffset account to default for asset.
    *				 GF 05/20/2003 - issue #20849 - need to check open batches for month when calculating
    *								 amount to be taken.
    *				 TV 02/11/04 - 23061 added isnulls
    *				 TV 03/01/05 - I am cleaning this up.
    *				 TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
	*				 DANF 04/05/07 - Added Posted Records for 6.x recode.
    *				 DANF 06/12/07 - Issue 124791 - Include depr taken by component type and component
	*				 DAN SO 05/07/08 - Issue 128084 - Default 'LS' as UM on record insert into bEMBF
	*                ERICV 06/08/11 - Issue 142100 Defect D-02002 Added order by clause to cursor select
    *
    *
    * USAGE:
    * Called from EM Depreciation Processing program.  Populates EMBF
    *
    *
    * INPUT PARAMETERS
    *   EMCo        	EMCo
    *   LastMonthCalc    	The last month that has been depreciated (from EMCO)
    *   Month       	Current month
    *   BatchID	 	Batch ID number
    *   PostingDate	PostingDate
    *   Equipment          Optional - Equipment
    *   Asset              Optional - Asset
    *   DeprAll            1 = Depreciating All Assets at once  0 = depreciating just select assets
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   (@EMCo bCompany, @LastMonthCalc bMonth, @ToMonth bMonth, @BatchID int, @PostingDate bDate,
    @SelEquipment bEquip, @SelAsset varchar(20), @DeprAll int, @PostedRecords int output, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int,
   	@opencursor tinyint,
   	@AmtToTake bDollar,
   	@AmtTaken bDollar,
   	@AmtTkn bDollar,
   	@TotalAmtToTake bDollar,
   	@TotalAmtTaken bDollar,
   	@batchamttaken bDollar,
   	@TotalDiff bDollar,
   	@Month bMonth,
   	@EMGroup bGroup,
   	@GLCo bCompany,
   	@DeprCostCode bCostCode,
   	@DeprCostType bEMCType,
   	@BatchSeq int,
   	@FetchCounter int,
   	@Equipment bEquip,
   	@Asset varchar(20),
   	@OldEquipment bEquip,
   	@OldAsset varchar(20),
   	@department bDept,
   	@GLTransAcct bGLAcct,
   	@GLOffsetAcct bGLAcct,
   	@FYBegMth bMonth,
   	@itemsdepr int,
   	@DeprCalcReqd varchar(1),
   	@FullyDepr bYN,
       @Type char(1),
   	@CompOfEquip bEquip,
       @ComponentTypeCode varchar(10),
       @Component bEquip,
       @PstEquipment bEquip
   
   select @rcode = 0, @opencursor = 0, @FetchCounter = 0, @TotalAmtToTake = 0,
   	   @TotalAmtTaken = 0, @TotalDiff = 0, @itemsdepr = 0, @PostedRecords = 0
   
   select @DeprCalcReqd = DeprCalcReqd, @GLCo = GLCo, @DeprCostCode = DeprCostCode, 
   	   @DeprCostType = DeprCostType
   from EMCO with (nolock) where EMCo = @EMCo
   if @DeprCalcReqd = 'N'
   	begin
   	select @msg = 'No depreciation processing required.'
   	select @rcode = 1
   	goto bspexit
   	end
   
   -- Get the Data we need from the Company file
   --select @GLCo = GLCo, @DeprCostCode = DeprCostCode, @DeprCostType = DeprCostType 
   --from bEMCO where EMCo = @EMCo
   
   -- Get EMGroup from bHQCO.
   select @EMGroup = EMGroup from bHQCO with (nolock) where HQCo = @EMCo
   
   -- Get Y beg month from bGLFY.
   select @FYBegMth = BeginMth from GLFY with (nolock) where GLCo = @GLCo and @ToMonth >= BeginMth and @ToMonth <= FYEMO
   
   if @DeprAll = 0 goto post_one
   
   
   
   -- Declare and open cursor on EMDS for posting.
   declare cEMDS scroll cursor for 
   select Equipment, Asset, Month, AmtToTake, AmtTaken 
    from bEMDS where EMCo = @EMCo and Month <= @ToMonth and Month >= @FYBegMth
    order by Equipment, Asset, Month   
   
   -- open cursor
   open cEMDS
   select @opencursor = 1
   fetch first from cEMDS into @Equipment, @Asset, @Month, @AmtToTake, @AmtTaken
   
   if @Equipment is null
   	begin
   	select @msg = 'No assets to depreciate.'
   	select @rcode = 1
   	goto bspexit
   	end
   
   goto reenter_postingloop
   
   -- loop through all rows in EMDS
   posting_loop:
   
   fetch next from cEMDS into @Equipment, @Asset, @Month, @AmtToTake, @AmtTaken
   
   if @@fetch_status <> 0 or @Equipment <> @OldEquipment or @Asset <> @OldAsset 
   	goto post_transaction
   
   reenter_postingloop:
   
   
   select @OldEquipment = @Equipment,
          @PstEquipment = @Equipment,
   	   @OldAsset = @Asset,
          @Component = null
   
   
   select @GLTransAcct = DeprExpAcct,  @GLOffsetAcct = AccumDeprAcct 
   from EMDP with (nolock) where EMCo = @EMCo and Equipment = @Equipment and Asset = @Asset
   
   select @Type = Type, @CompOfEquip = CompOfEquip, @ComponentTypeCode = ComponentTypeCode
   from bEMEM with (nolock) where EMCo = @EMCo and Equipment = @Equipment
   
   if isnull(@CompOfEquip,'') <> ''
   	begin
   	select @GLTransAcct = DeprExpAcct from EMDP with (nolock) 
   	where EMCo = @EMCo and Equipment = @CompOfEquip and Asset = @Asset
   	end
   
   if @Type = 'C' 
   	begin
   	select @Component = @Equipment, @Equipment = @CompOfEquip, @PstEquipment = @CompOfEquip
   	end
   
   if @GLTransAcct is null or @GLTransAcct = ''
   	begin
   	-- Get GLTransAcct from EMDO or EMDG.
   	-- Step 1 - Get Department for @equipment/@CompOfEquip from bEMEM.
   	select @department = Department
       from bEMEM with (nolock) where EMCo = @EMCo and Equipment = @Equipment
          
   	-- Step 2 - If GLAcct exists in bEMDO, use it.
   	select @GLTransAcct = GLAcct from bEMDO with (nolock)
   	where EMCo = @EMCo and Isnull(Department,'') = isnull(@department,'') and EMGroup = @EMGroup and CostCode = @DeprCostCode
   	-- Step 3 - If GLAcct not in bEMDO, get the GLAcct in bEMDG.
   	if @GLTransAcct is null or @GLTransAcct = ''
   		begin
   		select @GLTransAcct = GLAcct from bEMDG with (nolock)
   		where EMCo = @EMCo and isnull(Department,'') = isnull(@department,'') and EMGroup = @EMGroup and CostType = convert(tinyint,@DeprCostType)
   		end
   	end
   
   if isnull(@GLOffsetAcct,'') = ''
   	begin
   	select @GLOffsetAcct = AccumDeprAcct from EMDP with (nolock)
   	where EMCo = @EMCo and Equipment = @Equipment and Asset = @Asset
   	end
   
   if isnull(@GLOffsetAcct,'')=''
   	begin
   	-- Step 1 - Get Department for @equipment/@CompOfEquip from bEMEM.
   	select @department = Department, @Type = Type, @CompOfEquip = CompOfEquip
       from bEMEM with (nolock)where EMCo = @EMCo and Equipment = @Equipment
   	select @GLOffsetAcct = DepreciationAcct 
   	from EMDM with (nolock) where EMCo = @EMCo and isnull(Department,'') = isnull(@department,'')
   	-- Step 2 - If GLAcct exists in bEMDO, use it.
   	if @GLOffsetAcct is null or @GLOffsetAcct = ''
   		begin
   		select @GLOffsetAcct = GLAcct from bEMDO with (nolock)
   		where EMCo = @EMCo and isnull(Department,'') = isnull(@department,'') and EMGroup = @EMGroup and CostCode = @DeprCostCode
   		end
   	-- Step 3 - If GLAcct not in bEMDO, get the GLAcct in bEMDG.
   	if @GLOffsetAcct is null or @GLOffsetAcct = ''
   		begin
   		select @GLOffsetAcct = GLAcct from bEMDG with (nolock)
   		where EMCo = @EMCo and isnull(Department,'') = isnull(@department,'') and EMGroup = @EMGroup and CostType = convert(tinyint,@DeprCostType)
   		end
   	end
   
   
   set @TotalAmtToTake = @TotalAmtToTake + @AmtToTake
   set @TotalAmtTaken = @TotalAmtTaken + @AmtTaken
   set @TotalDiff = @TotalAmtToTake - @TotalAmtTaken
   
   goto posting_loop
   
   
   
   
   post_transaction:
   -- check for other EMDepr batches for this month or Existing transaction in this batch
   -- need to deduct amount to take from @TotalDiff. May not need any more depreciation
   set @batchamttaken = 0
   if isnull(@ComponentTypeCode,'') = ''
   	begin
   	-- get any depreciation already taken for this equipment and asset - with no component
   	select @batchamttaken = isnull(sum(Dollars),0) from EMBF with (nolock)
   	where Co = @EMCo and Mth = @ToMonth and Source = 'EMDepr' and Equipment = @PstEquipment 
   	and Asset = @OldAsset and ComponentTypeCode is null
   	end
   else
   	begin
   	-- get any depreciation already taken for this equipment and asset - with component
   	select @batchamttaken = isnull(sum(Dollars),0) from EMBF with (nolock)
   	where Co = @EMCo and Mth = @ToMonth and Source = 'EMDepr' and Equipment = @PstEquipment 
   	and Asset = @OldAsset and ComponentTypeCode = @ComponentTypeCode and Component = @Component -- Issue 124791
   	end
   
   -- if batch amount taken is not zero subtract for @TotalDiff
   if @batchamttaken <> 0
   	begin
   	select @TotalDiff = @TotalDiff - @batchamttaken
   	end
   
   if @TotalDiff <> 0 and @TotalDiff is not null
   	begin
   	begin transaction
   	select @BatchSeq = isnull(max(BatchSeq),0) + 1 from EMBF where Co = @EMCo and Mth = @ToMonth and BatchId = @BatchID
   	insert bEMBF (Co, Mth, BatchId, BatchSeq, Source, Equipment, BatchTransType, EMTransType, ComponentTypeCode, 
   			Component, Asset, EMGroup, CostCode, EMCostType, ActualDate, Description, 
   			GLCo, GLTransAcct, GLOffsetAcct, ReversalStatus, INStkUnitCost, UM, Units, Dollars, UnitPrice)
   	values (@EMCo, @ToMonth, @BatchID, @BatchSeq, 'EMDepr', @PstEquipment, 'A', 'Depn', @ComponentTypeCode, 
   			@Component, @OldAsset, @EMGroup, @DeprCostCode, @DeprCostType, @PostingDate, 'Depr Asset ' + SUBSTRING(@OldAsset,1,19), 
   			@GLCo, @GLTransAcct, @GLOffsetAcct, 0, 0, 'LS', 0, @TotalDiff, 0)
   	if @@rowcount = 0 goto posting_error
   	select @itemsdepr = @itemsdepr + 1, @PostedRecords = @PostedRecords +1

   	commit transaction
   	end
   
   if (@@fetch_status <> 0) goto posting_loop_end
   
   set @TotalAmtToTake = 0
   set	@TotalAmtTaken = 0
   set	@TotalDiff = 0
   set	@GLTransAcct = ''
   set	@GLOffsetAcct = ''
   set @ComponentTypeCode = null
   set @Component = null
   
   goto reenter_postingloop
   
   
   
   /* ***************************************** */
   /* Post depreciation for one asset. */
   /* ***************************************** */
   post_one:
   
   -- Declare and open cursor on EMDS for posting.
   declare cEMDS scroll cursor for select Equipment, Asset, Month, AmtToTake, AmtTaken 
   from bEMDS  with (nolock)
   where EMCo = @EMCo and Equipment = @SelEquipment and Asset = @SelAsset and Month <= @ToMonth and Month >= @FYBegMth
   
   -- open cursor
   open cEMDS
   select @opencursor = 1
   
   -- loop through all rows for this select Equipment
   posting_select_loop:
   fetch next from cEMDS into @Equipment, @Asset, @Month, @AmtToTake, @AmtTaken
   
   if(@@fetch_status <> 0) 
   	goto post_sel_transaction
   
   select @GLTransAcct = DeprExpAcct 
   from EMDP with (nolock) where EMCo = @EMCo and Equipment = @Equipment and Asset = @Asset
   
   select @Type = Type, @CompOfEquip = CompOfEquip, @ComponentTypeCode = ComponentTypeCode
   from bEMEM with (nolock) where EMCo = @EMCo and Equipment = @Equipment
   
   select @PstEquipment = @Equipment, @Component = null
   
   if @Type = 'C' 
   	begin
   	select @Component = @Equipment, @Equipment = @CompOfEquip, @PstEquipment = @CompOfEquip
   	end
   
   if @GLTransAcct is null or @GLTransAcct = ''
   	begin
   	-- Step 1 - Get Department for @equipment/@CompOfEquip from bEMEM.
   	select @department = Department, @Type = Type, @CompOfEquip = CompOfEquip
       from bEMEM with (nolock) where EMCo = @EMCo and Equipment = @Equipment
   	-- Step 2 - If GLAcct exists in bEMDO, use it.
   	select @GLTransAcct = GLAcct from bEMDO with (nolock)
   	where EMCo = @EMCo and isnull(Department,'') = isnull(@department,'') and EMGroup = @EMGroup and CostCode = @DeprCostCode
   	-- Step 3 - If GLAcct not in bEMDO, get the GLAcct in bEMDG.
   	if @GLTransAcct is null or @GLTransAcct = ''
   		begin
   		select @GLTransAcct = GLAcct from bEMDG with (nolock)
   		where EMCo = @EMCo and isnull(Department,'') = isnull(@department,'') and EMGroup = @EMGroup and CostType = convert(tinyint,@DeprCostType)
   		end
   	end
   
   -- get GL offset account
   select @GLOffsetAcct = AccumDeprAcct from EMDP with (nolock)
   where EMCo = @EMCo and Equipment = @Equipment and Asset = @Asset
   if @GLOffsetAcct is null or @GLOffsetAcct = ''
   	begin
   	-- Step 1 - Get Department for @equipment/@CompOfEquip from bEMEM.
   	select @department = Department, @Type = Type, @CompOfEquip = CompOfEquip
       from bEMEM with (nolock) where EMCo = @EMCo and Equipment = @Equipment
   	select @GLOffsetAcct = DepreciationAcct 
   	from EMDM with (nolock) where EMCo = @EMCo and isnull(Department,'') = isnull(@department,'')
   	-- Step 2 - If GLAcct exists in bEMDO, use it.
   	if @GLOffsetAcct is null or @GLOffsetAcct = ''
   		begin
   		select @GLOffsetAcct = GLAcct from bEMDO with (nolock)
   		where EMCo = @EMCo and isnull(Department,'') = isnull(@department,'')  and EMGroup = @EMGroup and CostCode = @DeprCostCode
   		end
   	-- Step 3 - If GLAcct not in bEMDO, get the GLAcct in bEMDG.
   	if @GLOffsetAcct is null or @GLOffsetAcct = ''
   		begin
   		select @GLOffsetAcct = GLAcct from bEMDG with (nolock)
   		where EMCo = @EMCo and isnull(Department,'') = isnull(@department,'') and EMGroup = @EMGroup and CostType = convert(tinyint,@DeprCostType)
   		end
   	end
   
   
   set @TotalAmtToTake = @TotalAmtToTake + @AmtToTake
   set @TotalAmtTaken = @TotalAmtTaken + @AmtTaken
   set @TotalDiff = @TotalAmtToTake - @TotalAmtTaken
   
   goto posting_select_loop
   
   
   
   post_sel_transaction:
   -- check for other EMDepr batches for this month or Existing transaction in this batch
   -- need to deduct amount to take from @TotalDiff. May not need any more depreciation
   set @batchamttaken = 0
   -- get any depreciation already taken for this equipment and asset
   if isnull(@ComponentTypeCode,'') = ''
   	begin
   	-- get any depreciation already taken for this equipment and asset - with no component
   	select @batchamttaken = isnull(sum(Dollars),0) from EMBF with (nolock)
   	where Co = @EMCo and Mth = @ToMonth and Source = 'EMDepr' and Equipment = @PstEquipment 
   	and Asset = @SelAsset and ComponentTypeCode is null
   	end
   else
   	begin
   	-- get any depreciation already taken for this equipment and asset - with component
   	select @batchamttaken = isnull(sum(Dollars),0) from EMBF with (nolock)
   	where Co = @EMCo and Mth = @ToMonth and Source = 'EMDepr' and Equipment = @PstEquipment 
   	and Asset = @SelAsset  and ComponentTypeCode = @ComponentTypeCode and Component = @Component -- Issue 124791
   	end
   
   -- if batch amount taken is not zero subtract for @TotalDiff
   if @batchamttaken <> 0
   	begin
   	select @TotalDiff = @TotalDiff - @batchamttaken
   	end
   
   
   if @TotalDiff <> 0 and @TotalDiff is not null
   	begin
   	begin transaction
   	select @BatchSeq = isnull(max(BatchSeq),0) + 1 from EMBF where Co = @EMCo and Mth = @ToMonth and BatchId = @BatchID
   	insert bEMBF (Co, Mth, BatchId, BatchSeq, Source, Equipment, BatchTransType, EMTransType, ComponentTypeCode, 
   			Component, Asset, EMGroup, CostCode, EMCostType, ActualDate, Description, 
   			GLCo, GLTransAcct, GLOffsetAcct, ReversalStatus, INStkUnitCost, UM, Units, Dollars, UnitPrice)
   	values (@EMCo, @ToMonth, @BatchID, @BatchSeq, 'EMDepr', @PstEquipment, 'A', 'Depn', @ComponentTypeCode, 
   			@Component, @SelAsset, @EMGroup, @DeprCostCode, @DeprCostType, @PostingDate, 'Depr Asset ' + SUBSTRING(@OldAsset,1,19), 
   			@GLCo, @GLTransAcct, @GLOffsetAcct, 0, 0, 'LS', 0, @TotalDiff, 0)
   	if @@rowcount = 0 goto posting_error
   	select @itemsdepr = @itemsdepr + 1, @PostedRecords = @PostedRecords + 1
   	commit transaction
   	goto bspexit
   	end
   
   posting_loop_end:
   if @DeprAll = 1
   	begin
   	update bEMCO set DeprLstMnthCalc = @ToMonth 
   	from bEMCO where EMCo = @EMCo
   	end
   
   goto bspexit
   
   
   
   posting_error:
   rollback transaction
   
   
   
   bspexit:
   	if @itemsdepr = 0 and @rcode = 0
   		select @msg = 'There was nothing to depreciate!', @rcode = 1
   	
   	if @opencursor = 1
   		begin
   		close cEMDS
   		deallocate cEMDS
   		end
   		
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMProcDepr]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMProcDepr] TO [public]
GO
