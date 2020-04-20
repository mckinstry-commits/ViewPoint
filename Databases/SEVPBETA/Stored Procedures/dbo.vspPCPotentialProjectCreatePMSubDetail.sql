SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspPCPotentialProjectCreatePMSubDetail]
  /***********************************************************
   * CREATED BY:	GP	12/06/2010
   * REVIEWD BY:	TL	12/06/2010	
   * MODIFIED BY:	
   *
   *				
   * USAGE:
   * Creates PM Subcontract Detail.
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
  
  	(@JCCo bCompany, @PhaseGroup bGroup, @PotentialProject varchar(20),
  	@Project bJob, @CreateSubDetailYN bYN, @SubDetailCostType bJCCType,
  	@NewRecordKeyID bigint output, @SLItemCount int output, @msg varchar(255) output)
  as
  set nocount on

	declare @rcode int, @SLCo bCompany
	select @rcode = 0

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

--check to make sure job already exists
if not exists (select top 1 1 from dbo.bJCJM where JCCo = @JCCo and Job = @Project)
begin
	select @msg = 'Project must already exist.', @rcode = 1
	goto vspexit
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
	
	--insert subcontract detail lines
	if not exists (select top 1 1 from dbo.bPMSL where PMCo = @JCCo and Project = @Project)
	begin
		insert bPMSL (PMCo, Project, Seq, RecordType, PhaseGroup, Phase, CostType, VendorGroup, Vendor, 
			SLCo, SLItemDescription, SLItemType, Units, UM, UnitCost, Amount, SendFlag)
		select @JCCo, @Project, row_number() over(order by c.CoverageJCCo asc, c.CoveragePotentialProject), 'O', 
			c.CoveragePhaseGroup, c.CoveragePhase, @SubDetailCostType, c.CoverageVendorGroup, c.CoverageVendor,
			@SLCo, p.[Description], 1, 0, 'LS', 0, isnull(c.BidAmount,0), 'Y'
		from PCBidCoverage c	
		join vPCBidPackage p on p.JCCo = c.JCCo and p.PotentialProject = c.CoveragePotentialProject and p.BidPackage = c.CoverageBidPackage	
		where c.CoverageJCCo = @JCCo and c.CoveragePotentialProject = @PotentialProject and c.BidAwarded = 'Y' 
			and c.CoveragePhase is not null 		
	end
	else
	begin
		insert bPMSL (PMCo, Project, Seq, RecordType, PhaseGroup, Phase, CostType, VendorGroup, Vendor, 
			SLCo, SLItemDescription, SLItemType, Units, UM, UnitCost, Amount, SendFlag)
		select @JCCo, @Project, isnull(max(s.Seq),0) + row_number() over(order by c.CoverageJCCo asc, c.CoveragePotentialProject), 'O', 
			c.CoveragePhaseGroup, c.CoveragePhase, @SubDetailCostType, c.CoverageVendorGroup, c.CoverageVendor,
			@SLCo, p.[Description], 1, 0, 'LS', 0, isnull(c.BidAmount,0), 'Y'
		from dbo.PCBidCoverage c
		join dbo.bPMSL s on s.PMCo = @JCCo and s.Project = @Project 
		join dbo.vPCBidPackage p on p.JCCo = c.JCCo and p.PotentialProject = c.CoveragePotentialProject and p.BidPackage = c.CoverageBidPackage	
		where c.CoverageJCCo = @JCCo and c.CoveragePotentialProject = @PotentialProject and c.BidAwarded = 'Y' 
			and c.CoveragePhase is not null
		group by c.CoverageJCCo, c.CoveragePotentialProject, c.CoveragePhaseGroup, c.CoveragePhase, c.CoverageVendorGroup,
			c.CoverageVendor, p.[Description], c.BidAmount
	end	
	
	--return how many records inserted for sub detail	
	select @SLItemCount = @@rowcount
		
	--return key id to launch PM Subcontract Detail form
	select @NewRecordKeyID = KeyID from dbo.JCJMPM where JCCo = @JCCo and Job = @Project
end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPCPotentialProjectCreatePMSubDetail] TO [public]
GO
