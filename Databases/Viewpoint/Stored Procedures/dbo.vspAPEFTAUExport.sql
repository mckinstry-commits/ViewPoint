SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            proc [dbo].[vspAPEFTAUExport]
    /************************************
    * Created: 08/25/08 - MV #127166
    * Modified: 
	*
    * This SP is called from form APEFT to return Australian EFT info.
    * Any changes here will require changes to the form.
    *
    ***********************************/
    (@apco bCompany, @month bMonth, @batchid bBatchID, @cmco bCompany, @cmacct bCMAcct,@cmref bCMRef)
  
   as
   set nocount on
	declare @rcode int
	select @rcode = 0
  
   select c.AUAccountName,c.AUBSB,c.BankAcct,c.AUBankShortName,c.AUCustomerNumber,
	c.AUReference, c.AUContraRequiredYN,v.AUVendorBSB,v.AUVendorAccountNumber,a.Amount,v.Name,v.AUVendorReference,a.CMRef 
   FROM bAPPB a with (nolock) 
	JOIN bCMAC c with (nolock) ON a.CMCo = c.CMCo and a.CMAcct = c.CMAcct
	JOIN bAPVM v with (nolock) ON v.VendorGroup=a.VendorGroup and v.Vendor=a.Vendor
	WHERE a.Co = @apco and a.Mth = @month and a.BatchId = @batchid and a.PayMethod = 'E' and a.CMCo=@cmco and a.CMAcct = @cmacct and a.CMRef=@cmref 
	ORDER BY v.SortName

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPEFTAUExport] TO [public]
GO
