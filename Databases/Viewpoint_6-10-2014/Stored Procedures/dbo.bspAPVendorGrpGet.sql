SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPVendorGrpGet    Script Date: 8/28/99 9:34:06 AM ******/
   CREATE     proc [dbo].[bspAPVendorGrpGet]
   /********************************************************
   * CREATED BY: 	SE 2/6/97
   * MODIFIED BY:	kb 10/29/2 - issue #18878 - fix double quotes
   *		ES 03/12/04 - #23061 isnull wrapping
   *
   * USAGE:
   * 	Retrieves the Vendor Group from bHQCO
   *
   * INPUT PARAMETERS:
   *	AP Company number
   *
   * OUTPUT PARAMETERS:
   *	Vendor Group from bHQCO
   *	Error message
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
   	(@apco bCompany = 0, @VendorGroup tinyint output, @msg varchar(60) output)
   as 
   
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @apco = 0
   	begin
   	select @msg = 'Missing AP Company#', @rcode = 1
   	goto bspexit
   	end
   
   select @VendorGroup = VendorGroup from bHQCO with (nolock) where HQCo = @apco
   
   if @@rowcount = 1 
      select @rcode=0
   else
      select @msg='HQ Company does not exist.  Please check company setup.', @rcode=1, @VendorGroup=0
   
   if @VendorGroup is Null 
      select @msg = 'Vendor group not setup for company ' + isnull(convert(varchar(3),@apco), '') , @rcode=1, @VendorGroup=0  --#23061
   	  
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPVendorGrpGet] TO [public]
GO
