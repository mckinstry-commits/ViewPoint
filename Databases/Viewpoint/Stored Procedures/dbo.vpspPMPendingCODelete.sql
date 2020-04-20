SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMPendingCODelete]
/************************************************************
* CREATED:     5/2/06 chs
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 11/16/2011 TK-09972
*
* USAGE:
*   Deletes PM Pending Change Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(@KeyID BIGINT)

AS
SET NOCOUNT ON;


---- TK-09972
DECLARE @rcode int, @Message varchar(255),
		@Original_PCOType nvarchar(50),
		@Original_PCO NVARCHAR(50),
		@Original_PMCo nvarchar(50),
		@Original_Project nvarchar(50)
SET @rcode = 0
SET @Message = ''

---- GET PCO KEY DATA
SELECT 	@Original_PCOType = PCOType,
		@Original_PCO = PCO,
		@Original_PMCo = PMCo,
		@Original_Project = Project
FROM dbo.PMOP WHERE KeyID = @KeyID
IF @@ROWCOUNT = 0 RETURN

---- check for PCO items
IF EXISTS(SELECT 1 FROM dbo.PMOI WHERE PMCo = @Original_PMCo AND Project = @Original_Project
				AND PCOType = @Original_PCOType AND PCO = @Original_PCO)
	BEGIN
	SET @rcode = 1
	SET @Message = 'PCO Items exist for this PCO!'
	GoTo bspmessage
	END

---- check if any PCO items have been approved
IF EXISTS(SELECT 1 FROM dbo.PMOI WHERE PMCo = @Original_PMCo AND Project = @Original_Project
				AND PCOType = @Original_PCOType AND PCO = @Original_PCO
				AND ACO IS NOT NULL)
	BEGIN
	SET @rcode = 1
	SET @Message = 'PCO Items have been approved for this PCO!'
	GoTo bspmessage
	END

DELETE FROM dbo.PMOP WHERE [KeyID] = @KeyID;

RETURN;


bspmessage:
	RAISERROR(@Message, 11, -1);
	return @rcode



----    (
----      @Original_PMCo bCompany,
----      @Original_Project bJob,
----      @Original_PCOType bDocType,
----      @Original_PCO bPCO,
----      @Original_Description bDesc,
----      @Original_Issue bIssue,
----      @Original_Contract bContract,
----      @Original_PendingStatus TINYINT,
----      @Original_IntExt CHAR(1),
----      @Original_Date1 bDate,
----      @Original_Date2 bDate,
----      @Original_Date3 bDate,
----      @Original_ApprovalDate bDate,
----      @Original_Notes VARCHAR(MAX),
----      @Original_UniqueAttchID UNIQUEIDENTIFIER
----    )
----AS 
----    SET NOCOUNT ON ;

----    DELETE  FROM PMOP
----    WHERE   ( PMCo = @Original_PMCo )
----            AND ( Project = @Original_Project )
----            AND ( PCO = @Original_PCO )
----            AND ( PCOType = @Original_PCOType )
----            AND ( Description = @Original_Description
----                  OR @Original_Description IS NULL
----                  AND Description IS NULL
----                )
----            AND ( Issue = @Original_Issue
----                  OR @Original_Issue IS NULL
----                  AND Issue IS NULL
----                )
----            AND ( Contract = @Original_Contract )
----            AND ( PendingStatus = @Original_PendingStatus )
----            AND ( IntExt = @Original_IntExt )
----            AND ( Date1 = @Original_Date1
----                  OR @Original_Date1 IS NULL
----                  AND Date1 IS NULL
----                )
----            AND ( Date2 = @Original_Date2
----                  OR @Original_Date2 IS NULL
----                  AND Date2 IS NULL
----                )
----            AND ( Date3 = @Original_Date3
----                  OR @Original_Date3 IS NULL
----                  AND Date3 IS NULL
----                )
----            AND ( ApprovalDate = @Original_ApprovalDate
----                  OR @Original_ApprovalDate IS NULL
----                  AND ApprovalDate IS NULL
----                )








GO
GRANT EXECUTE ON  [dbo].[vpspPMPendingCODelete] TO [VCSPortal]
GO
