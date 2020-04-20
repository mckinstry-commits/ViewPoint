SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[vspHQAP1099ExportCorrectedTrans2Update]
    /************************************
    * Created: 11/05/09 MV
    * Modified:		10/19/11 - MV - TK-09070 get mailing address from APVM V1099AddressSeq else APVM Payment Address

    *
    *	For Error Type 2 corrected filings -updates  APFT 1099 old vendor info to
	*	current vendor info from APVM, sets Corrected flag to 'N'
    *
    * Pass in:
    *	@APCo        AP Company
    *	@YEMO        YEMO
    *
    * Returns:
    *	Data related to the exporting of 1099 data
    *
    ***********************************/
    (@APCo bCompany, @Yemo bMonth, @errortype tinyint)
   
   as
   set nocount on
	-- Update APFT with current vendor info, set corrected = N
	--Update a SET OldVendorName=v.Name, OldVendorAddr=v.Address, OldVendorCity=v.City, OldVendorState=v.State, OldVendorZip=v.Zip,
	--	OldVendorTaxId=v.TaxId, CorrectedFilingYN='N'
	--From dbo.bAPFT a 
	--join dbo.bAPVM v on v.VendorGroup=a.VendorGroup and v.Vendor=a.Vendor
	--where a.APCo = @APCo and a.YEMO = @Yemo and v.V1099YN = 'Y' and a.CorrectedFilingYN = 'Y' and
	--	a.CorrectedErrorType = @errortype
	

	Update a SET 
	OldVendorName=v.Name,
	OldVendorAddr= ISNULL(d.Address,v.Address),
	OldVendorCity= ISNULL(d.City,v.City),
	OldVendorState= ISNULL(d.State, v.State),
	OldVendorZip= ISNULL(d.Zip,v.Zip),
	OldVendorTaxId=v.TaxId,
	CorrectedFilingYN='N'
	From dbo.bAPFT a
	Join dbo.bAPVM v on v.VendorGroup=a.VendorGroup and v.Vendor=a.Vendor
	LEFT JOIN dbo.bAPAA d ON d.VendorGroup = a.VendorGroup and d.Vendor = a.Vendor AND v.V1099AddressSeq = d.AddressSeq
	where a.APCo = @APCo and a.YEMO = @Yemo and v.V1099YN = 'Y' and a.CorrectedFilingYN = 'Y' and
		a.CorrectedErrorType = @errortype
   

 
GO
GRANT EXECUTE ON  [dbo].[vspHQAP1099ExportCorrectedTrans2Update] TO [public]
GO
