SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPRCOCompanyVal]
/******************************************
* Created:		CHS 11/30/10 - #140434
* Modified: 
*
* Purpose: Validates HQ Company number and returns country specific
* PR report Titles for PR Company Parameters.
*
* Note: Check Print Stub is selected over Check Print in that it works better for implementation team.
*
* Inputs:
*	@hqco		Company # 
*
* Ouput:
*	various report types
*	@msg		Company name or error message
* 
* Return code:
*	0 = success, 1 = failure
*
***********************************************/

(@HQCo bCompany = 0, 
	@CheckReportTitle varchar(60) output,
	@CheckReportTitleByempl varchar(60) output, 
	@EFTRemittanceRpt varchar(60) output, 
	@EFTRemittanceRptByEmpl varchar(60) output, 
	@Msg varchar(60) output)
	
AS
SET NOCOUNT ON

DECLARE @HQDefaultCountry varchar(3)

	-- validate HQCo
	IF @HQCo = 0
	BEGIN
		SELECT @Msg = 'Missing HQ Company#!'
		RETURN 1
	END
	
	SELECT @Msg = Name, @HQDefaultCountry = DefaultCountry
	FROM dbo.bHQCO WHERE @HQCo = HQCo
	IF @@rowcount = 0
		BEGIN
		SELECT @Msg = 'Not a valid HQ Company!'
		RETURN 1
		END
	ELSE
		BEGIN
		-- return country specific report titles
		IF @HQDefaultCountry = 'US'
			BEGIN
			--SELECT	@CheckReportTitle = Title FROM dbo.RPRT WHERE ReportID = 772 -- PR Check Print
			SELECT	@CheckReportTitle = Title FROM dbo.RPRT WHERE ReportID = 773 -- PR Check Print Stub		
			SELECT	@CheckReportTitleByempl = Title FROM dbo.RPRT WHERE ReportID = 1035 --'PR Check By Employee'
			SELECT	@EFTRemittanceRpt = Title FROM dbo.RPRT WHERE ReportID = 800 --'PR EFT Remittance'
			SELECT	@EFTRemittanceRptByEmpl = Title FROM dbo.RPRT WHERE ReportID = 1036 --'AP EFT Remittance Employee'
			END
		IF @HQDefaultCountry = 'CA'
			BEGIN
			--SELECT	@CheckReportTitle = Title FROM dbo.RPRT WHERE ReportID = 1037 --PR Cheque Print - Australia'
			SELECT	@CheckReportTitle = Title FROM dbo.RPRT WHERE ReportID = 1038 --PR Cheque Print Stub - Australia'			
			SELECT	@CheckReportTitleByempl = Title FROM dbo.RPRT WHERE ReportID = 1039 -- 'PR Cheque Print By Employee'
			SELECT	@EFTRemittanceRpt =	Title FROM dbo.RPRT WHERE ReportID = 1040	--'PR EFT Remittance - Australia'
			SELECT	@EFTRemittanceRptByEmpl = Title FROM dbo.RPRT WHERE ReportID = 1041 --'PR EFT Remittance Employee - Australia'
			END 
		IF @HQDefaultCountry = 'AU'
			BEGIN
			--SELECT	@CheckReportTitle = Title FROM dbo.RPRT WHERE ReportID = 1079 --PR Cheque Report - Canada
			SELECT	@CheckReportTitle = Title FROM dbo.RPRT WHERE ReportID = 1076 --PR Cheque Report Stub - Canada			
			SELECT	@CheckReportTitleByempl = Title FROM dbo.RPRT WHERE ReportID = 1075 -- 'PR Cheque Print By Employee'
			SELECT	@EFTRemittanceRpt =	Title FROM dbo.RPRT WHERE ReportID = 1078	--'PR EFT Remittance - Canada'
			SELECT	@EFTRemittanceRptByEmpl = Title FROM dbo.RPRT WHERE ReportID = 1077 --'PR EFT Remittance Employee - Canada'
			END 
		END

RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspPRCOCompanyVal] TO [public]
GO
