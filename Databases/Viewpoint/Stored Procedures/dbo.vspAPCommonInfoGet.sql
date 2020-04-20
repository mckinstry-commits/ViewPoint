SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspAPCommonInfoGet]
/********************************************************
* CREATED BY: 	MV 11/15/04
* MODIFIED BY:	GG 02/24/06 - removed cursor used to get Retainage Pay Types
*				MV 09/27/06 - #27760 APPayInit recode - added UseTaxDiscYN to the OUTPUT params
*				MV 01/09/07 - #122337 return Compliance flags for allowing trans in pay batch
*				MV 02/27/09 - #129891 - return APCO EMAIL fields
*				MV 02/11/10 - #136500 - return TaxBasisNetRetgYN from APCO
*				MV 07/01/10 - #134964 - return country specific report ids 
*				TJL 07/15/10 - #134964 - Made Rejection repairs when APCO Report Titles are empty    
*				EN 12/20/11 TK-10795 return APCreditService from APCO  
*				KK 01/23/2012 TK-11581 added APCO_CSCMCo and APCo_CSCMAcct to OUTPUT param list 
*								and reformatted code as per best practice         
* USAGE:
* 	Retrieves common info from AP Company for use in various
*	form's DDFH LoadProc field 
*
* INPUT PARAMETERS:
*	@co			AP Co#
*
* OUTPUT PARAMETERS:
*	@jcco				JC Co#
*	@emco				EM Co#
*	@inco				IN Co#
*	@glco				GL Co#
*	@cmco				CM Co#
*	@cmacct				CM Account
*	@paycategoryyn		Pay Categories option
*	@netamtoptyn		Net Amount to Subledgers options
*	@icrptyn			IC Reporting option
*	@vendorgroup		Vendor Group
*	@custgroup			Customer Group
*	@taxgroup			Tax Group
*	@apupdatepm			Update PM option
*	@apretholdcode		Retainage Hold Code
*	@apretpaytype		Retainage Pay Type
*	@appcretpaytypes	Pay Category Retainage Pay Types (comma separated string)
*	@phasegrp			Phase Group
*	@checkreportId		Check Report ID
*	@overflowreportId	Overflow Stub Report ID
*	@usetaxdiscyn		UseTaxDisc
*	...
*	@apcreditservice	set to non-zero value based on credit service selected in APCO ... =0 if none selected
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
 (@co bCompany=0,
	@jcco bCompany = NULL OUTPUT,
	@emco bCompany = NULL OUTPUT,
	@inco bCompany = NULL OUTPUT,
	@glco bCompany = NULL OUTPUT,
	@cmco bCompany = NULL OUTPUT,
	@cmacct bCMAcct = NULL OUTPUT,
	@paycategoryyn bYN = NULL OUTPUT,
	@netamtoptyn bYN = NULL OUTPUT,
	@icrptyn bYN = NULL OUTPUT,
	@vendorgroup bGroup = NULL OUTPUT,
	@custgroup bGroup = NULL OUTPUT,
	@taxgroup bGroup = NULL OUTPUT,
	@apupdatepm bYN = NULL OUTPUT,
	@apretholdcode bHoldCode = NULL OUTPUT,
	@apretpaytype int = NULL OUTPUT,
	@appcretpaytypes varchar(200) = NULL OUTPUT,
	@phasegrp bGroup = NULL OUTPUT,
	@checkreportId int OUTPUT,		-- Check Print Report ID
	@overflowreportId int OUTPUT,	-- Overflow Report ID
	@usetaxdiscyn bYN OUTPUT,
	@allallowpayyn bYN OUTPUT,
	@poallowpayyn bYN OUTPUT,
	@slallowpayyn bYN OUTPUT,
	@hqcodefaultcountry varchar(2) = NULL OUTPUT,
	@AttachVendorPayInfoYN bYN OUTPUT,
	@VendorPayAttachTypeId int OUTPUT,
	@CheckReportByVendorID int OUTPUT,	-- Check Print Report by Vendor ID
	@EFTRemittanceReportID int OUTPUT,	-- EFT Remittance Report ID
	@EFTRemittanceReportByVendorID int OUTPUT,	-- EFT Remittance Report by Vendor ID
	@APCOTaxBasisNetRetgYN bYN OUTPUT,
	@PaymentPreviewReportID int OUTPUT,		-- Payment Preview Report ID
	@apcreditservice tinyint OUTPUT,
	@cscmco bCompany OUTPUT,
    @cscmacct bCMAcct OUTPUT,
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
		@EFTRemittanceReportByVendor bReportTitle

SELECT @rcode = 0, @opencursor = 0 

-- Get info from HQCO
SELECT  @vendorgroup =VendorGroup, 
		@custgroup = CustGroup, 
		@taxgroup=TaxGroup, 
		@phasegrp = PhaseGroup,
		@hqcodefaultcountry=DefaultCountry
FROM bHQCO WITH(NOLOCK)
WHERE HQCo = @co 

-- Get info from APCO
SELECT	@jcco=JCCo,			
		@emco=EMCo, 
		@inco=INCo, 
		@glco=GLCo,
		@cmco=CMCo, 
		@cmacct = CMAcct,
		@paycategoryyn=PayCategoryYN,
		@netamtoptyn=NetAmtOpt, 
		@icrptyn = ICRptYN, 
		@apretholdcode=RetHoldCode,
		@apretpaytype=RetPayType, 
		@usetaxdiscyn = UseTaxDiscountYN,
		@allallowpayyn=AllAllowPayYN, 
		@poallowpayyn=POAllowPayYN ,
		@slallowpayyn=SLAllowPayYN,
		@AttachVendorPayInfoYN = AttachVendorPayInfoYN, 
		@VendorPayAttachTypeId = VendorPayAttachTypeID,
		@checkreporttitle = CheckReportTitle, 
		@overflowreporttitle=OverFlowReportTitle,
		@CheckReportTitleByVendor = CheckReportTitleByVendor, 
		@EFTRemittanceReport= EFTRemittanceReport,
		@EFTRemittanceReportByVendor = EFTRemittanceReportByVendor, 
		@APCOTaxBasisNetRetgYN=TaxBasisNetRetgYN,
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

-- Payment Preview Report Id - This report is not country specific at this time, but could be in the future.
SELECT @PaymentPreviewReportID = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 54		--AP Payment Preview 
		WHEN @hqcodefaultcountry = 'AU' THEN 54		--AP Payment Preview - Australia 
		WHEN @hqcodefaultcountry = 'CA' THEN 54		--AP Payment Preview - Canada
	END

-- Get APUpdatesPM flag from PMCO - per Carol get the first one where APCo=@co
select @apupdatepm = (select top 1 APVendUpdYN from bPMCO where APCo=@co order by PMCo asc)
if @@rowcount=0	select @apupdatepm = 'N'

set @appcretpaytypes = ''

select @appcretpaytypes = @appcretpaytypes + ',' + convert(varchar, RetPayType)
from bAPPC (nolock) where APCo = @co and RetPayType is not NULL
group by RetPayType	-- group by to eliminate duplicates

--strip leading character (,) from string of retainage pay types
if len(@appcretpaytypes)>0 select @appcretpaytypes = substring(@appcretpaytypes,2,len(@appcretpaytypes))
  
vspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspAPCommonInfoGet] TO [public]
GO
