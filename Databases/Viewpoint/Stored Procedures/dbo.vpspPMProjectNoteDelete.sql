SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMProjectNoteDelete]
/************************************************************
* CREATED:		3/7/06  CHS
* MODIFIED:		5/30/07 chs
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 11/11/2011 TK-09955 check for reviewers first
*
*
*
* USAGE:
*   Deletes PM Project Notes
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(@Original_KeyID BIGINT)

AS
SET NOCOUNT ON;

---- TK-09736
DECLARE @rcode int, @Message varchar(255),
		@Original_NoteSeq INT,
		@Original_PMCo nvarchar(50),
		@Original_Project nvarchar(50)
SET @rcode = 0
SET @Message = ''

---- GET PROJECT NOTE KEY DATA
SELECT 	@Original_NoteSeq = NoteSeq,
		@Original_PMCo = PMCo,
		@Original_Project = Project
FROM dbo.PMPN WHERE KeyID = @Original_KeyID
IF @@ROWCOUNT = 0 RETURN

---- check for project note reviewers
IF EXISTS(SELECT 1 FROM dbo.PMNR WHERE PMCo = @Original_PMCo AND Project = @Original_Project
				AND NoteSeq = @Original_NoteSeq)
	BEGIN
	SET @rcode = 1
	SET @Message = 'Reviewers have been assigned to the project note. Cannot delete!'
	GoTo bspmessage
	END

---- DELETE PROJECT NOTE
BEGIN
	DELETE FROM dbo.PMPN
	WHERE KeyID = @Original_KeyID
END

RETURN


bspmessage:
	RAISERROR(@Message, 11, -1);
	return @rcode


----    (
----      @Original_PMCo bCompany,
----      @Original_Project bJob,
----      @Original_NoteSeq INT,
----      @Original_Issue bIssue,
----      @Original_VendorGroup bGroup,
----      @Original_Firm bFirm,
----	--@Original_FirmName varchar(60),
----      @Original_FirmContact bEmployee,
----	--@Original_ContactName char(30),
----      @Original_PMStatus bStatus,
----      @Original_AddedBy bVPUserName,
----      @Original_AddedDate bDate,
----      @Original_ChangedBy bVPUserName,
----      @Original_ChangedDate bDate,
----      @Original_Summary VARCHAR(60),
----      @Original_Notes VARCHAR(MAX),
----      @Original_UniqueAttchID UNIQUEIDENTIFIER
----    )
----AS 
----    SET NOCOUNT ON ;


----    DELETE  FROM PMPN
----    WHERE   ( PMCo = @Original_PMCo )
----            AND ( Project = @Original_Project )
----            AND ( NoteSeq = @Original_NoteSeq )
----            AND ( Issue = @Original_Issue
----                  OR @Original_Issue IS NULL
----                  AND Issue IS NULL
----                )
----            AND ( VendorGroup = @Original_VendorGroup
----                  OR @Original_VendorGroup IS NULL
----                  AND VendorGroup IS NULL
----                )
----            AND ( Firm = @Original_Firm
----                  OR @Original_Firm IS NULL
----                  AND Firm IS NULL
----                )
------AND (FirmName = @Original_FirmName OR @Original_FirmName IS NULL AND FirmName IS NULL)
----            AND ( FirmContact = @Original_FirmContact
----                  OR @Original_FirmContact IS NULL
----                  AND FirmContact IS NULL
----                )
------AND (ContactName = @Original_ContactName OR @Original_ContactName IS NULL AND ContactName IS NULL)
----            AND ( PMStatus = @Original_PMStatus
----                  OR @Original_PMStatus IS NULL
----                  AND PMStatus IS NULL
----                )
----            AND ( AddedBy = @Original_AddedBy )
----            AND ( AddedDate = @Original_AddedDate )
----            AND ( ChangedBy = @Original_ChangedBy
----                  OR @Original_ChangedBy IS NULL
----                  AND ChangedBy IS NULL
----                )
----            AND ( ChangedDate = @Original_ChangedDate
----                  OR @Original_ChangedDate IS NULL
----                  AND ChangedDate IS NULL
----                )
----            AND ( Summary = @Original_Summary
----                  OR @Original_Summary IS NULL
----                  AND Summary IS NULL
----                )
--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL);



GO
GRANT EXECUTE ON  [dbo].[vpspPMProjectNoteDelete] TO [VCSPortal]
GO
