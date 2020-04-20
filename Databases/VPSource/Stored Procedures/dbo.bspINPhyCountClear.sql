SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspINPhyCountClear]
   /************************************************************************
   * CREATED: 1/10/00 ae
   * MODIFIED: RM 12/10/01 Only delete those associated with this user.
   *	     	RM 04/04/03 Added Material Group and Category restrictions. 20557
   *    		DANF 03/15/05 - #27294 - Remove scrollable cursor.
   *	      	TRL 09/22/05 - # 29642 - Remove Active flag from record selection
   *			GG 10/03/05 - #29642 - rewritten to remove cursor, add comments
   
   * Used by the IN Physical Count Initialization program to clear
   * entries from the IN Physical Count Worksheet.
   *
   * Inputs:
   *	@inco			current IN Company #
   *	@InLocList		comma separated list of Locations (e.g. '10','14','100')
   *	@MatlGroup		material group used by the IN Company
   *	@OnlyReadyYN	Y = clear only the entries not ready, N = clear all
   *	@begcat			beginning material category - first if null
   *	@endcat			ending material category - last if null
   *	@begmatl		beginning material - first if null
   *	@endmatl		ending material - last if null
   *
   * Output:
   *	@msg			error message
   *
   * Return code:
   * returns 0 if successfull
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   (@inco bCompany = null, @InLocList varchar(250) = null, @MatlGroup bGroup,
   	@OnlyReadyYN bYN,@begcat varchar(10) = null, @endcat varchar(10) = null,
   	@begmatl bMatl = null,@endmatl bMatl = null, @msg varchar(255) = null output)
   as
  
  set nocount on
   
  declare @rcode int, @Location bLoc
  
  select @rcode = 0
  
  /* -- #29642 replaced cursor and delete logic
   declare INLM_Locations cursor local fast_forward for select Loc
   from INLM
   where INCo = @inco and charindex(char(39) + rtrim(Loc) + char(39), @InLocList) <> 0
   
   open INLM_Locations
   select @cursoropen = 1
   
   location_loop:
       fetch next from INLM_Locations into @Location
       if @@fetch_status <> 0 goto bspexit
   
       if @OnlyReadyYN =  'Y'
           begin
           	delete from INCW where INCo= @inco and UserName = suser_sname() and Loc = @Location and MatlGroup = @MatlGroup  and Ready = 'N'
   		and Material in (select Material from bHQMT where Active = 'Y' and Stocked = 'Y'  and MatlGroup=@MatlGroup and 
   				Category >= isnull(@begcat, Category) and Category <= isnull(@endcat, Category)
   				and Material >= isnull(@begmatl, Material) and Material <= isnull(@endmatl, Material)
   				and Material in (select Material from bINMT where INCo = @inco and Loc = @Location and MatlGroup=@MatlGroup and Active = 'Y'))
           end
        else
           begin
           	delete from INCW where INCo = @inco and UserName = suser_sname() and Loc = @Location and MatlGroup = @MatlGroup
   		and Material in (select Material from bHQMT where Active = 'Y'  Stocked = 'Y'  and MatlGroup=@MatlGroup and 
   				Category >= isnull(@begcat, Category) and Category <= isnull(@endcat, Category)
   				and Material >= isnull(@begmatl, Material) and Material <= isnull(@endmatl, Material)
   				and Material in (select Material from bINMT where INCo = @inco and Loc = @Location and MatlGroup=@MatlGroup and Active = 'Y'))
           end
   
   goto location_loop
  *******************************/
  
  -- remove entries from IN Physical Count Worksheet based on IN Co#, User, list of Locations,
  -- range of Materials, range of Categories, and Ready flag
  delete dbo.bINCW
  from dbo.bINCW c
  join dbo.bHQMT m on m.MatlGroup = c.MatlGroup and m.Material = c.Material
  where c.INCo=@inco and c.UserName = suser_sname()
  	/*and charindex(char(39) + rtrim(c.Loc) + char(39), @InLocList) > 0*/
	and c.Loc = @InLocList
  	and c.MatlGroup = @MatlGroup
  	and c.Material >= isnull(@begmatl, c.Material) and c.Material <= isnull(@endmatl, c.Material)
  	and m.Category >= isnull(@begcat, m.Category) and m.Category <= isnull(@endcat, m.Category)
  	and ((@OnlyReadyYN = 'Y' and c.Ready = 'N') or @OnlyReadyYN = 'N') 
   
  bspexit:
   	/*if @cursoropen = 1
          begin
          close INLM_Locations
   		deallocate INLM_Locations
          end*/
  
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINPhyCountClear] TO [public]
GO
