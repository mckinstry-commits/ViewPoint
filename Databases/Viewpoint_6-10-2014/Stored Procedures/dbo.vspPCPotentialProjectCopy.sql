SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPCPotentialProjectCopy]
  /***********************************************************
   * CREATED BY:	GP	09/16/2010
   * REVIEWD BY:	GF	09/16/2010
   * MODIFIED BY:	GP	09/24/2010 - added overwrite option
   *				JG	11/16/2010 - Changed table from PCPotentialWork to JCJM
   *				GF	11/17/2010 - issue #141031 use date only function
   *				GP	11/22/2010 - added Job to insert, cannot be null. Added PCVisibleInJC to insert, must be 'N'.
   *				GP	12/09/2010 - Issues 142448 & 142455, fixed duplicate record inserts, also allow separate
   *								changes of Info/Bid Info/Forecast Info.
   *				GP	01/06/2010 - Changed table back to PCPotentialWork from JCJM
   *				
   * USAGE:
   * Copies specified items relating to the selected PC Potential Project.
   *
   * INPUT PARAMETERS
   *	JCCo   
   *	FromProject
   *	ToProject
   *	ToDesc
   *	CopyInfo
   *	CopyBidInfo
   *	CopyMWBEGoals
   *	CopyProjectTeam
   *	CopyBidPackages
   *	CopyForecastInfo
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Department if found.
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@JCCo bCompany, @VendorGroup bGroup, @FromProject varchar(20), @ToProject varchar(20), @ToDesc bItemDesc = null,
  		@CopyInfo bYN = null, @CopyBidInfo bYN = null, @CopyMWBEGoals bYN = null, @CopyProjectTeam bYN = null,
  		@CopyBidPackages bYN = null, @CopyForecastInfo bYN = null, @Overwrite bYN = null, @NewOrOverwrite char(1) = null, 
  		@msg varchar(255) output)
  as
  set nocount on

declare @rcode int
select @rcode = 0

--------------
--VALIDATION--
--------------
if @JCCo is null
begin
	select @msg='Missing JC Company!', @rcode = 1
	goto vspexit
end

if @FromProject is null
begin
	select @msg='Missing Copy From - Potential Project!', @rcode = 1
	goto vspexit
end

if @ToProject is null
begin
	select @msg='Missing Copy To - Potential Project!', @rcode = 1
	goto vspexit
end

if @ToProject is null
begin
	select @msg='Missing Copy To - Vendor Group!', @rcode = 1
	goto vspexit
end

--check that copy from and to are different
if @FromProject = @ToProject
begin
	select @msg='Copy From and Copy To Potential Project cannot be the same.', @rcode = 1
	goto vspexit
end

--check that the user project input is valid
if @NewOrOverwrite = 'N'
begin
	if exists (select top 1 1 from dbo.PCPotentialWork where JCCo = @JCCo and PotentialProject = @ToProject)
	begin
		select @msg='The Copy To Potential Project already exists. Enter a new value or use "Copy to Existing" option.', @rcode = 1
		goto vspexit
	end
end
else if @NewOrOverwrite = 'O'
begin
	if not exists (select top 1 1 from dbo.PCPotentialWork where JCCo = @JCCo and PotentialProject = @ToProject)
	begin
		select @msg='The Copy To Potential Project does not exists. Enter a new value or use "Copy to New" option.', @rcode = 1
		goto vspexit
	end
end

--check that from project exists
if not exists (select top 1 1 from dbo.PCPotentialWork where JCCo = @JCCo and PotentialProject = @FromProject)
begin
	select @msg='Copy From - Potential Project does not exist.', @rcode = 1
	goto vspexit
end

--check that to project does not exist - ask to overwrite
if exists (select top 1 1 from dbo.PCPotentialWork where JCCo = @JCCo and PotentialProject = @ToProject) and
	@Overwrite = 'N'
begin
	select @msg='Information for this Potential Project already exists.' + char(13) + char(10) + char(13) + char(10) + 
		'Would you like to overwrite it?', @rcode = 2
	goto vspexit
end

--------
--COPY--
--------

if @Overwrite = 'N'
begin
	--insert new potential project record
	insert vPCPotentialWork (JCCo, VendorGroup, PotentialProject, [Description], StartDate, CompletionDate, RevenueEst, 
		CostEst, ProfitEst, GoProbPct, AwardProbPct, ProjectedChase, AllowForecast)
	values (@JCCo, @VendorGroup, @ToProject, @ToDesc, dbo.vfDateOnly(), dbo.vfDateOnly(), 0, 0, 0, 0, 0, 0, 'N')
	----#141031
end
else
begin
	--delete existing values to copy over
	if @CopyMWBEGoals = 'Y' delete vPCPotentialProjectCertificate where JCCo = @JCCo and PotentialProject = @ToProject
	
	if @CopyProjectTeam = 'Y' delete vPCPotentialProjectTeam where JCCo = @JCCo and PotentialProject = @ToProject
	
	if @CopyBidPackages = 'Y' 
	begin
		delete vPCBidPackageScopeNotes where JCCo = @JCCo and PotentialProject = @ToProject
		delete vPCBidPackageBidList where JCCo = @JCCo and PotentialProject = @ToProject
		delete vPCBidPackageScopes where JCCo = @JCCo and PotentialProject = @ToProject
		delete vPCBidPackage where JCCo = @JCCo and PotentialProject = @ToProject
	end	
end

--Info
if @CopyInfo = 'Y'
begin
	update vPCPotentialWork
	set ProjectDetails = a.ProjectDetails, JobSiteStreet = a.JobSiteStreet, JobSiteCity = a.JobSiteCity, 
		JobSiteState = a.JobSiteState, JobSiteZip = a.JobSiteZip, JobSiteCountry = a.JobSiteCountry, 
		JobSiteRegion = a.JobSiteRegion, ProjectSize = a.ProjectSize, ProjectSizeUM = a.ProjectSizeUM, 
		ProjectValue = a.ProjectValue, PrimeSub = a.PrimeSub, ProjectStatus = a.ProjectStatus, ProjectType = a.ProjectType, 
		ContractType = a.ContractType, BidResult = a.BidResult, BidAwardedDate = a.BidAwardedDate, [Contract] = a.[Contract], 
		AwardedDate = a.AwardedDate, Competitor = a.Competitor, CompetitorBid = a.CompetitorBid
	from (select ProjectDetails, JobSiteStreet, JobSiteCity, 
		JobSiteState, JobSiteZip, JobSiteCountry, JobSiteRegion, ProjectSize, ProjectSizeUM, ProjectValue, PrimeSub, 
		ProjectStatus, ProjectType, ContractType, BidResult, BidAwardedDate, [Contract], AwardedDate, Competitor, 
		CompetitorBid
		from dbo.vPCPotentialWork
		where JCCo = @JCCo and PotentialProject = @FromProject) as a
	where JCCo = @JCCo and PotentialProject = @ToProject  
end		

--Bid Info
if @CopyBidInfo = 'Y'
begin
	update vPCPotentialWork
	set BidNumber = a.BidNumber, BidEstimator = a.BidEstimator, BidJCDept = a.BidJCDept, BidBondReqYN = isnull(a.BidBondReqYN,'N'),
		BidPrequalReqYN = isnull(a.BidPrequalReqYN,'N'), BidDate = a.BidDate, BidTime = a.BidTime, BidPreMeeting = a.BidPreMeeting,
		BidPreMeetingTime = a.BidPreMeetingTime, BidPreMeetingNotes = a.BidPreMeetingNotes, BidStatus = a.BidStatus,
		BidStarted = a.BidStarted, BidCompleted = a.BidCompleted, BidSubmitted = a.BidSubmitted,
		DocOtherPlanLoc = a.DocOtherPlanLoc, DocURL = a.DocURL, BidPlanOrdered = a.BidPlanOrdered,
		BidPlanReceived = a.BidPlanReceived, BidPlanCost = a.BidPlanCost, BidLaborCost = a.BidLaborCost,
		BidLaborHours = a.BidLaborHours, BidMaterialCost = a.BidMaterialCost, BidEquipCost = a.BidEquipCost,
		BidEquipHours = a.BidEquipHours, BidSubCost = a.BidSubCost, BidOtherCost = a.BidOtherCost, 
		BidTotalCost = a.BidTotalCost, BidProfit = a.BidProfit, BidMarkup = a.BidMarkup, BidTotalPrice = a.BidTotalPrice
	from (select BidNumber, BidEstimator, BidJCDept, BidBondReqYN, BidPrequalReqYN, BidDate, BidTime, BidPreMeeting,
		BidPreMeetingTime, BidPreMeetingNotes, BidStatus, BidStarted, BidCompleted, BidSubmitted, DocOtherPlanLoc,
		DocURL, BidPlanOrdered, BidPlanReceived, BidPlanCost, BidLaborCost, BidLaborHours, BidMaterialCost, BidEquipCost,
		BidEquipHours, BidSubCost, BidOtherCost, BidTotalCost, BidProfit, BidMarkup, BidTotalPrice
		from dbo.vPCPotentialWork
		where JCCo = @JCCo and PotentialProject = @FromProject) as a
	where JCCo = @JCCo and PotentialProject = @ToProject
end

--Forecast Info
if @CopyForecastInfo = 'Y'
begin
	update vPCPotentialWork
	----#141031
	set StartDate = isnull(a.StartDate, dbo.vfDateOnly()), CompletionDate = isnull(a.CompletionDate,dbo.vfDateOnly()), 
		RevenueEst = isnull(a.RevenueEst,0), CostEst = isnull(a.CostEst,0), ProfitEst = isnull(a.ProfitEst,0), 
		GoProbPct = isnull(a.GoProbPct,0), AwardProbPct = isnull(a.AwardProbPct,0), 
		ProjectedChase = isnull(a.ProjectedChase,0), ProjectMgr = a.ProjectMgr, AllowForecast = isnull(a.AllowForecast,'N')
	from (select StartDate, CompletionDate, RevenueEst, CostEst, ProfitEst, GoProbPct, AwardProbPct, ProjectedChase,
		ProjectMgr, AllowForecast
		from dbo.vPCPotentialWork
		where JCCo = @JCCo and PotentialProject = @FromProject) as a
	where JCCo = @JCCo and PotentialProject = @ToProject	
end

--MWBE Goals (certificates)
if @CopyMWBEGoals = 'Y'
begin
	insert vPCPotentialProjectCertificate (JCCo, PotentialProject, VendorGroup, CertificateType, GoalPct, ActualPct,
		GoalAmount, ActualAmount, GoalMetYN)
	select @JCCo, @ToProject, VendorGroup, CertificateType, GoalPct, ActualPct, GoalAmount, ActualAmount, GoalMetYN 
		from dbo.vPCPotentialProjectCertificate
		where JCCo = @JCCo and PotentialProject = @FromProject
end

--Project Team
if @CopyProjectTeam = 'Y'
begin
	insert vPCPotentialProjectTeam (JCCo, PotentialProject, Seq, ContactType, ContactSource, ContactCode, ContactName, 
		ContactFirmVendor, ContactFirmName, Phone, Mobile, Fax, Email, WebAddress)
	select @JCCo, @ToProject, Seq, ContactType, ContactSource, ContactCode, ContactName, 
		ContactFirmVendor, ContactFirmName, Phone, Mobile, Fax, Email, WebAddress 
		from dbo.vPCPotentialProjectTeam
		where JCCo = @JCCo and PotentialProject = @FromProject
end

--Bid Packages
if @CopyBidPackages = 'Y'
begin
	insert vPCBidPackage (JCCo, PotentialProject, BidPackage, Description, PackageDetails, SealedBid, BidDueDate, 
		BidDueTime, WalkthroughDate, WalkthroughTime, WalkthroughNotes, PrimaryContact, PrimaryContactPhone, 
		PrimaryContactEmail, SecondaryContact, SecondaryContactPhone, SecondaryContactEmail, Notes)
	select @JCCo, @ToProject, BidPackage, Description, PackageDetails, SealedBid, BidDueDate, 
		BidDueTime, WalkthroughDate, WalkthroughTime, WalkthroughNotes, PrimaryContact, PrimaryContactPhone, 
		PrimaryContactEmail, SecondaryContact, SecondaryContactPhone, SecondaryContactEmail, Notes 
		from dbo.vPCBidPackage
		where JCCo = @JCCo and PotentialProject = @FromProject
	
	--Bid Package Scopes/Phases
	insert vPCBidPackageScopes (JCCo, PotentialProject, BidPackage, Seq, VendorGroup, ScopeCode, PhaseGroup, Phase, Notes)
	select @JCCo, @ToProject, BidPackage, Seq, VendorGroup, ScopeCode, PhaseGroup, Phase, Notes 
		from dbo.vPCBidPackageScopes
		where JCCo = @JCCo and PotentialProject = @FromProject

	--Bid List
	insert vPCBidPackageBidList (JCCo, PotentialProject, BidPackage, VendorGroup, Vendor, ContactSeq, Notes, 
		AttendingWalkthrough, MessageStatus, LastSent)
	select @JCCo, @ToProject, BidPackage, VendorGroup, Vendor, ContactSeq, Notes, 
		AttendingWalkthrough, MessageStatus, LastSent 
		from dbo.vPCBidPackageBidList
		where JCCo = @JCCo and PotentialProject = @FromProject
		
	--Inclusions/Exclusions
	insert vPCBidPackageScopeNotes (JCCo, PotentialProject, BidPackage, Seq, VendorGroup, ScopeCode, PhaseGroup, 
		Phase, Type, Detail, DateEntered, EnteredBy, Notes)
	select @JCCo, @ToProject, BidPackage, Seq, VendorGroup, ScopeCode, PhaseGroup, 
		Phase, Type, Detail, DateEntered, EnteredBy, Notes 
		from dbo.vPCBidPackageScopeNotes
		where JCCo = @JCCo and PotentialProject = @FromProject	
end
	





vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectCopy] TO [public]
GO
