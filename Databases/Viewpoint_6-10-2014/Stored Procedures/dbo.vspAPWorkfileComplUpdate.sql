SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspAPWorkfileComplUpdate]
   /**********************************************************************
    * CREATED BY: MV 09/27/07
    * MODIFIED By : 
    *
    * USAGE: Called by AP PaymentWorkfile to check if a transaction is in compliance.
    * Updates APWD detail and header to Complied = Y.  If a Workfile transaction is 
	* out of compliance and the user cures the compliance issue, if the 'PayYN' flag is checked,
	* this stored proc reevaluates the transaction and updates the header and lines as 'in compliance'
	* and updates the header or line as 'in compliance' which allows the transaction to be paid.
    *
    * INPUT PARAMETERS
    *   APCo, Transaction Mth, Transaction APTrans, APPayWorkfile UserID      
    *
    * OUTPUT PARAMETERS
    *	errmsg if vendor is out of compliance
    * RETURN VALUE
    *   0 Success
    *   1 fail
    **********************************************************************/
   
   (@apco bCompany, @mth bMonth = null, @aptrans bTrans,@userid bVPUserName,
	 @msg varchar(255) output)

   as
   
   set nocount on
   
	declare @rcode int, @invdate bDate,@vendorgroup bGroup, @vendor bVendor,@compliedyn bYN
	select @rcode = 0, @compliedyn = 'N'

	--select InvDate from APTH	
	select @invdate= InvDate,@vendorgroup=VendorGroup,@vendor=Vendor
			 from APTH where APCo=@apco and Mth=@mth and APTrans=@aptrans
 
	-- check if vendor is out of compliance
	if exists(select 1 from bAPVC v join bHQCP h on v.CompCode=h.CompCode
		where v.APCo=@apco and v.VendorGroup=@vendorgroup and v.Vendor=@vendor and h.AllInvoiceYN='Y'
		and v.Verify='Y' and ((CompType='D' and (ExpDate<@invdate or
		ExpDate is null)) or (CompType='F' and (Complied='N' or Complied is null))))
			begin
			select @rcode=5 --return general failure
			goto vspexit
			end
	else -- vendor is in compliance
		begin
		-- update complied flag in bAPWD for PO lines that are in compliance
		update APWD set CompliedYN='Y' from APWD d join APTL l on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine
		 where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.UserId=@userid and
		(l.LineType = 6 and not exists(select * from POCT join HQCP on HQCP.CompCode=POCT.CompCode
			where POCo=l.APCo and POCT.PO=l.PO and POCT.Verify='Y' and 
			((HQCP.CompType='D' and (POCT.ExpDate<@invdate or ExpDate is null))or
			 (HQCP.CompType='F' and (POCT.Complied='N' or POCT.Complied is null)))))
		if @@rowcount > 0 select @compliedyn = 'Y'
	
	    -- update complied flag in bAPWD for SL lines that are in compliance
		update APWD set CompliedYN='Y' from APWD d join APTL l on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine
		 where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.UserId=@userid and
		l.LineType = 7 and not exists(select * from SLCT join HQCP on HQCP.CompCode=SLCT.CompCode
			where SLCo=l.APCo and SLCT.SL=l.SL and SLCT.Verify='Y' and
		 ((HQCP.CompType='D' and (SLCT.ExpDate<@invdate or ExpDate is null))
			or(HQCP.CompType='F' and (SLCT.Complied='N' or SLCT.Complied is null))))
		if @@rowcount > 0 select @compliedyn = 'Y'
	

		-- update complied flag on other lines 
		Update APWD set CompliedYN='Y' from APWD d join APTL l on d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine
		 where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.UserId=@userid and d.CompliedYN='N'
			and (l.LineType <> 6 and l.LineType <> 7)
		if @@rowcount > 0 select @compliedyn = 'Y'

		-- now update complied flag in header
		if @compliedyn = 'Y'
		begin
		update APWH set CompliedYN='Y' where APCo=@apco and Mth=@mth and APTrans=@aptrans
		end
		end

   vspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPWorkfileComplUpdate] TO [public]
GO
