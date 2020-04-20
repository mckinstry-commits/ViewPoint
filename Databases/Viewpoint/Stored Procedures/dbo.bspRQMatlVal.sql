SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRQMatlVal    Script Date: 3/19/2004 10:50:26 AM ******/
    CREATE               procedure [dbo].[bspRQMatlVal]
    /***********************************************************
    * CREATED BY: DC 3/19/2004
    * Modified By: DC - 12/23/2004  #26628 & #26629
    *				DC - 12/27/2004  #26567
	*				DC - 03/24/08 #127369
	*				DC - 04/03/08 #127682 - Changed the error message for inactive IN materials
    *
    * Validates Material based on the RQ Line Type
    *
    * Used
    *	RQ Entry
    *
    * Pass:
    *   Co - Inventory Company
    *   Loc - IN Location 
    *   Material = Material validate at the Location
    *   Material Group = 
    *   RQType = Line Type
    *
    * Success returns:
    *   Description of Material
    *
    * Error returns:
    *	1 and error message
    ************************************************************/
    	(@co bCompany = null,
		@inco bCompany,  --DC #127369
		@jcco bCompany,  --DC #127369
		@emco bCompany,  --DC #127369
    	@loc bLoc,
    	@material bMatl,
    	@matlgroup bGroup,
    	@rqtype as int,
   	@wo bWO = null,
   	@woitem bItem = null, 
   	@equipment bEquip = null,
    	@description bItemDesc output,
    	@purchaseum bUM output,
    	@matlphase bPhase output,
    	@jccosttype bJCCType output,
    	@msg varchar(255) output)
    as
    
    set nocount on
    
    declare @active bYN,
    	@category varchar(10),
    	@numrows int,
    	@stocked bYN,
    	@rcode int,
   	@hqmatl varchar(30), 
   	@hqmatlgrp bGroup
    
    select @rcode = 0, @description ='Not in material file.'
    if @rqtype is null
    	begin
    	select @msg = 'Missing RQ Item Type', @rcode = 1
    	goto bspexit
    	end
    
    if @co is null
    	begin
    	select @msg = 'Missing Company', @rcode = 1
    	goto bspexit
    	end
    
    IF @rqtype = 4 or @rqtype = 5
   	BEGIN
   		/* Validate material in EMWP */
   		if @wo is not null and @woitem is not null
   		BEGIN
   			--select @hqmatl = @material
   			select @description = Description, @purchaseum = UM 
   			from bEMWP with (nolock) 
   			where EMCo = @emco and 
   				WorkOrder=@wo and 
   				WOItem=@woitem and
   				MatlGroup = @matlgroup and 
   				Material = @material and 
   				Equipment = @equipment
   			IF @@rowcount > 0 goto End_Validation
   		END
   
   		/* Validate material in bEMEP */
   		select @description = Description, @purchaseum = UM, @hqmatlgrp = MatlGroup, @hqmatl=HQMatl
   		from bEMEP with (nolock) 
   		where EMCo = @emco and 
   			Equipment = @equipment and 
   			PartNo = @material
   		if @@rowcount > 0
   			begin
   			if @hqmatlgrp is not null and @hqmatl is not null
   				begin
   				select @purchaseum = PurchaseUM from bHQMT with (nolock)
   					where MatlGroup = @hqmatlgrp and Material = @hqmatl
   				end
   		 	goto End_Validation
   			end
   	
   		/* Validate material in bHQMT */
   		select @description = Description, @purchaseum = PurchaseUM
   		from bHQMT with (nolock) 
   		where MatlGroup = @matlgroup 
   			and Material = @material
   		if @@rowcount = 0 
   		/* If material Id not in bEMEP, bPOVM, bHQMT, return desc */
   		BEGIN
   		select @description = 'Not in Material File', @rcode = 0
   		goto bspexit 
   		END
   	END
   
    if @rqtype = 3 --Expense.
      BEGIN
    
    	IF @material is null
    		begin
    		select @msg = 'Missing Material', @rcode = 1
    		goto bspexit
    		end
    	IF @matlgroup is null
    		begin
    		select @msg = 'Missing Material Group', @rcode = 1
    		goto bspexit
    		end
    
    	SELECT 	@active = Active, @category=Category, @description = Description, @stocked = Stocked, 
    			@purchaseum = PurchaseUM, @matlphase = MatlPhase, @jccosttype = MatlJCCostType
    	FROM HQMT with (NOLOCK)
    	WHERE MatlGroup = @matlgroup and Material = @material
    	if @@rowcount = 0
    	    BEGIN
    		select @purchaseum = 'EA'
    	    select @msg = 'Material not on file', @rcode = 0
    	    goto bspexit
    	    END
    	IF @active = 'N' 
    		BEGIN
    	    select @msg = 'Must be an active Material', @rcode = 1
    	    goto bspexit
    		END
      END
   
    if @rqtype = 1 --Job.
      BEGIN
    
    	IF @material is null
    		begin
    		select @msg = 'Missing Material', @rcode = 1
    		goto bspexit
    		end
    	IF @matlgroup is null
    		begin
    		select @msg = 'Missing Material Group', @rcode = 1
    		goto bspexit
    		end
    
    	SELECT 	@active = Active, @category=Category, @description = Description, @stocked = Stocked, 
    			@purchaseum = PurchaseUM, @matlphase = MatlPhase, @jccosttype = MatlJCCostType
    	FROM HQMT with (NOLOCK)
    	WHERE MatlGroup = @matlgroup and Material = @material
    	if @@rowcount = 0
    	    BEGIN
   		select @purchaseum = 'EA'
   		select @msg = 'Material not on file', @rcode = 0
   		goto bspexit
   		END
    	IF @active = 'N' 
    		BEGIN
    	    select @msg = 'Must be an active Material', @rcode = 1
    	    goto bspexit
    		END
    		
      END
    
    IF @rqtype = 2  --Inventory
      BEGIN
    	if @loc is null
    		begin
    		select @msg = 'Missing IN Location', @rcode = 1
    		goto bspexit
    		end
    	if @material is null
    		begin
    		select @msg = 'Missing Material', @rcode = 1
    		goto bspexit
    		end
    	if @matlgroup is null
    		begin
    		select @msg = 'Missing Material Group', @rcode = 1
    		goto bspexit
    		end
    
    	--get category and material description
    	select  @category=Category, @description = Description, @stocked = Stocked, 
    			@purchaseum = PurchaseUM, @matlphase = MatlPhase, @jccosttype = MatlJCCostType
    	from HQMT with (nolock)
    	where  MatlGroup=@matlgroup and Material=@material
    	if @@rowcount = 0
    	     begin
    		 select @purchaseum = 'EA'
    	     select @msg='Material not set up in HQ Materials', @rcode=1
    	     goto bspexit
    	     end
    	if @stocked = 'N'
    	     begin
    	     select @msg = 'Must be a Stocked Material.', @rcode = 1
    	     goto bspexit
    	     end
    	--validate material in INMT
    	select @active = Active
    	from INMT WITH (NOLOCK)
    	where INCo = @inco and Loc = @loc and Material=@material and MatlGroup=@matlgroup
    	if @@rowcount = 0
    	    begin
    	    select @msg='Material not set up in IN Location Materials', @rcode=1   --DC 26567
    	    goto bspexit
    	    end
    	if @active = 'N'
    	    begin
    	    select @msg = 'Must be an active IN Inventory Material', @rcode = 1
    	    goto bspexit
    	    end
      END
    
   
   End_Validation:
    RETURN
    
    bspexit:
        if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspRQMatlVal]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQMatlVal] TO [public]
GO
