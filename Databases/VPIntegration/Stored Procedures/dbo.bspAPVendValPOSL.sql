SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspAPVendValPOSL]
   /***********************************************************
    * CREATED BY	: MV 10/15/02
    * MODIFIED BY	: MV 01/06/03 - #18720 rej 1 fix
    *              
    *
    * USED IN:
    *   APEntry
    *
    * USAGE:
    * Issue 18720 - Validates PO or SL lines for a batch sequence when
    * the vendor has been changed.
    *
    * INPUT PARAMETERS
    *   Co  		 Co we're in
    *   Month      Month of batch
    *   Batch      Batch we're currently in
    *   Sequence	 Sequence we're currently in
    *	Vendor	 the new vendor
    *   Source	 APEntry, APUnappInv, APRecurInv
    *   InvId	 used by APRecurInv
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if new vendor doesn't match vendor in
    *			 POHD or SLHD
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
       (@co bCompany , @mth bMonth, @batchid bBatchID,@seq int,
   	 @vendor bVendor, @source varchar(10),@invid char(10), @msg varchar(255)output)
   as
   
   set nocount on
   
   declare @rcode int, @action char(1), @aptrans int
   
   select @rcode = 0
   
   if @source = 'APEntry'
   begin
   --get action and aptrans to check bAPTL too
   select @action=BatchTransType, @aptrans=APTrans from bAPHB 
   	where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   
   if exists (select 1 from bAPLB b join bPOHD d on b.Co=d.POCo and b.PO=d.PO
   	where b.Co=@co and Mth=@mth and BatchId=@batchid and 
   	BatchSeq=@seq and b.LineType= 6 and b.PO=d.PO and d.Vendor <> @vendor)
   	begin
        select @msg = 'Vendor does not match the Purchase Order vendor.', @rcode = 1
        goto bspexit
        end
   	
   if exists (select 1 from bAPLB b join bSLHD d on b.Co=d.SLCo and b.SL=d.SL
   	where b.Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq and
   	b.LineType= 7 and b.SL=d.SL and d.Vendor <> @vendor)
   	begin
   	select @msg = 'Vendor does not match the Subcontract vendor.', @rcode=1
   	goto bspexit
   	end
   
   if @action = 'C'	-- check APTL if no lines were pulled back into the batch
   	begin
   	if exists (select 1 from bAPTL l join bPOHD d on l.APCo=d.POCo and l.PO=d.PO
   		where l.APCo=@co and l.Mth=@mth and l.APTrans=@aptrans and l.LineType= 6
   			 and l.PO=d.PO and d.Vendor <> @vendor)
   		begin
   	     select @msg = 'Vendor does not match the vendor for Purchase Order in bAPTL .', @rcode = 1
   	     goto bspexit
   	     end
   		
   	if exists (select 1 from bAPTL l join bSLHD d on l.APCo=d.SLCo and l.SL=d.SL
   		where l.APCo=@co and l.Mth=@mth and l.APTrans=@aptrans and l.LineType= 7
   			 and l.SL=d.SL and d.Vendor <> @vendor)
   		begin
   		select @msg = 'Vendor does not match the vendor for Subcontract in bAPTL.', @rcode=1
   		goto bspexit
   		end
   	end	-- action = C
   end	--AP Entry source
   
   
   if @source = 'APUnappInv'
   begin
   if exists (select * from bAPUL b join bPOHD d on b.APCo=d.POCo and b.PO=d.PO
   	where b.APCo=@co and UIMth=@mth and UISeq=@seq and b.LineType= 6 and b.PO=d.PO and d.Vendor <> @vendor)
   	begin
        select @msg = 'Vendor does not match the Purchase Order vendor.', @rcode = 1
        goto bspexit
        end
   	
   if exists (select * from bAPUL b join bSLHD d on b.APCo=d.SLCo and b.SL=d.SL
   	where b.APCo=@co and UIMth=@mth and UISeq=@seq and
   	b.LineType= 7 and b.SL=d.SL and d.Vendor <> @vendor)
   	begin
   	select @msg = 'Vendor does not match the Subcontract vendor.', @rcode=1
   	goto bspexit
   	end	
   end
   
   if @source = 'APRecurInv'
   begin
   if exists (select * from bAPRL b join bPOHD d on b.APCo=d.POCo and b.PO=d.PO
   	where b.APCo=@co and b.InvId=@invid and b.LineType= 6 and b.PO=d.PO and d.Vendor <> @vendor)
   	begin
        select @msg = 'Vendor does not match the Purchase Order vendor.', @rcode = 1
        goto bspexit
        end
   	
   if exists (select * from bAPRL b join bSLHD d on b.APCo=d.SLCo and b.SL=d.SL
   	where b.APCo=@co and b.InvId=@invid and b.LineType= 7 and b.SL=d.SL and d.Vendor <> @vendor)
   	begin
   	select @msg = 'Vendor does not match the Subcontract vendor.', @rcode=1
   	goto bspexit
   	end	
   end
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPVendValPOSL] TO [public]
GO
