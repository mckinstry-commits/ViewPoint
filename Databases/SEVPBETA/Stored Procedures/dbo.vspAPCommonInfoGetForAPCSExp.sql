SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspAPCommonInfoGetForAPCSExp]
/********************************************************
* CREATED BY: 	EN 04/02/12 B-08617/TK-13167
* MODIFIED BY:	KK 04/06/12 B-08616/TK-12875 Modified to check for credit service Co and Acct
*				EN 5/1/2012 B-09179/TK-14323 changed @tcco from smallint to int to resolve arithmetic overflow error
*				CHS	05/3/2012	B-09226 added code to retreive the Remittance Report By Vendor ID
*        
* USAGE:
* 	Retrieves common info for form frmAPCreditServiceExportFileGenerate
*
* INPUT PARAMETERS:
*	@co			AP Co#
*
* OUTPUT PARAMETERS:
*	@apcreditservice	AP Credit Service from APCO
*	@cscmco				Credit Service CM Co# from APCO
*	@cscmacct			Credit Service CM Acct from APCO
*	@cdacctcode			Comdata Account Code from APCO
*	@cdcustid			Comdata Customer ID from APCO
*	@tcco				T-Chek Company Number
*	@nextcmref			next available Credit Service CMRef #
*	@msg				Error Message if any
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@co bCompany = 0,
 @apcreditservice tinyint OUTPUT,
 @cscmco bCompany OUTPUT,
 @cscmacct bCMAcct OUTPUT,
 @cdacctcode varchar(5) OUTPUT,
 @cdcustid varchar(10) OUTPUT,
 @tcco int OUTPUT,
 @nextcmref bCMRef OUTPUT,
 @CSRemittanceReportByVendorID int OUTPUT,
 @VendorPayAttachTypeId int OUTPUT,
 @AttachVendorPayInfoYN bYN OUTPUT, 
 @msg varchar(100) OUTPUT)

AS
SET NOCOUNT ON

DECLARE @CSRemittanceReportByVendor bReportTitle, @hqcodefaultcountry varchar(2)

-- Get info from APCO
SELECT	@apcreditservice = APCreditService,
		@cscmco = CSCMCo,
		@cscmacct = CSCMAcct,
		@cdacctcode = CDAcctCode,
		@cdcustid = CDCustID,
		@tcco = TCCo,
		@CSRemittanceReportByVendor = CreditSvcRemittanceReportByVendor,
		@VendorPayAttachTypeId = VendorPayAttachTypeID,
		@AttachVendorPayInfoYN = AttachVendorPayInfoYN
FROM dbo.APCO WITH(NOLOCK)
WHERE APCo = @co

IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Company# ' + convert(varchar,@co) + ' not setup in AP'
	RETURN 1
END

IF @cscmacct IS NULL
BEGIN
	SELECT @msg = 'Missing Credit Service CM Account in AP Company Parameters '
	RETURN 1
END

IF @cscmco IS NULL 
BEGIN
	SELECT @msg = 'Missing CM Company in AP Company Parameters '
	RETURN 1
END

-- Get next available Credit Service CM Reference #
DECLARE @rcode int

EXEC	@rcode = [dbo].[vspAPCSCMRefGenVal]
		@cmco = @cscmco,
		@cmacct = @cscmacct,
		@begincmref = NULL,
		@overlookbatch = 'N',
		@mth = NULL,
		@batchid = NULL,
		@nextcmref = @nextcmref OUTPUT,
		@msg = @msg OUTPUT
		

-- Get info from HQCO
SELECT  @hqcodefaultcountry=DefaultCountry
FROM bHQCO WITH(NOLOCK)
WHERE HQCo = @co

		
-- CS Remiitance by Vendor Report Id
SELECT @CSRemittanceReportByVendorID=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@CSRemittanceReportByVendor)
IF ISNULL(@CSRemittanceReportByVendorID, 0) = 0
BEGIN
	SELECT @CSRemittanceReportByVendorID = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 1210	--AP CS Remittance Vendor
		WHEN @hqcodefaultcountry = 'AU' THEN 1210	--AP CS Remittance Vendor - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1210	--AP CS Remittance Vendor - Canada
	END
END		

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspAPCommonInfoGetForAPCSExp] TO [public]
GO
