SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPVendorTaxIDUnique    Script Date: 8/28/99 9:35:40 AM ******/
   CREATE proc [dbo].[bspAPVendorTaxIDUnique]
   /***********************************************************
    * CREATED BY	: EN 5/26/00
    * MODIFIED BY:	ES 03/12/04 - #23061 isnull wrapping
    *
    * USAGE:
    *	Checks a Vendor's tax ID# for uniqueness. Called
    *	from APVendMaster.
    *
    * INPUT PARAMETERS
    * 	 @vendgroup     Vendor Group
    *	 @vendor      	Vendor #
    *	 @taxid 		Tax ID#
    *
    * OUTPUT PARAMETERS
    *   	@msg      	error message
    *
    * RETURN VALUE
    *  	 0         		success
    *   	1        		failure
    *******************************************************************/
   
       (@vendgroup bGroup, @vendor bVendor, @taxid varchar(12), @msg varchar(80) output )
   
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @msg = ''
   
   select @rcode=1, @msg= 'Already in use by vendor # ' + isnull(convert(varchar(6), Vendor), '') + ' (' + Name + ').'
     from bAPVM where VendorGroup = @vendgroup and TaxId = @taxid and Vendor <> @vendor  --#23061
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPVendorTaxIDUnique] TO [public]
GO
