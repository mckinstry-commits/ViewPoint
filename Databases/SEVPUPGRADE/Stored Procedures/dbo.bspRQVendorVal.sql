SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRQVendorVal    Script Date: 9/3/2004 12:55:21 PM ******/
    CREATE           proc [dbo].[bspRQVendorVal]
    /***********************************************************
     * Created By:  DC 09/03/2004
     * Modified By:	DC 1/5/05 - 26569 & again on 2/3
     *					DC  7/06/05  - 28973 Vendor Change defaults the incorrect info
	*				DC 6/25/07 - 6.x re-code.  Noticed that the unit cost returned wasn't correct
     * Usage:
     *	Used by RQEntry to validate active vendors by either Sort Name or number.
     * 	
     *
     * Input params:
     *	@co			Company
     *	@vendgroup	Vendor Group
     *	@vendor		Vendor sort name or number
     * 	@matl		HQ Material Code
     *	@matlgrp	Material Group
     *	@um			HQ Material Unit of Measure
     *
     *
     * Output params:
     *	@vendorout	Vendor number
     *	@vendorMatl	Vendor Material ID
     *	@desc		Vendor Material Description
     *	@um			Vendor Material Unit of Measure
     *  @unitcost	Vendor Material Unit Cost
     *	@ecm		Vendor Material ECM
     *	@msg		Vendor Name or error message
     *
     * Return code:
     *	0 = success, 1 = failure
     *****************************************************/
    (@co bCompany = null, @vendgroup bGroup = null, @vendor varchar(15) = null, 
     	@matl bMatl = null, @matlgrp bGroup = null, @um bUM = null, 
    	@descin bDesc = null, @unitcostin bUnitCost = null,	@ecmin bECM = null,	
    	@vendorout bVendor=null output, @vendormatl bMatl = null output, 
    	@desc bDesc = null output, @unitcost bUnitCost = null output,
    	@ecm bECM = null output,
   	@vendum bUM = null output,
   	@msg varchar(255) output)
    
    as
    set nocount on
    
    declare @rcode int
    
    select @rcode = 0
    
    -- check required input params
    if @vendgroup is null
    	begin
    	select @msg = 'Missing Vendor Group.', @rcode = 1
    	goto bspexit
    	end
    
    if @vendor is null
    	begin
    	select @msg = 'Missing Vendor.', @rcode = 1
    	goto bspexit
    	end
    
    -- If @vendor is numeric then try to find Vendor number
    if dbo.bfIsInteger(@vendor) = 1 and len(@vendor) < 7 
    	BEGIN
    	SELECT @vendorout=Vendor, @msg=Name
    	FROM APVM WITH (NOLOCK)
    	WHERE VendorGroup=@vendgroup 
    		and Vendor = convert(int,convert(float, @vendor))
    		and ActiveYN = 'Y'
    	END
    
    -- if not numeric or not found try to find as Sort Name
    if @vendorout IS NULL
    	BEGIN
        SELECT @vendorout = Vendor, @msg = Name
    	FROM APVM WITH (NOLOCK)
    	WHERE VendorGroup = @vendgroup 
    		and SortName = @vendor
    		and ActiveYN = 'Y'
    	END
    
    -- if not found,  try to find closest
    if @vendorout IS NULL
    	BEGIN
    	SELECT @vendorout = Vendor, @msg = Name
    	FROM APVM WITH (NOLOCK)
    	WHERE VendorGroup = @vendgroup 
    		and SortName like @vendor + '%'
    	END
    
    if @vendorout IS NULL
      	BEGIN
   	SELECT @vendorout = @vendor  --DC 28973
    	SELECT @msg = 'Not a valid Vendor', @rcode = 1
    	GOTO bspexit
    	END
    
    -- If the vendor was found then set the output fields
    SELECT @vendormatl = VendMatId,
    		@desc = Description, 
			@unitcost = 
    			Case CostOpt
    				WHEN 1 then (select Cost from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @matl)
    				WHEN 2 then UnitCost
    				WHEN 3 then (select Price from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @matl) - ((select Price from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @matl) * PriceDisc)
    				WHEN 4 then BookPrice - (BookPrice * PriceDisc)
    			END , 
    		--@unitcost = UnitCost,  --DC 6.x recode
   			@vendum = UM,  --DC 26569
    		@ecm =  
    			Case CostOpt
    				WHEN 1 then (select CostECM from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @matl)
    				WHEN 2 then CostECM
    				WHEN 3 then (select CostECM from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @matl)
    				WHEN 4 then PriceECM
    			END  
    FROM POVM WITH (NOLOCK)
    WHERE VendorGroup = @vendgroup 
    	AND Vendor = @vendorout
    	AND MatlGroup = @matlgrp
    	AND Material = @matl
    	AND UM = @um
    --DC 26569
    IF @@Rowcount = 0 
   	BEGIN
   	 SELECT top 1 @vendormatl = VendMatId,
   	 		@desc = Description, 
			@unitcost = 
    			Case CostOpt
    				WHEN 1 then (select Cost from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @matl)
    				WHEN 2 then UnitCost
    				WHEN 3 then (select Price from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @matl) - ((select Price from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @matl) * PriceDisc)
    				WHEN 4 then BookPrice - (BookPrice * PriceDisc)
    			END,  
			--@unitcost = UnitCost,  --DC 6.x recode
   			@vendum  = UM,
   	 		@ecm =  
   	 			Case CostOpt
   	 				WHEN 1 then (select CostECM from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @matl)
   	 				WHEN 2 then CostECM
   	 				WHEN 3 then (select CostECM from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @matl)
   	 				WHEN 4 then PriceECM
   	 			END  
   	 FROM POVM WITH (NOLOCK)
   	 WHERE VendorGroup = @vendgroup 
   	 	AND Vendor = @vendorout
   	 	AND MatlGroup = @matlgrp
   	 	AND Material = @matl
   	END
   	
    
    bspexit:
    IF @desc IS NULL
    	BEGIN
    	SELECT @desc = @descin
    	END
    
    IF @unitcost IS NULL
    	BEGIN
    	SELECT @unitcost = @unitcostin
    	END
    
    IF @ecm IS NULL 
    	BEGIN
    	SELECT @ecm = @ecmin
    	END
    
    IF @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspRQVendorVal]'
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQVendorVal] TO [public]
GO
