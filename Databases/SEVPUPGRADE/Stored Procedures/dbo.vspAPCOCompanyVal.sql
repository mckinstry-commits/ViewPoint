SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspAPCOCompanyVal]
/******************************************
 * Created:	 MV 06/28/10 - #134964
 * Modified: KK 04/17/12 - B-08111 Added output parameters for Credit Service enhancement reports
 *
 * Purpose: Validates HQ Company number and returns country specific
 * AP report Titles for AP Company Parameters.
 *
 * Inputs:		
 *	@hqco		Company # 
 *
 * Ouput:		DDFI Validation Parameters: 0,-96,-97,-280,-285,-286,-290,-291
 *				various report types
 *	@msg		Company name or error message
 * 
 * Return code:
 *	0 = success, 1 = failure
 *
 ***********************************************/

(@HQCo bCompany = 0, 
 @CheckReportTitle varchar(60) OUTPUT, 
 @OverFlowReportTitle varchar(60) OUTPUT, 
 @CheckReportTitleByVendor varchar(60) OUTPUT, 
 @EFTRemittanceRpt varchar(60) OUTPUT,
 @CreditSvcRemittanceRpt varchar(60) OUTPUT,
 @EFTRemittanceRptByVendor varchar(60) OUTPUT, 
 @CreditSvcRemittanceRptByVendor varchar(60) OUTPUT, 
 @Msg varchar(60) output)
 
AS
SET NOCOUNT ON

DECLARE @HQDefaultCountry varchar(3)

	-- validate HQCo
	IF @HQCo = 0
	BEGIN
		SELECT @Msg = 'Missing HQ Company#!'
--		RAISERROR (@Msg, 15,1)
		RETURN 1
	END
	
	SELECT @Msg = Name, @HQDefaultCountry = DefaultCountry
	FROM dbo.bHQCO WHERE @HQCo = HQCo
	IF @@rowcount = 0
		BEGIN
		SELECT @Msg = 'Not a valid HQ Company!'
--		RAISERROR (@Msg,15,1)
		RETURN 1
		END
	ELSE
		BEGIN
		-- return country specific report titles
		IF @HQDefaultCountry = 'US'
			BEGIN
			SELECT	@CheckReportTitle = Title FROM dbo.RPRT WHERE ReportID = 18 -- AP Check Print
			SELECT	@OverFlowReportTitle = Title FROM dbo.RPRT WHERE ReportID = 17	--'AP Check OverFlow'
			SELECT	@CheckReportTitleByVendor = Title FROM dbo.RPRT WHERE ReportID = 1033 --'AP Check By Vendor'
			SELECT	@EFTRemittanceRpt = Title FROM dbo.RPRT WHERE ReportID = 26 --'AP EFT Remittance'
			SELECT	@CreditSvcRemittanceRpt = Title FROM dbo.RPRT WHERE ReportID = 1209 --'AP Credit Service Remittance'
			SELECT	@EFTRemittanceRptByVendor = Title FROM dbo.RPRT WHERE ReportID = 1032 --'AP EFT Remittance by Vendor'
			SELECT	@CreditSvcRemittanceRptByVendor = Title FROM dbo.RPRT WHERE ReportID = 1210 --'AP Credit Service Remittance by Vendor'			
			END
		IF @HQDefaultCountry = 'AU'
			BEGIN
			SELECT	@CheckReportTitle = Title FROM dbo.RPRT WHERE ReportID = 1056 --AP Cheque Print - Australia'
			SELECT	@OverFlowReportTitle = Title FROM dbo.RPRT WHERE ReportID = 1103 -- 'AP Cheque Overflow - Australia'
			SELECT	@CheckReportTitleByVendor = Title FROM dbo.RPRT WHERE ReportID = 1100 -- 'AP Cheque Print By Vendor'
			SELECT	@EFTRemittanceRpt =	Title FROM dbo.RPRT WHERE ReportID = 1096	--'AP EFT Remittance - Australia'
			SELECT	@CreditSvcRemittanceRpt = Title FROM dbo.RPRT WHERE ReportID = 1209 --'AP Credit Service Remittance'
			SELECT	@EFTRemittanceRptByVendor = Title FROM dbo.RPRT WHERE ReportID = 1098 --'AP EFT Remittance Vendor - Australia'
			SELECT	@CreditSvcRemittanceRptByVendor = Title FROM dbo.RPRT WHERE ReportID = 1210 --'AP Credit Service Remittance by Vendor'			
			END 
		IF @HQDefaultCountry = 'CA'
			BEGIN
			SELECT	@CheckReportTitle = Title FROM dbo.RPRT WHERE ReportID = 1028 --AP Cheque Report - Canada
			SELECT	@OverFlowReportTitle = Title FROM dbo.RPRT WHERE ReportID = 1104 -- 'AP Cheque Overflow - Canada 
			SELECT	@CheckReportTitleByVendor = Title FROM dbo.RPRT WHERE ReportID = 1101 -- 'AP Cheque Print By Vendor'
			SELECT	@EFTRemittanceRpt =	Title FROM dbo.RPRT WHERE ReportID = 1097	--'AP EFT Remittance - Canada'
			SELECT	@CreditSvcRemittanceRpt = Title FROM dbo.RPRT WHERE ReportID = 1209 --'AP Credit Service Remittance'
			SELECT	@EFTRemittanceRptByVendor = Title FROM dbo.RPRT WHERE ReportID = 1099 --'AP EFT Remittance Vendor - Canada'
			SELECT	@CreditSvcRemittanceRptByVendor = Title FROM dbo.RPRT WHERE ReportID = 1210 --'AP Credit Service Remittance by Vendor'			
			END 
		END

RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspAPCOCompanyVal] TO [public]
GO
