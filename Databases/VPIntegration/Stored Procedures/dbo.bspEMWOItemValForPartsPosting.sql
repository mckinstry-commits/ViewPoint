SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspEMWOItemValForPartsPosting]
   /***********************************************************
   * CREATED BY:	JM  Adapted from bspEMWOItemVal
   * MODIFIED By:	GF 05/19/2003 - issue #21306 @outsiderprct was declared as varchar(1). S/B bEMCType
   *				TV 02/11/04 - 23061 added isnulls 
   * USAGE:
   * 	Validates an EM WorkOrder Item for an EMCo/WorkOrder.
   *	Returns EquipType
   *	Component and Odo/Hrs info if applicable
   *	InvLoc
   *	CostCode
   *	InHseSubFlag
   *	GLTransAcct
   *
   * INPUT PARAMETERS
   *   	EMCo
   *   	WorkOrder
   *   	WOItem to validate
   *
   * OUTPUT PARAMETERS
   *	@equiptype (Equipment or Component)
   *	@equip
   *	@equipdesc
   *	@equipodo
   *	@equipreplodo
   *	@equiphrs
   *	@equipreplhrs
   *	@component
   *	@compdesc
   *	@compodo
   *	@compreplodo
   *	@comphrs
   *	@compreplhrs
   *	@costcode
   *	@lastequiptotodo
   *	@lastequiptothrs
   *	@lastcomptotodo
   *	@lastcomptothrs
   *    @outsiderprct (Outside Repair CostType from bEMCO)
   *   	@msg      error message if error occurs otherwise Description returned
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   (@emco bCompany = null,
   @workorder varchar(10) = null,
   @woitem smallint = null,
   @equipment bEquip = null,
   @equiptype char(1) = null output,
   /* comp return params */
   @component varchar(10) = null output,
   @compdesc varchar(30) = null output,
   @componenttypecode varchar(10) = null output,
   @compodo bHrs = null output,
   @comptotodo bHrs = null output,
   @comphrs bHrs = null output,
   @comptothrs bHrs = null output,
   /* other outputs */
   @costcode bCostCode = null output,
   @repairloc varchar(20) = null output,
   @costtype bEMCType = null output, /* bEMCO.PartsCT or bEMCO.OutsideRprCT */
   @emwpcount int = null output,
   @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, 
   	@numrows int, 
   	@inhsesubflag char(1), 
   	@emgroup bGroup,
   	@statuscode varchar(10), 
   	@department bDept, 
   	@wopostfinal bYN,
   	@compreplodo bHrs, 
   	@compreplhrs bHrs, 
   	@outsiderprct bEMCType
   
   select @rcode = 0, @numrows = 0, @equiptype = 'E',@emwpcount = 0
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @workorder is null
   	begin
   	select @msg = 'Missing Work Order!', @rcode = 1
   	goto bspexit
   	end
   if @woitem is null
   	begin
   	select @msg = 'Missing WO Item!', @rcode = 1
   	goto bspexit
   	end
   if @equipment is null
   	begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
   	end
   /*if @costtype is null
   	begin
   	select @msg = 'Missing Cost Type!', @rcode = 1
   	goto bspexit
   	end*/
   
   /* Validate WOItem. */
   select @msg = Description,@componenttypecode = ComponentTypeCode, @component = Component, 
   	@costcode = CostCode, @inhsesubflag = InHseSubFlag, @statuscode = StatusCode
   from dbo.EMWI with (nolock) where EMCo = @emco and WorkOrder = @workorder and WOItem = @woitem
   select @numrows = @@rowcount
   if @numrows = 0
   begin
		select @msg = 'WO Item not on file!', @rcode = 1
   		goto bspexit
   	end

   select @emwpcount = IsNull(Count(*),0) from dbo.EMWP with(nolock) where EMCo=@emco and WorkOrder = @workorder and WOItem=@woitem

   if (select StatusType from dbo.EMWS with(nolock) where EMGroup = (select EMGroup
    from dbo.HQCO with (nolock) where HQCo = @emco) and StatusCode = @statuscode) = 'F'
   and (select WOPostFinal from dbo.EMCO with (nolock) where EMCo = @emco) = 'N'
   	begin
   		select @msg = 'EMCo is not flagged to allow posting to completed WO Items!', @rcode = 1
   		goto bspexit
   	end
   
   /* Get info for Component from EMEM. */
   if @component is not null
   	begin
   		select @equiptype = 'C'
   		select @compdesc = Description, @compodo = OdoReading, @compreplodo = ReplacedOdoReading,
   		@comphrs = HourReading, @compreplhrs = ReplacedHourReading
   		from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @component
   	end
   
   /* Calculate Last Totals. */
   select @comptotodo = @compodo + @compreplodo, @comptothrs = @comphrs + @compreplhrs
   
   /* Get OutsideRprCT from bEMWO if bEMWI.InHseSubFlag = 'O'. */
   if @inhsesubflag = 'O'
		begin
			/* Get Outside Repair EMCostType. */
   			select @outsiderprct = OutsideRprCT from dbo.EMCO with (nolock) where EMCo = @emco
   			select @repairloc = 'Outside', @costtype = @outsiderprct
		 end
   else
   		begin
   			select @outsiderprct = null /* just to be sure that it's null for the following */
   			select @repairloc = 'In-House', @costtype = (select PartsCT from dbo.EMCO  with (nolock) where EMCo = @emco)
   		end
   
   /* Get GLTransAcct for Outside Repair per EMCostType = @outsiderprct.
   Ref Issue 5873 1/26/00 rejection. */
   /* First need EMGroup. */
   --select @emgroup = EMGroup from bHQCO where HQCo = @emco
   /* Now pull GLTransAcct from EMDO or EMDG. Per DH request dont run
   bspEMCostTypeValForCostCode as that will produce an error msg if
   the ct is not setup for the costcode. */
   /* Step 1 - Get Department for @equipment from bEMEM. */
   --select @department = Department from bEMEM where EMCo = @emco and Equipment = @equipment
   /* Step 2 - If GLAcct exists in bEMDO, use it. */
   /*select @gltransacct = GLAcct from bEMDO 
   where EMCo = @emco and Department = @department and EMGroup = @emgroup and CostCode = @costcode*/
   /* Step 3 - If GLAcct not in bEMDO, get the GLAcct in bEMDG. */
   /*if @gltransacct is null or @gltransacct = ''
   	select @gltransacct = GLAcct from bEMDG where EMCo = @emco and Department = @department
   		and EMGroup = @emgroup and CostType = isnull(@outsiderprct,@costtype)*/
   /* Step 4 - return an error if @gltransacct still not found. */
   /*if @gltransacct is null or @gltransacct = ''
   	begin
   	select @msg = 'GLTransAcct not found in EMDO or EMDG!', @rcode = 1
   	goto bspexit
   	end*/
	bspexit:
   	--if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOItemValForPartsPosting]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOItemValForPartsPosting] TO [public]
GO
