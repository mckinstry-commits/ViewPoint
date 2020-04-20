SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/14/09
-- Description:	Gets all Time Card start dates that need to be approved yet for the given user
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetApprovalGet]
	(@UserName bVPUserName, @KeyID int = NULL)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	WITH ApprovableTimeSheetEntries_CTE(PRCo, EntryEmployee, StartDate, Sheet, Seq, Approved, [Status], KeyID)
	AS
	(
		SELECT DISTINCT PRCo, EntryEmployee, StartDate, Sheet, Seq, Approved, [Status], PRMyTimesheetDetailForApproval.KeyID
		FROM PRMyTimesheetDetailForApproval
			INNER JOIN HQRP ON PRMyTimesheetDetailForApproval.Reviewer = HQRP.Reviewer
		WHERE VPUserName = ISNULL(@UserName, VPUserName) OR PRMyTimesheetDetailForApproval.KeyID = ISNULL(@KeyID, PRMyTimesheetDetailForApproval.KeyID)
	),
	TimeSheetStats_CTE(StartDate, UnlockedTimeSheets, LockedTimeSheets, ReadyToSendTimeSheets)
	AS
	(
		SELECT StartDate
			,COUNT(CASE WHEN [Status] = 0 THEN 1 ELSE NULL END)
			,COUNT(CASE WHEN [Status] = 1 THEN 1 ELSE NULL END)
			,COUNT(CASE WHEN [Status] = 2 THEN 1 ELSE NULL END)
		FROM
		(
			SELECT StartDate, [Status]
			FROM ApprovableTimeSheetEntries_CTE
			GROUP BY PRCo, EntryEmployee, StartDate, Sheet, [Status]) TimeSheetsThatHaveTimeCardEntriesApprovableByUser
		GROUP BY StartDate
	),
	TimeSheetEntriesToApprove_CTE(StartDate, TimeSheetEntriesToApprove)
	AS
	(
		SELECT StartDate, COUNT(1)
		FROM ApprovableTimeSheetEntries_CTE
		WHERE [Status] = 1 AND Approved <> 'Y'
		GROUP BY StartDate
	)

	SELECT DISTINCT ApprovableTimeSheetEntries_CTE.StartDate, UnlockedTimeSheets, LockedTimeSheets, ReadyToSendTimeSheets, ISNULL(TimeSheetEntriesToApprove, 0) AS TimeSheetEntriesToApprove, @UserName AS UserName, KeyID
	FROM ApprovableTimeSheetEntries_CTE
		INNER JOIN TimeSheetStats_CTE ON ApprovableTimeSheetEntries_CTE.StartDate = TimeSheetStats_CTE.StartDate
		LEFT JOIN TimeSheetEntriesToApprove_CTE ON ApprovableTimeSheetEntries_CTE.StartDate = TimeSheetEntriesToApprove_CTE.StartDate
	WHERE (TimeSheetEntriesToApprove <> 0 OR ReadyToSendTimeSheets > 0)

END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetApprovalGet] TO [VCSPortal]
GO
