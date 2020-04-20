SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[bspAPWDTransVal]
   /***********************************************************
   * CREATED: MV 3/4/01
   * MODIFIED: GG 09/20/02 - #18522 ANSI nulls 
   *
   * USAGE:
   * Returns Description, VendorGroup and Vendor from APTH to frmAPWDWorkfileDetail
   *
   * INPUT PARAMETERS
   *  @co                 AP Company
   *  @mth	           month
   *  @trans		   APTrans	
   * OUTPUT PARAMETERS
   *  @Desc		   description
   *  @vendorgrp	   vendorgroup
   *  @vendor             vendor
   *  @msg                error message if error occurs
   *
   * RETURN VALUE
   *  0                   success
   *  1                   failure
   ************************************************************/
    (@co bCompany, @mth bDate, @trans bTrans, @description bDesc output,
   	 @vendorgrp bGroup output, @vendor bVendor output, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @errmsg varchar (100)
   
   select @rcode = 0
   
   if @mth is null	 -- #18522
    begin
    select @errmsg = 'Missing AP Month!', @rcode = 1
    goto bspexit
    end
   
   if @trans is null	-- #18522
    begin
    select @errmsg = 'Missing AP Trans!', @rcode = 1
    goto bspexit
    end
   
   select @description = Description, @vendorgrp=VendorGroup, @vendor = Vendor
   from APTH
   where APCo = @co and Mth = @mth and APTrans = @trans
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPWDTransVal] TO [public]
GO
