SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Stored Procedure dbo.vspPOValforChgOrder    Script Date: 8/28/99 9:33:11 AM ******/
   CREATE  proc [dbo].[vspPOValforChgOrder]
   /***********************************************************
    * CREATED BY	: DC  08/22/08
    * MODIFIED BY	: GF 7/27/2011 - TK-07144 changed to varchar(30)
    *
    * USED IN:
    *   ChangeOrders
    *   
    *
    * USAGE:
    * validates PO, 
    *	returns: PO Description, Vendor, Vendor Description, TaxGroup
    * 
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
       @POSLTaxCode bTaxCode output, @VendorTaxCode bTaxCode output, @ExpectedDate bDate output,
       @OrderDate bDate output, @msg varchar(100) output)
       
   as
   
   set nocount on
   
   declare @rcode int, @InUse bBatchID, @InUseMth bMonth, @inuseby bVPUserName, @status tinyint,
   	@source bSource, @shiploc varchar(10)
   
   select @rcode = 0
   select @InUse=null
   
	if @poco is null
   		begin
   		select @msg = 'Missing PO Company!', @rcode = 1
   		goto vspexit
   		end
   
	if @po is null
   		begin   
   		select @msg = 'Missing PO!', @rcode = 1
   		goto vspexit
   		end
   
	select @InUse=InUseBatchId, @InUseMth=InUseMth, @status=Status
	from POHD 
   	where POCo = @poco and PO = @po
	if @@rowcount=0 
   		begin
   		select @msg = 'PO not on file!', @rcode = 1
   		goto vspexit
   		end
   		
	if @status<>0    
   		begin
   		select @msg = 'PO not open!', @rcode = 1
   		goto vspexit
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
   			goto vspexit
   			end
   	    else
   			begin
   			select @msg='PO already in use by another batch!', @rcode=1
   			goto vspexit	
   			end
   		end
	end
      
   poupdatesuccess:
   
	SELECT 	@msg=POHD.Description,
   		@Vendor=POHD.Vendor,
   		@VendorName=APVM.Name,
   		@VendorGroup=APVM.VendorGroup,
   		@shiploc = ShipLoc,   
   		@VendorTaxCode = APVM.TaxCode,
   		@ExpectedDate = POHD.ExpDate,
   		@OrderDate = POHD.OrderDate 
   	FROM POHD 
   	JOIN APVM ON APVM.VendorGroup=POHD.VendorGroup and APVM.Vendor=POHD.Vendor
   	WHERE POCo = @poco and PO = @po
   	
	if isnull(@shiploc,'') <> ''
		BEGIN
		select @POSLTaxCode=TaxCode
		from POSL where POCo=@poco and ShipLoc=@shiploc		
		END

   		
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOValforChgOrder] TO [public]
GO
