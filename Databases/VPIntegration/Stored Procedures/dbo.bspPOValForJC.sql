SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOValForJC    Script Date: 8/28/99 9:33:11 AM ******/
   CREATE  proc [dbo].[bspPOValForJC]
   /***********************************************************
    * CREATED BY	: DANF 01/10/2000
    * Modified By:		GF 7/27/2011 - TK-07144 changed to varchar(30) 
    *
    * USAGE:
    * validates PO, returns PO Description
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to validate against
    *   PO to validate, Vandor assgined to the Job Cost transaction with Venor Group.
    *
    * OUTPUT PARAMETERS
    *   @msg error message if error occurs otherwise Description of PO
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
   	(@poco bCompany = 0, @po VARCHAR(30) = null, @Vendor bVendor = null,
         @VendorGroup bGroup = null, @msg varchar(100) output)
   as
   
   set nocount on
   
   
   
   declare @rcode int, @numrows int, @source bSource, @POVendor bVendor,
           @POVendorGroup bGroup
   
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
   
   
   select 	@msg=POHD.Description,
   	    @POVendor=POHD.Vendor,
   	    @POVendorGroup=POHD.VendorGroup
   		from POHD where POCo = @poco and PO = @po
   
   if @@rowcount = 0
   	begin
   	select @msg = 'PO not on file!', @rcode = 1
   
   
   	goto bspexit
   	end
   
   if @POVendor<>@Vendor
      begin
      select @msg = 'PO Vendor ' + convert(varchar(6),@POVendor) + ' does not match assigned Vendor!', @rcode =1
      goto bspexit
      end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOValForJC] TO [public]
GO
