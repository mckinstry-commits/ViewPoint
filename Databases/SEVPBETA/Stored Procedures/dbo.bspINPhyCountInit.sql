SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************/
CREATE       procedure [dbo].[bspINPhyCountInit]
/************************************************************************
* CREATED: 1/5/00 ae
* MODIFIED: GR 03/07/00  added to initialize the unitcost and ecm based on
*							material from bINMT
*            ae 04/28/00 clear out cost method after each loop
*            GR 06/20/00 Added the category range and material range to
*							initialize  - as per issue 6921
*			RM 12/10/01 Add user to all initialized materials.
*			SR 12/13/01 - put parenthesis around the SysCount formula (UnitsIn + UnitsOut)
*			GG 01/11/05 - #25684 rewritten for cost method corrections
* 			DANF 10/14/05 - Issue 26788 Adjust System count for units received on or after system count date.
*			TRL 10/23/06 - Conversion Issue made changes for procedure to accept a null value for Cnt Date.
*			GP 07/15/08 - Issue 127257 Initialize by Physical Location.
*			GP 08/01/08 - Issue 121878 Current day material count adjustments show up on worksheet.
*			GP 09/02/08 - Issue 129634 Add message for materials that already exist on worksheet.
*			GP 04/13/09 - Issue 132897 Fixed to include count date on AP and PO units.
*			GP 1/26/2010 - Issue 135247 Removed old calculation and replaced with call to vspINMaterialCount
*			GF 01/02/2013 TK-20452 fix problem with location material exists in INCW bogus message
*
*
* Used by the IN Physical Count Initialization program to initialize
* entries into the IN Physical Count Worksheet.
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@inco bCompany = null, @InLocList varchar(250) = null, @MatlGroup bGroup, @CntDate bDate,
    @SysCntYN bYN, @begcat varchar(10) = null, @endcat varchar(10) = null, @begmatl bMatl = null,
    @endmatl bMatl = null, @PhyLoc varchar(30) = null, @InclCntDate bYN = null, 
	@msg varchar(255) = null output)
as
set nocount on

begin

declare @rcode int, @Location bLoc, @UM bUM, @cursoropen tinyint, @Material bMatl,
		@OnHand bUnits, @UnitsInOut bUnits, @SysCount bUnits, @category varchar(10), @costmethod tinyint,
		@unitcost bUnitCost, @ecm bECM, @PORecUnitsInOut bUnits, @APUnitsInOut bUnits

declare @avgcost bUnitCost, @avgecm bECM, @lastcost bUnitCost, @lastecm bECM, @stdcost bUnitCost,
		@stdecm bECM, @cocostmethod tinyint, @lmcostmethod tinyint, @locostmethod tinyint

   
   --initialize return code and open cursor flag 
   select @rcode = 0, @cursoropen = 0
   
	IF isnull(@PhyLoc, '') = '' SET @PhyLoc = null

   -- get IN Company default costing method
   select @cocostmethod = CostMethod
   from dbo.bINCO (nolock)
   where INCo = @inco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid IN Company #!', @rcode = 1
   	goto bspexit
   	end
   
   -- validate cost method 1=average,2=last,3=standard
   if @cocostmethod not in (1,2,3)
   	begin
   	select @msg = 'Invalid IN Company costing method, must be 1, 2, or 3!', @rcode = 1
   	goto bspexit
   	end
   
   -- use a cursor to process materials
   declare INMT_insert cursor for
   select m.Loc, m.Material, h.StdUM, m.AvgCost, m.AvgECM, m.LastCost, m.LastECM, m.StdCost, m.StdECM,
   	h.Category, isnull(l.CostMethod,0), isnull(o.CostMethod,0), m.OnHand
   from dbo.bINMT m (nolock)
   join dbo.bHQMT h (nolock) on h.MatlGroup = m.MatlGroup and h.Material = m.Material
   join dbo.bINLM l (nolock) on l.INCo = m.INCo and l.Loc = m.Loc
   left join dbo.bINLO o (nolock) on o.INCo = m.INCo and o.Loc = m.Loc and o.MatlGroup = m.MatlGroup
   	and o.Category = h.Category
   where l.INCo = @inco and l.Loc=@InLocList 
	and (@PhyLoc is null or isnull(@PhyLoc, m.PhyLoc) = m.PhyLoc)
 	and h.Category >= isnull(@begcat, h.Category) and h.Category <= isnull(@endcat, h.Category)
   	and m.Material >= isnull(@begmatl, m.Material) and m.Material <= isnull(@endmatl, m.Material)
   	and h.MatlGroup = @MatlGroup and m.Active = 'Y'
   order by m.Loc, m.Material
   
   -- open cursor and set flag
   open INMT_insert
   select @cursoropen = 1
   
   process_loop:
       fetch next from INMT_insert into @Location, @Material, @UM, @avgcost, @avgecm, @lastcost, @lastecm, @stdcost, @stdecm,
   		@category, @lmcostmethod, @locostmethod, @OnHand
       if @@fetch_status <> 0 goto process_end
   
   		-- skip material already on the Worksheet
		if exists(select top 1 1 from dbo.bINCW with (nolock) where INCo = @inco
					----TK-20452 added user name
					AND UserName = suser_sname()
					AND Loc = @Location 
					AND MatlGroup = @MatlGroup 
					AND Material = @Material) 
			BEGIN
			----TK-20452          
			----SELECT @msg = 'Some of the materials initialized may already exist on another users  count worksheet!', @rcode = 2
			GOTO process_loop
			END       

   	-- assign cost method, overrides in bINLO and bINLM
       select @costmethod = @locostmethod
   	if @costmethod = 0 select @costmethod = @lmcostmethod
   	if @costmethod = 0 select @costmethod = @cocostmethod	-- no overrides, use INCO option
   
   	if @costmethod not in (1,2,3)
   		begin
   		select @msg = 'Invalid Costing Method for Location: ' + @Location + ' Material: ' + @Material + '.  Must be 1, 2, or 3!', @rcode = 1
   		goto bspexit
   		end
   
   	-- assign unit cost
       select @unitcost = case @costmethod when 1 then @avgcost when 2 then @lastcost else @stdcost end,
              @ecm = case @costmethod when 1 then @avgecm when 2 then @lastecm else @stdecm end
      
   
    -- reset system count
   	select @SysCount = null
   	
   	--Get System Count
	exec vspINMaterialCount @inco, @Location, @MatlGroup, @Material, @InclCntDate, @CntDate, @SysCount output 

   	-- add entry to Worksheet
	insert dbo.bINCW (INCo, UserName, Loc, MatlGroup, Material, UM, CntDate, UnitCost, ECM, Ready,SysCnt)
	values (@inco, suser_sname(), @Location, @MatlGroup, @Material, @UM, case when @CntDate = '1/1/1950' then null else @CntDate end , @unitcost, @ecm, 'N', @SysCount)
   
   	goto process_loop
   
   process_end:
   	close INMT_insert
   	deallocate INMT_insert
   	set @cursoropen = 0
   
   
   bspexit:
   	if @cursoropen = 1
   		begin
          	close INMT_insert
   		deallocate INMT_insert
          	end
   
   --	if @rcode <> 0 select @msg = isnull(@msg,'') + ' [bspINPhyCountInit]'
   	return @rcode
      
   
   END

GO
GRANT EXECUTE ON  [dbo].[bspINPhyCountInit] TO [public]
GO
