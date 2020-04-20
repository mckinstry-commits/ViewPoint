SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE               proc [dbo].[bspEMWOPartsPostHQMatlVal]
      /********************************************************
      * CREATED BY: 	JM 12/29/98
      * MODIFIED BY: JM 10/4/99 - Changed to pull Desc and UM 1st from bEMEP
      *   if the material exists in that table, else from bHQMT.
      *              DANF - Added Inventory location validation
      *	JM 4/11/01 - Ref Issue 11586: Rewrote material validation into subroutine bspEMEquipPartVal.
      *	JM 5/30/01 - Added return param @category to bspEMEquipPartVal call
      *	JM 6/5/01 - Added return param @taxcode_out supplied by bspEMEquipPartVal call
      *	JM 8/6/01 - Ref Issue 13870 - Added param @formtaxcode to allow procedure to decide
      *		whether to pull a tax code to return as @taxcode_out.
      *	TV 02/11/04 - 23061 added isnulls 
   	*	TV 07/12/2005 - issue 29254 - Allow Deptartment and Category to be Null.
*		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
      *
      * USAGE: Called by EMWOPartsPosting form to validate Part Code.
      *	Allows invalid Part Code if MatlValid flag in bEMCO is
      *	set to 'N' and returns existing form values for Price,
      *	UM, Description, GLTransAcct and GLOffsetAcct.
      *
      *	If bEMCO.MatlValid = 'Y' forces validation and returns:
      *		Price, StdUM, and Description for Part Code from bHQMT.
      *		GLTransAcct from EMDO by EMCo/EMEM.Department
      *			(by EMCo/Equipment if Equipment or
      *			EMCo/CompOfEquip if Component)/CostCode/EMGroup;
      *			or from EMDG by EMCo/Department/CostType/EMGroup.
      *		GLOffsetAcct from HQMC by MatlGroup/HQMT.Category
      *			(by MatlGrp/Material).
      *
      * INPUT PARAMETERS:
      *	EMCo
      *	Material Group
      *	Material
      *  	Inventory Company
      *  	Location
      *	Equipment
      *	CostCode
      *	CostType
      *	EMGroup
      *
      * OUTPUT PARAMETERS:
      *	UnitPrice from HQMT
      *	StdUM from HQMT
      *	GLTransAcct from EMDO or EMGD
      *	GLOffsetAcct from HQMC
      *	Error Message, if one
      *
      * RETURN VALUE:
      * 	0 	    Success
      *	1 & message Failure
      **********************************************************/
      (@emco bCompany=null,
      @matlgroup bGroup=null,
      @material bMatl=null,
      @inco bCompany=null,
      @inloc bLoc=null,
      @equipment bEquip=null,
      @component bEquip=null,
      @costcode bCostCode=null,
      @costtype bEMCType=null,
      @emgroup bGroup=null,
      @formprice bUnitCost,
      @formum bUM,
      @formdesc varchar(60),
      @formtaxcode bTaxCode,
      @price bUnitCost output,
      @stdum bUM output,
      @gltransacct bGLAcct output,
      @gloffsetacct bGLAcct output,
      @taxcode_out bTaxCode output,
      @msg varchar(255) output)
      as
     
      set nocount on
     
      declare @category varchar(10),
      	@department varchar(10),
     	@hqmatl bMatl,
     	@stocked bYN,
      	@matlmiscglacct bGLAcct,
         	--@matlvalid char(1),
      	@rcode int,
      	@stdcost bUnitCost,
         	@validcnt int,
         	@upmsg varchar(60),
      	@subrcode int
     
   
      select @rcode=0
     
      if @emco is null
      	begin
      	select @msg='Missing EM Company!', @rcode=1
      	goto bspexit
      	end
      if @matlgroup is null
      	begin
      	select @msg='Missing Matl Group!', @rcode=1
      	goto bspexit
      	end
      if @material is null
      	begin
      	select @msg='Missing Material!', @rcode=1
      	goto bspexit
      	end
      if @equipment is null
      	begin
      	select @msg='Missing Equipment!', @rcode=1
      	goto bspexit
      	end
      /* Note that Component param can be null. */
      if @costcode is null
      	begin
      	select @msg='Missing Cost Code!', @rcode=1
      	goto bspexit
      	end
      if @costtype is null
      	begin
      	select @msg='Missing Cost Type!', @rcode=1
      	goto bspexit
      	end
      if @emgroup is null
      	begin
      	select @msg='Missing EM Group!', @rcode=1
      	goto bspexit
      	end
     
      /* Set @category and @msg to null. */
      select @category = null, @price = 0, @msg = null
     
     /* Validate Material against EMEP and/or HQMT */
     exec @rcode = dbo.bspEMEquipPartVal @emco, @equipment, @matlgroup, @inco, @inloc, 
   	@material, @formtaxcode, @hqmatl output, @stdum output, @price output, 
   	@stocked output, @category output, @taxcode_out output, @msg output
     if @rcode <> 0
     	begin 
   /*select @emco as '@emco', @equipment as '@equipment', @matlgroup as '@matlgroup', @inloc as '@inloc', @material as '@material', 
     	@hqmatl as '@hqmatl output', @stdum as '@stdum output', @price as '@price output', @stocked as '@stocked output', @category as '@category output',
     	@taxcode_out as '@taxcode_out output', @msg as '@msg output'
   select @rcode = 1
   goto bspexit*/
   --  	select @msg = @msg, @rcode = 1
     	goto bspexit
     	end
    /* Make sure that TaxCode is reset to the value on the form if passed in */
   -- if @formtaxcode is not null select @taxcode_out = @formtaxcode
    /* Make sure existing Price, UM and Part Desc on form don't get overwritten with nulls from val procs */
   /*  if @stdum is null select @stdum = @formum
     if @price is null select @price = @formprice
     if @msg is null select @msg = @formdesc*/
     
     if @inloc is not null
      begin
      select @validcnt = Count(*)
      from bINMT
      where INCo = @inco and Loc = @inloc and Material = case when @hqmatl is null then @material else @hqmatl end and MatlGroup = @matlgroup
     
      if @validcnt = 0
          begin
          select @msg = 'Material is not set up in inventory!', @rcode = 1
          goto bspexit
          end
      end
     
     --removed 4/17/01 ref Issue 11586 - zeroing out @price
     --exec @subrcode =  bspEMMatUnitPrice @matlgroup, @inco, @inloc, @material, @formum, 'N', @price output, 'E', @upmsg output
     
      /* If Material found in bHQMT read GLOffsetAcct = bHQMC.GLAcct by bHQMT.Category. */
      if @hqmatl is not null
          select @gloffsetacct = GLAcct
          from bHQMC
          where MatlGroup = @matlgroup and Category = @category
      else /* If Material not found in bHQMT read GLOffsetAcct = bEMCO.MatlMiscGLAcct. */
          select @gloffsetacct = MatlMiscGLAcct
          from bEMCO
          where EMCo = @emco
     
      /* Get GLTransAcct from EMDO or EMDG. */
      /* Step 1 - Because Department doesnt exist for a Component, if @equipment
         passed in is a Component, redefine @equipment as the CompOfEquip for that
         Component in bEMEM. */
      if @component is not null and @component <> ''
      	select @equipment =(select CompOfEquip
      				from bEMEM
      				where EMCo = @emco and Equipment = @component)
      /* Step 2 - Get Department for @equipment from bEMEM. */
      select @department = Department
      from bEMEM
      where EMCo = @emco
      	and Equipment = @equipment
      /* Step 3 - If GLAcct exists in bEMDO, use it. */
      select @gltransacct = GLAcct
      from bEMDO
      where EMCo = @emco
      	and isnull(Department,'') = isnull(@department,'')
      	and EMGroup = @emgroup
      	and CostCode = @costcode
      /* Step 4 - If GLAcct not in bEMDO, get the GLAcct in bEMDG. */
      if @gltransacct is null or @gltransacct = ''
      	select @gltransacct = GLAcct
      	from bEMDG
      	where EMCo = @emco
      		and isnull(Department,'') = isnull(@department,'')
      		and EMGroup = @emgroup
      		and CostType = @costtype
     
      bspexit:
      	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOPartsPostHQMatlVal]'
      	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMWOPartsPostHQMatlVal] TO [public]
GO
