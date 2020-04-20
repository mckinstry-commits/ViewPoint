SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspINInitializeMatl]
    /***********************************************************************************
    * Created By: GR 11/20/99
    * Modified by: GR 2/08/00, 5/17/00
    *               GG 5/30/00 - bINMU.Conversion datatype changed to bUnitCost
    *               GG 06/06/00 - Removed cursors to use multirow insert statements
    *               DANF 9/25/02 - Add Booked column
    *				 RM 12/23/02 Cleanup Double Quotes
    *				GG 02/02/04 - #20538 - split GL units flag
    *
    * This sp is used to set up materials at a location. The materials can be copied to
    * a location either by range of categories or by materials. All materials from
    * HQ materials within this range that are stocked, active and do not already exist
    * at this location will be added to IN Materials(bINMT) and bINMU. If range is not specified
    * all materials will be copied
    *
    * Inputs:
    *	@inco           IN Company
    *   @loc            Location
    *   @matlgroup      Material Group
    *   @begcat         Begining Category
    *   @endcat         Ending Category
    *   @begmatl        Begining Material
    *   @endmatl        Ending Material
    *
    * Output:
    *   @counter        # of materials added
    *   @msg            error message
    *
    * Return code:
    *	0 if successful, 1 if error
    *
    ***********************************************************************************/
        (@inco bCompany = null, @loc bLoc = null, @matlgroup bGroup = null, @begcat varchar(10) = null,
        @endcat varchar(10) = null, @begmatl bMatl = null, @endmatl bMatl = null, @counter int output,
        @msg varchar(100) output)
    as
    set nocount on
    
    declare @rcode int, @vendorgroup bGroup 
    
    select @rcode = 0, @counter = 0
    
    if @inco is null
        begin
        select @msg='Missing IN Company', @rcode=1
        goto bspexit
        end
    if @loc is null
        begin
        select @msg='Missing Location', @rcode=1
        goto bspexit
        end
    if @matlgroup is null
        begin
        select @msg='Missing Material Group', @rcode=1
        goto bspexit
        end
    
    --get Vendor Group
    select @vendorgroup=VendorGroup from bHQCO where HQCo=@inco
    if @@rowcount = 0
        begin
        select @msg = 'Invalid IN Company #', @rcode = 1
        goto bspexit
        end
    
    
    -- add Active, Stocked materials to Inventory from HQ Material master table
    insert bINMT (INCo, Loc, MatlGroup, Material, VendorGroup, LastCost, LastECM, AvgCost,
        AvgECM, StdCost, StdECM, StdPrice, PriceECM, LowStock, ReOrder, WeightConv, Active,
        AutoProd, GLSaleUnits, CustRate, JobRate, InvRate, EquipRate, OnHand, RecvdNInvcd, Alloc,
        OnOrder, AuditYN, Booked, GLProdUnits)
    select @inco, @loc, MatlGroup, Material, @vendorgroup, Cost, CostECM, Cost,
        CostECM, Cost, CostECM, Price, PriceECM, 0, 0, isnull(WeightConv, 0), 'Y',
        'N', 'N', 0, 0, 0, 0, 0, 0, 0, 0, 'Y', 0, 'N'
    from bHQMT where MatlGroup = @matlgroup
        and Category >= isnull(@begcat, Category) and Category <= isnull(@endcat, Category)
        and Material >= isnull(@begmatl, Material) and Material <= isnull(@endmatl, Material)
        and Active = 'Y' and Stocked = 'Y'
        and Material not in (select Material from bINMT where INCo = @inco and Loc = @loc)
    
    select @counter = @@rowcount    -- # of materials added to bINMT
    
    -- add alternative u/m's to Inventory
    insert bINMU (INCo, MatlGroup, Material, Loc, UM, Conversion, StdCost, StdCostECM, Price, PriceECM)
    select @inco, @matlgroup, u.Material, @loc, u.UM, u.Conversion, u.Cost, u.CostECM, u.Price, u.PriceECM
    from bHQMU u
    left join bINMU i on i.MatlGroup = u.MatlGroup and i.Material = u.Material and i.UM = u.UM
    join bHQMT m on m.MatlGroup = u.MatlGroup and m.Material = u.Material
    where m.MatlGroup = @matlgroup
        and m.Category >= isnull(@begcat, m.Category) and m.Category <= isnull(@endcat, m.Category)
        and m.Material >= isnull(@begmatl, m.Material) and m.Material <= isnull(@endmatl, m.Material)
        and m.Active = 'Y' and m.Stocked = 'Y' and i.Material is null  -- will be null for all rows not in bINMU
    
    bspexit:
    	--if @rcode<>0 select @msg
    
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINInitializeMatl] TO [public]
GO
