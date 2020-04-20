SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[bspAPHBPostIN]
/***********************************************************
* CREATED BY:	GR	02/01/2000
* Modfied By:	ae	04/13/2000	- changed Trans Type from AP to Purch
*				GG	06/16/2000	- modified for changes to bAPIN
*				GG	11/27/2000	- changed datatype from bAPRef to bAPReference
*				TV	04/18/2001	- AP will not update IN, Comenting out code except if recvyn = n
*				DANF 03/21/2002 - Modified Update TO inmt OnOrder units when Updatereceipt is Y and In Interface level is 0
*				kb	10/28/2002	- issue #18878 - fix double quotes
*				GF	08/11/2003	- issue #22112 - performance improvements
*				MV	11/26/2003	- 23061 isnull wrap
*				GP	11/25/2008	- 131227, increased description param to 60 char.
*				GF	08/03/2011	- TK-07143 expand PO
*				CHS	08/11/2011	- TK-07620
*
* USAGE: Called from the bspAPHBPost procedure to post IN distributions
*	tracked in bAPIN.  Interface level to IN is assigned in bAPCO.
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
   		@linedesc bItemDesc, @material bMatl, @matlgroup bGroup, @oldnew tinyint, @openapincursor tinyint, 
   		@po VARCHAR(30), @poitem bItem, @POItemLine int, @rcode int, @seq int, @totalcost bDollar, @transdesc bDesc, @um bUM, 
   		@unitcost bUnitCost, @units bUnits, @vendor bVendor, @vendorgroup bGroup, @loc bLoc, @stdum bUM, 
   		@stdunits bUnits, @recvyn bYN, @msg varchar(255), @onhand bUnits, @stdunitcost bUnitCost, 
   		@stdecm bECM, @stdtotalcost bDollar, @receiptupdate bYN, @ininterfacelevel tinyint
   
   select @rcode = 0
   
   --get IN interface level
   select @ininterfacelvl = INInterfaceLvl from bAPCO with (nolock) where APCo = @co
   
   --declare cusrsor on APIN
   declare APIN_cursor cursor LOCAL FAST_FORWARD
   for select INCo, Loc, MatlGroup, Material, BatchSeq, APLine, OldNew, APTrans, VendorGroup,
   		Vendor, APRef, InvDate, PO, POItem, POItemLine, LineDesc, GLCo, GLAcct, UM, Units, UnitCost, ECM,
   		TotalCost, StdUM, StdUnits, StdUnitCost, StdECM, StdTotalCost
   from bAPIN
   where APCo = @co and Mth = @mth and BatchId = @batchid
   
   --open cursor
   open APIN_cursor
   select @openapincursor = 1
   
   --loop through all the records
   apin_posting_loop:
   
   fetch next from APIN_cursor into @inco, @loc, @matlgroup, @material, @seq, @apline, @oldnew, @aptrans, @vendorgroup,
   		@vendor, @apref, @invdate, @po, @poitem, @POItemLine, @linedesc, @glco, @glacct, @um, @units, @unitcost, @ecm,
   		@totalcost, @stdum, @stdunits, @stdunitcost, @stdecm, @stdtotalcost
   
   if @@fetch_status = -1 goto apin_posting_end
   if @@fetch_status <> 0 goto apin_posting_loop
   
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
   		goto apin_posting_error
   		end
   
   	--add IN Detail entry
   	insert bINDT (INCo, Mth, INTrans, BatchId, MatlGroup, Loc, Material,
   			PostedDate, ActDate, Source, TransType,  Description, APPOCo, PO, POItem,
   			APTrans, VendorGroup, Vendor, APRef, APLine, GLCo, GLAcct,
   			PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
   			StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice,
   			PECM, TotalPrice)
   	values (@inco, @mth, @intrans, @batchid, @matlgroup, @loc, @material,
   			@dateposted, @invdate, 'AP Entry', 'Purch', @linedesc, @co, @po, @poitem,
   			@aptrans, @vendorgroup, @vendor, @apref, @apline, @glco, @glacct,
   			@um, @units, @unitcost, @ecm, @totalcost,
   			@stdum, @stdunits, @stdunitcost, @stdecm, @stdtotalcost, 0, 'E', 0)
   
   	if @@error <> 0 goto apin_posting_error
   
   	--update to Onhand, LastUnitCost, LastECM LastCostUpdate, Average Unit Cost are done in INDT trigger
   	end   --end of interface level 1
   
   
   --if it is a po line update OnOrder and RecvdNInvcd units irrespective of interface level
   if @po is not null
   	begin
   	--get RecvYN flag from bPOIT
   	select @recvyn = RecvYN from bPOIT with (nolock) where POCo=@co and PO=@po and POItem=@poitem
   	select @receiptupdate = ReceiptUpdate,  @ininterfacelevel = RecINInterfacelvl 
   	from bPOCO with (nolock) where POCo = @co
   	--AP will update IN OnOrder only if Recieved units and Reciept update = N 05/23/01 tv
   	if @recvyn = 'N' and @stdunits <> 0
   		begin
   		update bINMT
   			set OnOrder = (OnOrder - @stdunits), AuditYN = 'N'   -- do not trigger HQMA update
   		where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material
   		if @@rowcount<>1
   			begin
   			select @errmsg = 'Unable to update Inventory OnOrder units', @rcode=1
   			goto apin_posting_error
   			end
   		update bINMT set AuditYN = 'Y'
   		where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material
   		end
   
   	if @recvyn = 'Y' and @stdunits <> 0 --if flag is yes update received not invoiced units
   		begin
   		update bINMT
   			set RecvdNInvcd = (RecvdNInvcd - @stdunits), AuditYN = 'N'   -- do not trigger HQMA update
   		where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material
   		if @@rowcount<>1
   			begin
   			select @errmsg = 'Unable to update Inventory RecvdNInvcd units', @rcode=1
   			goto apin_posting_error
   			end
   		update bINMT set AuditYN = 'Y'
   		where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Material=@material
   		end
   	end
   
   -- delete current row from cursor
   delete bAPIN where APCo = @co and Mth = @mth and BatchId = @batchid and INCo = @inco
   and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   and BatchSeq = @seq and APLine = @apline and OldNew = @oldnew
   if @@rowcount <> 1
   begin
   	select @errmsg = 'Unable to remove posted distributions from APIN.', @rcode = 1
   	goto apin_posting_error
   	end
   
   commit transaction
   
   goto apin_posting_loop
   
   apin_posting_error:
   	rollback transaction
   	goto bspexit
   
   apin_posting_end:
   	close APIN_cursor
   	deallocate APIN_cursor
   	select @openapincursor = 0
   
   
   
   bspexit:
   	if @openapincursor = 1
   		begin
     		close APIN_cursor
     		deallocate APIN_cursor
     		end
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPHBPostIN] TO [public]
GO
