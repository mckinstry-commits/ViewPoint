SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO













CREATE VIEW [dbo].[PRMyTimesheetDetailForApproval]
AS
/* This view does the complex joins needed to figure out who can approve a detail record.
	The output of this view has all unique values except for the reviewer column, 
		which means that filtering by a reviewer will give you unique rows.
	This view is also updatable for all PRMyTimesheetDetail columns and allows for deletes.
	This view currently doesn't allow inserts. 
	This view should also be setup to allow for ud fields if so desired. -JVH */

WITH TimeSheetDetailsApprovabeByReviewer(PRCo, EntryEmployee, StartDate, Sheet, Seq, [Status], KeyID, UniqueAttchID, ReviewerGroup, Reviewer)
AS
(
/*
	SELECT DISTINCT PRMyTimesheetDetail.PRCo, dbo.PRMyTimesheetDetail.EntryEmployee, dbo.PRMyTimesheetDetail.StartDate, dbo.PRMyTimesheetDetail.Sheet, dbo.PRMyTimesheetDetail.Seq, dbo.PRMyTimesheet.[Status], dbo.PRMyTimesheet.KeyID, dbo.PRMyTimesheet.UniqueAttchID, dbo.HQRG.ReviewerGroup, Reviewer
	FROM dbo.PRMyTimesheetDetail
		INNER JOIN dbo.PRMyTimesheet WITH (NOLOCK) ON dbo.PRMyTimesheetDetail.PRCo = dbo.PRMyTimesheet.PRCo
			AND dbo.PRMyTimesheetDetail.EntryEmployee = dbo.PRMyTimesheet.EntryEmployee
			AND dbo.PRMyTimesheetDetail.StartDate = dbo.PRMyTimesheet.StartDate
			AND dbo.PRMyTimesheetDetail.Sheet = dbo.PRMyTimesheet.Sheet
		LEFT OUTER JOIN dbo.JCJM WITH (NOLOCK) ON dbo.PRMyTimesheetDetail.JCCo = dbo.JCJM.JCCo 
			AND dbo.PRMyTimesheetDetail.Job = dbo.JCJM.Job 
		LEFT OUTER JOIN dbo.PREH WITH (NOLOCK) ON dbo.PRMyTimesheetDetail.PRCo = dbo.PREH.PRCo 
			AND dbo.PRMyTimesheetDetail.Employee = dbo.PREH.Employee 
		LEFT JOIN dbo.HQRG WITH (NOLOCK) ON dbo.JCJM.TimesheetRevGroup = dbo.HQRG.ReviewerGroup 
			OR dbo.PRMyTimesheetDetail.Job IS NULL AND dbo.PREH.TimesheetRevGroup = dbo.HQRG.ReviewerGroup 
		LEFT JOIN dbo.HQRD WITH (NOLOCK) ON dbo.HQRG.ReviewerGroup = dbo.HQRD.ReviewerGroup
	WHERE dbo.HQRG.ReviewerGroupType IS NULL -- For Timesheets that don't match up to any reviewer group
		OR dbo.HQRG.ReviewerGroupType = 2 -- ReviewerGroupType 2 is the Timesheet reviewer group type
*/
	SELECT DISTINCT PRMyTimesheetDetail.PRCo, dbo.PRMyTimesheetDetail.EntryEmployee, dbo.PRMyTimesheetDetail.StartDate, 
	dbo.PRMyTimesheetDetail.Sheet, dbo.PRMyTimesheetDetail.Seq, dbo.PRMyTimesheet.[Status], dbo.PRMyTimesheet.KeyID, 
	dbo.PRMyTimesheet.UniqueAttchID, dbo.HQRG.ReviewerGroup, HQRD.Reviewer
	FROM dbo.PRMyTimesheetDetail
		INNER JOIN dbo.PRMyTimesheet WITH (NOLOCK) ON dbo.PRMyTimesheetDetail.PRCo = dbo.PRMyTimesheet.PRCo
			AND dbo.PRMyTimesheetDetail.EntryEmployee = dbo.PRMyTimesheet.EntryEmployee
			AND dbo.PRMyTimesheetDetail.StartDate = dbo.PRMyTimesheet.StartDate
			AND dbo.PRMyTimesheetDetail.Sheet = dbo.PRMyTimesheet.Sheet
		LEFT OUTER JOIN dbo.JCJM WITH (NOLOCK) ON dbo.PRMyTimesheetDetail.JCCo = dbo.JCJM.JCCo 
			AND dbo.PRMyTimesheetDetail.Job = dbo.JCJM.Job 
		LEFT OUTER JOIN dbo.bPREH WITH (NOLOCK) ON dbo.PRMyTimesheetDetail.PRCo = dbo.bPREH.PRCo 
			AND dbo.PRMyTimesheetDetail.Employee = dbo.bPREH.Employee 
		LEFT JOIN dbo.HQRG WITH (NOLOCK) ON 
		isnull(dbo.JCJM.TimesheetRevGroup, dbo.bPREH.TimesheetRevGroup) = dbo.HQRG.ReviewerGroup 
		LEFT JOIN dbo.HQRD WITH (NOLOCK) ON dbo.HQRG.ReviewerGroup = dbo.HQRD.ReviewerGroup
	WHERE dbo.HQRG.ReviewerGroupType IS NULL -- For Timesheets that don't match up to any reviewer group
		OR dbo.HQRG.ReviewerGroupType = 2 -- ReviewerGroupType 2 is the Timesheet reviewer group type
)

SELECT bPRMyTimesheetDetail.*, [Status], UniqueAttchID, ReviewerGroup, Reviewer
FROM bPRMyTimesheetDetail
	INNER JOIN TimeSheetDetailsApprovabeByReviewer ON bPRMyTimesheetDetail.PRCo = TimeSheetDetailsApprovabeByReviewer.PRCo
		AND bPRMyTimesheetDetail.EntryEmployee = TimeSheetDetailsApprovabeByReviewer.EntryEmployee
		AND bPRMyTimesheetDetail.StartDate = TimeSheetDetailsApprovabeByReviewer.StartDate
		AND bPRMyTimesheetDetail.Sheet = TimeSheetDetailsApprovabeByReviewer.Sheet
		AND bPRMyTimesheetDetail.Seq = TimeSheetDetailsApprovabeByReviewer.Seq













GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/10/09
-- Description:	Delete Trigger
-- =============================================
CREATE TRIGGER  [dbo].[vtPRMyTimesheetDetailForApprovald]
   ON  [dbo].[PRMyTimesheetDetailForApproval]
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DELETE bPRMyTimesheetDetail
	FROM bPRMyTimesheetDetail
		INNER JOIN DELETED ON bPRMyTimesheetDetail.PRCo = DELETED.PRCo
			AND bPRMyTimesheetDetail.EntryEmployee = DELETED.EntryEmployee
			AND bPRMyTimesheetDetail.StartDate = DELETED.StartDate
			AND bPRMyTimesheetDetail.Sheet = DELETED.Sheet
			AND bPRMyTimesheetDetail.Seq = DELETED.Seq

END

GO
GRANT SELECT ON  [dbo].[PRMyTimesheetDetailForApproval] TO [public]
GRANT INSERT ON  [dbo].[PRMyTimesheetDetailForApproval] TO [public]
GRANT DELETE ON  [dbo].[PRMyTimesheetDetailForApproval] TO [public]
GRANT UPDATE ON  [dbo].[PRMyTimesheetDetailForApproval] TO [public]
GO
