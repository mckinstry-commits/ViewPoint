SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPMApprovedCODelete
/************************************************************
* CREATED:     5/2/06 chs
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
* USAGE:	
*   Deletes PM Approved Change Orders (PMOH)
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@Original_PMCo bCompany,
	@Original_Project bJob,
	@Original_ACO bACO,
	@Original_Description bDesc,
	@Original_ACOSequence int,
	@Original_Issue bIssue,
	@Original_Contract bContract,
	@Original_ChangeDays smallint,
	@Original_NewCmplDate bDate,
	@Original_IntExt char(1),
	@Original_DateSent bDate,
	@Original_DateReqd bDate,
	@Original_DateRecd bDate,
	@Original_ApprovalDate bDate,
	@Original_ApprovedBy varchar(30),
	@Original_BillGroup bBillingGroup,
	@Original_Notes VARCHAR(MAX),
	@Original_UniqueAttchID uniqueidentifier
)

AS	
SET NOCOUNT ON;

DELETE FROM PMOH

	WHERE (PMCo = @Original_PMCo)
		AND (Project = @Original_Project)
		AND (ACO = @Original_ACO)
		AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL)
		AND (ACOSequence = @Original_ACOSequence OR @Original_ACOSequence IS NULL AND ACOSequence IS NULL)
		AND (Issue = @Original_Issue OR @Original_Issue IS NULL AND Issue IS NULL)
		AND (Contract = @Original_Contract)
		AND (ChangeDays = @Original_ChangeDays OR @Original_ChangeDays IS NULL AND ChangeDays IS NULL)
		AND (NewCmplDate = @Original_NewCmplDate OR @Original_NewCmplDate IS NULL AND NewCmplDate IS NULL)
		AND (IntExt = @Original_IntExt)
		AND (DateSent = @Original_DateSent OR @Original_DateSent IS NULL AND DateSent IS NULL)
		AND (DateReqd = @Original_DateReqd OR @Original_DateReqd IS NULL AND DateReqd IS NULL)
		AND (DateRecd = @Original_DateRecd OR @Original_DateRecd IS NULL AND DateRecd IS NULL)
		AND (ApprovalDate = @Original_ApprovalDate)
		AND (ApprovedBy = @Original_ApprovedBy OR @Original_ApprovedBy IS NULL AND ApprovedBy IS NULL)
		AND (BillGroup = @Original_BillGroup OR @Original_BillGroup IS NULL AND BillGroup IS NULL)






GO
GRANT EXECUTE ON  [dbo].[vpspPMApprovedCODelete] TO [VCSPortal]
GO
