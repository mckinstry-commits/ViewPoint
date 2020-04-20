SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPRCommonInfoGet]
/*************************************
* CREATED: EN 5/20/05
* MODIFIED: GG 03/23/07 - return Check and EFT Report IDs instead of titles
*			EN 7/24/07  added prco validation and error msg
*			mh 09/21/09 - Corrected the report title for Check report by Employee
*			CHS	11/30/2010	- 140434 default report titles by country
* 
* Returns commonly needed info for PR Load Procedures
*
* Note: Check Print Stub is selected over Check Print in that it works better for implementation team.
*
* Input:
*	@prco			PR Company
*
* Output:
*	@premco				EM Company
*	@prapco				AP Company
*	@prglco				GL Company
*	@prcmco				CM Company
*	@emusage			EM Usage posting flag
*	@autoot				Using Auto Overtime
*	@otearncode			Overtime Earnings Code
*	@allownophase		Allow No Phase on Timecards
*	@checkreportid		Report ID# for Checks
*	@eftreportid		Report ID# for EFTs
*	@nonnegcheckprint	Print Non Negotiable Check copies
*	@phasegroup			Phase Group for PR JC Company
*	@vendorgroup		Vendor Group for PR AP Company
*	@ddupshowrates		User's Show Rates flag
*	@HRActiveYN			HR Active flag
*   @attachpaystubyn	PRCo flag to attach check & paystubs to PRSQ
*	@paystubattachid	Attachment Type ID for paystubs
*	@checkreportbyempID	Report ID for Checks by Employee
*	@eftreportbyempID	ReportID for Dir Dep by Employee
*	@msg				Error message				
*
* Return code:
*	0 = success, 1 = error 
**************************************/
(@prco bCompany, 
	@premco bCompany output, 
	@prapco bCompany output, 
	@prglco bCompany output, 
	@prcmco bCompany output, 
	@emusage bYN output, 
	@autoot bYN output, 
	@otearncode bEDLCode output, 
	@allownophase bYN output,
	@checkreportid int output, 
	@eftreportid int output, 
	@nonnegcheckprint bYN output, 
	@phasegroup bGroup output, 
	@vendorgroup bGroup output,
	@ddupshowrates bYN output, 
	@HRActiveYN bYN output, 
	@attachpaystubyn bYN output,
	@paystubattachid int output, 
	@checkreportbyempID int output, 
	@eftreportbyempID int output, 
	@hqcodefaultcountry varchar(2) = null output, 
	@msg varchar(60) output)

as 
set nocount on
declare @rcode int, @checkreporttitle bReportTitle, @eftreporttitle bReportTitle, @prjcco bCompany,
@checkreporttitlebyemp bReportTitle, @eftreporttitlebyemp bReportTitle

select @rcode = 0

-- Get info from HQCO
select @hqcodefaultcountry=DefaultCountry
from bHQCO with (nolock)
where HQCo = @prco 
 
--get PRCO info  
select @prjcco = JCCo, @premco = EMCo, @prapco = APCo, @prglco = GLCo,@prcmco = CMCo,
	@emusage = EMUsage, @autoot = AutoOT, @otearncode = OTEarnCode, @allownophase = AllowNoPhase,
	@checkreporttitle = CheckReportTitle, @eftreporttitle = EFTReportTitle, @nonnegcheckprint = NonNegCheckPrint,
	@attachpaystubyn = AttachPayStubYN, @paystubattachid = PayStubAttachTypeID, 
	@checkreporttitlebyemp = CheckReportTitleByEmp, @eftreporttitlebyemp = EFTReportTitleByEmp 
from dbo.bPRCO (nolock)
where PRCo = @prco
if @@ROWCOUNT = 0
	begin
	select @msg = 'Company# ' + convert(varchar,@prco) + ' not setup in PR', @rcode = 1
  	goto vspexit
  	end

-- get Report ID#s
-- Check Print Report Id
SELECT @checkreportid=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@checkreporttitle)
IF ISNULL(@checkreportid, 0) = 0
BEGIN
	SELECT @checkreportid = 
	CASE
		--WHEN @hqcodefaultcountry = 'US' THEN 772	--PR Check Print - US
		--WHEN @hqcodefaultcountry = 'AU' THEN 1037	--PR Cheque Print - Australia
		--WHEN @hqcodefaultcountry = 'CA' THEN 1079	--PR Cheque Report - Canada
		-- Note: Check Print Stub is selected over Check Print in that it works better for implementation team.
		WHEN @hqcodefaultcountry = 'US' THEN 773	--PR Check Print Stub - US
		WHEN @hqcodefaultcountry = 'AU' THEN 1076	--PR Cheque Print Stub - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1038	--PR Cheque Report Stub - Canada
	END
END

-- EFT Report Id
SELECT @eftreportid=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@eftreporttitle)
IF ISNULL(@eftreportid, 0) = 0
BEGIN
	SELECT @eftreportid = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 800	--PR EFT Report - US
		WHEN @hqcodefaultcountry = 'AU' THEN 1078	--PR EFT Report - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1040	--PR EFT Report - Canada
	END
END

-- Check by Employee Report ID
SELECT @checkreportbyempID=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@checkreporttitlebyemp)
IF ISNULL(@checkreportbyempID, 0) = 0
BEGIN
	SELECT @checkreportbyempID = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 1035	--PR Check by Employee Report - US
		WHEN @hqcodefaultcountry = 'AU' THEN 1075	--PR Cheque by Employee Report - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1039	--PR Cheque Report - Canada
	END
END

-- EFT by Employee Report ID
SELECT @eftreportbyempID=ReportID
FROM dbo.RPRTShared
WHERE Title= RTRIM(@eftreporttitlebyemp)
IF ISNULL(@eftreportbyempID, 0) = 0
BEGIN
	SELECT @eftreportbyempID = 
	CASE
		WHEN @hqcodefaultcountry = 'US' THEN 1036	--PR EFT by Employee Report  - US
		WHEN @hqcodefaultcountry = 'AU' THEN 1077	--PR EFT by Employee Report  - Australia
		WHEN @hqcodefaultcountry = 'CA' THEN 1041	--PR EFT by Employee Report  - Canada
	END
END

--get Phase Group for PR JC Company
if @prjcco is not null
	begin
	select @phasegroup = PhaseGroup
	from dbo.bHQCO (nolock)
	where HQCo = @prjcco
	if @@rowcount = 0
		begin
   		select @msg = 'HQ company ' + convert(varchar(3),@prjcco) + ' does not exist.  Cannot get phase group.', @rcode=1
		goto vspexit
		end
	if @phasegroup is null 
		begin
   		select @msg = 'Missing Phase Group for HQ company ' + convert(varchar(3),@prjcco) , @rcode=1
		goto vspexit
		end
	end

--get Vendor Group from HQCO based on AP Company
if @prapco is not null
	begin
	select @vendorgroup=VendorGroup 
	from dbo.bHQCO (nolock)
	where HQCo = @prapco
	if @@rowcount = 0 
		begin
		select @msg='HQ Company ' + convert(varchar(3),@prapco) + ' does not exist.  Cannot get vendor group.', @rcode=1
		goto vspexit
		end
	if @vendorgroup is Null 
		begin
   		select @msg = 'Missing Vendor Group for HQ company ' + convert(varchar(3),@prapco), @rcode=1
		goto vspexit
		end
	end

--get Show Rates for current user 
select @ddupshowrates=ShowRates
from dbo.vDDUP (nolock)
where VPUserName = suser_sname()

--get HR Active Flag ... flag is automatically 'N' if HR is not set up in DDMO or License Level = 0
select @HRActiveYN = 'N'
select @HRActiveYN = Active
from dbo.vDDMO (nolock)
where Mod = 'HR' and LicLevel > 0


vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRCommonInfoGet] TO [public]
GO
