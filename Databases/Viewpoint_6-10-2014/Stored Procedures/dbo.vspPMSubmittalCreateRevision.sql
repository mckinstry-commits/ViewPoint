SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROC [dbo].[vspPMSubmittalCreateRevision]
/***********************************************************
* CREATED BY:	GP	08/23/2012
* MODIFIED BY:	GP	09/19/2012 - TK-17989 Added OurFirm and APCo to the insert
*						TRL	09/20/2012 - TK-17847 Added Related Linking for new record
*				GP	11/30/2012 TK-19818 - Changed submittal and package to bDocument
*				AW  3/5/2013 TFS - 42806 - Update OldStatus if differ from Original 
*				
* USAGE:
* Used in PM Submittal Register Create Revision 
* to create a new submittal revision.
*
*****************************************************/ 

(@OldKeyID BIGINT, @Submittal bDocument, @SubmittalRevision VARCHAR(5), 
@OldStatus bStatus,@NewStatus bStatus, @Package bDocument, @PackageRevision VARCHAR(5), @ClearPackage bYN, 
@CloseSubmittal bYN, @msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode TINYINT, @PMCo bCompany, @Project bProject, @NextSeq BIGINT, @NewKeyID BIGINT,@OrigStatus bStatus

----------
--Validate
----------
IF @OldKeyID IS NULL
BEGIN
	SET @msg = 'Missing source submittal information.'
	RETURN 1
END

IF @Submittal IS NULL
BEGIN
	SET @msg = 'Missing submittal.'
	RETURN 1
END

-----------------
--Validate fields
-----------------
SELECT @PMCo = PMCo, @Project = Project, @OrigStatus = Status FROM dbo.PMSubmittal WHERE KeyID = @OldKeyID

DECLARE @NewKeyIDvar table(KeyID BIGINT)

--Submittal revision
IF @SubmittalRevision IS NOT NULL
BEGIN
	EXEC @rcode = dbo.vspPMSubmittalCreateRevisionVal @PMCo, @Project, @Submittal, @SubmittalRevision, @msg OUTPUT
END	
IF @rcode = 1	RETURN 1

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

--Package revision
IF @PackageRevision IS NOT NULL
BEGIN
	EXEC @rcode = dbo.vspPMSubmittalCreateRevisionPackageRevVal @PMCo, @Project, @Package, @PackageRevision, @msg OUTPUT
END	
IF @rcode = 1	RETURN 1

--------------------------
--Create submittal revision
---------------------------
SELECT @NextSeq = MAX(ISNULL(Seq,0)) + 1 FROM dbo.vPMSubmittal WHERE PMCo = @PMCo AND Project = @Project

BEGIN TRY

	BEGIN TRANSACTION

	INSERT dbo.vPMSubmittal (PMCo, Project, Seq, SubmittalNumber, SubmittalRev, Package, PackageRev,
							[Description], Details, DocumentType, [Status], SpecSection, Copies,
							ApprovingFirm, ApprovingFirmContact, OurFirmContact, ResponsibleFirm,
							ResponsibleFirmContact, Subcontract, PurchaseOrder, ActivityID, ActivityDescription,
							ActivityDate, VendorGroup, DueToResponsibleFirm, SentToResponsibleFirm, DueFromResponsibleFirm,
							ReceivedFromResponsibleFirm, ReturnedToResponsibleFirm, DueToApprovingFirm, SentToApprovingFirm,
							DueFromApprovingFirm, ReceivedFromApprovingFirm, LeadDays1, LeadDays2, LeadDays3, Notes, UniqueAttchID,
							OurFirm, APCo) OUTPUT INSERTED.KeyID INTO @NewKeyIDvar
	SELECT PMCo, Project, @NextSeq, @Submittal, @SubmittalRevision, @Package, @PackageRevision,
							[Description], Details, DocumentType, @NewStatus, SpecSection, Copies,
							ApprovingFirm, ApprovingFirmContact, OurFirmContact, ResponsibleFirm,
							ResponsibleFirmContact, Subcontract, PurchaseOrder, ActivityID, ActivityDescription,
							ActivityDate, VendorGroup, DueToResponsibleFirm, SentToResponsibleFirm, DueFromResponsibleFirm,
							ReceivedFromResponsibleFirm, ReturnedToResponsibleFirm, DueToApprovingFirm, SentToApprovingFirm,
							DueFromApprovingFirm, ReceivedFromApprovingFirm, LeadDays1, LeadDays2, LeadDays3, Notes, UniqueAttchID,
							OurFirm, APCo				
	FROM dbo.vPMSubmittal
	WHERE KeyID = @OldKeyID

	IF @ClearPackage = 'Y'
	BEGIN
		UPDATE dbo.vPMSubmittal
		SET Package = NULL, PackageRev = NULL
		WHERE KeyID = @OldKeyID
	END

    IF @CloseSubmittal = 'Y'
	BEGIN
		UPDATE dbo.vPMSubmittal
		SET Closed='Y'
		WHERE KeyID = @OldKeyID
	END

	---------------------------
	--Update Orig Status if necessary
	---------------------------
	if dbo.vfToString(@OldStatus) <> dbo.vfToString(@OrigStatus)
	begin
	  UPDATE  dbo.PMSubmittal SET Status = @OldStatus WHERE KeyID = @OldKeyID
	end

	SELECT @NewKeyID=KeyID FROM @NewKeyIDvar	
 
	INSERT INTO dbo.PMRelateRecord(RecTableName, RECID, LinkTableName, LINKID)
	SELECT 'PMSubmittal', @NewKeyID,LinkTableName,LINKID
	FROM dbo.PMRelateRecord
	WHERE RECID=@OldKeyID and RecTableName='PMSubmittal'

	COMMIT TRANSACTION
	
END TRY	

BEGIN CATCH

	ROLLBACK TRANSACTION
	RETURN 1

END CATCH

---------
--Success
---------
RETURN 0	
	

GO
GRANT EXECUTE ON  [dbo].[vspPMSubmittalCreateRevision] TO [public]
GO
