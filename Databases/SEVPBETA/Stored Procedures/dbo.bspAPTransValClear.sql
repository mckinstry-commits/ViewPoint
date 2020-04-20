SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPTransValClear    Script Date: 8/28/99 9:32:33 AM ******/
   CREATE        proc [dbo].[bspAPTransValClear]
   /***********************************************************
    * CREATED BY: KF 10/9/97
    * MODIFIED By : kb 3/24/99
    *               GH 4/20/99  Added check to make sure that APTD.Status<3, so that it will pull
    *                           in just the lines that are open.
    *               EN 1/22/00 - expand dimension of @vendorname to varchar(60)
    *               GR 11/21/00 - changed datatype from bAPRef to bAPReference
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *				ES 03/12/04 - #23061 isnull wrapping
    *				MV 04/20/04 - #24359 - validate for unprocessed prepaid
    *				MV 09/30/04 - #25638 - validate for workfile, improved msg for open trans
    *				MV 12/29/04 - #26649 - tweak validation for open transaction detail
    *				MV 04/19/06 - APClear 6X recode - return vendor name
    *				MV 11/06/07 - #126076 - check for holdcodes
    * USAGE:
    * validates AP Transaction # in AP Clear program
    *
    * INPUT PARAMETERS
    *   @apco - AP Company
    *   @expmth - Expense month for transaction
    *   @aptrans - AP Transaction to validate from AP Transaction Header
    *
    * OUTPUT PARAMETERS
    *   @msg If Error, error message, otherwise description of Company
    * RETURN VALUE
    *   0   success
    *   1   fail
    ****************************************************************************************/
   	(@apco bCompany, @expmth bMonth, @aptrans bTrans, @batchid bBatchID, @mth bMonth,
   	@vendorname varchar(60)output, /*@vendorout varchar(40) output*/ @apref bAPReference output,
	@invdate bDate output, @desc bDesc output, @gross bDollar output, @paid bDollar output,
   
   	@remaining bDollar output, @msg varchar(100) output)
   as
   
   set nocount on
   
   declare @rcode int, @inusebatchid bBatchID, @inuseby bVPUserName, @inusemth bMonth, @vendor bVendor,
   	/*@vendorname varchar(60),*/ @source bSource, @status tinyint, @prepaidyn bYN, @prepaidprocyn bYN,
   	@username bVPUserName
   
   select @rcode = 0
   
   if @apco = 0
   
   	begin
   	select @msg = 'Missing AP Company#', @rcode = 1
   	goto bspexit
   	end
   
   if @expmth is null
   	begin
   	select @msg = 'Missing Expense Month' , @rcode = 1
   	goto bspexit
   	end
   
   
   
   select @inusebatchid=InUseBatchId, @inusemth=InUseMth, @status = APTD.Status, @prepaidyn=APTH.PrePaidYN,
   	@prepaidprocyn=APTH.PrePaidProcYN
   	from APTD join APTH on APTH.APCo=APTD.APCo and APTH.Mth=APTD.Mth and APTH.APTrans=APTD.APTrans
   	where APTD.APCo=@apco and APTD.Mth=@expmth and APTD.APTrans=@aptrans --and APTD.Status<3
   
   if @@rowcount=0
   	begin
   	select @msg='Invalid Transaction' , @rcode=1
   	goto bspexit
   	end
   
   if not exists (select 1 from APTD where APCo=@apco and Mth=@expmth and APTrans=@aptrans and Status=1  )
   	begin
   	select @msg='There is no open transaction detail to be cleared!' , @rcode=1
   	goto bspexit
   	end

	--check for holdcodes 
	if exists(select 1 from bAPHD (nolock) where APCo=@apco and Mth=@expmth and APTrans=@aptrans)
		begin
		select @msg = 'Transaction has hold detail, cannot add to clear batch.', @rcode = 1
        goto bspexit
		end
   
   -- if @status <> 1
   -- 	begin
   -- 	select @msg='All transaction detail must be open to be cleared!' , @rcode=1
   -- 	goto bspexit
   -- 	end
   
   if @prepaidyn='Y' and @prepaidprocyn='N'
   	begin
   	select @msg='Transaction is an unprocessed prepaid.  It cannot be cleared!' , @rcode=1
   	goto bspexit
   	end
   
   select @username = UserId from APWH with (nolock) where APCo=@apco and Mth=@expmth and APTrans=@aptrans
   	if @@rowcount > 0
   	begin
   	select @msg='Transaction must be deleted from AP Workfile: ' + @username + ' before clearing.' , @rcode=1
   	goto bspexit
   	end
   
   if @inusebatchid is not null or @inusemth is not null
   	begin
   
   	/*select @inuseby=InUseBy from HQBC where Co=@apco and BatchId=@batchid and Mth=@mth
   	select @msg='Transaction is in use by ' + @inuseby + ' batch# ' + convert(varchar(10),@inusebatchid)*/
   	select @source=Source
   	       from HQBC
   	       where Co=@apco and BatchId=@inusebatchid and Mth=@inusemth
   	    if @@rowcount<>0
   	       begin
   		select @msg = 'Transaction already in use by ' +
   		      isnull(convert(varchar(2),DATEPART(month, @inusemth)), '') + '/' +
   		      isnull(substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4), '') +
   			' batch # ' + isnull(convert(varchar(6),@inusebatchid), '') + 
   			' - ' + 'Batch Source: ' + isnull(@source, ''), @rcode = 1  --#23061
   
   		goto bspexit
   	       end
   	    else
   	       begin
   		select @msg='Transaction already in use by another batch!', @rcode=1
   		goto bspexit
   	       end
   	goto bspexit
   	end
   /*took this out cause it caused a TDS stream error*/
     /*select @vendor=APTH.Vendor, @vendor=APVM.Name, @apref=APTH.APRef, @desc=APTH.Description,
     	@invdate=APTH.InvDate, @gross=sum(APTL.GrossAmt),
     	@paid=(select isnull(sum(APTD.Amount),0) + isnull(sum(APTD.DiscTaken),0) from APTD
     		where APCo=@apco and Mth=@expmth and APTrans=@aptrans and Status=3),
     	@remaining=(select isnull(sum(APTD.Amount),0) from APTD
     	where APCo=@apco and Mth=@expmth and APTrans=@aptrans and Status<3)
     	from APTH
     	join APTL on APTL.APCo=APTH.APCo and APTL.Mth=APTH.Mth and APTL.APTrans=APTH.APTrans
     	join APVM on APVM.VendorGroup=APTH.VendorGroup and APVM.Vendor=APTH.Vendor
     	where APTH.APCo = @apco and APTH.Mth = @expmth and APTH.APTrans=@aptrans
     	group by APTH.Vendor, APVM.Name, APTH.APRef, APTH.Description, APTH.InvDate
   
     select @vendorout=convert(varchar(10),@vendor) +' '+@vendorname*/
   
   select @vendor=APTH.Vendor, @vendorname=APVM.Name, @apref=APTH.APRef, @desc=APTH.Description,
     	@invdate=APTH.InvDate
     	from APTH
     	join APVM on APVM.VendorGroup=APTH.VendorGroup and APVM.Vendor=APTH.Vendor
     	where APTH.APCo = @apco and APTH.Mth = @expmth and APTH.APTrans=@aptrans
   
   select @gross=sum(APTL.GrossAmt) from APTL where APCo = @apco and Mth = @expmth and APTrans = @aptrans
   select @paid= isnull(sum(APTD.Amount),0) + isnull(sum(APTD.DiscTaken),0) from APTD
     		where APCo=@apco and Mth=@expmth and APTrans=@aptrans and Status=3
   select @remaining=isnull(sum(APTD.Amount),0) from APTD
     	where APCo=@apco and Mth=@expmth and APTrans=@aptrans and Status<3
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPTransValClear] TO [public]
GO
