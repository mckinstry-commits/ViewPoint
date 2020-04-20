SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspHQUMValForRQEntry    Script Date: 8/28/99 9:34:56 AM ******/
   CREATE   proc [dbo].[vspHQUMValForRQEntry]
   /*************************************
	*	Created By:	DC  06/26/2007
	*
	*
    * USAGE:
	*	validates HQ Unit of Measure For RQ Entry
	*	If Material exists in POVM then it returns the 
	*	Unit Cost for that Material.
	*	If no record in POVM, then validates UM in
	*	HQMT if no match, UM must  exist
	*	in HQMU or be STD Unit Of Measure.
	*
	*	If Material doesn't exist in HQMT then UM must
	*	exist in HQUM
	*
    * INPUT PARAMETERS
	*	Material Group
	*	Material
	*   Unit Of Measure to validate
	*	VendorGroup
	*	Vendor
	*	Vendor Material
	*	
	* Returns:
	*	Description from bHQUM
	*	Unit Cost from POVM if there is a match	
	*
	* Success returns:
	*	0
	*
	* Error returns:
	*	1 and error message
	**************************************/
   
   	(@matlgroup bGroup, @matl bMatl, @um bUM, 
	@vendorgroup bGroup = null, @vendor bVendor = null, 
	@unitcost bUnitCost = null output, @ecm bECM = null output, 
	@msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int, @stdum bUM
   
   select @rcode = 0

	if @vendorgroup is not null and @vendor is not null 
		begin
			SELECT @unitcost = 
					Case CostOpt
						WHEN 1 then (select Cost from HQMT WITH (NOLOCK) where MatlGroup = @matlgroup AND Material = @matl)
						WHEN 2 then UnitCost
						WHEN 3 then (select Price from HQMT WITH (NOLOCK) where MatlGroup = @matlgroup AND Material = @matl) - ((select Price from HQMT WITH (NOLOCK) where MatlGroup = @matlgroup AND Material = @matl) * PriceDisc)
						WHEN 4 then BookPrice - (BookPrice * PriceDisc)
					END , 
				@ecm =  
					Case CostOpt
						WHEN 1 then (select CostECM from HQMT WITH (NOLOCK) where MatlGroup = @matlgroup AND Material = @matl)
						WHEN 2 then CostECM
						WHEN 3 then (select CostECM from HQMT WITH (NOLOCK) where MatlGroup = @matlgroup AND Material = @matl)
						WHEN 4 then PriceECM
					END  
			FROM POVM with (nolock)
			WHERE VendorGroup = @vendorgroup
				and Vendor = @vendor 
				and MatlGroup = @matlgroup
				and Material = @matl
				and UM = @um

		end
   
	SELECT @stdum = StdUM 
	FROM bHQMT
    WHERE MatlGroup=@matlgroup and Material=@matl
   
	/*If Material exists in bHQMT then must be in HQMU or STDUM*/
	if @@rowcount > 0
		begin
			if @stdum <> @um
				if not exists (select * from bHQMU
					where MatlGroup=@matlgroup and Material=@matl and UM = @um)
     			begin
   					select @msg = 'Unit of Measure not setup for material:' + isnull(@matl,''), @rcode = 1
   					goto vspexit
   				end
		end
   
	select @msg = Description from bHQUM where UM = @um
    if @@rowcount = 0
		begin
			select @msg = 'Unit of Measure not setup!', @rcode = 1
		end
   
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQUMValForRQEntry] TO [public]
GO
