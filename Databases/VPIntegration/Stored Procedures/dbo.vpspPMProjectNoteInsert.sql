SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMProjectNoteInsert]
/***********************************************************
* Created:     8/27/09		JB		Rewrote SP/cleanup
* Modified:		GF 09/09/2010 - issue #141031 changed to use function vfDateonly
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* 
* Description:	Insert a project note record.
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @NoteSeq VARCHAR(10),
      @Issue bIssue,
      @VendorGroup bGroup,
      @Firm bFirm,
      @FirmContact bEmployee,
      @PMStatus bStatus,
      @AddedBy bVPUserName,
      @AddedDate bDate,
      @ChangedBy bVPUserName,
      @ChangedDate bDate,
      @Summary VARCHAR(60),
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @EmptyBox VARCHAR(8000),
      @UserID INT
    )
AS 
    BEGIN
        SET NOCOUNT ON ;

        DECLARE @CrLf NVARCHAR(50),
            @newNotes VARCHAR(1024),
            @DocCat VARCHAR(10),
            @msg VARCHAR(255)
        SET @DocCat = 'PROJNOTES'
        SET @CrLf = CHAR(13) + CHAR(10)
        SET @AddedBy = ( SELECT FirstName + ' ' + LastName
                         FROM   pUsers
                         WHERE  UserID = @UserID
                       )
	----#141031
        SET @AddedDate = dbo.vfDateOnly()

	--Note Seq Validation
        SET @NoteSeq = ( SELECT ISNULL(MAX(NoteSeq), 0) + 1
                         FROM   PMPN
                         WHERE  PMCo = @PMCo
                                AND Project = @Project
                                AND VendorGroup = @VendorGroup
                       )

	--Issue Validation
        IF @Issue = -1 
            SET @Issue = NULL
	
	--Firm Validation
        IF @Firm = -1 
            SET @Firm = NULL
	
	--Contact Validation
        IF @FirmContact = -1 
            SET @FirmContact = NULL
	
	--Status Code Validation
        IF ( [dbo].vpfPMValidateStatusCode(@PMStatus, @DocCat) ) = 0 
            BEGIN
                SET @msg = 'PM Status ' + ISNULL(LTRIM(RTRIM(@PMStatus)), '')
                    + ' is not valid for Document Category: ' + ISNULL(@DocCat,
                                                              '') + '.'
                RAISERROR(@msg, 16, 1)
                GOTO vspExit
            END

	--Notes validation
        IF @EmptyBox IS NOT NULL 
            BEGIN
                SET @newNotes = CONVERT(VARCHAR, GETDATE(), 101) + ' By '
                    + @AddedBy + ' (portal)' + @CrLf + @EmptyBox + @CrLf
                    + '__________'
            END
        ELSE 
            BEGIN
                SET @newNotes = ''
            END

	--Insert the project note
        INSERT  INTO PMPN
                ( PMCo,
                  Project,
                  NoteSeq,
                  Issue,
                  VendorGroup,
                  Firm,
                  FirmContact,
                  PMStatus,
                  AddedBy,
                  AddedDate,
                  ChangedBy,
                  ChangedDate,
                  Summary,
                  Notes,
                  UniqueAttchID
		    )
        VALUES  ( @PMCo,
                  @Project,
                  @NoteSeq,
                  @Issue,
                  @VendorGroup,
                  @Firm,
                  @FirmContact,
                  @PMStatus,
                  @AddedBy,
                  @AddedDate,
                  @AddedBy		--ChangedBy is the AddedBy on insert
                  ,
                  @AddedDate	--ChangeDate is the AddedDate on insert
                  ,
                  @Summary,
                  @newNotes,
                  @UniqueAttchID
		    )

	--Get the current updated record
        DECLARE @KeyID BIGINT
        SET @KeyID = SCOPE_IDENTITY()
        EXECUTE vpspPMProjectNoteGet @PMCo, @Project, @UserID, @KeyID 
	
        vspExit:
    END
	


GO
GRANT EXECUTE ON  [dbo].[vpspPMProjectNoteInsert] TO [VCSPortal]
GO
