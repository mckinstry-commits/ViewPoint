SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPSortNameUnique    Script Date: 8/28/99 9:34:05 AM ******/
   CREATE  proc [dbo].[bspAPSortNameUnique]
   /***********************************************************
    * CREATED BY	: kb 11/24/97
    * MODIFIED BY	: kb 11/24/97
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *		ES 03/12/04 - #23061 isnull wrapping
    *
    * USAGE:
    * validates AP SortName to see if it is unique. Is called
    * from AP Vendor Master.  Checks APVM
    *
    * INPUT PARAMETERS
    *   @vendorgroup  AP vendor group validate against 
    *   @vendor       Vendor
    *   @sortname     SortName to Validate
    * 
    * OUTPUT PARAMETERS
    *   @msg      message if Reference is not unique otherwise nothing
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if sortname has already been used
    *******************************************************************/ 
   
       (@vendorgroup bGroup = 0,@vendor bVendor, @sortname bSortName, @msg varchar(80) output )
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @msg = 'AP Unique'
    
   select @rcode=1, @msg='Sortname ' + isnull(@sortname, '') + ' already used by vendor# ' 
   		+ isnull(convert(varchar(10), Vendor) , '')
     from bAPVM where VendorGroup=@vendorgroup and SortName=@sortname and Vendor<>@vendor  --#23061
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPSortNameUnique] TO [public]
GO
