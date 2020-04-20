SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
















CREATE VIEW [dbo].[PRMyTimesheetApproval]
AS

	WITH TimeSheetStats_CTE(StartDate, Reviewer, UnlockedTimeSheets, LockedTimeSheets, ReadyToSendTimeSheets)
	AS
	(
		SELECT StartDate
			,Reviewer
			,COUNT(CASE WHEN [Status] = 0 THEN 1 ELSE NULL END)
			,COUNT(CASE WHEN [Status] = 1 THEN 1 ELSE NULL END)
			,COUNT(CASE WHEN [Status] = 2 THEN 1 ELSE NULL END)
		FROM
		(
			SELECT StartDate, [Status], Reviewer
			FROM PRMyTimesheetDetailForApproval
			GROUP BY PRCo, EntryEmployee, StartDate, Sheet, [Status], Reviewer) TimeSheetsThatHaveTimeCardEntriesApprovableByUser
		GROUP BY StartDate, Reviewer
	),
	TimeSheetEntriesToApprove_CTE(StartDate, Reviewer, TimeSheetEntriesToApprove)
	AS
	(
		SELECT StartDate, Reviewer, COUNT(1)
		FROM PRMyTimesheetDetailForApproval
		WHERE [Status] = 1 AND Approved <> 'Y'
		GROUP BY StartDate, Reviewer
	)

	SELECT DISTINCT PRMyTimesheetDetailForApproval.PRCo
		,PRMyTimesheetDetailForApproval.StartDate
		,PRMyTimesheetDetailForApproval.Reviewer
		,UnlockedTimeSheets
		,LockedTimeSheets
		,ReadyToSendTimeSheets
		,ISNULL(TimeSheetEntriesToApprove, 0) AS TimeSheetEntriesToApprove
	FROM PRMyTimesheetDetailForApproval
		LEFT JOIN TimeSheetStats_CTE ON PRMyTimesheetDetailForApproval.StartDate = TimeSheetStats_CTE.StartDate
			-- NULL <> NULL therefore we need a manual check to compare for nulls
			AND (PRMyTimesheetDetailForApproval.Reviewer = TimeSheetStats_CTE.Reviewer OR (PRMyTimesheetDetailForApproval.Reviewer IS NULL AND TimeSheetStats_CTE.Reviewer IS NULL))
		LEFT JOIN TimeSheetEntriesToApprove_CTE ON PRMyTimesheetDetailForApproval.StartDate = TimeSheetEntriesToApprove_CTE.StartDate
			-- NULL <> NULL therefore we need a manual check to compare for nulls
			AND (PRMyTimesheetDetailForApproval.Reviewer = TimeSheetEntriesToApprove_CTE.Reviewer OR (PRMyTimesheetDetailForApproval.Reviewer IS NULL AND TimeSheetEntriesToApprove_CTE.Reviewer IS NULL))
	/*WHERE ([Status] BETWEEN 1 AND 3)*/
	WHERE ([Status] BETWEEN 0 AND 3)














GO
GRANT SELECT ON  [dbo].[PRMyTimesheetApproval] TO [public]
GRANT INSERT ON  [dbo].[PRMyTimesheetApproval] TO [public]
GRANT DELETE ON  [dbo].[PRMyTimesheetApproval] TO [public]
GRANT UPDATE ON  [dbo].[PRMyTimesheetApproval] TO [public]
GRANT SELECT ON  [dbo].[PRMyTimesheetApproval] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRMyTimesheetApproval] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRMyTimesheetApproval] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRMyTimesheetApproval] TO [Viewpoint]
GO
