SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Stored Procedure dbo.bspPOValWithInfoRtn    Script Date: 8/28/99 9:33:11 AM ******/
   CREATE  proc [dbo].[bspPOValWithInfoRtn]
   /***********************************************************
    * CREATED BY	: kf 3/12/97
    * MODIFIED BY	: kf 3/12/97
	*					DC 7/12/2007 - #122909.  Need to return the Attachment ID so	
	*										the form can show the attachment.
	*					DC 04/15/2008 - #122166.  Does not display if CLOSED status; cannot delete entries
	*					GF 7/27/2011 - TK-07144 changed to varchar(30) 
    *
    * USAGE:
    * validates PO, returns PO Description, Vendor, Vendor Description,
    * Order Date, Date Expected, Ordered By
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to validate against 
    *   PO to validate
    *   BatchId, Month to see if already in use by another batch
    * 
    * OUTPUT PARAMETERS
    *   @msg error message if error occurs 
	*	Vendor
	*	Vendor group, 
    *	Vendor Name
	*	OrderDate
	*	ExpDate
	*	Ordered By
	*	UniqueAttchID
	*
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@poco bCompany = 0, @po VARCHAR(30) = null, @BatchId bBatchID = null, @Month bMonth=null,
   	@Vendor bVendor output, @VendorName char(30)=null output, @VendorGroup bGroup output, 
   	@OrderDate bDate=null output, @ExpDate bDate=null output, @OrderedBy char(10)=null 
   	output, @UniqueAttchID uniqueidentifier output, @msg varchar(100) output)
   as
   
   set nocount on
   
   declare @rcode int, @InUseBatchId bBatchID, @InUseMth bMonth, @numrows int, @source bSource,
		@status tinyint  --DC #122166 

   select @rcode = 0
   
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
   	
   
	SELECT
		@msg=POHD.Description,
   		@Vendor=POHD.Vendor,
   		@VendorName=APVM.Name,
   		@VendorGroup=APVM.VendorGroup,
   		@OrderDate=POHD.OrderDate,
   		@ExpDate=POHD.ExpDate,
   		@OrderedBy=POHD.OrderedBy,
   		@InUseBatchId=InUseBatchId,
   		@InUseMth=InUseMth,
		@UniqueAttchID = POHD.UniqueAttchID,
		@status=POHD.Status  --DC #122166
   	FROM POHD 
	JOIN APVM ON APVM.VendorGroup=POHD.VendorGroup and 
   		APVM.Vendor=POHD.Vendor	
	WHERE POCo = @poco and PO = @po
   		
   if @@rowcount = 0
   	begin
   	select @msg = 'PO not on file!', @rcode = 1
   	goto bspexit
   	end
   
--DC #122166
   if @status<>0 
   	begin
   	select @msg = 'PO not open!', @rcode = 1
   	goto bspexit
   	end
	   
   if not @InUseBatchId is null and @InUseBatchId<>@BatchId
   	begin
   	select @source=Source
   	       from HQBC 
   	       where Co=@poco and BatchId=@InUseBatchId and Mth=@InUseMth
   	    if @@rowcount<>0
   	       begin
   		select @msg = 'PO already in use by ' +
   		      convert(varchar(2),DATEPART(month, @InUseMth)) + '/' + 
   		      substring(convert(varchar(4),DATEPART(year, @InUseMth)),3,4) + 
   			' batch # ' + convert(varchar(6),@InUseBatchId) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
   
   		goto bspexit
   	       end
   	    else
   	       begin
   		select @msg='PO already in use by another batch!', @rcode=1
   		goto bspexit	
   	       end
   	end
   
   
   
   select @numrows=count(*) from POIT where POCo=@poco and PO=@po and RecvYN='Y'
   
   if @numrows=0
   	begin
   	select @msg = 'There are no PO items to be received on this PO', @rcode=1 
   	goto bspexit
   	end 
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOValWithInfoRtn] TO [public]
GO
