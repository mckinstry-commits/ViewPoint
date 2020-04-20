SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROC [dbo].[vspPMSubmittalPackageCreateRevision]
/***********************************************************
* CREATED BY:	GPT	09/05/2012
* MODIFIED BY:	GP	09/19/2012 - TK-17989 Added OurFirm and APCo to the insert
*				TRL	09/20/2012 - TK-17847 Added Related Linking for new record
*				GP	11/30/2012 TK-19818 - Changed submittal and package to bDocument
*				AW  3/5/2013 TFS - 42806 Update old status if different / close original if chosen
*				TRL 3/13/2013 TFS -  43632 Added New Fields in PMSubmittalPackageCopy
*				AJW 6/4/13 TFS - 50703 Update Submittal Register Status if updating package see original US 5132 for specs
--*				AJW 7/24/13 TFS - 56731 Clear Date option added 
* USAGE:
* Used in PM Submittal Package Create Revision 
* to create a new submittal package revision.
*
*****************************************************/ 

(@OldKeyID BIGINT, @OldStatus bStatus, @NewStatus bStatus, @CloseSubmittalPackage bYN, @Package bDocument, @PackageRevision VARCHAR(5), @ClearNewDates bYN,
@msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode TINYINT, 
		@PMCo bCompany, 
		@Project bProject,
		@OldPackage bDocument, 
		@OldPackageRevision VARCHAR(5), 
		@OrigStatus bStatus,
		@MaxSubmittalSeq BIGINT,
		@NewKeyID BIGINT


SELECT @rcode = 0

----------
--Validate
----------
IF @OldKeyID IS NULL
BEGIN
	SET @msg = 'Missing source submittal package information.'
	RETURN 1
END

-----------------
--Validate fields
-----------------
SELECT	@PMCo = PMCo, 
		@Project = Project, 
		@OldPackage = Package, 
		@OldPackageRevision = PackageRev,
		@OrigStatus = Status
	FROM dbo.PMSubmittalPackage 
	WHERE KeyID = @OldKeyID

DECLARE @NewKeyIDvar table(KeyID BIGINT)

--OldStatus
IF @OldStatus IS NOT NULL
BEGIN
	EXEC @rcode = dbo.bspPMStatusCodeVal @OldStatus, 'SBMTL', NULL, @msg OUTPUT
END	
IF @rcode = 1	RETURN 1

--NewStatus
IF @NewStatus IS NOT NULL
BEGIN
	EXEC @rcode = dbo.bspPMStatusCodeVal @NewStatus, 'SBMTL', NULL, @msg OUTPUT
END	
IF @rcode = 1	RETURN 1

--Package
IF @Package IS NOT NULL
BEGIN
	EXEC @rcode = dbo.vspPMSubmittalCreateRevisionPackageVal @PMCo, @Project, @Package, @msg OUTPUT
END	
IF @rcode = 1	RETURN 1

--Package revision should be new
IF @PackageRevision IS NOT NULL
BEGIN
	EXEC @rcode = dbo.vspPMSubmittalPackageCreateRevisionRevVal @PMCo, @Project, @Package, @PackageRevision, @msg OUTPUT
END	
IF @rcode = 1	RETURN 1


BEGIN TRY

	BEGIN TRANSACTION

	INSERT dbo.vPMSubmittalPackage (PMCo,Project,Package,PackageRev,CreateDate,
		[Description],[Status],SpecSection,ApprovingFirm,ApprovingContact,OurFirm, OurFirmContact,
		ResponsibleFirm, ResponsibleContact,ActivityID,ActivityDescription,ActivityDate,
		VendorGroup,Notes,UniqueAttchID, Closed,	DocType) OUTPUT INSERTED.KeyID INTO @NewKeyIDvar

	SELECT PMCo, Project, @Package, @PackageRevision,GetDate(),
		[Description],@NewStatus,SpecSection,ApprovingFirm,ApprovingContact,OurFirm,OurFirmContact, 
		ResponsibleFirm, ResponsibleContact,ActivityID,ActivityDescription,ActivityDate,
		VendorGroup,Notes,UniqueAttchID, 'N',DocType
	
	FROM dbo.vPMSubmittalPackage
	WHERE KeyID = @OldKeyID

	SELECT @NewKeyID=KeyID FROM @NewKeyIDvar

	INSERT INTO dbo.PMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
	SELECT 'PMSubmittalPackage', @NewKeyID,LinkTableName,LINKID
	FROM dbo.PMRelateRecord
	WHERE RECID=@OldKeyID and RecTableName='PMSubmittalPackage'
	

	SELECT @MaxSubmittalSeq = MAX(ISNULL(Seq,0)) FROM dbo.vPMSubmittal WHERE PMCo = @PMCo AND Project = @Project


	INSERT dbo.vPMSubmittal (PMCo, Project, Seq, SubmittalNumber, SubmittalRev, Package, PackageRev,
							[Description], Details, DocumentType, [Status], SpecSection, Copies,
							ApprovingFirm, ApprovingFirmContact, OurFirmContact, ResponsibleFirm,
							ResponsibleFirmContact, Subcontract, PurchaseOrder, ActivityID, ActivityDescription,
							ActivityDate, VendorGroup, DueToResponsibleFirm, SentToResponsibleFirm, DueFromResponsibleFirm,
							ReceivedFromResponsibleFirm, ReturnedToResponsibleFirm, DueToApprovingFirm, SentToApprovingFirm,
							DueFromApprovingFirm, ReceivedFromApprovingFirm, LeadDays1, LeadDays2, LeadDays3, Notes, UniqueAttchID,
							OurFirm, APCo, Closed) 
	SELECT PMCo, Project, @MaxSubmittalSeq + ROW_NUMBER() OVER (ORDER BY Seq), r.SubmittalNumber, 
						  (	
						    SELECT MAX(ISNULL(SubmittalRev,0)) + 1 
							FROM dbo.PMSubmittal 
							WHERE PMCo = r.PMCo AND Project = r.Project
								AND SubmittalNumber = r.SubmittalNumber
								AND ISNUMERIC(SubmittalRev) = 1
						  ) as SubmittalRev, 
	
							@Package, @PackageRevision,
							r.[Description], Details, DocumentType, r.[Status], SpecSection, Copies,
							ApprovingFirm, ApprovingFirmContact, OurFirmContact, ResponsibleFirm,
							ResponsibleFirmContact, Subcontract, PurchaseOrder, ActivityID, ActivityDescription,
							ActivityDate, VendorGroup, DueToResponsibleFirm, SentToResponsibleFirm, DueFromResponsibleFirm,
							ReceivedFromResponsibleFirm, ReturnedToResponsibleFirm, DueToApprovingFirm, SentToApprovingFirm,
							DueFromApprovingFirm, ReceivedFromApprovingFirm, LeadDays1, LeadDays2, LeadDays3, r.Notes, r.UniqueAttchID,
							r.OurFirm, r.APCo, 'N'
	FROM dbo.vPMSubmittal r
	LEFT JOIN dbo.PMSC s ON s.Status = r.Status
	WHERE	r.PMCo = @PMCo AND r.Project = @Project  
			AND r.Package = @OldPackage AND r.PackageRev = @OldPackageRevision
			AND (r.Status IS NULL OR ISNULL(s.CodeType,'') <> 'F')

	IF dbo.vfToString(@ClearNewDates) = 'Y'
	BEGIN
		UPDATE dbo.PMSubmittal
		SET ActivityDate = null
			,DueToResponsibleFirm = null
			,SentToResponsibleFirm = null
			,DueFromResponsibleFirm = null
			,ReceivedFromResponsibleFirm = null
			,ReturnedToResponsibleFirm = null
			,DueToApprovingFirm = null
			,SentToApprovingFirm = null
			,DueFromApprovingFirm = null
			,ReceivedFromApprovingFirm = null
			,Status = null
			,Notes = null
		FROM PMSubmittal s
		JOIN PMSubmittalPackage p ON p.PMCo = s.PMCo AND p.Project = s.Project 
			AND p.Package = s.Package AND p.PackageRev = s.PackageRev
		WHERE p.KeyID = @NewKeyID
	END

	IF dbo.vfToString(@CloseSubmittalPackage) = 'Y'
	BEGIN
		UPDATE dbo.PMSubmittalPackage
		SET Closed='Y'
		WHERE KeyID = @OldKeyID
		
		UPDATE dbo.PMSubmittal
		SET Closed='Y'
		FROM PMSubmittal s
		JOIN PMSubmittalPackage p ON p.PMCo = s.PMCo AND p.Project = s.Project 
			AND p.Package = s.Package AND p.PackageRev = s.PackageRev
		WHERE p.KeyID = @OldKeyID
	END

	---------------------------
	--Update Orig Status if necessary
	---------------------------
	if dbo.vfToString(@OldStatus) <> dbo.vfToString(@OrigStatus)
	begin
	  UPDATE  dbo.PMSubmittalPackage SET Status = @OldStatus WHERE KeyID = @OldKeyID

	  -- see method SubmittalPackageUpdateStatus in PM.Action.Task.SubmittalPackage.vb 
	  --     when any changes occur here status update logic should be the same.
	  UPDATE dbo.PMSubmittal
		SET Status = @OldStatus
		FROM PMSubmittal s
		JOIN PMSubmittalPackage p ON p.PMCo = s.PMCo AND p.Project = s.Project 
			AND p.Package = s.Package AND p.PackageRev = s.PackageRev
		LEFT JOIN dbo.PMSC [status] ON [status].[Status] = s.[Status] 
        WHERE p.KeyID = @OldKeyID
           AND ( ([status].ActiveAllYN = 'N' AND [status].DocCat = 'SBMTL' AND [status].CodeType <> 'F')
               OR ([status].ActiveAllYN = 'Y' AND [status].CodeType <> 'F')
               OR (ISNULL(s.[Status],'') = '') )
	end

	COMMIT TRANSACTION
	
END TRY	

BEGIN CATCH

	ROLLBACK TRANSACTION
	SET @msg = ERROR_MESSAGE()
	RETURN 1

END CATCH

---------
--Success
---------
RETURN 0	
	

GO
GRANT EXECUTE ON  [dbo].[vspPMSubmittalPackageCreateRevision] TO [public]
GO
