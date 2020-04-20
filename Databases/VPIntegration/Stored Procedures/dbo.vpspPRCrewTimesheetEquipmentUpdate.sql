SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
-- Author:		Chris Gall
-- Create date: 4/16/2012
-- Description:	Updates the record from PRRE
-- =============================================*/
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetEquipmentUpdate]
	(@Original_Key_PRCo bCompany, @Original_Key_Crew varchar(10), 
	@Original_Key_PostDate bDate, @Original_Key_SheetNum SMALLINT, 
	@Original_Key_Equipment bEquip, 
	@Original_Key_EMCo bCompany, @Original_Key_EMGroup bGroup, 
	@Original_Key_LineSeq SMALLINT,
	@Employee bEmployee,
	@Phase1Usage bHrs, @Phase1CType bJCCType, @Phase1Rev bRevCode,
	@Phase2Usage bHrs, @Phase2CType bJCCType, @Phase2Rev bRevCode,
	@Phase3Usage bHrs, @Phase3CType bJCCType, @Phase3Rev bRevCode,
	@Phase4Usage bHrs, @Phase4CType bJCCType, @Phase4Rev bRevCode,
	@Phase5Usage bHrs, @Phase5CType bJCCType, @Phase5Rev bRevCode,
	@Phase6Usage bHrs, @Phase6CType bJCCType, @Phase6Rev bRevCode,
	@Phase7Usage bHrs, @Phase7CType bJCCType, @Phase7Rev bRevCode,
	@Phase8Usage bHrs, @Phase8CType bJCCType, @Phase8Rev bRevCode)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @isLocked AS BIT, @rcode INTEGER, @msg AS VARCHAR(255)
	
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
		RAISERROR('This crew time sheet is locked down. To edit records change the time sheet''s status to "Not Completed".', 16, 1)
	END
	ELSE
	BEGIN
			
		UPDATE 
			PRRQ
		SET
			 Employee = @Employee
			,Phase1Usage = @Phase1Usage, Phase1CType = @Phase1CType, Phase1Rev = @Phase1Rev
			,Phase2Usage = @Phase2Usage, Phase2CType = @Phase2CType, Phase2Rev = @Phase2Rev
			,Phase3Usage = @Phase3Usage, Phase3CType = @Phase3CType, Phase3Rev = @Phase3Rev
			,Phase4Usage = @Phase4Usage, Phase4CType = @Phase4CType, Phase4Rev = @Phase4Rev
			,Phase5Usage = @Phase5Usage, Phase5CType = @Phase5CType, Phase5Rev = @Phase5Rev
			,Phase6Usage = @Phase6Usage, Phase6CType = @Phase6CType, Phase6Rev = @Phase6Rev
			,Phase7Usage = @Phase7Usage, Phase7CType = @Phase7CType, Phase7Rev = @Phase7Rev
			,Phase8Usage = @Phase8Usage, Phase8CType = @Phase8CType, Phase8Rev = @Phase8Rev
			,TotalUsage = ISNULL(@Phase1Usage, 0) +
						  ISNULL(@Phase2Usage, 0) +
						  ISNULL(@Phase3Usage, 0) +
						  ISNULL(@Phase4Usage, 0) +
						  ISNULL(@Phase5Usage, 0) +
						  ISNULL(@Phase6Usage, 0) +
						  ISNULL(@Phase7Usage, 0) +
						  ISNULL(@Phase8Usage, 0)			
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
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetEquipmentUpdate] TO [VCSPortal]
GO
