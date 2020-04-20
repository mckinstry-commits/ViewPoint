SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          procedure [dbo].[bspINMatlCopy]
/* Created By: GR 11/6/99
 * Modified By:  GR 5/17/00
 * 				DANF 9/25/02 - Added Booked column to INMT
 * 				RM 12/23/02 Cleanup Double Quotes
 *				GG 02/02/04 - #20538 - split GL units flag
 *
 * Use this procedure to copy the materials from the source location to the destination
 * location. Copy can be restricted by material category - means copies only materials
 * assigned to this category to all the selected locations. And can be restricted by
 * material - means copies only that material to all the selected locations. If there
 * is no category or material restriction then copies all the materials from the source
 * location to all the selected destination locations - this procedure copies one
 * location at a time. If a material already exists at the destination location,
 * no update will occur for that Location and material
 *
 * Pass:
 *	INCO, SourceLocation, DestinationLocation, Category, Material
 *
 * Success returns:
 *	0
 *
 * Error returns:
 *	1 and error message
 ***********************************************************************************/
 	( @inco bCompany = null, @sourceloc bLoc = null, @destloc bLoc = null,
     @category varchar(10) = null, @material bMatl = null, @counter int output, @msg varchar(256) output)
 as
 	set nocount on
 	declare  @rcode int, @matlgroup bGroup, @validcnt int, @opencat int, @openmatl int
 	select @rcode = 0
     select @validcnt=0
     select @opencat=0
     select @openmatl=0
     select @counter = 0
 
 if @inco is null
     begin
     select @msg='Missing IN Company', @rcode=1
     goto bspexit
     end
 
 if @sourceloc is null
     begin
     select @msg='Missing Source Location', @rcode=1
     goto bspexit
     end
 
 if @destloc is null
     begin
     select @msg='Missing Destination Location', @rcode=1
     goto bspexit
     end
 
 -- get material group for this company
 select @matlgroup=MatlGroup from bHQCO where HQCo=@inco
 if @@rowcount = 0
     begin
     select @msg='Material Group not set up for this Company', @rcode=1
     goto bspexit
     end
 
 --if material is specified copy the material to the destination location from source location
 if @material is not null and @category is null
     begin
     select @validcnt=Count(*) from dbo.INMT
     where INCo=@inco and Loc=@destloc and Material=@material and MatlGroup=@matlgroup
     if @validcnt>0
         begin
         --select @msg='Material already exists at the specified destination location', @rcode=1
         goto bspexit
         end
    else
         begin
          insert dbo.INMT(INCo, Loc, MatlGroup, Material, VendorGroup, LastCost, LastECM,
                 AvgCost, AvgECM, StdCost, StdECM, StdPrice, PriceECM, LowStock, ReOrder,
                 WeightConv, PhaseGroup, CostPhase, Active, AutoProd, GLSaleUnits, CustRate,
                 JobRate, InvRate, EquipRate, OnHand, RecvdNInvcd, Alloc, OnOrder,
                 AuditYN, Booked, GLProdUnits)
          select a.INCo, @destloc, a.MatlGroup, @material, a.VendorGroup, a.LastCost, a.LastECM,
                 a.AvgCost, a.AvgECM, a.StdCost, a.StdECM, a.StdPrice, a.PriceECM, a.LowStock, a.ReOrder,
                 a.WeightConv, a.PhaseGroup, a.CostPhase, a.Active, a.AutoProd, a.GLSaleUnits, a.CustRate,
                 a.JobRate, a.InvRate, a.EquipRate, 0, 0, 0, 0, 'Y', 0, a.GLProdUnits
                 from dbo.INMT a
				 inner join dbo.HQMT b with(nolock)on b.MatlGroup=a.MatlGroup and b.Material=a.Material
				where a.INCo=@inco and a.MatlGroup=@matlgroup and a.Loc=@sourceloc 
                 and a.Material=@material and b.Active ='Y' and b.Stocked='Y'
				If @@rowcount >=1 
					Begin
						select @counter = @counter+1
					End
				insert dbo.INMU(MatlGroup, INCo, Material, Loc, UM, Conversion, StdCost, StdCostECM,Price, PriceECM)
				select MatlGroup, INCo, @material, @destloc, UM, Conversion, StdCost, StdCostECM, Price, PriceECM
				from dbo.INMU where INCo=@inco and MatlGroup=@matlgroup and Loc=@sourceloc  and Material=@material
				end
     goto bspexit
     end
  --if category is specified, copy all the materials for this category
 if @category is not null and @material is null
     begin
     declare cat_cursor cursor for
     select Material from dbo.HQMT where MatlGroup=@matlgroup and Category=@category
	and Active = 'Y' and Stocked = 'Y'
	
     open cat_cursor
     select @opencat=1
 
     cat_cursor_loop:                  --loop through all the records
 
     fetch next from cat_cursor into @material
 
     if @@fetch_status=0
         begin
         if not exists(select * from dbo.INMT where INCo=@inco and MatlGroup=@matlgroup
         and Loc=@destloc and Material=@material)
             begin      --if this material does not exist at dest location then insert
             insert dbo.INMT(INCo, Loc, MatlGroup, Material, VendorGroup, LastCost, LastECM,
                    AvgCost, AvgECM, StdCost, StdECM, StdPrice, PriceECM, LowStock, ReOrder,
                    WeightConv, PhaseGroup, CostPhase, Active, AutoProd, GLSaleUnits, CustRate,
                    JobRate, InvRate, EquipRate, OnHand, RecvdNInvcd, Alloc, OnOrder,
                    AuditYN, Booked, GLProdUnits)
             select INCo, @destloc, MatlGroup, @material, VendorGroup, LastCost, LastECM,
                    AvgCost, AvgECM, StdCost, StdECM, StdPrice, PriceECM, LowStock, ReOrder,
                    WeightConv, PhaseGroup, CostPhase, Active, AutoProd, GLSaleUnits, CustRate,
                    JobRate, InvRate, EquipRate, 0, 0, 0, 0, 'Y', 0, GLProdUnits
                    from dbo.INMT 
					where INCo=@inco and MatlGroup=@matlgroup and Loc=@sourceloc  and Material=@material
					 If @@rowcount >=1 
					Begin
						select @counter = @counter+1
					End
					insert dbo.INMU(MatlGroup, INCo, Material, Loc, UM, Conversion, StdCost, StdCostECM,Price, PriceECM)
					select MatlGroup, INCo, @material, @destloc, UM, Conversion, StdCost, StdCostECM,Price, PriceECM
					from dbo.INMU
					where INCo=@inco and MatlGroup=@matlgroup and Loc=@sourceloc and Material=@material
			end
         goto cat_cursor_loop                   --get the next record
         end
 
         --close and deallocate cursor
         if @opencat=1
             begin
             close cat_cursor
             deallocate cat_cursor
             select @opencat=0
             end
     goto bspexit
     end
 
 -- if material and category are not specified then copy the material from the source location
if @category is  null and  @material is null
Begin
 declare matl_cursor cursor for
	select a.Material from dbo.INMT a
	inner join dbo.HQMT b with(nolock)on b.MatlGroup=a.MatlGroup and b.Material=a.Material
    where a.INCo=@inco and a.MatlGroup=@matlgroup and a.Loc=@sourceloc and b.Active = 'Y' and b.Stocked = 'Y'
 
 open matl_cursor
 select @openmatl=1
 
 matl_cursor_loop:                 --loop through all the records
 
 fetch next from matl_cursor into @material
 if @@fetch_status=0
     begin
     if not exists(select * from dbo.INMT where INCo=@inco and MatlGroup=@matlgroup
         and Loc=@destloc and Material=@material)
         begin     --if this material does not exist at dest location then insert
         insert dbo.INMT(INCo, Loc, MatlGroup, Material, VendorGroup, LastCost, LastECM,
                AvgCost, AvgECM, StdCost, StdECM, StdPrice, PriceECM, LowStock, ReOrder,
                WeightConv, PhaseGroup, CostPhase, Active, AutoProd, GLSaleUnits, CustRate,
                JobRate, InvRate, EquipRate, OnHand, RecvdNInvcd, Alloc, OnOrder,
                AuditYN, Booked, GLProdUnits)
         select INCo, @destloc, MatlGroup, @material, VendorGroup, LastCost, LastECM,
                AvgCost, AvgECM, StdCost, StdECM, StdPrice, PriceECM, LowStock, ReOrder,
                WeightConv, PhaseGroup, CostPhase, Active, AutoProd, GLSaleUnits, CustRate,
                JobRate, InvRate, EquipRate, 0, 0, 0, 0, 'Y', 0, GLProdUnits
                from dbo.INMT 
				where INCo=@inco and MatlGroup=@matlgroup and Loc=@sourceloc  and Material=@material
 				If @@rowcount >=1 
				Begin
					select @counter = @counter+1
				End
				insert dbo.INMU(MatlGroup, INCo, Material, Loc, UM, Conversion, StdCost, StdCostECM,Price, PriceECM)
				select MatlGroup, INCo, @material, @destloc, UM, Conversion, StdCost, StdCostECM,Price, PriceECM
				from dbo.INMU
				where INCo=@inco and MatlGroup=@matlgroup and Loc=@sourceloc and Material=@material
         end
     goto matl_cursor_loop                  --get the next record
     end
 
     --close and deallocate cursor
     if @openmatl=1
         begin
         close matl_cursor
         deallocate matl_cursor
         select @openmatl=0
         end 
	Goto bspexit
End
 
 bspexit:
     if @opencat=1
         begin
         close cat_cursor
         deallocate cat_cursor
         end
 
      if @openmatl=1
         begin
         close matl_cursor
         deallocate matl_cursor
         end
 
     --if @rcode<>0 select @msg=@msg + char(13) + char(13) + '[bspINMatlCopy]'
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMatlCopy] TO [public]
GO
