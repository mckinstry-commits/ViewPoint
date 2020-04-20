SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    proc [dbo].[bspPOValForAddrSeq]
   /***********************************************************
    * CREATED BY	: MV 11/12/02
    * MODIFIED BY	: GF 7/27/2011 - TK-07144 changed to varchar(30) 
    *                
    *
    * USAGE:
    * validates PO, returns PayAddressSeq
    * 
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to validate against 
    *   PO to validate
    *   Vendor to validate the PO is for the right vendor
    *	VendorGroup to validate for vendor
    * 
    * OUTPUT PARAMETERS
    *	@addressseq	PayAddressSeq from POHD
    *   @msg      error message if error occurs otherwise 
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@poco bCompany, @po VARCHAR(30), @vendorgroup bGroup, @vendor bVendor, 
   	@addressseq tinyint output, @msg varchar(100) output )
   as
   
   set nocount on
   
   declare @rcode int,@povendor bVendor
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
   
   select @povendor=Vendor,@addressseq = isnull(PayAddressSeq,0) from POHD
   	where POCo = @poco and PO = @po
   if @@rowcount=0
   	begin
   	select @msg = 'PO not on file!', @rcode = 1
   	goto bspexit
   	end
   
   if @povendor<>@vendor
   	begin
   	select @msg = 'Invoice Vendor does not match the PO Vendor!', @rcode=1
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOValForAddrSeq] TO [public]
GO
