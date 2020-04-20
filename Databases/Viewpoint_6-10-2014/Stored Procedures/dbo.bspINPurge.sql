SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*******************************************/
CREATE procedure [dbo].[bspINPurge]
/*****************************************************************************
* Created By:	GR 10/19/00
* Modified By: DANF 10/27/00
*				TerryL 09/20/07 Issue 28161
*				CHS 01/09/2008 Issue # 122462 concat error messages for invalid materials
*				GF 01/16/2008 - issue #122462 changed how materials are deleted for a location.
*					do not throw error when material in use, just track ones that cannot be deleted
*					and delete ones that can be deleted.
*				GP 08/20/2009 - issue #135093 added check in INMI for existing records before delete
*
*
* Used to delete inactive Locations and/or materials.
* 1. Delete a single material for a location. no cursor will be used.
* 2. When deleting all materials for a location, then a cursor will be used. In addition,
*    if a material is still in use in another table, then that material will be
*    skipped and SP will move to the next location material and try to delete.
*
* Pass:
*	INCo, Location, Material, Material Group,
*   Purge Option 0 - Delete Location and all of its Materials
*                1 - Delete all Materials, but leave Location on file
*                2 - Delete a select Material from Location
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
*******************************************************************************/
(@inco bCompany = null, @loc bLoc = null, @matl bMatl = null,
 @matlgroup bGroup = null, @purgeopt int = null, @msg varchar(1000) output)
as
set nocount on

declare @rcode int, @openlocmatl int, @openlocmatldel int, @material bMatl, @onhand bUnits,
		@onorder bUnits, @alloc bUnits, @recvdninvcd bUnits, @locgroup bGroup, @glco bCompany,
		@lastmthsubclsd bMonth, @stkunits bUnits, @mth bMonth, @batchid int, @batchseq int,
		@error_count int, @valid_count int, @MO varchar(10) --GP

select @rcode = 0, @openlocmatl = 0, @openlocmatldel = 0, @error_count = 0, @valid_count = 0

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

if @purgeopt is null
	begin
	select @msg='Missing Purge Option', @rcode=1
	goto bspexit
	end

If @purgeopt = 0
	Begin
	---- Check for Location in IN Location Master
	if not exists(select 1 from dbo.INLM with(nolock) where INCo=@inco and Loc=@loc)
		begin
		select @msg='Location ' + @loc + ' does not exist in IN Location Master!', @rcode=1
		goto bspexit
		end

	---- Check Location for Materials
	if not exists(select 1 from dbo.INMT with(nolock) where INCo=@inco and Loc=@loc)
		begin
		select @msg='Inventory Location ' + @loc + ' has no Materials!' + char(13)+char(10) + 'Please delete Locaiton from IN Location Master.', @rcode=1
		goto bspexit
		end
	End

If @purgeopt = 1
	Begin
	---- check for Materials in INMT for Locaton
	if not exists(select 1 from dbo.INMT with(nolock) where INCo=@inco and Loc=@loc)
		begin
		select @msg='Inventory Location ' + @loc + ' has no Materials!', @rcode=1
		goto bspexit
		end
	End

If @purgeopt = 2
	Begin
	---- check Material exists in Location
	if not exists(select 1 from dbo.INMT with(nolock) where INCo=@inco and Loc=@loc and Material = @matl)
		begin
		select @msg='Material ' + @matl + ' doesnot exist for IN Location ' + @loc, @rcode=1
		goto bspexit
		end
	End

---- Get Gl Company from IN Company
select @glco=GLCo from dbo.INCO with(nolock) where INCo=@inco

---- Get Sub Last Month Closed from GL Company
select @lastmthsubclsd=LastMthSubClsd from dbo.GLCO with(nolock) where GLCo=@glco

---- Get Location group for the location
select @locgroup=LocGroup from dbo.INLM with(nolock) where INCo=@inco and Loc=@loc

---- if purging materials for a location then create cursor
if isnull(@matl,'') <> ''
	begin
	select @material = Material
	from dbo.INMT where INCo=@inco and MatlGroup=@matlgroup and Loc=@loc and Material=@matl
	end
else
	begin
	declare LocMatl_cursor cursor LOCAL FAST_FORWARD for select Material
	from dbo.INMT where INCo=@inco and MatlGroup=@matlgroup and Loc=@loc

	open LocMatl_cursor
	select @openlocmatl = 1
	end


LocMatl_cursor_loop:
---- fetch next from cursor if purging for a location
if @openlocmatl = 1
	begin
	fetch next from LocMatl_cursor into @material

	if @@fetch_status <> 0 goto LocMatl_cursor_end
	end


---- create first part error msg with material when only deleting a selected material
---- if deleting all materials for a location, then we will only track the number
---- of materials that cannot be deleted.
if @openlocmatl = 1
	begin
	select @msg = ''
	end
else
	begin
	select @msg = 'Material: ' + isnull(cast(@material as varchar(10)),'') + char(13) + char(10)
	end

---- check in IN Materials
select @onhand=OnHand, @onorder=OnOrder, @alloc=Alloc, @recvdninvcd=RecvdNInvcd
from dbo.INMT with (nolock)
where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material

if @onhand <> 0 or @onorder <> 0 or @alloc <> 0 or @recvdninvcd <> 0
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Current OnHand/OnOrder/Allocated/RecvdNInvcd quantities in IN Materials must be zero for Material.' + char(13) + char(10)
		select @rcode = 1
		end
	end

---- check in Bill of Materials and Bill of Materials Override
if exists(select top 1 1 from dbo.INBH with(nolock) where INCo=@inco and LocGroup=@locgroup and MatlGroup=@matlgroup and FinMatl=@material)
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Is a Finished Material in Bill of Materials Header.'  + char(13) + char(10)
		select @rcode = 1
		end
	end

if exists(select top 1 1 from dbo.INBM with(nolock) where INCo=@inco and LocGroup=@locgroup and MatlGroup=@matlgroup and CompMatl=@material)
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Is a Component Material in Bill of Materials Detail.' + char(13) + char(10)
		select @rcode = 1
		end
	end

if exists(select top 1 1 from dbo.INBL where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and FinMatl=@material)
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Is a Finished Material in Bill Of Materials Override Header.' + char(13) + char(10)
		select @rcode = 1
		end
	end

if exists(select top 1 1 from dbo.INBO with(nolock) where INCo=@inco and CompLoc=@loc and MatlGroup=@matlgroup and CompMatl=@material)
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Is a Component Material in Bill of Materials Override Detail.' + char(13) + char(10)
		select @rcode = 1
		end
	end

if exists(select top 1 1 from dbo.INCW with(nolock) Where  INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material)
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Is assigned to Physical Count Worksheet.'  + char(13) + char(10)
		select @rcode = 1
		end
	end

--Issue 135093
if exists(select top 1 1 from dbo.INMI with (nolock) where INCo=@inco and Loc=@loc and Material=@material)
	begin
		select top 1 @MO = MO from dbo.INMI with (nolock) where INCo=@inco and Loc=@loc and Material=@material
		select @msg = @msg + 'IN Material Order Item records exist on MO: ' + @MO + char(13) + char(10)
		select @rcode = 1
	end

---- check in an Open Month
select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
from dbo.INAB with(nolock) where Co=@inco and Loc=@loc and MatlGroup=@matlgroup
and Material=@material and Mth>=@lastmthsubclsd
if @@rowcount > 0
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Exists in an Adjustment batch for Month: ' +
				convert(varchar(6),@mth,1) + substring(convert(varchar(8),@mth,1),7,2) + 
				' and BatchId: ' + convert(varchar(8), @batchid) + ' and BatchSeq: ' + convert(varchar(8), @batchseq) + char(13) + char(10)
		select @rcode = 1
		end
	end

select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
from dbo.INTB with(nolock) where Co=@inco and MatlGroup=@matlgroup 
and Material=@material and FromLoc=@loc and Mth>=@lastmthsubclsd
if @@rowcount > 0
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Exists in Transfer batch for Month: ' +
				convert(varchar(6),@mth,1) + substring(convert(varchar(8),@mth,1),7,2) + 
				' and BatchId: ' + convert(varchar(8), @batchid) + ' and BatchSeq: ' + convert(varchar(8), @batchseq) + char(13) + char(10)
		select @rcode = 1
		end
	end

select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
from dbo.INTB with(nolock) where Co=@inco and MatlGroup=@matlgroup and Material=@material
and ToLoc=@loc and Mth>=@lastmthsubclsd
if @@rowcount > 0
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Exists in Transfer batch for Month: ' +
				convert(varchar(6),@mth,1) + substring(convert(varchar(8),@mth,1),7,2) +
				' and BatchId: ' + convert(varchar(8), @batchid) + ' and BatchSeq: ' + convert(varchar(8), @batchseq) + char(13) + char(10)
		select @rcode = 1
		end
	end

select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
from dbo.INPB with(nolock) where Co=@inco and MatlGroup=@matlgroup
and FinMatl=@material and ProdLoc=@loc and Mth>=@lastmthsubclsd
if @@rowcount > 0
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Exists in Production Batch as a finished material for Month: ' +
				convert(varchar(6),@mth,1) + substring(convert(varchar(8),@mth,1),7,2) +
				' and BatchId: ' + convert(varchar(8), @batchid) + ' and BatchSeq: ' + convert(varchar(8), @batchseq) + char(13) + char(10)
		select @rcode = 1
		end
	end

select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
from dbo.INPD with(nolock) where Co=@inco and MatlGroup=@matlgroup 
and CompMatl=@material and CompLoc=@loc and Mth>=@lastmthsubclsd
if @@rowcount > 0
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Exists in Product Batch as a component material for Month: ' +
				convert(varchar(6),@mth,1) + substring(convert(varchar(8),@mth,1),7,2) +
				' and BatchId: ' + convert(varchar(8), @batchid) + ' and BatchSeq: ' + convert(varchar(8), @batchseq) + char(13) + char(10)
		select @rcode = 1
		end
	end

if exists(select StkUnits from dbo.INDT with(nolock) where INCo=@inco and Loc=@loc
				and MatlGroup=@matlgroup and Material=@material and Mth>@lastmthsubclsd)
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'IN Detail entries exists after closed subledger month.' + char(13) + char(10)
		select @rcode = 1
		end
	end

select @stkunits = isnull(SUM(StkUnits),0)
from dbo.INDT with(nolock) where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material
if @stkunits <> 0
	begin
	if @openlocmatl = 1
		begin
		select @error_count = @error_count + 1
		goto LocMatl_cursor_loop
		end
	else
		begin
		select @msg = @msg + 'Sum of units does not balance in IN Detail.'  + char(13) + char(10)
		select @rcode = 1
		end
	end

---- if only deleting selected material and @rcode = 1 then we have an error, exit SP
if @openlocmatl = 0 and @rcode = 1 goto bspexit


---- at this point we can purge the material for location using the purge option flag
---- can get tricky here because we do not want to delete the location @purgeopt = 0
---- unless we have finished deleting all materials for the location without any errors

---- delete from INDT, INMA, and INMT this applies for all purge options
update dbo.INDT set PurgeYN = 'Y' where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
---- delete from IN Detail
delete from dbo.INDT where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material 
---- delete from Monthly Detail
delete from dbo.INMA where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material 
---- delete materials
delete from dbo.INMT where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material 

---- material successfully purged increment count
select @valid_count = @valid_count + 1

---- if deleting materials for a location go to fetch next loop, otherwise we are done
if @openlocmatl = 1
	begin
	goto LocMatl_cursor_loop
	end
else
	begin
	goto bspexit
	end


LocMatl_cursor_end:
	if @openlocmatl = 1
		begin
		close LocMatl_cursor
		deallocate LocMatl_cursor
		select @openlocmatl = 0
		end

---- now if all the materials have been deleted for the location and the
---- purge option = '0' then delete the location from the IN location tables
if @purgeopt = 0 and @error_count = 0
	begin
	---- Issue 28161
	---- Location Company Category Override
	delete from dbo.INLC where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup 	
	---- Location Category Override              
	delete from dbo.INLO where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup      	
	---- Location Company Override
	delete from dbo.INLS where INCo=@inco and Loc=@loc  
	---- Location Master
	delete from dbo.INLM where INCo=@inco and Loc=@loc               
	end

---- create return message
select @msg = 'Location materials that could not be purged: ' + convert(varchar(8), @error_count) + char(13) + char(10)
select @msg = @msg + 'Location Materials successfully purged: ' + convert(varchar(8),@valid_count) + char(13) + char(10)

if @error_count <> 0 select @rcode = 1

goto bspexit  


----if @@fetch_status = 0
----	begin
----	---- create first part error msg with material
----	select @msg = 'Material: ' + isnull(cast(@material as varchar(10)),'') + char(13) + char(10)
----
----	---- check in IN Materials
----	select @onhand=OnHand, @onorder=OnOrder, @alloc=Alloc, @recvdninvcd=RecvdNInvcd
----	from dbo.INMT with (nolock)
----	where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material
----
----	if @onhand <> 0 or @onorder <> 0 or @alloc <> 0 or @recvdninvcd <> 0
----		begin
----		select @msg = @msg + 'Current OnHand/OnOrder/Allocated/RecvdNInvcd quantities in IN Materials must be zero for Material.' + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	---- check in Bill of Materials and Bill of Materials Override
----	if exists(select top 1 1 from dbo.INBH with(nolock) where INCo=@inco and LocGroup=@locgroup and MatlGroup=@matlgroup and FinMatl=@material)
----		begin
----		select @msg = @msg + 'Is a Finished Material in Bill of Materials Header.'  + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	if exists(select top 1 1 from dbo.INBM with(nolock) where INCo=@inco and LocGroup=@locgroup and MatlGroup=@matlgroup and CompMatl=@material)
----		begin
----		select @msg = @msg + 'Is a Component Material in Bill of Materials Detail.' + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	if exists(select top 1 1 from dbo.INBL where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and FinMatl=@material)
----		begin
----		select @msg = @msg + 'Is a Finished Material in Bill Of Materials Override Header.' + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	if exists(select top 1 1 from dbo.INBO with(nolock) where INCo=@inco and CompLoc=@loc and MatlGroup=@matlgroup and CompMatl=@material)
----		begin
----		select @msg = @msg + 'Is a Component Material in Bill of Materials Override Detail.' + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	if exists(select top 1 1 from dbo.INCW with(nolock) Where  INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material)
----		begin
----		select @msg = @msg + 'Is assigned to Physical Count Worksheet.'  + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	---- check in an Open Month
----	select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
----	from dbo.INAB with(nolock) where Co=@inco and Loc=@loc and MatlGroup=@matlgroup
----	and Material=@material and Mth>=@lastmthsubclsd
----	if @@rowcount > 0
----		begin
----		select @msg = @msg + 'Exists in an Adjustment batch for Month: ' +
----				convert(varchar(6),@mth,1) + substring(convert(varchar(8),@mth,1),7,2) + 
----				' and BatchId: ' + convert(varchar(8), @batchid) + ' and BatchSeq: ' + convert(varchar(8), @batchseq) + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
----	from dbo.INTB with(nolock) where Co=@inco and MatlGroup=@matlgroup 
----	and Material=@material and FromLoc=@loc and Mth>=@lastmthsubclsd
----	if @@rowcount > 0
----		begin
----		select @msg = @msg + 'Exists in Transfer batch for Month: ' +
----				convert(varchar(6),@mth,1) + substring(convert(varchar(8),@mth,1),7,2) + 
----				' and BatchId: ' + convert(varchar(8), @batchid) + ' and BatchSeq: ' + convert(varchar(8), @batchseq) + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
----	from dbo.INTB with(nolock) where Co=@inco and MatlGroup=@matlgroup and Material=@material
----	and ToLoc=@loc and Mth>=@lastmthsubclsd
----	if @@rowcount > 0
----		begin
----		select @msg = @msg + 'Exists in Transfer batch for Month: ' +
----				convert(varchar(6),@mth,1) + substring(convert(varchar(8),@mth,1),7,2) +
----				' and BatchId: ' + convert(varchar(8), @batchid) + ' and BatchSeq: ' + convert(varchar(8), @batchseq) + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
----	from dbo.INPB with(nolock) where Co=@inco and MatlGroup=@matlgroup
----	and FinMatl=@material and ProdLoc=@loc and Mth>=@lastmthsubclsd
----	if @@rowcount > 0
----		begin
----		select @msg = @msg + 'Exists in Production Batch as a finished material for Month: ' +
----				convert(varchar(6),@mth,1) + substring(convert(varchar(8),@mth,1),7,2) +
----				' and BatchId: ' + convert(varchar(8), @batchid) + ' and BatchSeq: ' + convert(varchar(8), @batchseq) + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	select @mth=Mth, @batchid=BatchId, @batchseq=BatchSeq
----	from dbo.INPD with(nolock) where Co=@inco and MatlGroup=@matlgroup 
----	and CompMatl=@material and CompLoc=@loc and Mth>=@lastmthsubclsd
----	if @@rowcount > 0
----		begin
----		select @msg = @msg + 'Exists in Product Batch as a component material for Month: ' +
----				convert(varchar(6),@mth,1) + substring(convert(varchar(8),@mth,1),7,2) +
----				' and BatchId: ' + convert(varchar(8), @batchid) + ' and BatchSeq: ' + convert(varchar(8), @batchseq) + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	if exists(select StkUnits from dbo.INDT with(nolock) where INCo=@inco and Loc=@loc
----					and MatlGroup=@matlgroup and Material=@material and Mth>@lastmthsubclsd)
----		begin
----		select @msg = @msg + 'IN Detail entries exists after closed subledger month.' + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	select @stkunits = isnull(SUM(StkUnits),0)
----	from dbo.INDT with(nolock) where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material
----	if @stkunits <> 0
----		begin
----		select @msg = @msg + 'Sum of units does not balance in IN Detail.'  + char(13) + char(10)
----		select @rcode = 1
----		end
----
----	---- if material exists in one of the previous checks then we are done. Exit procedure
----	if @rcode = 1 
----		begin
----		select @msg = @msg + 'Cannot Purge.'
----		goto bspexit
----		end
----
----	goto LocMatl_cursor_loop
----	end
----
----
-------- close and deallocate cursor
----if @openlocmatl = 1
----	begin
----	close LocMatl_cursor
----	deallocate LocMatl_cursor
----	select @openlocmatl = 0
----	end




-------- Now delete the records from the tables
----	if @matl is null
----	begin
----	declare LocMatlDel_cursor cursor LOCAL FAST_FORWARD for select Material
----	from dbo.INMT where INCo=@inco and MatlGroup=@matlgroup and Loc=@loc
----	end
----else
----	begin
----	declare LocMatlDel_cursor cursor LOCAL FAST_FORWARD for select Material
----	from dbo.INMT where INCo=@inco and MatlGroup=@matlgroup and Loc=@loc and Material=@matl
----	end
----
----open LocMatlDel_cursor
----select @openlocmatldel=1
----
----LocMatlDel_cursor_loop:
----
----fetch next from LocMatlDel_cursor into @material
----
----if @@fetch_status=0
----	begin
----	--delete location from file too
----	if @purgeopt = 0      
----		begin
----		update dbo.INDT set PurgeYN = 'Y' where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup
----		-- delete from IN Detail
----		delete from dbo.INDT where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup 
----		--28161
----		-- delete from Monthly Detail
----		delete from dbo.INMA where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup 
----		--Issue 28161
----		--delete materials
----		delete from dbo.INMT where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup 
----		--Issue 28161
----		--Location Company Category Override
----		delete from dbo.INLC where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup 	
----		--Location Category Override              
----		delete from dbo.INLO where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup      	
----		--Location Company Override
----		delete from dbo.INLS where INCo=@inco and Loc=@loc  
----		-- Location Master
----		delete from dbo.INLM where INCo=@inco and Loc=@loc               
----		end
----
----	if @purgeopt = 1
----		begin
----		update dbo.INDT set PurgeYN = 'Y' where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup
----		-- delete from IN Detail
----		delete from dbo.INDT where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup 
----		--28161
----		-- delete from Monthly Detail
----		delete from dbo.INMA where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup 
----		--delete materials
----		delete from dbo.INMT where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup 
----		end
----
----	if @purgeopt = 2
----		begin
----		update dbo.INDT set PurgeYN = 'Y' where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
----		-- delete from IN Detail
----		delete from dbo.INDT where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material 
----		--28161
----		-- delete from Monthly Detail
----		delete from dbo.INMA where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material 
----		--delete materials
----		delete from dbo.INMT where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material 
----		end
----
----	---- get the next record
----	goto LocMatlDel_cursor_loop                   
----	end
----
-------- close and deallocate cursor
----if @openlocmatldel=1
----	begin
----	close LocMatlDel_cursor
----	deallocate LocMatlDel_cursor
----	select @openlocmatldel=0
----	end




bspexit:
	---- close and deallocate cursor
	if @openlocmatl = 1
		begin
		close LocMatl_cursor
		deallocate LocMatl_cursor
		end

--	---- close and deallocate cursor
--	if @openlocmatldel=1
--		begin
--		close LocMatlDel_cursor
--		deallocate LocMatlDel_cursor
--		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINPurge] TO [public]
GO
