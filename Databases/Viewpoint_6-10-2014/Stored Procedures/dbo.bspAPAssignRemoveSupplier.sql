SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPAssignRemoveSupplier    Script Date: 8/28/99 9:33:55 AM ******/
   CREATE       procedure [dbo].[bspAPAssignRemoveSupplier]
   
   
   /***********************************************************
    * CREATED BY: EN 11/06/97
    * MODIFIED BY: EN 11/06/97
    *              EN 7/19/00 - fixed to not delete vendor group when remove supplier
    * 			 MV 12/10/01 - Issue 14160 update supplier in APWD
    *			 MV 10/18/02 - 18878 quoted identifier cleanup 
    *
    * USAGE:
    * Assign or remove a specified supplier from all open/held
    * transactions for a specified pay type.
    *
    *  INPUT PARAMETERS
    *   @apco	AP company number
    *   @mth	expense month of trans
    *   @aptrans	transaction to restrict by
    *   @suppgrp	supplier group
    *   @supplier	supplier to assign/remove
    *   @paytype	pay type to restrict on
    *   @optaddremove	'A' to assign supplier, 'R' to remove
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
   *********************************
   **********************************/
   (@apco bCompany = 0, @mth bMonth, @aptrans bTrans, @suppgrp bGroup,
    @supplier bVendor, @paytype tinyint, @optaddremove varchar(1),
    @msg varchar(90) output)
   
   as
   set nocount on
   
   declare @rcode tinyint
   
   select @rcode=0
   
   if @optaddremove='A'
   	BEGIN
   	update bAPWD
   		set VendorGroup=@suppgrp, Supplier=@supplier
   		from bAPWD d join bAPTD t on d.APCo=t.APCo and
   		d.Mth=t.Mth and d.APTrans=t.APTrans and d.APLine=t.APLine and d.APSeq = t.APSeq 
   		where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and t.PayType=@paytype
   	/*update bAPTD
   		set VendorGroup=@suppgrp, Supplier=@supplier
   		where APCo=@apco and Mth=@mth and APTrans=@aptrans and PayType=@paytype
   		and Status<>3 and Status<>4 and Supplier is null*/
   	END
   if @optaddremove='R'
   	BEGIN
   	/*update bAPTD
   		set Supplier=null
   		where APCo=@apco and Mth=@mth and APTrans=@aptrans and PayType=@paytype
   		and Status<>3 and Status<>4 and VendorGroup=@suppgrp and
   		Supplier=@supplier*/
   
   	update bAPWD
   		set Supplier=null
   		from bAPWD d join bAPTD t on d.APCo=t.APCo and d.Mth=t.Mth and d.APTrans=t.APTrans and
   		d.APLine=t.APLine and d.APSeq = t.APSeq  
   		where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and t.PayType=@paytype
   	END
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPAssignRemoveSupplier] TO [public]
GO
