SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE procedure [dbo].[vspINMaterialCount]
/************************************************************************
*
* CREATED:	GP 09/24/2009 - Issue #135247 Re-factor IN material counts to get correct counts.
* MODIFIED:	
*
* Called by other SP's to get IN material counts.
*
* SP's Using This:
*	bspINPhyCountInit
*	bspINGetSysCount
*
* Returns @msg - error message
* Returns @rcode - 0 if success
* Returns @rcode - 1 if fail
*
*************************************************************************/
(@INCo bCompany = null, @Loc bLoc = null, @MatlGroup bGroup = null, @Material bMatl = null, @IncludeCountDate bYN = null, 
	@CountDate bDate = null, @SystemCount bUnits = null output, @msg varchar(255) = null output)
as
set nocount on

declare @rcode tinyint, @OnHand bUnits, @UnitsInOut bUnits, @APUnitsInOut bUnits, @POUnitsInOut bUnits

select @rcode = 0, @SystemCount = 0, @OnHand = 0, @UnitsInOut = 0, @APUnitsInOut = 0, @POUnitsInOut = 0
if @CountDate is null set @CountDate = '1/1/1950'


-- Get Various Material Counts
if @IncludeCountDate = 'Y'
begin
	-- current OnHand from IN Location Materials
	select @OnHand = isnull(OnHand,0) from dbo.bINMT with (nolock) 
	where INCo = @INCo and Loc = @Loc and MatlGroup = @MatlGroup and Material = @Material

	-- stocked units, not including any from AP and PO
	select @UnitsInOut = isnull(sum(StkUnits),0)
	from dbo.bINDT with (nolock)
	where INCo = @INCo and Loc = @Loc and MatlGroup = @MatlGroup and Material = @Material
		and ActDate > @CountDate and Source not like 'AP%' and Source not like 'PO%'
	
	-- stocked units, from AP where not expensing PO's from receipt is turned off
	select @APUnitsInOut = isnull(sum(StkUnits),0)
	from dbo.bINDT i with (nolock)
	left join dbo.bPOIT p with (nolock) on i.APPOCo = p.POCo and i.PO = p.PO and i.POItem = p.POItem
	left join dbo.bPOCO o with (nolock) on i.APPOCo = o.POCo
	where i.INCo = @INCo and i.Loc = @Loc and i.MatlGroup = @MatlGroup and i.Material = @Material
		and i.ActDate > @CountDate and i.Source like 'AP%' and (i.PO is null or p.RecvYN = 'N')
		
	-- received units from PO
	select @POUnitsInOut = 
	isnull(sum(d.RecvdUnits * isnull(dbo.bfINUMConv(p.MatlGroup, p.Material, p.PostToCo, p.Loc, p.UM),0)),0)
	from dbo.bPORD d with (nolock)
	join dbo.bPOIT p with (nolock) on d.POCo = p.POCo and d.PO = p.PO and d.POItem = p.POItem
	where p.PostToCo = @INCo and p.Loc = @Loc and p.MatlGroup = @MatlGroup and p.Material = @Material
		and d.RecvdDate > @CountDate 			
end
else
begin
	-- current OnHand from IN Location Materials
	select @OnHand = isnull(OnHand,0) from dbo.bINMT with (nolock) 
	where INCo = @INCo and Loc = @Loc and MatlGroup = @MatlGroup and Material = @Material

	-- stocked units, not including any from AP and PO
	select @UnitsInOut = isnull(sum(StkUnits),0)
	from dbo.bINDT with (nolock)
	where INCo = @INCo and Loc = @Loc and MatlGroup = @MatlGroup and Material = @Material
		and ActDate >= @CountDate
		and Source not like 'AP%' and Source not like 'PO%'
	
	-- stocked units, from AP where not expensing PO's from receipt is turned off
	select @APUnitsInOut = isnull(sum(StkUnits),0)
	from dbo.bINDT i with (nolock)
	left join dbo.bPOIT p with (nolock) on i.APPOCo = p.POCo and i.PO = p.PO and i.POItem = p.POItem
	left join dbo.bPOCO o with (nolock) on i.APPOCo = o.POCo
	where i.INCo = @INCo and i.Loc = @Loc and i.MatlGroup = @MatlGroup and i.Material = @Material
		and i.ActDate >= @CountDate and i.Source like 'AP%' and (i.PO is null or p.RecvYN = 'N')
		
	-- received units from PO
	select @POUnitsInOut = 
	isnull(sum(d.RecvdUnits * isnull(dbo.bfINUMConv(p.MatlGroup, p.Material, p.PostToCo, p.Loc, p.UM),0)),0)
	from dbo.bPORD d with (nolock)
	join dbo.bPOIT p with (nolock) on d.POCo = p.POCo and d.PO = p.PO and d.POItem = p.POItem
	where p.PostToCo = @INCo and p.Loc = @Loc and p.MatlGroup = @MatlGroup and p.Material = @Material
		and d.RecvdDate >= @CountDate		
end


-- Calculate System Count
select @SystemCount = @OnHand - (@UnitsInOut + @APUnitsInOut + @POUnitsInOut)



vspexit:
	select @msg = isnull(@msg, '')
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspINMaterialCount] TO [public]
GO
