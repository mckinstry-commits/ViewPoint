SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 7/5/09
-- Description:	Copy the PRMyTimesheetDetails from one sheet to another.  Parameters should be
--				validated before using this, that way we are not doing double validation.
-- Modifified:  ECV 06/06/11 - TK-14637 Add SMCostType and SMJCCostType to new record.
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetCopy]
	(@Key_PRCo bCompany, @Key_EntryEmployee bEmployee, @Key_StartDate bDate, @Key_Sheet SMALLINT, @CopyFromStartDate bDate, @CopyFromSheet SMALLINT, @CreatedBy bVPUserName, @CreatedOn bDate, @CopyHours BIT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- This should only be called by a procedure that has already validated the parameters.

	INSERT INTO [dbo].[PRMyTimesheetDetail]
		   ([PRCo]
		   ,[EntryEmployee]
		   ,[StartDate]
		   ,[Sheet]
		   ,[Seq]
		   ,[Employee]
		   ,[JCCo]
		   ,[Job]
		   ,[PhaseGroup]
		   ,[Phase]
		   ,[EarnCode]
		   ,[Craft]
		   ,[Class]
		   ,[Shift]
		   ,[DayOne]
		   ,[DayTwo]
		   ,[DayThree]
		   ,[DayFour]
		   ,[DayFive]
		   ,[DaySix]
		   ,[DaySeven]
		   ,[CreatedBy]
		   ,[CreatedOn]
		   ,[Approved]
		   ,[LineType]
		   ,[SMCo]
		   ,[WorkOrder]
		   ,[Scope]
		   ,[PayType]
		   ,[SMCostType]
		   ,[SMJCCostType])

	(SELECT 
			@Key_PRCo, 
			@Key_EntryEmployee, 
			@Key_StartDate,
			@Key_Sheet,
			ROW_NUMBER() OVER(Order by Seq) as Seq, 
			Employee, 
			JCCo, 
			Job, 
			PhaseGroup, 
			Phase, 
			EarnCode, 
			Craft, 
			Class, 
			Shift, 
			CASE WHEN @CopyHours = 1 THEN [DayOne] ELSE NULL END, 
			CASE WHEN @CopyHours = 1 THEN [DayTwo] ELSE NULL END, 
			CASE WHEN @CopyHours = 1 THEN [DayThree] ELSE NULL END, 
			CASE WHEN @CopyHours = 1 THEN [DayFour] ELSE NULL END, 
			CASE WHEN @CopyHours = 1 THEN [DayFive] ELSE NULL END, 
			CASE WHEN @CopyHours = 1 THEN [DaySix] ELSE NULL END, 
			CASE WHEN @CopyHours = 1 THEN [DaySeven] ELSE NULL END, 
			@CreatedBy,
			@CreatedOn,
			'N',
			LineType,
			SMCo,
			WorkOrder,
			Scope,
			PayType,
			SMCostType,
			SMJCCostType
	FROM PRMyTimesheetDetail
	WHERE PRCo = @Key_PRCo AND EntryEmployee = @Key_EntryEmployee AND StartDate = @CopyFromStartDate AND Sheet = @CopyFromSheet)

	vspExit:
END



GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetCopy] TO [VCSPortal]
GO
