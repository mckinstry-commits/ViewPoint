SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPEquipValNoComponent    Script Date: 2/12/2002 3:41:14 PM ******/
    
    CREATE procedure [dbo].[bspAPEquipValNoComponent]
    
    /***********************************************************
     * CREATED BY: GR 7/23/99
     * MODIFIED BY: JM 2-12-02 Corrected reference to EMSX to include ShopGroup in key.
	 *				MV 12/11/07 - #209702 Reviewer Groups
	 *				MV 07/30/08 - #129184 - fix @dept declare from int to bDept
	 *				TRL 08/13/2008 - 126196 check to see Equipment code is being Changed 
     *
     * USAGE:
     *	Validates EMEM.Equipment. 
     *	Returns following:
     *
     *		Status ('A' if active 
     *			or 'I' if not)
     *		Inventory Location for parts
     *		Equipment Type ('E' or 'C')
     *		Whether costs are posted to components
     * 
     * INPUT PARAMETERS
     *	@emco		EM Company 
     *	@equip		Equipment to be validated
     *
     * OUTPUT PARAMETERS
     *	@shop
     *	@status 	Active (A) or Inactive (I)
     *	@invloc		bEMSX.InvLoc by bEMEM.Shop
     *	@equiptype	bEMEM.Type ('E' for Equipment or 'C' for Component)
     *	@postcosttocomp bEMEM.PostCostToComp
     *	@msg		Description or Error msg if error
     *
     * RETURN VALUE:
     * 	0 	    Success
     *	1 & message Failure
      **********************************************************/
    	
    (@emco bCompany = null, 
    @equip bEquip = null, 
    @status char(1) output, 
    @shop char(20) output,
    @invloc bLoc output,
    @equiptype char(1) output,
    @postcosttocomp char(1) output,
	@reviewergroup varchar(10) output,
    @msg varchar(255) output) 
    
    as 
    
    set nocount on
    declare @rcode int, @type char(1), @shopgroup bGroup, @dept bDept
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
    
	-- Return if Equipment Change in progress for New Equipment Code, 126196.
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end

    /* Validate Equipment and read @shop and @type from bEMEM. */
    select @status=Status, 
    	@equiptype = Type,
    	@postcosttocomp = PostCostToComp,
		@dept = Department, 
    	@msg = Description
    from bEMEM 
    where EMCo = @emco 
    	and Equipment = @equip
    if @@rowcount = 0
    	begin
    	select @msg = 'Equipment invalid!', @rcode = 1
    	goto bspexit
    	end
	
    /* Treat a null EMEM.PostCostToComp as a 'N'. */	
    if @postcosttocomp is null
    	select @postcosttocomp = 'N'
    
    /* Reject if passed Equipments Type is C for Component. */
    if @equiptype = 'C'
    	begin
    	select @msg = 'Equipment is a Component!', @rcode = 1
    	goto bspexit
    	end
    
    /* Determine if status is active  */
    if @status='I'
    	begin
    	select @msg='Equipment must be active!', @rcode=1
    	goto bspexit
    	end
    
    /* Read inventory location from bEMSX for @shop, if available. */
    if @shop is not null
   	/* Get ShopGroup from bHQCO for @emco */
   	select @shopgroup = ShopGroup from bHQCO where HQCo = @emco
    	select @invloc = InvLoc
    	from bEMSX
     	where ShopGroup = @shopgroup and Shop = @shop

	-- If EMEM.Department is not null get ReviewerGroup from bEMDM
	if @dept is not null
		begin
		select @reviewergroup=ReviewerGroup
		 from bEMDM with (nolock)
		 where EMCo = @emco and Department = @dept
		end
    		
    bspexit:
    	if @rcode<>0 select @msg=@msg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPEquipValNoComponent] TO [public]
GO
