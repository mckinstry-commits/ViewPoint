SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    procedure [dbo].[bspPORBExpPostIN]
   /***********************************************************
    * CREATED BY: DANF 04/21/01
    * Modfied By: DANF 08/31/01 - Issue 14506 - Check for no PO Company
    *             DANF 05/01/02 - Added Interface levels from PORH for Initializing Receipts.
    *			   GF 08/11/2003 - issue #22116 - performance improvements
    *			   DANF 09/25/03 - issue 21985 - Corrected Backingout or turning Reciept expenses.
    *			   RT 12/04/03 - #23061, use isnulls when concatenating message strings, added with (nolock)s.
	*				GP 11/25/08 - 131227, increased description param to 60 char.
    *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *				GF 08/22/2011 TK-07879 PO ITEM LINE
    *
    *
    * USAGE: Called from the bspPORBPost procedure to post IN distributions
    *	tracked in bPORN.  Interface level to IN is assigned in bPOCO.
    *
    * Interface levels:
    *	0      No update of actual units or costs but will still update
    *         onorder and received n/invcd units to INMT
    *	1      Interface at the transaction line level.  Each line on an invoice
    *		   creates a bINDT entry.
    *
    * INPUT PARAMETERS
    *	@co			    AP Co#
    *	@mth			Batch month
    *	@batchid		Batch ID#
    *	@dateposted	    Posting date
    *
    * OUTPUT PARAMETERS
    *	@errmsg		    Message used for errors
    *
    * RETURN VALUE
    *	0	success
    *	1	fail
    *****************************************************/
   (@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @apline smallint, @apref bAPReference, @aptrans bTrans, @ecm bECM, @inco bCompany,
   		@ininterfacelvl tinyint, @intrans bTrans, @glacct bGLAcct, @glco bCompany, @invdate bDate, 
   		@desc bItemDesc, @material bMatl, @matlgroup bGroup, @oldnew tinyint, @openPORNcursor tinyint, 
   		@po varchar(30), @poitem bItem, @rcode int, @seq int, @totalcost bDollar, @transdesc bDesc, @um bUM, 
   		@unitcost bUnitCost, @units bUnits, @vendor bVendor, @vendorgroup bGroup, @loc bLoc, @stdum bUM, 
   		@stdunits bUnits, @recvyn bYN, @msg varchar(255), @onhand bUnits, @stdunitcost bUnitCost,
       	@stdecm bECM, @stdtotalcost bDollar, @receiver# varchar(20), @recdate bDate, @potrans bTrans,
       	@Source bSource, @oldininterfacelvl TINYINT,
       	----TK-07879
       	@POItemLine INT
   
   select @rcode = 0
   
   --get IN interface level
   select @ininterfacelvl = RecINInterfacelvl from bPOCO with (nolock) where POCo = @co
   if @@rowcount = 0
       begin
       --- Not every one will have PO /// select @errmsg = 'Missing PO Company!', @rcode = 1
       goto bspexit
       end
   
   --   Over Ride Interface levels if Initializing Expenses from Receipts.
   select @Source=Source from bHQBC with (nolock) 
   where Co = @co and Mth = @mth and BatchId = @batchid
   if isnull(@Source,'') = 'PO InitRec'
   	begin
   	-- get PORH info
   	select @ininterfacelvl = RecINInterfacelvl,  @oldininterfacelvl = OldRecINInterfacelvl
   	from bPORH with (nolock) 
   	where Co = @co and Mth = @mth and BatchId = @batchid
   	if @@rowcount = 0
   		begin
   		select @errmsg = ' Missing Receipt Header for Interface levels!', @rcode = 1
   		goto bspexit
   		end
   
       -- if turning off receipt expenses swith interface level to on for backing out receipt expenses
   	if @oldininterfacelvl = 1 and @ininterfacelvl = 0 select @ininterfacelvl =1
   	end
   
   --declare cusrsor on PORN
   declare PORN_cursor cursor LOCAL FAST_FORWARD
   for select INCo, Loc, MatlGroup, Material, BatchSeq, APLine, OldNew, POTrans, VendorGroup,
           Vendor, RecDate, Receiver#, PO, POItem, Description, GLCo, GLAcct, UM, Units, UnitCost, ECM,
           TotalCost, StdUM, StdUnits, StdUnitCost, StdECM, StdTotalCost,
           ----TK-07879
           POItemLine
   from bPORN with (nolock)
   where POCo = @co and Mth = @mth and BatchId = @batchid
   
   -- open cursor
   open PORN_cursor
   select @openPORNcursor = 1
   
   --loop through all the records
   PORN_posting_loop:
   fetch next from PORN_cursor into @inco, @loc, @matlgroup, @material, @seq, @apline, @oldnew,
			@potrans, @vendorgroup, @vendor, @recdate, @receiver#, @po, @poitem, @desc, @glco,
			@glacct, @um, @units, @unitcost, @ecm, @totalcost, @stdum, @stdunits, @stdunitcost,
			@stdecm, @stdtotalcost,
			----TK-07879
			@POItemLine
   
   if @@fetch_status = -1 goto PORN_posting_end
   if @@fetch_status <> 0 goto PORN_posting_loop
   
   begin transaction
   
   -- IN Interface Level 0 no updates to actuals but updates to On Order and Received not Invoiced units
   -- which is done below for interface level 0 and 1
   if (@units <> 0 or @totalcost <> 0) and @ininterfacelvl = 1
   	begin
   	--get next available transaction # for INDT
   	exec @intrans = bspHQTCNextTrans 'bINDT', @inco, @mth, @msg output
   	if @intrans = 0
   		begin
   		select @errmsg = 'Unable to update IN Detail.  ' + isnull(@msg,''), @rcode = 1
   		goto PORN_posting_error
   		end
   
   	-- add IN Detail entry
   	insert bINDT (INCo, Mth, INTrans, BatchId, MatlGroup, Loc, Material,
				PostedDate, ActDate, Source, TransType,  Description, APPOCo, PO, POItem,
				VendorGroup, Vendor, GLCo, GLAcct,
				PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
				StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice,
				PECM, TotalPrice,
				----TK-07879
				POItemLine)
   	values (@inco, @mth, @intrans, @batchid, @matlgroup, @loc, @material,
				@dateposted, @recdate, 'PO', 'Purch', @desc, @co, @po, @poitem,
				@vendorgroup, @vendor, @glco, @glacct,
				@um, @units, @unitcost, @ecm, @totalcost,
				@stdum, @stdunits, @stdunitcost, @stdecm, @stdtotalcost, 0,
				'E', 0,
				----TK-07879
				@POItemLine)
   
   	if @@error <> 0 goto PORN_posting_error
   
   	--update to Onhand, LastUnitCost, LastECM LastCostUpdate, Average Unit Cost are done in INDT trigger
   	end   --end of interface level 1
   
   
   	--delete current row from cursor
   	delete bPORN where POCo = @co and Mth = @mth and BatchId = @batchid and INCo = @inco
   	and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   	and BatchSeq = @seq and APLine = @apline and OldNew = @oldnew
   	if @@rowcount <> 1
   		begin
   		select @errmsg = 'Unable to remove posted distributions from PO Receipt Inventory table.', @rcode = 1
   		goto PORN_posting_error
   		end
   
   commit transaction
   
   goto PORN_posting_loop
   
   PORN_posting_error:
   	rollback transaction
   	goto bspexit
   
   PORN_posting_end:
   	close PORN_cursor
   	deallocate PORN_cursor
   	select @openPORNcursor = 0
   
   
   
   bspexit:
   	if @openPORNcursor = 1
   		begin
    		close PORN_cursor
    		deallocate PORN_cursor
    		end
   
       return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPORBExpPostIN] TO [public]
GO
