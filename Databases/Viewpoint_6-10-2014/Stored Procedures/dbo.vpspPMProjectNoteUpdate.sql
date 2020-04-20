SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMProjectNoteUpdate]  
/***********************************************************  
* Created:     8/27/09  JB  Rewrote SP/cleanup  
* Modified:    3/31/2010 Dave C -- Removed an apparent debugging statement that got left in the sp
*								   and prevented the portal control from saving data.
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*   
* Description: Update a project note record.  
************************************************************/
    (
      @PMCo bCompany,
      @Project bJob,
      @NoteSeq INT,
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
      @KeyID BIGINT,
      @Original_PMCo bCompany,
      @Original_Project bJob,
      @Original_NoteSeq INT,
      @Original_Issue bIssue,
      @Original_VendorGroup bGroup,
      @Original_Firm bFirm,
      @Original_FirmName VARCHAR(60),
      @Original_FirmContact bEmployee,
      @Original_ContactName CHAR(30),
      @Original_PMStatus bStatus,
      @Original_AddedBy bVPUserName,
      @Original_AddedDate bDate,
      @Original_ChangedBy bVPUserName,
      @Original_ChangedDate bDate,
      @Original_Summary VARCHAR(60),
      @Original_Notes VARCHAR(MAX),
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_KeyID BIGINT,
      @EmptyBox VARCHAR(8000),
      @UserID INT  
  
    )
AS 
    BEGIN  
        SET NOCOUNT ON ;  
  
        DECLARE @newNotes VARCHAR(1024),
            @FirstLastName NVARCHAR(50),
            @CrLf NVARCHAR(50),
            @OldNotes VARCHAR(8000),
            @DocCat VARCHAR(10),
            @msg VARCHAR(255)  
        SET @DocCat = 'PROJNOTES'  
  
        SET @CrLf = CHAR(13) + CHAR(10)  
        SET @FirstLastName = ( SELECT   FirstName + ' ' + LastName
                               FROM     pUsers
                               WHERE    UserID = @UserID
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
  
 --Notes Validation  
 -- if the @Notes string contains HTML characters replace with ASCII  
        SET @OldNotes = REPLACE(REPLACE(CONVERT(VARCHAR(8000), ISNULL(@Notes,
                                                              '')), '<br>',
                                        CHAR(13) + CHAR(10)), '&nbsp;',
                                CHAR(32))  
  
        IF @EmptyBox IS NULL
            OR @EmptyBox = '' 
            SET @newNotes = @OldNotes  
        ELSE 
            SET @newNotes = @OldNotes + @CrLf + CONVERT(VARCHAR, GETDATE(), 101)
                + ' By ' + @FirstLastName + ' (portal)' + @CrLf + @EmptyBox
                + @CrLf + '__________'  
   
 --Update the project note  
        UPDATE  PMPN
        SET     Issue = @Issue,
                VendorGroup = @VendorGroup,
                Firm = @Firm,
                FirmContact = @FirmContact,
                PMStatus = @PMStatus,
                AddedBy = @AddedBy,
                AddedDate = @AddedDate,
                ChangedBy = @ChangedBy,
                ChangedDate = @ChangedDate,
                Summary = @Summary,
                Notes = @newNotes,
                UniqueAttchID = @UniqueAttchID
        WHERE   ( PMCo = @Original_PMCo )
                AND ( Project = @Original_Project )
                AND ( NoteSeq = @Original_NoteSeq )  
   
   
 --Get the current updated record  
        EXECUTE vpspPMProjectNoteGet @PMCo, @Project, @UserID, @KeyID   
   
        vspExit:  
    END
GO
GRANT EXECUTE ON  [dbo].[vpspPMProjectNoteUpdate] TO [VCSPortal]
GO
