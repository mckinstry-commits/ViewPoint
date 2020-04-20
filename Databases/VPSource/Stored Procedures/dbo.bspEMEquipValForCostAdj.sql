SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspEMEquipValForCostAdj]
   
 /***********************************************************
 * CREATED BY: JM 03/21/02 - Copied from bspEMEquipValNoComponent with modifications
 * MODIFIED By : JM 03/21/02 - Added return param of FuelCostCode, FuelCostType and FuelMatlCode
 *		from bEMEM for use as defaults when entering a Fuel cost adjustment. Changed
 *		@shop from return param to local var and removed and @warrantystatus return 
 *		param.
 *		TV 02/11/04 - 23061 added isnulls	
 *		TRL 01/15/08 - 121839 added Equipment Depts Depr Accum GLAcct
 *		TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
 * USAGE:
 *	Validates EMEM.Equipment.
 *	Returns following:
 *		Shop
 *		Warranty Status ('A' if active warranties exist
 *			or 'I' if not)
 *		Inventory Location for parts
 *		Equipment Type ('E' or 'C')
 *		Whether costs are posted to components
 *		EMEM.FuelCostCode
 *		EMEM.FuelCostType
 *		EMEM.FuelMatlCode
 *
 * INPUT PARAMETERS
 *	@emco		EM Company
 *	@equip		Equipment to be validated
 *
 * OUTPUT PARAMETERS
 *	@shop 		bEMEM.Shop
 *	@warrantystatus Active (A) or Inactive (I)
 *	@invloc		bEMSX.InvLoc by bEMEM.Shop
 *	@equiptype	bEMEM.Type ('E' for Equipment or 'C' for Component)
 *	@postcosttocomp bEMEM.PostCostToComp
 *	@fuelcostcode	bEMEM.FuelCostCode
 *	@fuelcosttype bEMEM.FuelCostType
 *	@fuelmatlcode bEMEM.FuelMatlCode
 *	@msg		Description or Error msg if error
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 **********************************************************/
(@emco bCompany = null,
@equip bEquip = null,
@invloc bLoc output,
@equiptype char(1) output,
@postcosttocomp char(1) output,
@fuelcostcode varchar(10) output,
@fuelcosttype tinyint output,
@fuelmatlcode bMatl output,
@deptdepraccumglacct bGLAcct =null output,
@msg varchar(255) output)
   
as
   
set nocount on
declare @rcode int, @type char(1), @warcnt smallint,@status char(1),@shopgroup bGroup,@shop varchar(20)
   
select @rcode = 0
   
if @emco is null
begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
end
   
if @equip is null
begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
end
  

--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
If @rcode = 1
begin
      goto bspexit
end
 
/* Validate Equipment and read @shop and @type from bEMEM. */
select @shop = m.Shop,
@equiptype = m.Type,
@postcosttocomp = PostCostToComp,
@status = Status,
@fuelcostcode = m.FuelCostCode,
@fuelcosttype = m.FuelCostType,
@fuelmatlcode = m.FuelMatlCode,
@deptdepraccumglacct = IsNull(p.DepreciationAcct,''),
@msg = m.Description
from dbo.EMEM m with(nolock)
left join dbo.EMDM p with(nolock) on p.EMCo=m.EMCo and p.Department=m.Department
where m.EMCo = @emco and m.Equipment = @equip
if @@rowcount = 0
begin
   	select @msg = 'Equipment invalid!', @rcode = 1
   	goto bspexit
end

/* Treat a null EMEM.PostCostToComp as a 'N'. */
if @postcosttocomp is null
begin
   	select @postcosttocomp = 'N'
end
   
/* Reject if passed Equipments Type is C for Component. */
if @equiptype = 'C'
begin
	select @msg = 'Equipment is a Component!', @rcode = 1
   	goto bspexit
end
   
/* Reject if Status inactive. */
if @status = 'I'
begin
      select @msg = 'Equipment Status = Inactive!', @rcode = 1
      goto bspexit
end
   
/* Read inventory location from bEMSX for @shop, if available. */
if @shop is not null
begin
	/* Get ShopGroup from bHQCO for @emco */
	select @shopgroup = ShopGroup from bHQCO where HQCo = @emco
   	select @invloc = InvLoc
   	from dbo.EMSX with(nolock)
   	where Shop = @shop and ShopGroup = @shopgroup
end

bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValForCostAdj] TO [public]
GO
