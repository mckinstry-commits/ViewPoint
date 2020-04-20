SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPMDrawingRevInit]
   
   /***********************************************************
    * CREATED BY:	GP	07/27/2009 - Issue #134115
    * MODIFIED BY:	GF 09/10/2010 - issue #141031 change to use vfDateOnly
    *				GP	04/26/2010 - TK-04421 Get vendor group from HQCO if null
    *
    *
    * USAGE:
    * Initialize revisions for each selected drawing.
    *
    *
    * INPUT PARAMETERS
    *	@PMCo
    *   @Project
    *	@Revision
    *	@Description
    *	@RevDate
    *	@Status
    *	@Remarks
    *	@DrawingType
    *	@DrawingNo
    *	@Firm1-3
    *	@Contact1-3
    *	@VendorGroup
    *
    * OUTPUT PARAMETERS
    *	@Inserted
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
    *****************************************************/
   (@PMCo bCompany = null, @Project bJob = null, @Revision varchar(10) = null, @Description bItemDesc = null,
	@RevDate bDate = null, @Status bStatus = null, @Remarks varchar(max) = null, @DrawingType bDocType = null,
	@DrawingNo bDocument = null, @Firm1 bFirm = null, @Contact1 bEmployee = null, @Firm2 bFirm = null, 
	@Contact2 bEmployee = null, @Firm3 bFirm = null, @Contact3 bEmployee = null, @VendorGroup bGroup = null,
	@Inserted bYN = null output, @msg varchar(255) output)
   as
   set nocount on
   
	declare @rcode tinyint, @PrefMethod char(1), @EmailOption char(1)
	select @rcode = 0, @Inserted = 'N'

	--VALIDATION--
	if @PMCo is null
	begin
		select @msg = 'Missing PM Company.', @rcode = 1
	end
	
	if @Project is null
	begin
		select @msg = 'Missing Project.', @rcode = 1
	end	

	if @DrawingType is null
	begin
		select @msg = 'Missing Drawing Type.', @rcode = 1
	end
	
	if @DrawingNo is null
	begin
		select @msg = 'Missing Drawing.', @rcode = 1
	end	

	if @Revision is null
	begin
		select @msg = 'Missing Revision.', @rcode = 1
	end
	
	--Get Vendor Group if null
	if isnull(@VendorGroup, '') = ''
		select @VendorGroup = hq.VendorGroup
		from PMCO pm
		join HQCO hq on hq.HQCo = pm.APCo
		where pm.PMCo = @PMCo
	
	--ADD DRAWING REVISION--
	if not exists(select top 1 1 from dbo.PMDR with (nolock) where PMCo=@PMCo and Project=@Project
		and DrawingType=@DrawingType and Drawing=@DrawingNo and Rev=@Revision)
	begin
		insert bPMDR(PMCo, Project, DrawingType, Drawing, Rev, RevisionDate, Status, Notes, Description)
		values(@PMCo, @Project, @DrawingType, @DrawingNo, @Revision, @RevDate, @Status, @Remarks, @Description)
		if @@rowcount > 0 set @Inserted = 'Y'
	end
	
	--ADD FIRM CONTACTS 1,2,3--
	if isnull(@Firm1,'') <> '' and isnull(@Contact1,'') <> ''
	begin
		set @PrefMethod = 'E'
		select @PrefMethod = isnull(PrefMethod,'E') 
		from dbo.PMPM with (nolock) 
		where VendorGroup=@VendorGroup and FirmNumber=@Firm1 and ContactCode=@Contact1
	
		set @EmailOption = 'N'
		select @EmailOption = isnull(EmailOption,'N') 
		from dbo.PMPF with (nolock) 
		where PMCo=@PMCo and Project=@Project and VendorGroup=@VendorGroup and FirmNumber=@Firm1 and ContactCode=@Contact1
	
		insert dbo.PMDistribution(PMCo, Project, DrawingType, Drawing, Seq, VendorGroup,
				SentToFirm, SentToContact, PrefMethod, DateSent, CC)
		select @PMCo, @Project, @DrawingType, @DrawingNo, isnull(max(d.Seq),0) + 1, @VendorGroup,
				----#141031
				@Firm1, @Contact1, @PrefMethod, dbo.vfDateOnly(), @EmailOption
		FROM dbo.PMDistribution d
		where d.PMCo=@PMCo and d.Project=@Project and d.DrawingType=@DrawingType and d.Drawing=@DrawingNo
		AND NOT EXISTS(SELECT 1 FROM dbo.PMDistribution x WITH (NOLOCK) WHERE x.PMCo=d.PMCo AND x.Project=d.Project
					AND x.DrawingType=d.DrawingType AND x.Drawing=d.Drawing AND x.SentToFirm=d.SentToFirm
					AND x.SentToContact=d.SentToContact)
	end
	
	if isnull(@Firm2,'') <> '' and isnull(@Contact2,'') <> ''
	begin
		set @PrefMethod = 'E'
		select @PrefMethod = isnull(PrefMethod,'E') 
		from dbo.PMPM with (nolock) 
		where VendorGroup=@VendorGroup and FirmNumber=@Firm2 and ContactCode=@Contact2
	
		set @EmailOption = 'N'
		select @EmailOption = isnull(EmailOption,'N') 
		from dbo.PMPF
		where PMCo=@PMCo and Project=@Project and VendorGroup=@VendorGroup and FirmNumber=@Firm2 and ContactCode=@Contact2
	
		insert dbo.PMDistribution(PMCo, Project, DrawingType, Drawing, Seq, VendorGroup,
				SentToFirm, SentToContact, PrefMethod, DateSent, CC)
		select @PMCo, @Project, @DrawingType, @DrawingNo, isnull(max(d.Seq),0) + 1, @VendorGroup,
				----#141031
				@Firm2, @Contact2, @PrefMethod, dbo.vfDateOnly(), @EmailOption
		from dbo.PMDistribution d 
		where PMCo=@PMCo and Project=@Project and DrawingType=@DrawingType and Drawing=@DrawingNo
		AND NOT EXISTS(SELECT 1 FROM dbo.PMDistribution x WHERE x.PMCo=d.PMCo AND x.Project=d.Project
					AND x.DrawingType=d.DrawingType AND x.Drawing=d.Drawing AND x.SentToFirm=d.SentToFirm
					AND x.SentToContact=d.SentToContact)
	end

	if isnull(@Firm3,'') <> '' and isnull(@Contact3,'') <> ''
	begin
		set @PrefMethod = 'E'
		select @PrefMethod = isnull(PrefMethod,'E') 
		from dbo.PMPM with (nolock) 
		where VendorGroup=@VendorGroup and FirmNumber=@Firm3 and ContactCode=@Contact3
	
		set @EmailOption = 'N'
		select @EmailOption = isnull(EmailOption,'N') 
		from dbo.PMPF with (nolock) 
		where PMCo=@PMCo and Project=@Project and VendorGroup=@VendorGroup and FirmNumber=@Firm3 and ContactCode=@Contact3
	
		insert dbo.PMDistribution(PMCo, Project, DrawingType, Drawing, Seq, VendorGroup,
				SentToFirm, SentToContact, PrefMethod, DateSent, CC)
		select @PMCo, @Project, @DrawingType, @DrawingNo, isnull(max(d.Seq),0) + 1, @VendorGroup,
				----#141031
				@Firm3, @Contact3, @PrefMethod, dbo.vfDateOnly(), @EmailOption
		from dbo.PMDistribution d
		where PMCo=@PMCo and Project=@Project and DrawingType=@DrawingType and Drawing=@DrawingNo
		AND NOT EXISTS(SELECT 1 FROM dbo.PMDistribution x WHERE x.PMCo=d.PMCo AND x.Project=d.Project
					AND x.DrawingType=d.DrawingType AND x.Drawing=d.Drawing AND x.SentToFirm=d.SentToFirm
					AND x.SentToContact=d.SentToContact)
	end




vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMDrawingRevInit] TO [public]
GO
