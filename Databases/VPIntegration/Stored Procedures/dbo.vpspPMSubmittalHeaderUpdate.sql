SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspPMSubmittalHeaderUpdate]
/***********************************************************
* Created:     8/31/09		JB		Rewrote SP/cleanup
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* 
* Description:	update a submittal header.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @Submittal bDocument,
      @SubmittalType bDocType,
      @Rev TINYINT,
      @SubmittalDescription bItemDesc,
      @PhaseGroup bGroup,
      @Phase bPhase,
      @Issue bIssue,
      @Status bStatus,
      @VendorGroup bGroup,
      @ResponsibleFirm bFirm,
      @ResponsiblePerson bEmployee,
      @ResponsiblePersonAliased bEmployee,
      @SubFirm bFirm,
      @SubContact bEmployee,
      @ArchEngFirm bFirm,
      @ArchEngContact bEmployee,
      @DateReqd bDate,
      @DateRecd bDate,
      @ToArchEng bDate,
      @DueBackArch bDate,
      @DateRetd bDate,
      @ActivityDate bDate,
      @CopiesRecd TINYINT,
      @CopiesSent TINYINT,
      @Notes VARCHAR(MAX),
      @CopiesReqd TINYINT,
      @CopiesRecdArch TINYINT,
      @CopiesSentArch TINYINT,
      @UniqueAttchID UNIQUEIDENTIFIER,
      @SpecNumber VARCHAR(20),
      @RecdBackArch bDate,
      @KeyID BIGINT,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_Submittal bDocument,
      @Original_SubmittalType bDocType,
      @Original_Rev TINYINT,
      @Original_SubmittalDescription bItemDesc,
      @Original_PhaseGroup bGroup,
      @Original_Phase bPhase,
      @Original_Issue bIssue,
      @Original_Status bStatus,
      @Original_VendorGroup bGroup,
      @Original_ResponsibleFirm bFirm,
      @Original_ResponsiblePerson bEmployee,
      @Original_ResponsiblePersonAliased bEmployee,
      @Original_SubFirm bFirm,
      @Original_SubContact bEmployee,
      @Original_ArchEngFirm bFirm,
      @Original_ArchEngContact bEmployee,
      @Original_DateReqd bDate,
      @Original_DateRecd bDate,
      @Original_ToArchEng bDate,
      @Original_DueBackArch bDate,
      @Original_DateRetd bDate,
      @Original_ActivityDate bDate,
      @Original_CopiesRecd TINYINT,
      @Original_CopiesSent TINYINT,
      @Original_Notes VARCHAR(MAX),
      @Original_CopiesReqd TINYINT,
      @Original_CopiesRecdArch TINYINT,
      @Original_CopiesSentArch TINYINT,
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_SpecNumber VARCHAR(20),
      @Original_RecdBackArch bDate,
      @Original_KeyID BIGINT
    )
AS 
    BEGIN
        SET NOCOUNT ON ;
        DECLARE @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'SUBMIT'
	
	--Status Code Validation
        IF ( [dbo].vpfPMValidateStatusCode(@Status, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@Status)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END
	
	--Issue Validation		
        IF @Issue = -1 
            SET @Issue = NULL
	
	--Responsible Firm Validation
        IF @ResponsibleFirm = -1 
            SET @ResponsibleFirm = NULL
	
	--Responsible Person Validation
        IF @ResponsiblePerson = -1 
            SET @ResponsiblePerson = NULL
	
	--Sub Firm Validation
        IF @SubFirm = -1 
            SET @SubFirm = NULL
	
	--Sub Contractor Validation
        IF @SubContact = -1 
            SET @SubContact = NULL
	
	--Arch Eng Firm Validation
        IF @ArchEngFirm = -1 
            SET @ArchEngFirm = NULL
	
	--Arch Eng Contact Validation
        IF @ArchEngContact = -1 
            SET @ArchEngContact = NULL
	
	--Responsible Alias Validation
        IF @ResponsiblePersonAliased = -1 
            SET @ResponsiblePersonAliased = NULL
        SET @ResponsiblePerson = @ResponsiblePersonAliased
	
	--Phase Group Validation
        SET @PhaseGroup = ( SELECT  PhaseGroup
                            FROM    HQCO
                            WHERE   HQCo = @PMCo
                          )
	
	--Update the submittal 
        UPDATE  PMSM
        SET     Description = @SubmittalDescription,
                PhaseGroup = @PhaseGroup,
                Phase = @Phase,
                Issue = @Issue,
                Status = @Status,
                VendorGroup = @VendorGroup,
                ResponsibleFirm = @ResponsibleFirm,
                ResponsiblePerson = @ResponsiblePerson,
                SubFirm = @SubFirm,
                SubContact = @SubContact,
                ArchEngFirm = @ArchEngFirm,
                ArchEngContact = @ArchEngContact,
                DateReqd = @DateReqd,
                DateRecd = @DateRecd,
                ToArchEng = @ToArchEng,
                DueBackArch = @DueBackArch,
                DateRetd = @DateRetd,
                ActivityDate = @ActivityDate,
                CopiesRecd = @CopiesRecd,
                CopiesSent = @CopiesSent,
                Notes = @Notes,
                CopiesReqd = @CopiesReqd,
                CopiesRecdArch = @CopiesRecdArch,
                CopiesSentArch = @CopiesSentArch,
                UniqueAttchID = @UniqueAttchID,
                SpecNumber = @SpecNumber,
                RecdBackArch = @RecdBackArch
        WHERE   PMCo = @Original_PMCo
                AND Project = @Original_Project
                AND Submittal = @Original_Submittal
                AND SubmittalType = @Original_SubmittalType
                AND Rev = @Original_Rev
		
	--Get a update of the current record
        EXECUTE vpspPMSubmittalHeaderGet @PMCo, @Project, @KeyID
	
        vspExit:
    END
		
		
		



GO
GRANT EXECUTE ON  [dbo].[vpspPMSubmittalHeaderUpdate] TO [VCSPortal]
GO
