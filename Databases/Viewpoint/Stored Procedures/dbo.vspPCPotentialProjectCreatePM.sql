SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPCPotentialProjectCreatePM]
  /***********************************************************
   * CREATED BY:	GP	11/17/2010
   * REVIEWD BY:	
   * MODIFIED BY:	GP	12/01/2010 - added create contract and validation
   *				GP	12/02/2010 - added create subcontract detail and validation
   *				GP	12/07/2010 - added assign firm contacts
   *				GF  05/04/2011 - TK-04879 tax group is missing
   *				JG	07/25/2011 - TK-07042 - Adding Potential Project to PM Contract when created.
   *
   *				
   * USAGE:
   * Creates PM Project and JC Job from PC Potential Projects.
   *
   * INPUT PARAMETERS
   *	JCCo   
   *	PotentialProject
   *	Project
   *	
   *
   * OUTPUT PARAMETERS
   *   @msg      Description of Department if found.
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/ 
  
  	(@JCCo bCompany, @PhaseGroup bGroup, @VendorGroup bGroup, @PotentialProject varchar(20),
  	@Project bJob, @Description bItemDesc, @Contract bContract, @ContractDesc bItemDesc, 
  	@Department bDept, @CreateSubDetailYN bYN, @SubDetailCostType bJCCType, @AssignFirmContactsYN bYN,
  	@NewRecordKeyID bigint output, @SLItemCount int output, @msg varchar(255) output)
  as
  set nocount on

	declare @rcode int, @TempJob bJob, @DefaultBillType bBillType, @SLCo bCompany
	select @rcode = 0, @SLItemCount = 0

--------------
--VALIDATION--
--------------
if isnull(@JCCo,'') = ''
begin
	select @msg = 'Missing JC Company.', @rcode = 1
	goto vspexit
end

if isnull(@PotentialProject,'') = ''
begin
	select @msg = 'Missing Potential Project.', @rcode = 1
	goto vspexit
end

if isnull(@Project,'') = ''
begin
	select @msg = 'Missing Project.', @rcode = 1
	goto vspexit
end	

if isnull(@Contract,'') = ''
begin
	select @msg = 'Missing Contract.', @rcode = 1
	goto vspexit	
end

if isnull(@Department,'') = ''
begin
	select @msg = 'Missing Department.', @rcode = 1
	goto vspexit	
end

--check to make sure project hasn't been created from this potential project
select @TempJob = j.Job 
from dbo.bJCJM j
join dbo.vPCPotentialWork p on p.KeyID = j.PotentialProjectID
where p.JCCo = @JCCo and p.PotentialProject = @PotentialProject and j.PCVisibleInJC = 'Y'

if @TempJob is not null
begin
	select @msg = 'Project: ' + @TempJob + ' already created from this Potential Project, please select another.', @rcode = 1
	goto vspexit
end

--check to make sure job doesn't already exist
if exists (select top 1 1 from dbo.bJCJM where JCCo = @JCCo and Job = @Project)
begin
	select @msg = 'Project must not already exist.', @rcode = 1
	goto vspexit
end

--check that contract status is 0
if (select ContractStatus from dbo.bJCCM where JCCo = @JCCo and [Contract] = @Contract) <> 0
begin
	select @msg = 'Contract status must be Pending.', @rcode = 1
	goto vspexit		
end

--check for valid JC Department
if not exists (select * from dbo.bJCDM where JCCo = @JCCo and Department = @Department)
begin
	select @msg = 'Not a valid JC Department.', @rcode = 1
	goto vspexit
end


----------------------
--CREATE PROJECT/JOB--
----------------------

--get keyid to return to form, to load correct project in PM
select @NewRecordKeyID = j.KeyID 
from dbo.bJCJM j
join dbo.vPCPotentialWork p on p.KeyID = j.PotentialProjectID
where p.JCCo = @JCCo and p.PotentialProject = @PotentialProject

update bJCJM
set Job = @Project, [Description] = @Description, PCVisibleInJC = 'Y'
where KeyID = @NewRecordKeyID

--------------------------
--CREATE/ASSIGN CONTRACT--
--------------------------

--If contract already exists, simply assign value to newly created job record.
--If not, create new contract record and assign it to the job.
if exists (select top 1 1 from dbo.bJCCM where JCCo = @JCCo and [Contract] = @Contract)
begin
	update bJCJM
	set [Contract] = @Contract
	where KeyID = @NewRecordKeyID
end
else
begin
	select @DefaultBillType = DefaultBillType from dbo.bJCCO where JCCo = @JCCo
	----TK-04879
	insert bJCCM (JCCo, [Contract], [Description], Department, ContractStatus, TaxInterface, DefaultBillType,
			TaxGroup, CustGroup, PotentialProject)	----TK-07042 07/25/2011
	SELECT @JCCo, @Contract, @ContractDesc, @Department, 0, 'N', @DefaultBillType,
			h.TaxGroup, h.CustGroup, @PotentialProject
	FROM dbo.bHQCO h WHERE h.HQCo = @JCCo
			
	
	update bJCJM
	set [Contract] = @Contract
	where KeyID = @NewRecordKeyID
end

----------------------------
--CREATE SUBCONRACT DETAIL--
----------------------------

if @CreateSubDetailYN = 'Y'
begin
	--check for missing input param values	
	if isnull(@SubDetailCostType,'') = ''
	begin
		select @msg = 'Missing subcontract Cost Type.', @rcode = 1
		goto vspexit
	end
	
	--make sure Cost Type is valid
	if not exists (select * from dbo.bJCCT where PhaseGroup = @PhaseGroup and CostType = @SubDetailCostType)
	begin
		select @msg = 'Not a valid JC Cost Type.', @rcode = 1
		goto vspexit	
	end
	
	--get SL Company for insert
	select @SLCo = APCo from dbo.bPMCO where PMCo = @JCCo
	
	if not exists (select top 1 1 from dbo.bPMSL where PMCo = @JCCo and Project = @Project)
	begin	
		--insert subcontract detail lines
		insert bPMSL (PMCo, Project, Seq, RecordType, PhaseGroup, Phase, CostType, VendorGroup, Vendor, 
			SLCo, SLItemDescription, SLItemType, Units, UM, UnitCost, Amount, SendFlag)
		select @JCCo, @Project, row_number() over(order by c.CoverageJCCo asc, c.CoveragePotentialProject asc), 'O', 
			c.CoveragePhaseGroup, c.CoveragePhase, @SubDetailCostType, c.CoverageVendorGroup, c.CoverageVendor,
			@SLCo, p.[Description], 1, 0, 'LS', 0, isnull(c.BidAmount,0), 'Y'
		from PCBidCoverage c	
		join vPCBidPackage p on p.JCCo = c.JCCo and p.PotentialProject = c.CoveragePotentialProject and p.BidPackage = c.CoverageBidPackage	
		where c.CoverageJCCo = @JCCo and c.CoveragePotentialProject = @PotentialProject and c.BidAwarded = 'Y' 
			and c.CoveragePhase is not null 
		
		--return how many records inserted for sub detail	
		select @SLItemCount = @@rowcount
	end		
end

---------------------------
--ASSIGN PM FIRM CONTACTS--
---------------------------

if @AssignFirmContactsYN = 'Y'
begin
	--assign existing PM Firm Contacts ***Add check that they still exist in bPMPM***
	if not exists (select top 1 1 from dbo.bPMPF where PMCo = @JCCo and Project = @Project)
	begin
		insert bPMPF (PMCo, Project, Seq, VendorGroup, FirmNumber, ContactCode)
		select @JCCo, @Project, row_number() over(order by t.JCCo asc, t.PotentialProject asc), @VendorGroup, t.ContactFirmVendor, t.ContactCode  
		from dbo.vPCPotentialProjectTeam t
		where t.JCCo = @JCCo and t.PotentialProject = @PotentialProject and t.ContactSource = 'PMPM'
			and exists (select top 1 1 from dbo.bPMPM p where p.VendorGroup = @VendorGroup and p.FirmNumber = t.ContactFirmVendor and p.ContactCode = t.ContactCode)
	end
end


vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectCreatePM] TO [public]
GO
