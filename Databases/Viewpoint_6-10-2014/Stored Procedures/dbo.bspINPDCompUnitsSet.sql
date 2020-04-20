SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[bspINPDCompUnitsSet]
   /*******************************************************************************************
    * CREATED:  GR 12/07/99
    * Modified: RM 05/20/02 - changed all bUnits to numeric(14,5)
    *			 GG 10/16/02 - #16039 - changed output param for neg units, fixed logic to calculate
    *									component units
    *
    * USAGE:
    * This routine is used to update component material units on update
    * of production material units
    *
    * INPUT PARAMETERS
    * @inco            IN Company
    * @mth             Batch Month
    * @batchid         Batch Id
    * @batchseq        Batch Seq
    * @matlgroup       Material Group
    * @produnits       Production Units
    * @prevprodunits   Production Units before change
    *
    * OUTPUT:
    * @negunits		# of components with negative on-hand qty
    *
    * Return 0 success
    *        1 error
    *
    ********************************************************************************************/
       (@inco bCompany = null, @mth bMonth = null, @batchid int = null , @batchseq int = null,
       @matlgroup bGroup = null, @produnits numeric(14,5) = 0, @prevprodunits numeric(14,5) = 0,
       @negunits int output, @msg varchar(255) output )
   as
   
   set nocount on
   
   declare @rcode int, @comploc bLoc, @compmatl bMatl, @units numeric(14,5), @openinpd int, @onhand bUnits
   
   select @rcode = 0, @openinpd = 0, @negunits = 0
   
   if @inco is null
       begin
       select @msg='Missing IN Company', @rcode=1
       goto bspexit
       end
   if @mth is null
       begin
       select @msg='Missing Batch Month', @rcode=1
       goto bspexit
       end
   if @batchid is null
       begin
       select @msg='Missing Batch Id', @rcode=1
       goto bspexit
       end
   if @batchseq is null
       begin
       select @msg='Missing Batch Seq', @rcode=1
       goto bspexit
       end
   if @matlgroup is null
       begin
       select @msg='Missing Material Group', @rcode=1
       goto bspexit
       end
   
   -- create a cursor to process each Production Detail entry for the Batch Seq
   declare INPD_cursor cursor for
   select CompLoc, CompMatl, Units
   from bINPD
   where  Co = @inco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   
   open INPD_cursor
   select @openinpd=1
   
   INPD_cursor_loop:                  --loop through all the records
       fetch next from INPD_cursor into @comploc, @compmatl, @units
       if @@fetch_status <> 0 goto INPD_cursor_end
   
   	if @produnits = 0 select @units = 0		-- assume 0.00 component qty if nothing produced
   
   	-- new component qty based on proportion of current component qty to previous production qty
   	if @produnits <> 0 and @prevprodunits <> 0 select @units = (@produnits / @prevprodunits) * @units
   	
       update bINPD
   	set Units = @units
       where  Co = @inco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
       	and CompMatl=@compmatl and CompLoc=@comploc
   	if @@rowcount = 0
   		begin
   		select @msg = 'Error adjusting component units in bINPD.', @rcode = 1
   		goto bspexit
   		end
   
       -- check for negative on-hand
       select @onhand = OnHand
   	from bINMT with (nolock)
       where INCo = @inco and Loc = @comploc and MatlGroup = @matlgroup and Material = @compmatl
   	if @@rowcount = 0
   		begin
   		select @msg = 'Invalid Location: ' + @comploc + ' and Material: ' + @compmatl, @rcode = 1
   		goto bspexit
   		end
   
       if @onhand < @units select @negunits = @negunits + 1
          
       goto INPD_cursor_loop
   
   INPD_cursor_end:
   	close INPD_cursor
       deallocate INPD_cursor
       select @openinpd=0
   
   bspexit:
       if @openinpd=1
           begin
           close INPD_cursor
           deallocate INPD_cursor
           end
   
    --   if @rcode <> 0 select @msg
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINPDCompUnitsSet] TO [public]
GO
