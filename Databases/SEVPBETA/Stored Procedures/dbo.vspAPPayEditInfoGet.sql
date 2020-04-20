SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspAPPayEditInfoGet]
/********************************************************
* CREATED BY: 	KK 04/12/12 - Created to incorporate Credit Service enhancement
* MODIFIED BY:	KK 04/24/12 - B-09140 Modified to accept alternate reports for credit service remittance
*
*      
* USAGE:
* 	Retrieves common info for AP Pay Edit (AKA AP Payment Posting AKA frmPaymentPosting)
*	DDFH LoadProc 
*
* INPUT PARAMETERS:
*	@co			AP Co#
*
*	
* RETURN VALUE:
* 	0 	    Success
*	1		+ Failure message @msg
*
**********************************************************/
 (@co bCompany=0,
  @glco bCompany = NULL OUTPUT,
  @cmco bCompany = NULL OUTPUT,
  @cmacct bCMAcct = NULL OUTPUT,
  @vendorgroup bGroup = NULL OUTPUT,
  @checkreportId int OUTPUT,		-- Check Print Report ID
  @overflowreportId int OUTPUT,	-- Overflow Report ID
  @hqcodefaultcountry varchar(2) = NULL OUTPUT,
  @AttachVendorPayInfoYN bYN OUTPUT,
  @VendorPayAttachTypeId int OUTPUT,
  @CheckReportByVendorID int OUTPUT,	-- Check Print Report by Vendor ID
  @EFTRemittanceReportID int OUTPUT,	-- EFT Remittance Report ID
  @EFTRemittanceReportByVendorID int OUTPUT,	-- EFT Remittance Report by Vendor ID
  @PaymentPreviewReportID int OUTPUT,		-- Payment Preview Report ID
  @apcreditservice tinyint OUTPUT,
  @cscmco bCompany OUTPUT,
  @cscmacct bCMAcct OUTPUT,
  @CreditServiceRemittanceReportID int OUTPUT,	-- Credit Service Remittance Report ID
  @CreditServiceRemittanceReportByVendorID int OUTPUT,	-- Credit Service Remittance Report by Vendor ID
  @msg varchar(100) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @rcode int, 
		@opencursor int, 
		@retpaytype int,
		@checkreporttitle varchar(40),
		@overflowreporttitle varchar(40),
		@CheckReportTitleByVendor bReportTitle, 
		@EFTRemittanceReport bReportTitle, 
		@EFTRemittanceReportByVendor bReportTitle,
		@CreditServiceRemittanceReport bReportTitle, 
		@CreditServiceRemittanceReportByVendor bReportTitle

SELECT @rcode = 0, @opencursor = 0 

-- Get info from HQCO
SELECT  @vendorgroup =VendorGroup, 
		@hqcodefaultcountry=DefaultCountry
FROM bHQCO WITH(NOLOCK)
WHERE HQCo = @co 

-- Get info from APCO
SELECT	@glco=GLCo,
		@cmco=CMCo, 
		@cmacct = CMAcct,
		@AttachVendorPayInfoYN = AttachVendorPayInfoYN, 
		@VendorPayAttachTypeId = VendorPayAttachTypeID,
		@checkreporttitle = CheckReportTitle, 
		@overflowreporttitle=OverFlowReportTitle,
		@CheckReportTitleByVendor = CheckReportTitleByVendor, 
		@EFTRemittanceReport= EFTRemittanceReport,
		@EFTRemittanceReportByVendor = EFTRemittanceReportByVendor, 
		@CreditServiceRemittanceReport = CreditSvcRemittanceReport,
		@CreditServiceRemittanceReportByVendor = CreditSvcRemittanceReportByVendor,
		@apcreditservice = APCreditService,		
		@cscmco = CSCMCo,
		@cscmacct = CSCMAcct                
FROM APCO WITH(NOLOCK)
WHERE APCo=@co
IF @@rowcount = 0
BEGIN
	SELECT @msg = 'Company# ' + convert(varchar,@co) + ' not setup in AP', @rcode = 1
	GOTO vspexit
END

-- get Report ID#s
-- Check Print Report Id
SELECT @checkreportId=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@checkreporttitle)
IF ISNULL(@checkreportId, 0) = 0
BEGIN
	SELECT @checkreportId = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 18		--AP Check Print
		WHEN @hqcodefaultcountry = 'AU' THEN 1056	--AP Cheque Print - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1028	--AP Cheque Report - Canada
	END
END

-- Over flow check stub report id
SELECT @overflowreportId=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@overflowreporttitle)
IF ISNULL(@overflowreportId, 0) = 0
BEGIN
	SELECT @overflowreportId = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 17		--AP Check OverFlow	
		WHEN @hqcodefaultcountry = 'AU' THEN 1103	--AP Cheque Overflow - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1104	--AP Cheque Overflow - Canada
	END
END

-- Check Print by Vendor Report Id
SELECT @CheckReportByVendorID=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@CheckReportTitleByVendor)
IF ISNULL(@CheckReportByVendorID, 0) = 0
BEGIN
	SELECT @CheckReportByVendorID = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 1033	--AP Check By Vendor
		WHEN @hqcodefaultcountry = 'AU' THEN 1100	--AP Cheque Print By Vendor
		WHEN @hqcodefaultcountry = 'CA' THEN 1101	--AP Cheque Print By Vendor
	END
END

-- EFT Remiitance Report Id
SELECT @EFTRemittanceReportID=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@EFTRemittanceReport)
IF ISNULL(@EFTRemittanceReportID, 0) = 0
BEGIN
	SELECT @EFTRemittanceReportID = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 26		--AP EFT Remittance
		WHEN @hqcodefaultcountry = 'AU' THEN 1096	--AP EFT Remittance - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1097	--AP EFT Remittance - Canada
	END
END

-- EFT Remiitance by Vendor Report Id
SELECT @EFTRemittanceReportByVendorID=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@EFTRemittanceReportByVendor)
IF ISNULL(@EFTRemittanceReportByVendorID, 0) = 0
BEGIN
	SELECT @EFTRemittanceReportByVendorID = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 1032	--AP EFT Remittance Vendor
		WHEN @hqcodefaultcountry = 'AU' THEN 1098	--AP EFT Remittance Vendor - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1099	--AP EFT Remittance Vendor - Canada
	END
END

-- CreditService Remiitance Report Id
SELECT @CreditServiceRemittanceReportID=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@CreditServiceRemittanceReport)
IF ISNULL(@CreditServiceRemittanceReportID, 0) = 0
BEGIN
	SELECT @CreditServiceRemittanceReportID = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 1209	--AP CreditService Remittance
		WHEN @hqcodefaultcountry = 'AU' THEN 1209	--AP CreditService Remittance - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1209	--AP CreditService Remittance - Canada
	END
END

-- CreditService Remiitance by Vendor Report Id
SELECT @CreditServiceRemittanceReportByVendorID=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@CreditServiceRemittanceReportByVendor)
IF ISNULL(@CreditServiceRemittanceReportByVendorID, 0) = 0
BEGIN
	SELECT @CreditServiceRemittanceReportByVendorID = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 1210	--AP CreditService Remittance Vendor
		WHEN @hqcodefaultcountry = 'AU' THEN 1210	--AP CreditService Remittance Vendor - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1210	--AP CreditService Remittance Vendor - Canada
	END
END

-- Payment Preview Report Id - This report is not country specific at this time, but could be in the future.
SELECT @PaymentPreviewReportID = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 54		--AP Payment Preview 
		WHEN @hqcodefaultcountry = 'AU' THEN 54		--AP Payment Preview - Australia 
		WHEN @hqcodefaultcountry = 'CA' THEN 54		--AP Payment Preview - Canada
	END
  
vspexit:
return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspAPPayEditInfoGet] TO [public]
GO
