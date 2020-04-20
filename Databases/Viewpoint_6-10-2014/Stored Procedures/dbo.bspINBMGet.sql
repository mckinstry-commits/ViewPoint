SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspINBMGet]
    /***********************************************************************************
    * Created By: GR 11/12/99
    * Modified:	RM 05/17/02 - Changed datatype for units
    *
    * Pulls the Location Group's Bill of Material List of Components and inserts into
    * Bill of Materials Override table when adding a new entry
    *
    * Pass:
    *	INCo      Company
    *   Location  Location
    *   Material  Material
    *   MatlGroup MatlGroup
    *
    * Success returns:
    *	0
    *
    * Error returns:
    *	1 and error message
    ************************************************************************************/
    	(@inco bCompany = null, @location bLoc = null , @material bMatl = null, @matlgroup bGroup = null, @msg varchar(256) output)
    as
    	set nocount on
    	declare @rcode int, @validcnt int, @locgroup bGroup, @compmatl bMatl, @units numeric(14,5),
                @opencomplist int
    	select @rcode = 0
        select @opencomplist=0
    
    if @inco is null
        begin
        select @msg='Missing IN Company', @rcode=1
        goto bspexit
        end
    
    if @location is null
        begin
        select @msg='Missing Location', @rcode=1
        goto bspexit
        end
    
    if @material is null
        begin
        select @msg='Missing Material', @rcode=1
        goto bspexit
        end
    
    if @matlgroup is null
        begin
        select @msg='Missing Material Group', @rcode=1
        goto bspexit
        end
    
    --get Location Group for this location
    select @locgroup=LocGroup from bINLM where INCo=@inco and Loc=@location
    if @@rowcount=0
        begin
        select @msg='Invalid Location', @rcode=1
        goto bspexit
        end
    
    --get standard bill of material list of components
    declare complist_cursor cursor for
    select CompMatl, Units from bINBM
    where INCo=@inco and MatlGroup=@matlgroup and LocGroup=@locgroup and FinMatl=@material
    
    open complist_cursor
    select @opencomplist=1
    
    complist_cursor_loop:                 --loop through all the records
    
    fetch next from complist_cursor into @compmatl, @units
    if @@fetch_status=0
        begin
        if @compmatl=@material goto complist_cursor_loop    --finished good cannot be equal to component material
        select * from bINMT
        where INCo=@inco and Loc=@location and Material=@compmatl and MatlGroup=@matlgroup
        if @@rowcount > 0
            begin
            insert bINBO (INCo, Loc, FinMatl, MatlGroup, CompLoc, CompMatl, Units)
            values (@inco, @location, @material, @matlgroup, @location, @compmatl, @units)
            end
        goto complist_cursor_loop              --get the next record
        end
    
        --close and deallocate cursor
        if @opencomplist=1
            begin
            close complist_cursor
            deallocate complist_cursor
            select @opencomplist=0
            end
    
    bspexit:
        if @opencomplist=1
            begin
            close complist_cursor
            deallocate complist_cursor
            end
    
     --   if @rcode<>0 select @msg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINBMGet] TO [public]
GO
