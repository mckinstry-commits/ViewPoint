SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Stored Procedure dbo.bspPOValVendInUse    Script Date: 8/28/99 9:33:11 AM ******/
   CREATE  proc [dbo].[bspPOValVendInUse]
   /***********************************************************
    * CREATED BY	: kf 3/24/97
    * MODIFIED BY	: kf 3/24/97
    *				GF 7/27/2011 - TK-07144 changed to varchar(30) 
    *
    * USED IN:
    *   ChangeOrders
    *   Receipts
    *
    * USAGE:
    * validates PO, returns PO Description, Vendor, and Vendor Description and
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to validate against 
    *   PO to validate
    * 
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of PO, Vendor, 
    *   Vendor group, and Vendor Name
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
       (@poco bCompany = 0, @po VARCHAR(30) = null, @BatchId bBatchID=null, @BatchMth bMonth=null,
       @Vendor bVendor=null output, @VendorName char(30)=null output, @VendorGroup bGroup=0 output, 
       @msg varchar(100) output)
   as
   
   set nocount on
   
   declare @rcode int, @InUse bBatchID, @InUseMth bMonth, @inuseby bVPUserName, @status tinyint,
   	@source bSource
   
   select @rcode = 0
   select @InUse=null
   
   if @poco is null
   	begin
   	select @msg = 'Missing PO Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @po is null
   	begin
   
   	select @msg = 'Missing PO!', @rcode = 1
   	goto bspexit
   	end
   
   select @InUse=InUseBatchId, @InUseMth=InUseMth, @status=Status from POHD 
   	where POCo = @poco and PO = @po
   if @@rowcount=0 
   	begin
   	select @msg = 'PO not on file!', @rcode = 1
   	goto bspexit
   	end
   if @status<>0 
   
   	begin
   	select @msg = 'PO not open!', @rcode = 1
   	goto bspexit
   	end
   if @BatchId is not null
   	begin
   	if not @InUse is null
   	   begin
   	    if @InUse=@BatchId and @InUseMth=@BatchMth
   	       goto poupdatesuccess
   	
   	    select @source=Source
   	       from HQBC 
   	       where Co=@poco and BatchId=@InUse and Mth=@InUseMth
   	    if @@rowcount<>0
   	       begin
   		select @msg = 'PO already in use by ' +
   		      convert(varchar(2),DATEPART(month, @InUseMth)) + '/' + 
   		      substring(convert(varchar(4),DATEPART(year, @InUseMth)),3,4) + 
   			' batch # ' + convert(varchar(6),@InUse) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
   
   		goto bspexit
   	       end
   	    else
   	       begin
   		select @msg='PO already in use by another batch!', @rcode=1
   		goto bspexit	
   	       end
   	   end
   	end
   
   
   poupdatesuccess:
   
   select 	@msg=POHD.Description,
   	@Vendor=POHD.Vendor,
   	@VendorName=APVM.Name,
   	@VendorGroup=APVM.VendorGroup
   
   		from POHD JOIN APVM ON APVM.VendorGroup=POHD.VendorGroup and 
   
   		APVM.Vendor=POHD.Vendor
   		where POCo = @poco and PO = @po
   		
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOValVendInUse] TO [public]
GO
