SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       proc [dbo].[bspEMEquipValForFuelPosting]
   /****************************************************************************
   * CREATED BY: 	JM 12/23/99
   * MODIFIED BY:  JM 5/9/00 - Added restriction on validation to Status A or D.
   *               DANF 06/12/00 - Added check for tax exempt material
   *               JM 6/13/00 - Changed PerECM return param to hardcoded to 'E' per RH
   *               DANF 06/19/00 - Added  default unit price
   *               DANF 08/15/00 - Corrected incorrect Equipment Description being returned.
   *				JM 11/13/01 - Removed return of @taxcode; replaced with return of @taxable
   *				JM 1/24/02 - Ref Issue 16025 #1 - Added rejection if Equipment is Component (bEMEM.Type='C')
   *				JM 3/20/02 - Ref Issue 12679 - Added call to bspEMVal_Cost_Inventory to get GLOffsetAcct when
   *							 InLoc applies. Changed @inco from local var to input param.
   *				GF 10/14/2003 - #22704 - if changing equipment with In location need to look in IN for GL offset acct.
   *				TV 02/11/04 - 23061 added isnulls	
   *				TV 2/8/05 - I am cleaning out this un-used code. CLEAN-UP!!!!
   *				TV 03/05/04 27012 - GL offset account doesn't pull correctly after changing equipment #
   *				TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
   *				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
   * USAGE:
   *	Used by EMFuelPosting form to validate Equipment entered by user and return
   *   various default info to the form.
   *
   * INPUT PARAMETERS:
   *	EM Company
   *   Equipment
   *   MatlGroup
   *   EMGroup
   *
   * OUTPUT PARAMETERS:
   *   CostCode = bEMEM.FuelCostCode
   *   EMCostType = bEMEM.FuelCostType
   *   Description = bHQMT.Description
   *   GLTransAcct = bEMDO.GLAcct or bEMDG.GLAcct for bEMEM.Department and bEMEM.FuelCostType
   *   GLOffsetAcct = bHQMC.GLAcct for bHQMT.Category or bEMCO.MatlMiscGLAcct
   *   Material = bEMEM.FuelMatlCode
   *   UM = bHQMT.StdUM
   *   UnitPrice = bHQMT.Price
   *   PerECM = bHQMT.CostECM --changed to hardcoded to 'E' per RH 6/13/00
   *   OffsetGLCo = bEMCO.GLCo
   *   ReplacedHourReading = bEMEM.ReplacedHourReading
   *   PreviousHourMeter = bEMEM.HourReading
   *   PreviousTotalHourMeter = bEMEM.ReplacedHourReading + bEMEM.HourReading
   *   ReplacedOdoReading = bEMEM.ReplacedOdoReading
   *   PreviousOdometer = bEMEM.OdoReading
   *   PreviousTotalOdometer = bEMEM.ReplacedOdoReading + bEMEM.OdoReading
   *   TaxCode = Inventory (later)
   *   TaxGroup = Inventory (later)
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   (@emco bCompany = null, @equipment bEquip = null, @matlgroup bGroup = null, @emgroup bGroup = null, @inco bCompany = null, @inlocation bLoc = null,
   @costcode bCostCode output, @costtype bEMCType output, @fueldesc bDesc output, @gltransacct bGLAcct output, @gloffsetacct bGLAcct output,
   @origequipgloffsetacct bGLAcct output, @fuelmatlcode bMatl output, @um bUM= null  output, @unitprice bUnitCost output, @perecm bECM output,
   @replacedhourreading bHrs output, @previoushourmeter bHrs output, @previoustotalhourmeter bHrs output, @replacedodoreading bHrs output,
   @previousodometer bHrs output, @previoustotalodometer bHrs output, @taxable bYN output, @taxcode bTaxCode output, @EquipNoFuel char(1) output,
   @errmsg varchar(255) output)
   
   as
   set nocount on
   
   declare @category varchar(10), @department varchar(10), @status char(1), @oridegloffsetacctout bGLAcct,
   		@priceecm bECM, @matlvalid bYN, @rcode int, @subrcode int, @upmsg varchar(255), @type char(1),
   		@inglco bCompany
   
   select @rcode = 0
   
   if @emco is null
   	begin
   	select @errmsg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @equipment is null
   	begin
   	select @errmsg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
   	end
   if @matlgroup is null
   	begin
   	select @errmsg = 'Missing Material Group!', @rcode = 1
   	goto bspexit
   	end
   if @emgroup is null
   	begin
   	select @errmsg = 'Missing EM Group!', @rcode = 1
   	goto bspexit
   	end
   
   -- Get valid material flag from bEMCO.
   select @matlvalid = MatlValid from bEMCO with (nolock) where EMCo = @emco
   

	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equipment, @errmsg output
	If @rcode = 1
	begin
		  goto bspexit
	end

   -- Get various info from bEMEM for @equipment.
   -- JM 1/24/02 - Ref Issue 16025 #1 - Added rejection if Equipment is Component (bEMEM.Type='C')
   select @errmsg = Description, @fuelmatlcode = FuelMatlCode, @costcode = FuelCostCode,
   	   @costtype = FuelCostType, @previoushourmeter = HourReading, @previousodometer = OdoReading,
   	   @replacedhourreading = ReplacedHourReading, @replacedodoreading = ReplacedOdoReading,
   	   @category = Category, @status = Status, @type = Type
   from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid Equipment - not on file in Equip Master!', @rcode = 1
   	goto bspexit
   	end
   if @type = 'C'
   	begin
   	select @errmsg = 'Invalid Equipment - cannot be a Component!', @rcode = 1
   	goto bspexit
   	end
   
   -- Reject if Status inactive. 
   if @status = 'I'
   	begin
   	select @errmsg = 'Equipment Status = ''''Inactive''''!', @rcode = 1
   	goto bspexit
   	end
   
   -- If FuelMatlCode found, read HQMT.Taxable 
   if @fuelmatlcode is not null 
   	begin
   	select @taxable = Taxable from bHQMT with (nolock) where MatlGroup = @matlgroup and Material = @fuelmatlcode
   	end
   
   if @taxable = 'Y' and @inlocation is not null 
   	begin
   	select @taxcode = TaxCode from bINLM with (nolock) where INCo = @inco and Loc = @inlocation
   	end
   
   -- If FuelCostCode not found in bEMEM, use bEMCO.FuelCostCode. 
   if @costcode is null 
   	begin
   	select @costcode = FuelCostCode from bEMCO with (nolock) where EMCo = @emco
   	end
   
   -- If FuelCostType not found in bEMEM, use bEMCO.FuelCostType. 
   if @costtype is null 
   	begin
   	select @costtype = FuelCostType from bEMCO with (nolock) where EMCo = @emco
   	end
   
   -- Get @desc from bHQMT for @fuelmatlcode. 
   select @fueldesc = Description, @taxable = Taxable 
   from bHQMT with (nolock) 
   where MatlGroup = @matlgroup and Material = @fuelmatlcode
   
   -- Get @um from bEMEM.FuelCapUM. 
   select @um = FuelCapUM 
   from bEMEM with (nolock) 
   where EMCo = @emco and Equipment = @equipment
   
   -- If no IN Location entered by user, update #MatchingEquip.UnitPrice with HQMT.Price for @equipment. 
   select @perecm = 'E', @unitprice = 0
   
   exec @subrcode =  bspEMMatUnitPrice @matlgroup, @inco, @inlocation, @fuelmatlcode, @um, @matlvalid, @unitprice output, @priceecm, @upmsg output
   
   -- Calculate previous total hour/odo info.
   set @previoustotalhourmeter = @previoushourmeter + @replacedhourreading
   set @previoustotalodometer = @previousodometer + @replacedodoreading
   
   -- Get GLOffsetAcct from bHQMC or bEMCO.
   select @gloffsetacct = GLAcct 
   from bHQMC with (nolock) where MatlGroup = @matlgroup 
   and Category = (select Category from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@fuelmatlcode)
   
   -- If not returned, get bEMCO.MatlMiscGLAcct. 
   -- Note that Fuel Posting form will not allow bEMCO.MatlMiscGLAcct to be null.
   if @gloffsetacct is null select @gloffsetacct = MatlMiscGLAcct from bEMCO with (nolock) where EMCo = @emco
   select @origequipgloffsetacct = @gloffsetacct
   
   /*if @inco is not null and @inlocation is not null TV 03/05/04 27012 - GL offset account doesn't pull correctly after changing equipment #
   	begin
   	-- Get OffsetGLAcct = EquipSalesGLAcct from INLC or INLS or INLM or error.
   	select @gloffsetacct = EquipSalesGLAcct 
   	from bINLS with (nolock) where INCo = @inco and Loc = @inlocation and Co = @emco
   	if @gloffsetacct is null
   		begin
   		select @gloffsetacct = EquipSalesGLAcct 
   		from bINLC with (nolock) where INCo = @inco and Loc = @inlocation and Co = @emco and MatlGroup = @matlgroup 
   	  	and Category = (select Category from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@fuelmatlcode)
   		end
   	if @gloffsetacct is null
   		begin
   	  	select @gloffsetacct = EquipSalesGLAcct 
   		from bINLM with (nolock) where INCo = @inco and Loc = @inlocation
   		end
   	if @gloffsetacct is null
   	  	begin
   	  	set @gloffsetacct = @origequipgloffsetacct
   	  	end
   	end*/
   
   -- Get Department for @equipment from bEMEM. 
   select @department = Department 
   from bEMEM with (nolock) 
   where EMCo = @emco and Equipment = @equipment
   
   -- If GLAcct exists in bEMDO, use it. 
   select @gltransacct = GLAcct 
   from bEMDO with (nolock) 
   where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostCode = @costcode
   
   -- If GLAcct not in bEMDO, get the GLAcct in bEMDG. 
   if @gltransacct is null
   	begin
   	select @gltransacct = GLAcct from bEMDG with (nolock) 
   	where EMCo = @emco and isnull(Department,'') = isnull(@department,'') and EMGroup = @emgroup and CostType = @costtype
   	end
   
   -- If Equip does not use fuel, tell front end to display a warning - ref Issue 16433
   if (select FuelType from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment) = 'N'
   	begin
   	select @EquipNoFuel = '1'
   	end
   else
   	begin
   	select @EquipNoFuel = '0'	
   	end
   
   bspexit:
   	if @rcode<>0 select @errmsg = isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMEquipValForFuelPosting]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValForFuelPosting] TO [public]
GO
