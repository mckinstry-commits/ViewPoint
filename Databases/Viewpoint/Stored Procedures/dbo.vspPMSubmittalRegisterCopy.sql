SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROC [dbo].[vspPMSubmittalRegisterCopy]
/***********************************************************
* CREATED BY:	TRL 10/13/2012 TK-19147 Add Stored Procedure
* MODIFIED BY:	GP	11/30/2012 TK-19818 - Changed submittal and package to bDocument
*						
* USAGE: used to fill grid on PM Submittal Register Copy form
*
*****************************************************/ 
(@PMCo bCompany, @DestinationProject bProject, @CopyApprovingFirm bYN=NULL, @CopyResponsibleFirm bYN = NULL, @OverwriteDuplicate bYN = NULL, 
@SourceSubmittal bDocument = NULL, @SourceRev varchar(5) = NULL, @SourceKeyID bigint = NULL,
@DestinationKeyID bigint OUTPUT, @DestinationUniqueAttchID uniqueidentifier OUTPUT, @errmsg VARCHAR(255) OUTPUT)

AS

SET NOCOUNT ON

DECLARE @rcode TINYINT, @pmsubmittalud_flag bYN, @NextSeq INT, @DestinationOurFirm bFirm, @DestinationSeq int, @Joins varchar(1000), @Where varchar(1000)

SELECT @rcode = 0,@pmsubmittalud_flag='N' , @DestinationOurFirm = '', @DestinationKeyID = NULL, @DestinationUniqueAttchID=NULL

-----------------
--Validate fields
-----------------
IF @PMCo IS NULL
BEGIN
	SELECT @errmsg = 'Missing PM Company'
	RETURN 1
END

IF @DestinationProject IS NULL
BEGIN
	SELECT @errmsg = 'Missing Project'
	RETURN 1
END

IF @SourceKeyID IS NULL
BEGIN
	SELECT @errmsg = 'Missing Submittal Revisoin Source Key ID', @rcode = 1
	RETURN 1
END

-- Check for  memo fields in PMSubmittal table
IF EXISTS(SELECT name FROM syscolumns WHERE name LIKE 'ud%' AND id = object_id('dbo.PMSubmittal'))
BEGIN
	SELECT @pmsubmittalud_flag = 'Y'
END

--Get next sequence for PMCo, Project from PMSubmittal
SELECT @DestinationSeq = ISNULL(Max(Seq),0) +1 FROM dbo.PMSubmittal WHERE PMCo=PMCo AND Project=@DestinationProject

--Get Destination Project's OurFirm to compare with Source record's Project Our Firm
SELECT @DestinationOurFirm = OurFirm FROM dbo.JCJMPM WHERE PMCo=PMCo AND Project=@DestinationProject

/*At this time Date fields and Notes don't copy over*/
/* IF Source Submittal, Revision don't exist for Destination Project, copy record*/
IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.PMSubmittal WHERE PMCo=@PMCo AND Project = @DestinationProject 
						AND SubmittalNumber=@SourceSubmittal AND SubmittalRev=@SourceRev )  
BEGIN
	INSERT INTO dbo.PMSubmittal(PMCo,Project,Seq,SubmittalNumber,SubmittalRev,Description,Details,DocumentType,SpecSection,Copies,
	ActivityID,ActivityDescription,APCo,VendorGroup,LeadDays1,LeadDays2,LeadDays3,
	ApprovingFirm,ApprovingFirmContact,ResponsibleFirm,ResponsibleFirmContact,OurFirm,OurFirmContact)

	SELECT @PMCo,@DestinationProject,@DestinationSeq,@SourceSubmittal,@SourceRev,Description,Details,DocumentType,SpecSection,Copies,
	ActivityID,ActivityDescription,APCo,VendorGroup,LeadDays1,LeadDays2,LeadDays3,
	CASE WHEN @CopyApprovingFirm='Y' THEN ApprovingFirm ELSE NULL END,/*ApprovingFirm*/ 
	CASE WHEN @CopyApprovingFirm='Y' THEN ApprovingFirmContact ELSE NULL END,/*ApprovingFirmContact*/
	CASE WHEN @CopyResponsibleFirm='Y' THEN ResponsibleFirm ELSE NULL END,/*ResponsibleFirm*/
	CASE WHEN @CopyResponsibleFirm='Y' THEN ResponsibleFirmContact ELSE NULL END,/*ResponsibleFirmContact*/
	--OurFirm only copies over when Source OurFirm matches the Destination OurFirm from the Destination Project in Project Master
	case when ISNULL(OurFirm,'') = ISNULL(@DestinationOurFirm,'') then OurFirm else NULL end,/*OurFirm*/
	case when ISNULL(OurFirm,'') = ISNULL(@DestinationOurFirm,'') then OurFirmContact else NULL end/*OurFirmContact*/
	FROM dbo.PMSubmittal
	WHERE KeyID=@SourceKeyID
	--Copy User Memo Fields
	IF @@rowcount = 1 
	BEGIN
		--Return New KeyID record for attamchent copy
		SELECT @DestinationKeyID = SCOPE_IDENTITY()
	
		IF @pmsubmittalud_flag='Y'
		BEGIN
			-- build joins and where clause
			SELECT @Joins = ' from dbo.PMSubmittal join PMSubmittal z on z.KeyID = ' +  dbo.vfToString(@SourceKeyID) 
			SELECT @Where = ' where PMSubmittal.PMCo = ' + dbo.vfToString(@PMCo) + ' and PMSubmittal.Project = ' + CHAR(39) +  dbo.vfToString(@DestinationProject) + CHAR(39) 
			+ ' and PMSubmittal.Seq = ' + CHAR(39) + dbo.vfToString(@DestinationSeq) + CHAR(39)
			
			-- execute user memo update
			EXEC @rcode = dbo.bspPMProjectCopyUserMemos 'PMSubmittal', @Joins, @Where, @errmsg output
			IF @rcode = 1
			BEGIN
				--If destination record is updated, don't stop the copy process on user memo fail	
				RETURN 2
			END
		END		
	END

	--Return Code 2 tells PM SubmittalRegisterCopy form
	 RETURN 2
END
ELSE
BEGIN
	IF IsNULL(@OverwriteDuplicate,'N') = 'Y'
	BEGIN
		--Get Existing record's KeyID to update.
		--Return Exising KeyID record for attamchent copy
		--Select Distinct to keep form updating duplicates for records based on where clause
		SELECT DISTINCT @DestinationKeyID=KeyID, @DestinationUniqueAttchID=UniqueAttchID FROM dbo.PMSubmittal WHERE PMCo=@PMCo AND Project = @DestinationProject 
					AND SubmittalNumber=@SourceSubmittal AND SubmittalRev=@SourceRev 
					
		IF @DestinationKeyID IS NOT NULL
		BEGIN
			--Date Fields aren't updated and our form info is not updated
			UPDATE dbo.PMSubmittal
			SET	Description=s.Description,Details=s.Details,DocumentType=s.DocumentType,Copies=s.Copies, 
				ActivityID=s.ActivityID,ActivityDescription=s.ActivityDescription,LeadDays1=s.LeadDays1,LeadDays2=s.LeadDays2,LeadDays3=s.LeadDays3,
				ApprovingFirm = CASE WHEN @CopyApprovingFirm='Y' THEN s.ApprovingFirm ELSE NULL END,
				ApprovingFirmContact = CASE WHEN @CopyApprovingFirm='Y' THEN s.ApprovingFirmContact ELSE NULL END,
				ResponsibleFirm = CASE WHEN @CopyResponsibleFirm='Y' THEN s.ResponsibleFirm ELSE NULL END,
				ResponsibleFirmContact = CASE WHEN @CopyResponsibleFirm='Y' THEN s.ResponsibleFirmContact ELSE NULL END--,
			FROM dbo.PMSubmittal 
			INNER JOIN PMSubmittal s ON s.KeyID=@SourceKeyID
			WHERE PMSubmittal.KeyID=@DestinationKeyID
			IF @@rowcount = 1 AND @pmsubmittalud_flag='Y'
			BEGIN
					-- build joins and where clause
					SELECT @Joins = ' from dbo.PMSubmittal join PMSubmittal z on z.KeyID = ' + convert(varchar,@SourceKeyID) 
					SELECT @Where = ' where PMSubmittal.KeyID= ' + convert(varchar,@DestinationKeyID) 
					
					-- execute user memo update
					EXEC @rcode = dbo.bspPMProjectCopyUserMemos 'PMSubmittal', @Joins, @Where, @errmsg output
					IF @rcode = 1
					BEGIN
						--If destination record is updated, don't stop the copy process on user memo fail
						RETURN 2
					END
			END
			--Return Code 2 tells PM SubmittalRegisterCopy form
			RETURN 2
	   END
	END
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[vspPMSubmittalRegisterCopy] TO [public]
GO
