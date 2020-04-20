SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspRQVendMatlVal    Script Date: 06/26/2007 9:33:10 AM ******/
   CREATE  proc [dbo].[vspRQVendMatlVal]
   /***********************************************************
    * CREATED BY: DC 6/26/2007
    *
    * USAGE:
    * validates PO Vendor Material 
    *
    * INPUT PARAMETERS
    *   Vendor 
    *   Vendor Material 
	*	Vendor Group
	*
    * OUTPUT PARAMETERS
	*	Description 
	*	Material
	*	UM
	*	Unit Cost and ECM
    *   @msg      error message if error occurs otherwise Description of EarnCode
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   	(@vendorgroup bGroup, @vendor bVendor, @vendmatl varchar(30),
        @hqmtmatl bMatl output,  @matldesc bDesc output, @um bUM output,
        @unitcost bUnitCost output, @ecm bECM = null output, 
		@msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @matlgrp bGroup
   
   select @rcode = 0
   
   if @vendorgroup is null
   	begin
   	select @msg = 'Missing Vendor Group!', @rcode = 1
   	goto vspexit
   	end
   
   if @vendor is null
   	begin
   	select @msg = 'Missing Vendor!', @rcode = 1
   	goto vspexit
   	end
   
   if @vendmatl is null
       begin
       select @msg = 'Missing Vendor Material #', @rcode = 1
       goto vspexit
       end
   
	SELECT top 1 @um = UM,
		@hqmtmatl = Material,
		@matldesc = Description,
		@matlgrp = MatlGroup
	FROM POVM with (nolock)
	WHERE VendorGroup = @vendorgroup and Vendor = @vendor and VendMatId = @vendmatl
    IF @@Rowcount = 0 
       begin
       select @msg = 'Invalid Vendor Material', @rcode = 1
       goto vspexit
       end

	SELECT @unitcost = 
			Case CostOpt
				WHEN 1 then (select Cost from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @hqmtmatl)
				WHEN 2 then UnitCost
				WHEN 3 then (select Price from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @hqmtmatl) - ((select Price from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @hqmtmatl) * PriceDisc)
				WHEN 4 then BookPrice - (BookPrice * PriceDisc)
			END , 
		@ecm =  
			Case CostOpt
				WHEN 1 then (select CostECM from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @hqmtmatl)
				WHEN 2 then CostECM
				WHEN 3 then (select CostECM from HQMT WITH (NOLOCK) where MatlGroup = @matlgrp AND Material = @hqmtmatl)
				WHEN 4 then PriceECM
			END  
	FROM POVM with (nolock)
	WHERE VendorGroup = @vendorgroup
		and Vendor = @vendor 
		and MatlGroup = @matlgrp
		and Material = @hqmtmatl
		and UM = @um

   vspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspRQVendMatlVal] TO [public]
GO
