SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPRefValForAPPC    Script Date: 8/28/99 9:32:32 AM ******/
   CREATE  proc [dbo].[bspAPRefValForAPPC]
   /***********************************************************
    * CREATED BY	: kf 10/24/97
    * MODIFIED BY	: kf 10/24/97
    * MODIFIED By: kb 8/8/00 issue #7908
    *              EN 11/15/00 issue #11324 - return @multref = 'Y' if mult unpaid trans exist for ref#
    *              GR 11/21/00 changed datatype from bAPRef to bAPReference
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *		ES 03/12/04 - #23061 isnull wrapping
    *
    * USAGE:
    * validates AP Reference to see if it is valid for the specified
    * company, vendor group and vendor and to verify that it's open
    * and not in use in a batch.
    *
    * INPUT PARAMETERS
    *   @apco      AP Co to validate against
    *   @vendrgrp  Vendor Group
    *   @vendor    Vendor
    *   @apref     Reference to Validate
    *
    * OUTPUT PARAMETERS
    *   @multref  'Y' if multiple open transactions exist with same reference; else 'N'
    *   @msg      message if Reference is not unique otherwise nothing
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if Fails Address, City, State and Zip are ''
    *****************************************************/
   
       (@apco bCompany = 0, @vendrgrp bGroup, @vendor bVendor, @apref bAPReference,
        @multref char(1) output, @msg varchar(100) output )
   as
   
   set nocount on
   
   declare @rcode int, @openyn bYN, @inusemth bMonth, @inusebatchid bBatchID, @source bSource,
     @prepaidproc bYN, @prepaidyn bYN, @numrows int, @numrows1 int
   
   select @rcode = 0
   
   select @numrows = 0, @numrows1 = 0, @multref = 'N'
   
   -- check for multiple transaction with same reference
   select @numrows = count(*) from APTH
   where APCo = @apco and VendorGroup = @vendrgrp and Vendor = @vendor and APRef = @apref
   if @numrows > 1
       begin
        select @multref = 'Y'
        --quit validation if more than one of the multiple transactions found is unpaid
        select @numrows1 = count(*) from APTH
        where APCo = @apco and VendorGroup = @vendrgrp and Vendor = @vendor and APRef = @apref
           and OpenYN='Y'
        if @numrows1 > 1 goto bspexit
       end
   
   select @openyn=OpenYN, @inusemth=InUseMth, @inusebatchid=InUseBatchId,
       @prepaidproc = PrePaidProcYN, @prepaidyn = PrePaidYN from APTH
   	where APCo=@apco and VendorGroup=@vendrgrp and Vendor=@vendor and APRef=@apref
       and (@multref = 'N' or (@multref = 'Y' and OpenYN = 'Y'))
   
   --clear multref flag if only one transaction remains open for this ref#
   select @multref = 'N'
   
   if @@rowcount = 0
   	begin
   	 select @msg = 'Invalid reference!', @rcode = 1
   	 goto bspexit
   	end
   
   if @openyn <> 'Y'
   	begin
   	 select @msg = 'Transaction is closed!', @rcode = 1
   	 goto bspexit
   	end
   
   if @prepaidyn = 'Y' and @prepaidproc = 'N'
       begin
       select @msg = 'Unprocessed prepaid transactions cannot be accessed here.', @rcode = 1
       goto bspexit
       end
   
   if @inusebatchid is not null
   	begin
   /*	 select @msg = 'Transaction is currently in use by another user in batch ID # '
   + convert(varchar,@inusebatchid) + ', month ' + convert(varchar,@inusemth) + '!', @rcode=1*/
   	select @source=Source
   	       from HQBC
   	       where Co=@apco and BatchId=@inusebatchid and Mth=@inusemth
   	    if @@rowcount<>0
   	       begin
   		select @msg = 'Transaction already in use by ' +
   		      isnull(convert(varchar(2),DATEPART(month, @inusemth)), '') + '/' +
   		      isnull(substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4), '') +
   			' batch # ' + isnull(convert(varchar(6),@inusebatchid), '') + ' - ' + 
   			'Batch Source: ' + isnull(@source, ''), @rcode = 1  --#23061
   
   		goto bspexit
   	       end
   	    else
   	       begin
   		select @msg='Transaction already in use by another batch!', @rcode=1
   		goto bspexit
   	       end
   	 goto bspexit
   	end
   
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPRefValForAPPC] TO [public]
GO
