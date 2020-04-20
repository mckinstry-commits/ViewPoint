SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[vpspPMPendingCOUpdate]
/************************************************************
* CREATED:     5/2/06 chs
* Modified By: GF 09/16/2011 TK-08524
*				GF 11/15/2011 TK-09972 additional fields added for 6.4.0
*				GF 12/06/2011 TK-10599
*
*
* USAGE:
*   Updates PM Approved Change Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@PMCo bCompany,
	@Project bJob,
	@PCOType bDocType,
	@PCO bPCO,
	@Description VARCHAR(60),
	@Issue bIssue,
	@Contract bContract,
	@PendingStatus tinyint,
	@IntExt char(1),
	@Date1 bDate,
	@Date2 bDate,
	@Date3 bDate,
	@ApprovalDate bDate,
	@Notes VARCHAR(MAX),
	@UniqueAttchID uniqueidentifier
	----TK-09972
	,@DateCreated bDate
	,@Priority TINYINT
	,@Reference VARCHAR(30)
	,@ROMAmount bDollar
	--,@ReasonCode bReasonCode
	--,@Status bStatus

	,@Original_PMCo bCompany
	,@Original_Project bJob
	,@Original_PCOType bDocType
	,@Original_PCO bPCO
	,@Original_Description bDesc
	,@Original_Issue bIssue
	,@Original_Contract bContract
	,@Original_PendingStatus tinyint
	,@Original_IntExt char(1)
	,@Original_Date1 bDate
	,@Original_Date2 bDate
	,@Original_Date3 bDate
	,@Original_ApprovalDate bDate
	,@Original_Notes bNotes
	,@Original_UniqueAttchID UNIQUEIDENTIFIER
	----TK-09972
	,@Original_DateCreated bDate
	,@Original_Priority TINYINT
	,@Original_Reference VARCHAR(30)
	,@Original_ROMAmount bDollar
	--,@Original_ReasonCode bReasonCode
	--,@Original_Status bStatus
	,@Original_KeyID BIGINT
)
AS
	SET NOCOUNT ON;

declare @rcode int, @message varchar(255)
SET @rcode = 0
SET @message = ''

---- TK-08524 check item amount only when internal/external changes
IF @Original_IntExt = 'E' AND @IntExt = 'I'
	BEGIN
	
	DECLARE @PendingSum bDollar
	SELECT @PendingSum = SUM(PendingAmount)
	FROM dbo.PMOI
	WHERE (PMCo = @Original_PMCo)
		AND (Project = @Original_Project)
		AND (PCO = @Original_PCO)
		AND (PCOType = @Original_PCOType)
	HAVING SUM(PendingAmount) <> 0

	IF @PendingSum <> 0
		BEGIN
		SET @rcode = 1
		SET @message = 'PM Pending CO Items have item amounts. Cannot change to internal.'
		GOTO bspmessage
		END
	END

UPDATE PMOP
	SET Description = @Description, 
		PendingStatus = @PendingStatus, 
		Issue = @Issue, 
		Contract = @Contract, 
		IntExt = @IntExt, 
		Date1 = @Date1, 
		Date2 = @Date2, 
		Date3 = @Date3, 
		ApprovalDate = @ApprovalDate, 
		Notes = @Notes, 
		UniqueAttchID = @UniqueAttchID,
		DateCreated = @DateCreated,
		Priority = @Priority,
		Reference = @Reference,
		ROMAmount = @ROMAmount
		--,@ReasonCode bReasonCode
		--,@Status bStatus	
			
	----TK-09972
	WHERE KeyID = @Original_KeyID
	--WHERE (PMCo = @Original_PMCo)
	--	AND (Project = @Original_Project)
	--	AND (PCO = @Original_PCO)
	--	AND (PCOType = @Original_PCOType)
	--	AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL)
	--	AND (Issue = @Original_Issue OR @Original_Issue IS NULL AND Issue IS NULL)
	--	AND (Contract = @Original_Contract)
	--	AND (PendingStatus = @Original_PendingStatus)
	--	AND (IntExt = @Original_IntExt)
	--	AND (Date1 = @Original_Date1 OR @Original_Date1 IS NULL AND Date1 IS NULL)
	--	AND (Date2 = @Original_Date2 OR @Original_Date2 IS NULL AND Date2 IS NULL)
	--	AND (Date3 = @Original_Date3 OR @Original_Date3 IS NULL AND Date3 IS NULL)
	--	AND (ApprovalDate = @Original_ApprovalDate OR @Original_ApprovalDate IS NULL AND ApprovalDate IS NULL)


/*SELECT PMCo, Project, PCOType, PCO, Description, PendingStatus,
	Issue, Contract, IntExt, 
	Date1, Date2, Date3, ApprovalDate, 
	Notes, UniqueAttchID

	FROM PMOP

	WHERE (PMCo = @PMCo) 
		AND (Project = @Project)
		AND (PCO = @PCO)*/

bspexit:
	return @rcode

bspmessage:
	RAISERROR(@message, 11, -1);
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vpspPMPendingCOUpdate] TO [VCSPortal]
GO
