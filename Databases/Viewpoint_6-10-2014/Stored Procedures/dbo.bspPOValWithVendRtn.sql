SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   /****** Object:  Stored Procedure dbo.bspPOValWithVendRtn    Script Date: 8/28/99 9:33:11 AM ******/
   CREATE    proc [dbo].[bspPOValWithVendRtn]
   /***********************************************************
    * CREATED BY	: CJW 2/23/97
    * MODIFIED BY	: CJW 2/23/97
    *                LM 4/28/99 - modified to check status of po and if coming from PM it can be pending
    *				MV 03/14/03 - #20611 - remove status validation and return status
    *				GF 7/27/2011 - TK-07144 changed to varchar(30) 
    * USAGE:
    * validates PO, returns PO Description, Vendor, and Vendor Description
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to validate against 
    *   PO to validate
    * 
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of PO, Vendor, Vendor group, and Vendor Name
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@poco bCompany = 0, @po VARCHAR(30) = null, @source char(1), @Vendor bVendor output, 
   	@VendorName char(30)=null output, @VendorGroup bGroup output,@status tinyint output,
   	@msg varchar(60) output )
   as
   
   set nocount on
   
   declare @rcode int --, @status tinyint
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
   
   /* make sure the PO is open unless you are coming from PM */
   select @status=Status from POHD 
   	where POCo = @poco and PO = @po
   if @@rowcount=0 
   	begin
   	select @msg = 'Purchase Order not on file!', @rcode = 1
   	goto bspexit
   	end
   /*if @source <> 'P'	-- #20611
   begin
   if @status<>0
   	begin
   	select @msg = 'Purchase Order not open!', @rcode = 1
   	goto bspexit
   	end
   end*/
   
   
   select 	@msg=POHD.Description,
   	@Vendor=POHD.Vendor,
   	@VendorName=APVM.Name,
   	@VendorGroup=APVM.VendorGroup
   	from POHD JOIN APVM ON APVM.VendorGroup=POHD.VendorGroup and 
   		APVM.Vendor=POHD.Vendor
   		where POCo = @poco and PO = @po
   		
   if @@rowcount = 0
   	begin
   	select @msg = 'PO not on file!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOValWithVendRtn] TO [public]
GO
