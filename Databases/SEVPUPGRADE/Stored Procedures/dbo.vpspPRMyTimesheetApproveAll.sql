SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/3/09
-- Description:	Updates all the records that a user is able to approve for a specific start date
-- Modification: EN 6/6/11 D-02028 when insert into PRMyTimesheetDetail, plug CreatedOn date with no timestamp by using dbo.vfDateOnly() rather than GETDATE()
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyTimesheetApproveAll]
	(@UserName bVPUserName, @StartDate bDate)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	UPDATE PRMyTimesheetDetail
		SET Approved = 'Y'
				,ApprovedBy = @UserName
				,ApprovedOn = dbo.vfDateOnly()
	FROM PRMyTimesheetDetail
		INNER JOIN
		(
			SELECT DISTINCT PRCo, EntryEmployee, StartDate, Sheet, Seq
			FROM PRMyTimesheetDetailForApproval
				INNER JOIN HQRP ON PRMyTimesheetDetailForApproval.Reviewer = HQRP.Reviewer
			WHERE LineType = 'J' --We are only supporting job time in connects right now
				AND Approved = 'N' AND [Status] = 1 AND VPUserName = @UserName AND StartDate = @StartDate) TimeCardsToApprove
		ON PRMyTimesheetDetail.PRCo = TimeCardsToApprove.PRCo
			AND PRMyTimesheetDetail.EntryEmployee = TimeCardsToApprove.EntryEmployee
			AND PRMyTimesheetDetail.StartDate = TimeCardsToApprove.StartDate
			AND PRMyTimesheetDetail.Sheet = TimeCardsToApprove.Sheet
			AND PRMyTimesheetDetail.Seq = TimeCardsToApprove.Seq
	
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimesheetApproveAll] TO [VCSPortal]
GO
