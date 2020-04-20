SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE            proc [dbo].[vspAPEFTCAExport]
    /************************************
    * Created: 12/31/08 - MV #127222
    * Modified:	01/05/11 - MV #142776 added CAShortName, CALongName
	*			3/4/2011 - EN #143404 added EFTSeq and Vendor
	*			07/26/11 - MV #144182 return CARBCFileDescriptor from bCMAC
	*
    * This SP is called from form APEFT to return Canadian EFT info.
    * Any changes here will require changes to the form.
    *
    ***********************************/
    (@apco bCompany, @month bMonth, @batchid bBatchID, @cmco bCompany, @cmacct bCMAcct,@cmref bCMRef)
  
	AS
	SET NOCOUNT ON
	DECLARE @rcode INT
	SELECT @rcode = 0
  
	SELECT c.CAOriginatorId,
		   c.CADestDataCentre,
		   c.CACurrencyCode, 
		   c.BankAcct AS 'CMBankAcct',
		   c.CACMRoutingNbr,
		   c.CAShortName, 
		   c.CALongName,
		   v.RoutingId AS 'PayeeRoutingID',
		   v.BankAcct AS 'PayeeBankAcct',
		   v.Name AS 'PayeeName',
		   a.Amount AS 'Amt',
		   q.Name, 
		   a.Vendor AS 'CustomerNumber', 
		   c.CAEFTFormat, --determines format used in EFT file
		   c.CARBCFileDescriptor
    FROM dbo.bAPPB a WITH (NOLOCK) 
	JOIN bCMAC c WITH (NOLOCK) ON a.CMCo = c.CMCo 
								  AND a.CMAcct = c.CMAcct
	JOIN bAPVM v WITH (NOLOCK) ON v.VendorGroup=a.VendorGroup 
								  AND v.Vendor=a.Vendor
	JOIN bHQCO q WITH (NOLOCK) ON q.HQCo=@cmco
	WHERE a.Co = @apco 
		  AND a.Mth = @month 
		  AND a.BatchId = @batchid 
		  AND a.PayMethod = 'E' 
		  AND a.CMCo=@cmco 
		  AND a.CMAcct = @cmacct 
		  AND a.CMRef=@cmref 
	ORDER BY v.SortName --order assists in generating payment number for RBC format detail record in EFT file

	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPEFTCAExport] TO [public]
GO
