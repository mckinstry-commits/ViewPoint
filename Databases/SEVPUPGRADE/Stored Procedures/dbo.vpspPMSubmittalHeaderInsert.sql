SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[vpspPMSubmittalHeaderInsert]
/***********************************************************
* Created:     8/31/09		JB		Rewrote SP/cleanup
* Modified:	   2011/06/30   TEJ     Fixed SP to take into account
*				   the special PM logic for calculating the number
*                  of submittals based off of project settings to
*                  determine if they are supposed to key off just
*                  project or a combination of project and submittal
*                  number.
*			  8/3/2011		CJG		(D-02606) Fixed Revision to start at 0
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)

* 
* Description:	Insert a submittal header.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @Submittal bDocument,
      @SubmittalType bDocType,
      @Rev VARCHAR(3),
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
      @RecdBackArch bDate
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
	
	--Submittal Validation
        IF ( ISNULL(@Submittal, '') = '' )
            OR @Submittal = '+'
            OR @Submittal = 'n'
            OR @Submittal = 'N' 
            BEGIN
		-- 2011/06/30 - TomJ 
		-- Must Calculate the PM DocNumber using the same logic as V6 Whether we key off project and
		-- Sequence number or Project, doc type, and sequence number can be set on a project by project
		-- basis
                SET @msg = NULL
                EXECUTE dbo.vspPMGetNextPMDocNum @PMCo, @Project,
                    @SubmittalType, '', 'Submittal', @Submittal OUTPUT,
                    @msg OUTPUT
                IF ( LEN(@msg) > 0 ) 
                    BEGIN
                        RAISERROR(@msg, 16, 1)
                        GOTO vspExit
                    END				
            END
        SET @msg = NULL
        EXECUTE dbo.vpspFormatDatatypeField 'bDocument', @Submittal,
            @msg OUTPUT
        SET @Submittal = @msg

	--Rev Validation
        IF ( ISNULL(@Rev, '') = '' )
            OR @Rev = '+'
            OR @Rev = 'n'
            OR @Rev = 'N' 
            BEGIN
                SET @Rev = ( SELECT MAX(Rev)
                             FROM   PMSM
                             WHERE  PMCo = @PMCo
                                    AND Project = @Project
                                    AND SubmittalType = @SubmittalType
                                    AND Submittal = @Submittal
                           )	
                IF ( ISNULL(@Rev, '') = '' ) 
                    BEGIN
                        SET @Rev = 0 -- D-02606 - Always default to 0 if no MAX is found
                    END		
                ELSE 
                    BEGIN
                        SET @Rev = @Rev + 1
                    END
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
	
	
	--Insert the submittal
        INSERT  INTO PMSM
                ( PMCo,
                  Project,
                  Submittal,
                  SubmittalType,
                  Rev,
                  Description,
                  PhaseGroup,
                  Phase,
                  Issue,
                  Status,
                  VendorGroup,
                  ResponsibleFirm,
                  ResponsiblePerson,
                  SubFirm,
                  SubContact,
                  ArchEngFirm,
                  ArchEngContact,
                  DateReqd,
                  DateRecd,
                  ToArchEng,
                  DueBackArch,
                  DateRetd,
                  ActivityDate,
                  CopiesRecd,
                  CopiesSent,
                  Notes,
                  CopiesReqd,
                  CopiesRecdArch,
                  CopiesSentArch,
                  UniqueAttchID,
                  SpecNumber,
                  RecdBackArch
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @Submittal,
                  @SubmittalType,
                  @Rev,
                  @SubmittalDescription,
                  @PhaseGroup,
                  @Phase,
                  @Issue,
                  @Status,
                  @VendorGroup,
                  @ResponsibleFirm,
                  @ResponsiblePerson,
                  @SubFirm,
                  @SubContact,
                  @ArchEngFirm,
                  @ArchEngContact,
                  @DateReqd,
                  @DateRecd,
                  @ToArchEng,
                  @DueBackArch,
                  @DateRetd,
                  @ActivityDate,
                  @CopiesRecd,
                  @CopiesSent,
                  @Notes,
                  @CopiesReqd,
                  @CopiesRecdArch,
                  @CopiesSentArch,
                  @UniqueAttchID,
                  @SpecNumber,
                  @RecdBackArch
		    )

	--Get a update for the current record
        DECLARE @KeyID BIGINT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMSubmittalHeaderGet @PMCo, @Project, @KeyID
	
        vspExit:
    END


GO
GRANT EXECUTE ON  [dbo].[vpspPMSubmittalHeaderInsert] TO [VCSPortal]
GO
