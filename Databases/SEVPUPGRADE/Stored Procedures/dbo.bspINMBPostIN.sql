SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspINMBPostIN]
   /***********************************************************
    * Created: GG 03/22/02
    * Modified: GG 06/04/02 - #17548 - don't accum RemainUnits if Item flagged for delete 
    *  
    * Usage:
    * 	Called by bspINMBPost to update allocated units for each
    *	material referenced on a Material Order in the batch.
    *
    * Inputs:
    *  @co           	IN Co#
    *  @mth          	Month of batch
    *  @batchid      	Batch ID
    *  @seq			Batch Sequence
    *
    * Outputs:
    *  @errmsg     	error message
    *
    * Returns:
    *  @rcode			0 = success, 1 = error
    *   
    *****************************************************/
     	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
   	 @seq int = null, @errmsg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int, @loc bLoc, @matlgroup bGroup, @material bMatl, @um bUM, @units bUnits,
   	@stdum bUM, @umconv bUnitCost, @opencursor tinyint
   
   select @rcode = 0
   
   -- update Inventory Allocations
   declare bcMaterials cursor for
   select Loc, MatlGroup, Material, UM, sum(case BatchTransType when 'D' then 0 else RemainUnits end) -- 0.00 if deleting Item
   from bINIB
   where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
   group by Loc, MatlGroup, Material, UM
   union
   select OldLoc, OldMatlGroup, OldMaterial, OldUM, -(sum(OldRemainUnits))	-- reverse sign on old units
   from bINIB
   where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @seq and OldRemainUnits is not null
   group by OldLoc, OldMatlGroup, OldMaterial, OldUM
   
   open bcMaterials
   select @opencursor = 1
   
   update_loop:
   	fetch next from bcMaterials into @loc, @matlgroup, @material, @um, @units
   
   	if @@fetch_status <> 0 goto update_end
   
   	-- get Material Std U/M
   	select @stdum = StdUM from bHQMT where MatlGroup = @matlgroup and Material = @material
   	if @@rowcount = 0 
   		begin
   		select @errmsg = 'Material not setup in HQ!', @rcode = 1
   		goto bspexit
   		end
   
   	select @umconv = 1
   	if @um <> @stdum
   		begin
   		select @umconv = Conversion
   		from bINMU
   		where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Material = @material and UM = @um
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Material U/M not setup at IN Location!', @rcode = 1
   			goto bspexit
   			end
   		end
   
   	-- update IN Material Allocations
   	update bINMT set Alloc = Alloc + (@units * @umconv), AuditYN = 'N'	-- no audits with system updates
   	where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Unable to update IN Material allocated quantity!', @rcode = 1
   		goto bspexit
   		end
   
   	-- reset audit flag
   	update bINMT set AuditYN = 'Y'	
   	where INCo = @co and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Unable to reset IN Material audit flag!', @rcode = 1
   		goto bspexit
   		end
   
   	goto update_loop
   
   update_end:	-- finished with IN updates
   	close bcMaterials
   	deallocate bcMaterials
   	select @opencursor = 0
   
   bspexit:
   	if @opencursor = 1
   		begin
   		close bcMaterials
   		deallocate bcMaterials
   		end
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMBPostIN] TO [public]
GO
