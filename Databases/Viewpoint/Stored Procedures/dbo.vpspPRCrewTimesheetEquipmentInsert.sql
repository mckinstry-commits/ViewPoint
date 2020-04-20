SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 4/16/2012
-- Description:	Inserts the record into PRRE
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetEquipmentInsert]
	(@Key_PRCo bCompany, @Key_Crew varchar(10), @Key_PostDate bDate, @Key_SheetNum SMALLINT, 
	 @Key_Equipment bEquip, @Key_EMCo bCompany, @Key_EMGroup bGroup,
	 @Key_LineSeq AS VARCHAR(10), @Employee bEmployee, 
	 @Phase1Usage bHrs = NULL, @Phase1CType bJCCType = NULL, @Phase1Rev bRevCode = NULL,
	 @Phase2Usage bHrs = NULL, @Phase2CType bJCCType = NULL, @Phase2Rev bRevCode = NULL,
	 @Phase3Usage bHrs = NULL, @Phase3CType bJCCType = NULL, @Phase3Rev bRevCode = NULL,
	 @Phase4Usage bHrs = NULL, @Phase4CType bJCCType = NULL, @Phase4Rev bRevCode = NULL,
	 @Phase5Usage bHrs = NULL, @Phase5CType bJCCType = NULL, @Phase5Rev bRevCode = NULL,
	 @Phase6Usage bHrs = NULL, @Phase6CType bJCCType = NULL, @Phase6Rev bRevCode = NULL,
	 @Phase7Usage bHrs = NULL, @Phase7CType bJCCType = NULL, @Phase7Rev bRevCode = NULL,
	 @Phase8Usage bHrs = NULL, @Phase8CType bJCCType = NULL, @Phase8Rev bRevCode = NULL)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @isLocked AS BIT, @lineSeq AS SMALLINT, @rcode INTEGER, @msg AS VARCHAR(255), 
			@emCo bCompany, @emGroup bGroup
	
	SELECT 
		@isLocked = CASE WHEN PRRH.[Status] = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
	FROM [dbo].[PRRH] WITH (NOLOCK)
	WHERE
		PRRH.PRCo = @Key_PRCo 
		AND PRRH.Crew = @Key_Crew
		AND PRRH.PostDate = @Key_PostDate
		AND PRRH.SheetNum = @Key_SheetNum

	IF @isLocked = 1
	BEGIN
		RAISERROR('This crew time sheet is locked down. To add records change the time sheet''s status to "Not Completed".', 16, 1)
	END
	ELSE
	BEGIN
		
		-- Derive the EMCo and EMGroup from various setups
		SELECT @emCo = EMCo FROM PRCO WHERE PRCo = @Key_PRCo
		SELECT @emGroup = EMGroup FROM HQCO WHERE HQCo = @emCo
	
		-- Find the next available line seq if + or '' passed in
		IF @Key_LineSeq = '+' OR @Key_LineSeq = '' OR @Key_LineSeq IS NULL
			BEGIN
				SELECT @lineSeq = MAX(LineSeq) + 1
				FROM PRRQ
				WHERE PRCo = @Key_PRCo 
					AND Crew = @Key_Crew
					AND PostDate = @Key_PostDate
					AND SheetNum = @Key_SheetNum
					AND EMCo = @Key_EMCo
					AND EMGroup = @Key_EMGroup
					AND Equipment = @Key_Equipment									
			END
		ELSE
			BEGIN
				-- Otherwise, convert varchar to int (FUTURE: if we allow users to enter this)
				SET @lineSeq = CAST(@Key_LineSeq AS SMALLINT)
			END
	
		IF @lineSeq IS NULL
			BEGIN
				SET @lineSeq = 1
			END		
	
		INSERT INTO PRRQ (
			 PRCo
			,Crew
			,PostDate
			,SheetNum
			,EMCo
			,EMGroup
			,Equipment
			,Employee
			,LineSeq
			,Phase1Usage,Phase1CType,Phase1Rev
			,Phase2Usage,Phase2CType,Phase2Rev
			,Phase3Usage,Phase3CType,Phase3Rev
			,Phase4Usage,Phase4CType,Phase4Rev
			,Phase5Usage,Phase5CType,Phase5Rev
			,Phase6Usage,Phase6CType,Phase6Rev
			,Phase7Usage,Phase7CType,Phase7Rev
			,Phase8Usage,Phase8CType,Phase8Rev
			,TotalUsage
		)
		VALUES
		(
			 @Key_PRCo
			,@Key_Crew	
			,@Key_PostDate
			,@Key_SheetNum
			,@emCo
			,@emGroup
			,@Key_Equipment
			,@Employee
			,@lineSeq
			,@Phase1Usage,@Phase1CType,@Phase1Rev
			,@Phase2Usage,@Phase2CType,@Phase2Rev
			,@Phase3Usage,@Phase3CType,@Phase3Rev
			,@Phase4Usage,@Phase4CType,@Phase4Rev
			,@Phase5Usage,@Phase5CType,@Phase5Rev
			,@Phase6Usage,@Phase6CType,@Phase6Rev
			,@Phase7Usage,@Phase7CType,@Phase7Rev
			,@Phase8Usage,@Phase8CType,@Phase8Rev
			,ISNULL(@Phase1Usage, 0) +
			 ISNULL(@Phase2Usage, 0) +
			 ISNULL(@Phase3Usage, 0) +
			 ISNULL(@Phase4Usage, 0) +
			 ISNULL(@Phase5Usage, 0) +
			 ISNULL(@Phase6Usage, 0) +
			 ISNULL(@Phase7Usage, 0) +
			 ISNULL(@Phase8Usage, 0)
		)
    END
	 vspExit:
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetEquipmentInsert] TO [VCSPortal]
GO
