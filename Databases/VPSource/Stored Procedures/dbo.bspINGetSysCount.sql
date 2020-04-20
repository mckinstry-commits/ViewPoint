SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINGetSysCount    Script Date: 8/28/99 9:34:43 AM ******/
   CREATE procedure [dbo].[bspINGetSysCount]
   /************************************************************************
   * CREATED: 1/7/00 ae
   * MODIFIED: 10/10/01 RM - Changed to look at ActDate from bINDT and not PostedDate.
   *					    - Changed Cursor from Scroll Cursor to Forward_Only cursor
   *		12/13/01 SR -put parenthesis around @SysCount = OnHand - (UnitsIn + UnitsOut)
   *
   *       04/28/06 TRL --Removed @CntDate from parameter list and replaced with @username for VP6 conversion
   *								@CntDate was being used and is during the cursor. 
   *		GP 1/26/2010 - Issue 135247 Removed old calculation and replaced with call to vspINMaterialCount
   *		GF 10/26/2010 - issue #141031 change to use vfDateOnly Function
   *
   * Used by the IN Physical Count Initialization program and Physical Count Worksheet
   * get a system count for a a given count date.
   *
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
  -- (@inco bCompany = null, @Loc bLoc, @MatlGroup bGroup, @CntDate bDate, @msg varchar(255) = null output)
 (@inco bCompany = null, @Loc bLoc, @MatlGroup int, @username varchar(128), @msg varchar(255) = null output)
   as
   set nocount on
   
   begin
   
   
   declare @rcode int, @cursoropen tinyint, @Material bMatl, @OnHand bUnits, @UnitsIn bUnits,
   		@UnitsOut bUnits, @SysCount bUnits,@unitstotal bUnits, @CntDate smalldatetime
   
   -- initialize return code and open cursor flag
   select @rcode = 0, @cursoropen = 0
   
   --update INCW set AdjUnits = null, Ready = 'N' where INCo = @inco and Loc = @Loc and AdjUnits = 0
   
   --declare INCW_Material scroll cursor for select Material
   declare INCW_Material cursor FAST_FORWARD
   for select Material
   from INCW with (nolock)
   where INCo = @inco and Loc = @Loc and MatlGroup = @MatlGroup
   
   open INCW_Material
   select @cursoropen = 1
   
   material_loop:
   
   fetch next from INCW_Material into @Material
   if @@fetch_status <> 0 goto bspexit
   
   ----#141031
   select @CntDate = isnull(CntDate, dbo.vfDateOnly()) from INCW with (nolock) 
   where INCo = @inco and Loc = @Loc and MatlGroup = @MatlGroup and Material = @Material and UserName = @username   
   
   set @SysCount = null
   
   	--Get System Count
	exec vspINMaterialCount @inco, @Loc, @MatlGroup, @Material, 'Y', @CntDate, @SysCount output 
   
   update INCW set SysCnt = @SysCount 
   where INCo = @inco and Loc = @Loc and MatlGroup = @MatlGroup and Material = @Material and UserName = @username
   
   goto material_loop
   
   
   
   bspexit:
   	if @cursoropen = 1
   		begin
   		close INCW_Material
   		deallocate INCW_Material
   		set @cursoropen = 0
   		end
        return @rcode
   
   END

GO
GRANT EXECUTE ON  [dbo].[bspINGetSysCount] TO [public]
GO
