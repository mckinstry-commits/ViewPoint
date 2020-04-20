SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPGlacctDflt    Script Date: 8/28/99 9:33:58 AM ******/
   CREATE   proc [dbo].[bspAPGlacctDflt]
   /***********************************************************
    * CREATED BY: SE   4/26/96
    * MODIFIED By : SE 4/26/96
    *               GR 11/23/99 to default the glactt based on Material Category, if null
    *                  then default from Vendor Master based on Vendor
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *				DC 12/06/04 - #26184 - initialize GlAcct variable to null
    *
    * USAGE:
    * this sp takes infomation about an vendor and returns the default
    * glacct.
    *
    *
    * INPUT PARAMETERS
    *    vendorgroup vendor group
    *    vendor	  Vendor
    *
    * OUTPUT PARAMETERS
    *    glacct        GLAcct for this vendor
    *    msg           error message. *
    *
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   	(@vendorgroup bGroup, @vendor bVendor, @matlgroup bGroup, @material bMatl = null,
            @glacct bGLAcct output, @msg varchar(30) output)
   as
   set nocount on
   
   
   
   declare @rcode int
   
   SELECT @glacct = NULL  --DC 26184
   
   --get glacct from Material Category
   select @glacct=GLAcct from bHQMC c join bHQMT t on c.MatlGroup = t.MatlGroup
   and c.Category=t.Category
   where t.MatlGroup=@matlgroup and t.Material=@material and t.Stocked='N'
   
   --get glacct from Vendor Master if Material Category glacct is null
   if isnull(@glacct, '') = ''
   begin
     select @glacct=GLAcct from bAPVM
     where VendorGroup=@vendorgroup and Vendor = @vendor
   end

GO
GRANT EXECUTE ON  [dbo].[bspAPGlacctDflt] TO [public]
GO
