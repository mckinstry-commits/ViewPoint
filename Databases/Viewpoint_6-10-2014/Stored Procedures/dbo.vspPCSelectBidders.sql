SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspPCSelectBidders]
/***********************************************************
* CREATED BY:		CHS	02/12/2010	- #129020
* MODIFIED BY:		GP	03/19/2010 - 129020 added search criteria Phase and ProjectTypeCode
*					GP	10/5/2010 - TFS #774 added @Qualified and where clause condition
*					JG	12/09/2010 - Added ability to search for multiple scopes, phases, and certificate types
*					JG  12/13/2010 - Changed the state and country to look for vendors in the State tab (PCStates)
*					HH	06/20/2013 - TFS 53697 add phase to result set
*					HH  06/21/2013 - TFS 53590 add preferred vendor filter
*
* USAGE:
* 	Called to fill available Select Bidders list view.
*
* INPUT PARAMETERS:
*   @PotentialProject 
*   @BidPackage 
*   @VendorGroup
*   @Vendor 
*   @ContactSeq 
*   @ContactType 
*   @Country 
*   @State 
*   @Region
*   @LargestEverMin 
*   @LargestEverMax 
*   @LargestYearMin 
*   @LargestYearMax 
*   @IsBidContact 
*   @PhaseGroup 
*   @ProjectType
*   @Qualified 
*   @Scopes 
*   @Phases 
*   @Certificates 
*	@Preferred
* OUTPUT PARAMETERS:
*
*****************************************************/
(@JCCo bCompany = null,
	@PotentialProject varchar(20) = null, 
	@BidPackage varchar(20) = null,
	@VendorGroup bGroup= null, 
	@Vendor bVendor = null, 
	@ContactSeq tinyint =  null,
	@ContactType varchar(10) = null,
	@Country char(2) = null,
	@State varchar(4) = null,
	@Region varchar(10) = null,
	@LargestEverMin numeric(18,0) = null,
	@LargestEverMax numeric(18,0) = null,
	@LargestYearMin numeric(18,0) = null,
	@LargestYearMax numeric(18,0) = null,
	@IsBidContact bYN = null,
	@PhaseGroup bGroup = null,
	@ProjectType varchar(20) = null,
	@Qualified bYN = null,
	@Scopes VARCHAR(MAX) = NULL,
	@Phases VARCHAR(MAX) = NULL,
	@Certificates VARCHAR(MAX) = NULL,
	@Preferred bYN = NULL
	)

AS

declare @rcode int
set @rcode = 0

--Create temporary tables for being searched
DECLARE @ScopeTable TABLE (NAMES VARCHAR(150))
DECLARE @PhaseTable TABLE (NAMES VARCHAR(150))
DECLARE @CertTable TABLE (NAMES VARCHAR(150))

INSERT INTO @ScopeTable
SELECT * FROM vfTableFromArray(@Scopes)

INSERT INTO @PhaseTable
SELECT * FROM vfTableFromArray(@Phases)

INSERT INTO @CertTable
SELECT * FROM vfTableFromArray(@Certificates)


;with bidders
as
(
	select distinct 
		q.VendorGroup as [Vendor Group], 
		q.Vendor as [Vendor], 
		q.Name as [Vendor Name], 
		c.Seq as [Contact],
		c.Name as [Contact Name], 
		c.Phone as [Phone], 
		c.Email as [Email],
		c.Fax as [Fax],
		b.ContactSeq,
		t.PhaseCode as [Phases]
	
	from PCQualifications q with (nolock) 
		left join PCContacts c with (nolock) on q.VendorGroup = c.VendorGroup and q.Vendor = c.Vendor
		left join PCContactTypeCodes ct with (nolock) on c.VendorGroup = ct.VendorGroup and c.ContactTypeCode = ct.ContactTypeCode
		left join PCScopes t with (nolock) on q.VendorGroup = t.VendorGroup and q.Vendor = t.Vendor
		left join PCCertificates m with (nolock) on q.VendorGroup = m.VendorGroup and q.Vendor = m.Vendor
		left join PCWorkRegions r with (nolock) on q.VendorGroup = r.VendorGroup and q.Vendor = r.Vendor
		left join PCStates s with (nolock) on q.VendorGroup = s.VendorGroup and q.Vendor = s.Vendor
		left join PCBidPackageBidList b with (nolock) on  b.VendorGroup = c.VendorGroup and b.Vendor = c.Vendor and b.ContactSeq = c.Seq and b.JCCo = @JCCo and b.PotentialProject = @PotentialProject and b.BidPackage = @BidPackage
		left join PCProjectTypes tc with (nolock) on tc.VendorGroup = q.VendorGroup and tc.Vendor = q.Vendor and tc.ProjectTypeCode = @ProjectType

	where q.VendorGroup = @VendorGroup
		and q.Vendor = isnull(@Vendor, q.Vendor)
		and ((@ContactSeq is null) or (c.Seq = @ContactSeq))
		and ((@ContactType is null) or (ct.ContactTypeCode = @ContactType))
		and ((@Scopes is null) or (t.ScopeCode IN (SELECT * FROM @ScopeTable)))
		and ((@Certificates is null) or (m.CertificateType IN (SELECT * FROM @CertTable)))
		and ((@Country is null) or (s.Country = @Country))
		and ((@State is null) or (s.State = @State))
		and ((@Region is null) or (r.RegionCode = @Region))
		and ((@LargestEverMin is null) or (q.LargestEverAmount >= @LargestEverMin))
		and ((@LargestEverMax is null) or (q.LargestEverAmount <= @LargestEverMax))
		and ((@LargestYearMin is null) or (q.LargestLastYearAmount >= @LargestYearMin))
		and ((@LargestYearMax is null) or (q.LargestLastYearAmount <= @LargestYearMax))
		and b.ContactSeq is null
		and c.Seq is not null
		and ISNULL(q.Qualified, 'N') = case when @Qualified = 'Y' then @Qualified else ISNULL(q.Qualified, 'N') END
		and ((@IsBidContact = 'N') or (c.IsBidContact = 'Y'))
		and ((@PhaseGroup is null or @Phases is NULL) or (t.PhaseGroup = @PhaseGroup and t.PhaseCode IN (SELECT * FROM @PhaseTable)))
		and ((@ProjectType is null) or (tc.ProjectTypeCode = @ProjectType))
		and ISNULL(q.Preferred, 'N') = case when @Preferred = 'Y' then @Preferred else ISNULL(q.Preferred, 'N') END
)
select 
		[Vendor Group], 
		[Vendor], 
		[Vendor Name], 
		[Contact],
		[Contact Name], 
		[Phone], 
		[Email],
		[Fax],
		ContactSeq,
		stuff((select ',' + CAST(t2.[Phases] as varchar(10))
				from bidders t2 where t1.[Vendor Group] = t2.[Vendor Group]
										and t1.[Vendor] = t2.[Vendor]
										and t1.[Contact] = t2.[Contact]
		for xml path('')),1,1,'') PhaseCode
from bidders t1
group by [Vendor Group], 
		[Vendor], 
		[Vendor Name], 
		[Contact],
		[Contact Name], 
		[Phone], 
		[Email],
		[Fax],
		ContactSeq

GO
GRANT EXECUTE ON  [dbo].[vspPCSelectBidders] TO [public]
GO
