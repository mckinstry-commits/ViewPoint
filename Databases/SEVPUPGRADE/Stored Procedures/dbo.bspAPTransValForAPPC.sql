SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPTransValForAPPC    Script Date: 8/28/99 9:32:33 AM ******/
   CREATE  proc [dbo].[bspAPTransValForAPPC]
   /***********************************************************
    * CREATED BY: EN 9/12/97
    * MODIFIED By: EN 4/3/98
    * MODIFIED By: kb 8/8/00 issue #7908
    *              GR 11/21/00 - changed datatype from bAPRef to bAPReference
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *		ES 03/12/04 - #23061 isnull wrapping
			AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
    *
    * USAGE:
    * Validates AP Trans # for AP Payment Control.  Transaction
    * must exist in the specified month, posted for the specified
    * vendor, have 1 or more unpaid lines and not currently be in
    * a batch.
    *
    * INPUT PARAMETERS
    *   @apco	AP Company
    *   @expmth	Expense month for transaction
    *   @aptrans	AP Transaction to validate from AP Transaction Header
    *   @vendorgrp	Vendor group
    *   @vendr	Vendor number associated with transaction
    *
    * OUTPUT PARAMETERS
    *   @eft	eft flag from vendor master
    *   @apref	AP reference
    *   @transdesc Transaction description
    *   @invdate   Invoice date
    *   @msg 	If Error, return error message.
    * RETURN VALUE
    *   0   success
    *   1   fail
    ****************************************************************************************/
    (@apco bCompany, @expmth bMonth, @aptrans bTrans, @vendorgrp bGroup=null,
    	@vendr bVendor=null, @eft char(1) output, @apref bAPReference output,
    	@transdesc bDesc output, @invdate bDate output, @msg varchar(90) output)
   as
   
   set nocount on
   
   declare @rcode int, @tvendgrp bGroup, @tvendor bVendor, @source varchar(10),
   	@inuseby varchar(10), @inusemth bMonth, @inusebatchid bBatchID
   
   select @rcode = 0
   
   if @apco = 0
   	begin
   	select @msg = 'Missing AP Company#', @rcode=1
   	goto bspexit
   	end
   
   if @expmth is null
   	begin
   	select @msg = 'Missing Expense Month' , @rcode=1
   	goto bspexit
   	end
   
   /* validate trans # */
   if not exists (select * from APTH where APCo=@apco and APTrans=@aptrans)
   	begin
   	select @msg = 'Invalid transaction!', @rcode=1
   	goto bspexit
   	end
   
   /* verify trans belongs to selected vendor and month */
   if not exists (select * from APTH
   		where APCo=@apco and VendorGroup=@vendorgrp and Vendor=@vendr
   		and Mth=@expmth and APTrans=@aptrans)
   	begin
   	select @msg = 'Invalid transaction for this vendor and month!', @rcode=1
   	goto bspexit
   	end
   
   /* get eft flag from vendor master */
   select @eft=EFT from APVM
   	where VendorGroup=@vendorgrp and Vendor=@vendr
   
   /* verify that trans is open */
   if not exists (select * from APTH where APCo=@apco and Mth=@expmth and APTrans=@aptrans
   		and OpenYN='Y')
   	begin
   	select @msg = 'Transaction is closed!', @rcode=1
   	goto bspexit
   	end
   
   /* verify that trans is not in use by another user */
   --#142278
   SELECT   @source = c.Source,
            @inuseby = c.InUseBy,
            @inusemth = h.InUseMth,
            @inusebatchid = h.InUseBatchId
   FROM     dbo.APTH h
            JOIN dbo.HQBC c	ON h.APCo = c.Co 
								AND h.InUseMth = c.Mth
								AND h.InUseBatchId = c.BatchId
   WHERE    h.APCo = @apco
            AND h.Mth = @expmth
            AND h.APTrans = @aptrans
            
   if @inusebatchid is not null
   	begin
   	/*select @msg = 'Transaction in use by ' + @inuseby + ' in Batch # ' + convert(varchar,@inusebatchid) + ', Month ' + convert(varchar,datepart(month,@inusemth)) + '/' + convert(varchar,datepart(year,@inusemth)) + ', Source ' + @source + '.', @rcode=1
   	goto bspexit*/
   	select @msg = 'Transaction already in use by ' +
   		      isnull(convert(varchar(2),DATEPART(month, @inusemth)), '') + '/' +
   		      isnull(substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4), '') +
   			' batch # ' + isnull(convert(varchar(6),@inusebatchid), '') + 
   			' - ' + 'Batch Source: ' + isnull(@source, ''), @rcode = 1  --#23061
   
   		goto bspexit
   	end
   
   /*check to make sure if prepaid trans that it is processed*/
   if exists(select * from APTH where APCo = @apco and Mth = @expmth and APTrans = @aptrans
     and PrePaidYN = 'Y' and PrePaidProcYN = 'N')
       begin
       select @msg = 'Unprocessed prepaid transactions cannot be accessed here.', @rcode = 1
       goto bspexit
       end
   
   /* verify that trans contains at least one open line */
   --#142278
   SELECT   @tvendgrp = h.VendorGroup,
            @tvendor = h.Vendor,
            @inusebatchid = h.InUseBatchId,
            @apref = h.APRef,
            @transdesc = h.[Description],
            @invdate = InvDate
   FROM     dbo.APTH h
            JOIN dbo.APTD d ON h.APCo = d.APCo
							AND h.Mth = d.Mth
							AND h.APTrans = d.APTrans
   WHERE    h.APCo = @apco
            AND h.Mth = @expmth
            AND h.APTrans = @aptrans
            AND h.VendorGroup = @vendorgrp
            AND h.Vendor = @vendr
            AND h.InUseBatchId IS NULL
            AND OpenYN = 'Y'
            AND d.[Status] NOT IN (3,4)
            
   if @@rowcount=0
   	begin
   	select @msg = 'Transaction contains no unpaid lines!', @rcode=1
   	goto bspexit
   	end
   
   /* verify that vendor is valid for the trans */
   if @tvendgrp<>@vendorgrp or @tvendor<>@vendr
   	begin
   	select @msg = 'Not a valid transaction for this vendor.', @rcode=1
   	goto bspexit
   	end
   
   /* verify that trans is not currently in a batch */
   if not @inusebatchid is null
   	begin
   	select @msg = 'Transaction is currently in use in a batch.', @rcode=1
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPTransValForAPPC] TO [public]
GO
