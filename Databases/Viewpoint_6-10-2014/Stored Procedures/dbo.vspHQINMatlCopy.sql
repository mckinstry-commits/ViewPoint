SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         procedure [dbo].[vspHQINMatlCopy]
/* Created By: TRL 07/27/06
 * Modified By: 
 *
 * Use this procedure to copy the materials to the selected location.
 *  Copy can be restricted by UM 
 *	 This procedure copies one location at a time. 
 *   If a material already exists at the destination location,
 *	  no update will occur for that Location and material
 *
 * Pass:
 *	MatlGroup Material, Selected Location INCO, UM, AllUM (Y/N)
 *
 * Success returns:
 *	0
 *
 * Error returns:
 *	1 and error message
 ***********************************************************************************/
 (@matlgroup bGroup = null, 
  @material bMatl = null, 
  @destloc bLoc = null, 
  @inco bCompany = null, 
  @um bUM = null, 
  @allUM varchar(1) = 'N',  
  @msg varchar(256) output)
 as
 	set nocount on
 	declare  @rcode int, @vendorgroup int
 	select @rcode = 0
    
 If  IsNull(@matlgroup,0) = 0
     begin
		select @msg='Missing Material Group!', @rcode=1
		goto vspexit
	end

 if @material is  null
      begin
		 select @msg='Missing Material!', @rcode=1
		 goto vspexit
     end

 if  Isnull(@inco,0)=0
     begin
		 select @msg='Missing IN Company!', @rcode=1
		 goto vspexit
     end

  if @allUM ='N' and @um is null
     begin
		 select @msg='Missing UM!', @rcode=1
		 goto vspexit
     end

 if @destloc is null
     begin
		select @msg='Missing Source Location', @rcode=1
		 goto vspexit
     end
 
select @vendorgroup = HQCO.VendorGroup from dbo.HQCO with(nolock) Where HQCO.HQCo = @inco

 --if material is specified copy the material to the destination location from source location
If (select Count(*) from dbo.INMT with (nolock)	where INCo=@inco and Loc=@destloc and Material=@material and MatlGroup=@matlgroup) =0
	Begin
		insert into dbo.INMT(INCo, Loc, MatlGroup, Material,  LastCost, LastECM,
		AvgCost, AvgECM, StdCost, StdECM, StdPrice, PriceECM, LowStock, ReOrder,
		WeightConv, Active, AutoProd, GLSaleUnits, CustRate,
		JobRate, InvRate, EquipRate, OnHand, RecvdNInvcd, Alloc, OnOrder,
		AuditYN, Booked, GLProdUnits, VendorGroup)
		select @inco, @destloc, @matlgroup, @material,  Cost, CostECM,
		Cost, CostECM, Cost, CostECM, Price, PriceECM, 0, 0,
		IsNull(WeightConv,0),  Active,'N', 'N', 0, 
		0, 0, 0, 0, 0, 0, 0, 'Y', 0, 'N',@vendorgroup
        from dbo.HQMT with(nolock)
		where  MatlGroup=@matlgroup and Material=@material 
		If @@rowcount = 1 
			Begin	
			If @allUM = 'A'
				begin
					insert into dbo.INMU(MatlGroup, INCo, Material, Loc, UM, Conversion, StdCost, StdCostECM, Price, PriceECM)
					select @matlgroup, @inco, @material, @destloc, a.UM, a.Conversion, a.Cost, a.CostECM, a.Price, a.PriceECM
					from dbo.HQMU a with(nolock)
					where  a.MatlGroup=@matlgroup and a.Material=@material  
					and not exists (select UM From INMU Where INCo=@inco and MatlGroup=@matlgroup and Loc=@destloc 
					and Material=@material and UM = a.UM)
					--and a.UM <> IsNull((Select UM From INMU Where INCo=@inco and MatlGroup=@matlgroup and Loc=@destloc and Material=@material),'')
				end
			Else
				If	(select Count(*) from dbo.INMU with(nolock)where  INCo =@inco and MatlGroup=@matlgroup and Loc=@destloc and Material=@material and UM = @um)=0
					Begin
						insert into dbo.INMU(MatlGroup, INCo, Material, Loc, UM, Conversion, StdCost, StdCostECM,	Price, PriceECM)
						select @matlgroup, @inco, @material, @destloc, a.UM, a.Conversion, a.Cost, a.CostECM, a.Price, a.PriceECM
						from dbo.HQMU a with(nolock)
						where   a.MatlGroup=@matlgroup and a.Material = @material and a.UM = @um 
					End
			END	EndELSE	If @allUM = 'A'
		begin
			insert into  dbo.INMU(MatlGroup, INCo, Material, Loc, UM, Conversion, StdCost, StdCostECM, Price, PriceECM)
			select @matlgroup, @inco, @material, @destloc, a.UM, a.Conversion, a.Cost, a.CostECM, a.Price, a.PriceECM
			from dbo.HQMU a with(nolock) 
			where  a.MatlGroup=@matlgroup and a.Material=@material  
			--and a.UM <> IsNull((Select UM From INMU Where INCo=@inco and MatlGroup=@matlgroup and Loc=@destloc and Material=@material),'')
			and not exists (select UM From INMU Where INCo=@inco and MatlGroup=@matlgroup and Loc=@destloc 
			and Material=@material and UM = a.UM)
		end
    Else
		If (select Count(*) from dbo.INMU with(nolock) where  INCo =@inco and MatlGroup=@matlgroup and Loc=@destloc and Material=@material and UM = @um)=0
			Begin
				insert into dbo.INMU(MatlGroup, INCo, Material, Loc, UM, Conversion, StdCost, StdCostECM,	Price, PriceECM)
				select @matlgroup, @inco, @material, @destloc, a.UM, a.Conversion, a.Cost, a.CostECM, a.Price, a.PriceECM
				from dbo.HQMU a with(nolock)
				where   a.MatlGroup=@matlgroup and a.Material = @material and a.UM = @um 
			end
		
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQINMatlCopy] TO [public]
GO
