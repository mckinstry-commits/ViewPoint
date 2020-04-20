SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE          procedure [dbo].[vspEMWOInitParts]
/*******************************************************************
* CREATED: TRL 05/08/08 --Issue 127344
* LAST MODIFIED:  06/05/08 -- Issue 128586 when EMWP.Required = 'Y' update Qty Needed
*				07/30/08 TRL -- Issue 129213 fix for initializing parts by Status Code
*				GF 09/06/2010 - issue #141031 changed to use function vfDateOnly
*					GF 04/26/2013 TFS-48552 EMSH/EMSI expanded descriptions
*				GF 06/25/2013 TFS-53934 calculate tax basis
*
*
* USAGE: Called by EMWOPartsInit form to post parts on a Work Order
*	to batch table bEMBF.
*
* INPUT PARAMS:
*	@emco			Controlling EM Company
*	@workorder		EMWH.WorkOrder for which Parts are to be posted to bEMBF.
*	@selectbystatuscode	PartsStatusCode by which to select Parts in bEMWP for initialization.
*	@changetostatuscode	New PartsStatusCode for all initialized Parts.
*	@batchid		Batch ID
*	@batchmth		Batch Month
*	@emgroup		EM Group for @emco
*	@matlgroup		Material Group for @emco
*	@glco			GLCo for @emco
*	@inco			 IN Co for @emco
*  	@taxgroup           	TaxGroup
*  	@taxbasis
*  	@taxrate
*  	@taxamount
*	@defpartscosttype	PartsCT for @emco
*
* OUTPUT PARAMS:
*	@alreadyinitialized
*	@partsinitialized		Number of parts on @workorder successfully initialized
*	@rcode			Return code; 0 = success, 1 = failure
*	@errmsg		Error message; # copied if success, error message if failure
********************************************************************/
(@emco bCompany = null, 
@workorder bWO = null, 
@selectbystatuscode varchar(10) = null, 
@changetostatuscode varchar(10) = null,
@batchid bBatchID = null, 
@batchmth bMonth = null, 
@alreadyinitialized smallint output,
@partsinitialized smallint output, 
@errmsg varchar(255) output)
   
as   

set nocount on
   
--declare locals 
declare @rcode int,
/*EMCO variables*/
@matlmiscglacct bGLAcct,@emmatltaxyn varchar(1),@defpartscosttype bEMCType,@taxgroup bGroup,@emgroup bGroup,@glco tinyint,
/*WOItem cursor variables*/
@opencursoritem int, @woitem smallint, @wiequipment bEquip, @wicomponent bEquip, @wicomponenttypecode varchar(10), @wicostcode bCostCode,
/*WOItemParts cursor variables*/
----TFS-48552
@opencursorpart int,@wpseq int,@wpmaterial bMatl,@wpmatlgroup bGroup,@wpinco bCompany,@wpinvloc bLoc,@wpartsstatuscode varchar(10),
@wpdescription bItemDesc,  @wpum bUM,@wpqtyneeded bUnits,@wprequired bYN,
--declare IN Variable
@gloffsetacct bGLAcct,  @intaxcode varchar(10),@intaxrate bRate,@category varchar(10),@hqmatl bMatl,
@unitprice bUnitCost, @department varchar(10),@glequipment bEquip,@gltransacct bGLAcct,@batchseq smallint, @numrows int
  
----TFS-53934
DECLARE @TaxBasis bDollar, @TaxAmount bDollar
  
   
select @rcode = 0, @alreadyinitialized = 0, @partsinitialized = 0,@opencursorpart=0, @opencursoritem=0
  
-- Verify parameters passed. 
if @emco is null
begin
   	select @errmsg = 'Missing EM Company!', @rcode = 1
   	goto vspexit
end
   
if isnull(@workorder,'') = '' 
begin
   	select @errmsg = 'Missing Work Order!', @rcode = 1
   	goto vspexit
end
   
if @batchid is null
begin
   	select @errmsg = 'Missing Batch ID!', @rcode = 1
   	goto vspexit
end
   
if @batchmth is null
begin
   	select @errmsg = 'Missing Batch Month!', @rcode = 1
   	goto vspexit
end

-- Get EMCompany info. 
select @matlmiscglacct = IsNull(MatlMiscGLAcct,''), @emmatltaxyn = IsNull(MatlTax,'N'),
@defpartscosttype=PartsCT, @glco = GLCo, @emgroup=HQCO.EMGroup, @taxgroup=HQCO.TaxGroup
from dbo.EMCO with (nolock)
Inner Join dbo.HQCO with(nolock)on HQCO.HQCo=EMCO.EMCo
where EMCo = @emco
if isnull(@matlmiscglacct,'') = ''
begin
	select @errmsg = 'Matl Misc GLAcct missing in EMCO!', @rcode = 1
   	goto vspexit
end
if @emgroup is null
begin
	select @errmsg = 'Missing EM Group!', @rcode = 1
   	goto vspexit
end
if @glco is null
begin
   	select @errmsg = 'Missing GL Co!', @rcode = 1
   	goto vspexit
end
--Set GLOffsetacct
select @gloffsetacct = @matlmiscglacct

-- delcare cursor for Work Order Items
declare vcsWOItem cursor local fast_forward for
select WOItem, Equipment, ComponentTypeCode, Component, CostCode
from dbo.EMWI with(nolock)
where EMCo = @emco and WorkOrder = @workorder

--Open cursor
open vcsWOItem
select @opencursoritem = 1

NextWOItem:
fetch next from vcsWOItem into @woitem, @wiequipment, @wicomponenttypecode, @wicomponent, @wicostcode
if @@fetch_status <> 0 
begin
	goto EndNextWOItem
end
	--declare cursor for Work Order Item Parts
	declare vcsWOItemParts cursor local fast_forward for
	select Seq,Material,MatlGroup,INCo,InvLoc,PartsStatusCode,Description,UM,QtyNeeded,Required
	from dbo.EMWP with (nolock)
	Where EMCo = @emco and WorkOrder = @workorder and Equipment = @wiequipment and WOItem = @woitem
	-- Issue 129213 fix
	and PartsStatusCode = isnull(@selectbystatuscode,PartsStatusCode)

	--Open cursor
	open vcsWOItemParts
	select @opencursorpart = 1

	NextWOItemPart:
	fetch next from vcsWOItemParts into @wpseq,@wpmaterial,@wpmatlgroup,@wpinco,@wpinvloc,@wpartsstatuscode,
		@wpdescription, @wpum,@wpqtyneeded, @wprequired
       			  
	if @@fetch_status <> 0 
	begin
		goto EndNextWOItemPart
   	end

	--If WO Part has already been initialized into bEMBF, increment the @alreadyinitialized counter and skip. 
	if exists (select top 1 1 from dbo.EMBF with (nolock)
	where Co = @emco and Equipment=@wiequipment and WorkOrder = @workorder and WOItem = @woitem and WOPartSeq = @wpseq 
	and Material = @wpmaterial and MatlGroup = @wpmatlgroup and IsNull(INCo,'')=IsNull(@wpinco,'') and IsNull(INLocation,'')=IsNull(@wpinvloc,'')
    and PartsStatusCode = case when IsNull(@changetostatuscode,'')='' then @wpartsstatuscode else @changetostatuscode end)
	begin
		select @alreadyinitialized = @alreadyinitialized + 1
		goto NextWOItemPart
	end
	
	--Beg insert section
	--reset for each part code
    select @intaxcode=null, @intaxrate=0,/*Issue 128586*/@wprequired =IsNull(@wprequired,'N')

    /***********************************************************************************
    Material can be in either EMEP or HQMT or both as follows:
    1 - In HQMT (or both where HQMT takes precedence).
    2 - In EMEP with a referenced HQMatl.
    3 - In EMEP only (without a referenced HQMatl).
    In cases 1 and 2, use standard code to pull UnitPrice and GLAccts.
    For case 3, set UnitPrice to zero and use EMCO.MatlMiscGLAcct for GLOffset acct
    and get GLTransAcct from EMDO or EMDG.
    **********************************************************************************/
	if exists(select top 1 1 from dbo.HQMT with (nolock) where MatlGroup = @wpmatlgroup and Material = @wpmaterial)
		begin
			select @hqmatl  = @wpmaterial
    		goto UseHQMTCode -- Case 1 
		end
	else
    	begin
    		select @hqmatl = Isnull(HQMatl,'') 
   			from dbo.EMEP with (nolock)
   			where EMCo = @emco and Equipment = @wiequipment and PartNo = @wpmaterial
    		if isnull(@hqmatl,'') <> ''
				-- Case 2 - Make sure to substitute @material with @hqmatl, then use std code. 
				begin
					select  @hqmatl = @wpmaterial
    				goto UseHQMTCode
    			end
       		else
				-- Case 3 In EMEP only (without a referenced HQMatl).
       			begin
       				select @unitprice = 0, @gloffsetacct = @matlmiscglacct
       	    		goto FinishInsert
       			end
       	end
       			
		UseHQMTCode:
   			-- geeting unitprice from wrong place
   			EXEC @rcode = dbo.bspHQUMValWithInfoForEM @emco,'Equip',@wpum,@wpmatlgroup, @hqmatl,
				@wpinco,@wpinvloc,@unitprice output,@errmsg output
			--Sets Unit price for non HQ Matls
			if @unitprice is null 
			begin
				set @unitprice = 0	
			end

			-- 1 - Get Category from bHQMT. 
   			select @category = IsNull(Category,'')
			from dbo.HQMT with (nolock)
			where MatlGroup=@wpmatlgroup and Material= @hqmatl
			-- 2 - Get GLOffsetAcct from bHQMC. 
       		-- Added if condition per Issue 15591 - only look for a GLOffsetAcct in HQMC if INLoc is not specified. 
			if IsNull(@wpinvloc,'')=''
       			begin
   					select @gloffsetacct = Isnull(GLAcct,'')
   					from dbo.HQMC with (nolock)
   					where MatlGroup = @wpmatlgroup and Category = @category
   					if IsNull(@gloffsetacct,'') = ''
						begin
   							select @errmsg = 'GLAcct missing in HQMC for MatlGroup ' + isnull(convert(varchar(3),@wpmatlgroup),'') 
							+' and Material ' + @hqmatl + ' and Category '+ isnull(@category,'') + '!',@rcode = 1
   	     					goto vspexit
   						end
				end	
			else
				-- needs to get Offset account form IN when loc is not null
				begin
					select @gloffsetacct = Isnull(EquipSalesGLAcct,'')
					from dbo.INLS with (nolock) 
					where INCo = @wpinco and Loc = @wpinvloc
					if IsNull(@gloffsetacct,'')=''
					begin
						select @gloffsetacct = EquipSalesGLAcct 
						from dbo.INLC with (nolock) 
						where INCo = @wpinco and Loc = @wpinvloc and MatlGroup = @wpmatlgroup and Co = @emco 
                   		and Category =@category 
					end
					if IsNull(@gloffsetacct,'')=''
					begin
						select @gloffsetacct = EquipSalesGLAcct 
						from dbo.INLM with (nolock) 
						where INCo = @wpinco and Loc = @wpinvloc
					end
					if IsNull(@gloffsetacct,'')=''
					begin
						select @errmsg = 'Missing GLOffsetAcct for Inventory Sales to Equip!', @rcode = 1
						goto vspexit
					end
					--Do Not set Tax Code or Tax Rates
					--If EMCo Use Tax overrides HQ Materials Is taxable flag
					if IsNull(@emmatltaxyn,'N') = 'Y' 
						begin
							/*If taxgroups aren't the same return taxcode to show inv and location are taxable
							even though it will generate a validation error in the form*/
							select @intaxcode=INLM.TaxCode, @intaxrate=0
							from dbo.INLM with(nolock)
							where INLM.INCo=@wpinco and INLM.Loc=@wpinvloc
						end
					else
						begin
							select @intaxcode=null, @intaxrate=0
						end
				end
			                  
		FinishInsert:
			if isnull(@wicomponent,'') <>''
				begin
					select @glequipment =(select CompOfEquip from dbo.EMEM with(nolock) where EMCo = @emco and Equipment = @wicomponent)
				end
			else
				begin
					select @glequipment = @wiequipment
				end

				-- 3b-Get Department for @equipment from bEMEM. 
			select @department = Department 
	 		from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @glequipment

			-- 3c-If GLAcct exists in bEMDO, use it. 
         	select @gltransacct = GLAcct from dbo.EMDO with (nolock)
         	where EMCo = @emco and isnull(Department,'') = isnull(@department,'')
         	and EMGroup = @emgroup and CostCode = @wicostcode

         	-- 3d-If GLAcct not in bEMDO, get the GLAcct in bEMDG. 
         	if IsNull(@gltransacct,'')= ''/* is null  or @gltransacct = ''*/
			begin
         		select @gltransacct = IsNull(GLAcct,'')
         		from dbo.EMDG with(nolock)
         		where EMCo = @emco and isnull(Department,'') = isnull(@department,'')
         			and EMGroup = @emgroup and CostType = @defpartscosttype
			END
  
			----TFS-53934 calculate tax basis and tax amount
			SET @TaxBasis = 0
			SET @TaxAmount = 0

			IF ISNULL(@wprequired, 'N') = 'Y' AND ISNULL(@wpqtyneeded, 0) <> 0
				BEGIN
				SET @TaxBasis = ISNULL(@wpqtyneeded, 0) * ISNULL(@unitprice, 0)
				IF ISNULL(@intaxrate, 0) <> 0
					BEGIN
					SET @TaxAmount = @TaxBasis * ISNULL(@intaxrate, 0)
					END                  
				END              

         	-- Get next Batch Seq for this insert. 
         	select @batchseq = isnull(max(BatchSeq),0)+1 from dbo.EMBF with(nolock)
        	where Co = @emco and Mth = @batchmth and BatchId = @batchid

         	insert dbo.EMBF(Co, Mth, BatchId, BatchSeq, Source, Equipment, BatchTransType,
         	EMTransType, ComponentTypeCode, Component, EMGroup, CostCode, 
   			EMCostType,ActualDate, Description, GLCo, GLTransAcct, 
   			GLOffsetAcct, ReversalStatus, WorkOrder, WOItem, MatlGroup, INCo, INLocation, Material, 
   			SerialNo, UM, 
			Units, 
			Dollars, UnitPrice, PerECM, 
   			CurrentHourMeter, CurrentTotalHourMeter, CurrentOdometer, CurrentTotalOdometer, 
   			PartsStatusCode, 
   			TaxGroup, TaxCode, TaxBasis, TaxRate, TaxAmount, WOPartSeq)
			values (@emco, @batchmth, @batchid, @batchseq, 'EMParts', @wiequipment, 'A',
			/*135655*/
          	'Parts', @wicomponenttypecode, isnull(@wicomponent,null), @emgroup, @wicostcode,
			@defpartscosttype,
			----#141031
			dbo.vfDateOnly(),
			@wpdescription, @glco, @gltransacct,
            @gloffsetacct, 0, @workorder, @woitem, @wpmatlgroup, @wpinco, @wpinvloc, @wpmaterial,
            null, @wpum, 
			--Issue 128586
			case @wprequired when 'Y' then @wpqtyneeded else 0 end,
			case @wprequired when 'Y' then @wpqtyneeded * @unitprice else 0 end, @unitprice, 'E',
   			0, 0, 0, 0,
            case when IsNull(@changetostatuscode,'') = ''then @wpartsstatuscode else @changetostatuscode end,
			----TFS-53934
			@taxgroup, @intaxcode, @TaxBasis, @intaxrate, @TaxAmount, @wpseq)
            --@taxgroup, @intaxcode,/*@taxbasis*/0, @intaxrate, /*@taxamount*/0,@wpseq)

			-- Increment @partsinitialized counter. 
			select @numrows = @@rowcount
           	select @partsinitialized = @partsinitialized + @numrows
		
			goto NextWOItemPart
			
	EndNextWOItemPart:
	If @opencursorpart= 1
	begin
		close vcsWOItemParts
		deallocate vcsWOItemParts
		select @opencursorpart= 0
	End
	
	
  
goto NextWOItem
EndNextWOItem:
if @opencursoritem = 1
begin
	close vcsWOItem
	deallocate vcsWOItem
	select @opencursoritem = 0
end

vspexit:
If @opencursorpart= 1
	begin
		close vcsWOItemParts
		deallocate vcsWOItemParts
	End

if @opencursoritem = 1
begin
	close vcsWOItem
	deallocate vcsWOItem
end
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOInitParts] TO [public]
GO
