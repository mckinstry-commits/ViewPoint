SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 4/16/2012
-- Description:	Deletes the record from PRRE
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetEquipmentDelete]
	(@Original_Key_PRCo bCompany, @Original_Key_Crew VARCHAR(10), @Original_Key_PostDate bDate, 
	@Original_Key_SheetNum SMALLINT, @Original_Key_EMCo bCompany, @Original_Key_EMGroup bGroup,
	@Original_Key_Equipment bEquip, @Original_Key_LineSeq SMALLINT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @isLocked AS BIT, @lineSeq AS SMALLINT
	
	SELECT 
		@isLocked = CASE WHEN PRRH.[Status] = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
	FROM [dbo].[PRRH] WITH (NOLOCK)
	WHERE
		PRRH.PRCo = @Original_Key_PRCo 
		AND PRRH.Crew = @Original_Key_Crew
		AND PRRH.PostDate = @Original_Key_PostDate
		AND PRRH.SheetNum = @Original_Key_SheetNum

	IF @isLocked = 1
	BEGIN
		RAISERROR('This crew time sheet is locked down. To delete records change the time sheet''s status to "Not Completed".', 16, 1)
	END
	ELSE
	BEGIN
		DELETE FROM 
			PRRQ		
		WHERE 
			PRRQ.PRCo = @Original_Key_PRCo 
			AND PRRQ.Crew = @Original_Key_Crew
			AND PRRQ.PostDate = @Original_Key_PostDate
			AND PRRQ.SheetNum = @Original_Key_SheetNum
			AND PRRQ.EMCo = @Original_Key_EMCo
			AND PRRQ.EMGroup = @Original_Key_EMGroup
			AND PRRQ.Equipment = @Original_Key_Equipment
			AND PRRQ.LineSeq = @Original_Key_LineSeq
    END
	 vspExit:
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetEquipmentDelete] TO [VCSPortal]
GO
