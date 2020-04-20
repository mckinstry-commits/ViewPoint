SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* =============================================
* Author:		Chris Gall
* Create date:  4/11/12
* Description:	Copies a Crew Timesheet Detail to another timesheet
 =============================================*/
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetCopy]
	(@Key_PRCo bCompany, @Key_Crew varchar(10), @Key_PostDate bDate, 
	 @Key_SheetNum SMALLINT, @CopyFromPostDate bDate, @CopyFromSheet SMALLINT, 
	 @CopyHours BIT, @msg varchar(256) output)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rcode int
	SET @rcode = 0

	-- Make sure the PRRH record exists before copying, if not throw an error
	IF NOT EXISTS(SELECT 1 FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @CopyFromPostDate AND SheetNum = @CopyFromSheet)
		BEGIN			
			SET @msg = 'The copy-from timesheet doesn''t exist for the given crew, post date and sheet number.' + @msg
			SET @rcode = 1
			GOTO vspExit
		END

	-- COPY THE HEADER
	UPDATE PRRH SET
		 PRRH.PhaseGroup = copy.PhaseGroup
		,PRRH.Phase1 = copy.Phase1
		,PRRH.Phase1Units = NULL
		,PRRH.Phase1CostType = copy.Phase1CostType
		,PRRH.Phase2 = copy.Phase2
		,PRRH.Phase2Units = NULL
		,PRRH.Phase2CostType = copy.Phase2CostType
		,PRRH.Phase3 = copy.Phase3
		,PRRH.Phase3Units = NULL
		,PRRH.Phase3CostType = copy.Phase3CostType
		,PRRH.Phase4 = copy.Phase4
		,PRRH.Phase4Units = NULL
		,PRRH.Phase4CostType = copy.Phase4CostType
		,PRRH.Phase5 = copy.Phase5
		,PRRH.Phase5Units = NULL
		,PRRH.Phase5CostType = copy.Phase5CostType
		,PRRH.Phase6 = copy.Phase6
		,PRRH.Phase6Units = NULL
		,PRRH.Phase6CostType = copy.Phase6CostType
		,PRRH.Phase7 = copy.Phase7
		,PRRH.Phase7Units = NULL
		,PRRH.Phase7CostType = copy.Phase7CostType
		,PRRH.Phase8 = copy.Phase8
		,PRRH.Phase8Units = NULL
		,PRRH.Phase8CostType = copy.Phase8CostType	
	FROM 
		PRRH 
	INNER JOIN PRRH copy ON 
		copy.PRCo = @Key_PRCo
		AND copy.Crew = @Key_Crew
		AND copy.PostDate = @CopyFromPostDate
		AND copy.SheetNum = @CopyFromSheet		
	WHERE
		PRRH.PRCo = @Key_PRCo
		AND PRRH.Crew = @Key_Crew
		AND PRRH.PostDate = @Key_PostDate
		AND PRRH.SheetNum = @Key_SheetNum
		
		
	-- COPY Employees
	INSERT INTO PRRE
		(PRCo
		,Crew
		,PostDate
		,SheetNum
		,Employee
		,LineSeq
		,Craft
		,Class
		,Phase1RegHrs
		,Phase1OTHrs
		,Phase1DblHrs
		,Phase2RegHrs
		,Phase2OTHrs
		,Phase2DblHrs
		,Phase3RegHrs
		,Phase3OTHrs
		,Phase3DblHrs
		,Phase4RegHrs
		,Phase4OTHrs
		,Phase4DblHrs
		,Phase5RegHrs
		,Phase5OTHrs
		,Phase5DblHrs
		,Phase6RegHrs
		,Phase6OTHrs
		,Phase6DblHrs
		,Phase7RegHrs
		,Phase7OTHrs
		,Phase7DblHrs
		,Phase8RegHrs
		,Phase8OTHrs
		,Phase8DblHrs
		,RegRate
		,OTRate
		,DblRate
		,TotalHrs)
	(SELECT
		 @Key_PRCo		
		,@Key_Crew
		,@Key_PostDate
		,@Key_SheetNum
		,Employee
		,LineSeq
		,Craft
		,Class
		,CASE WHEN @CopyHours = 1 THEN Phase1RegHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase1OTHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase1DblHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase2RegHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase2OTHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase2DblHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase3RegHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase3OTHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase3DblHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase4RegHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase4OTHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase4DblHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase5RegHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase5OTHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase5DblHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase6RegHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase6OTHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase6DblHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase7RegHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase7OTHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase7DblHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase8RegHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase8OTHrs ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase8DblHrs ELSE NULL END
		,RegRate
		,OTRate
		,DblRate
		,TotalHrs
	FROM PRRE
	WHERE
		PRCo = @Key_PRCo
		AND Crew = @Key_Crew
		AND PostDate = @CopyFromPostDate
		AND SheetNum = @CopyFromSheet
	)
	
	-- COPY Equipment
	INSERT INTO PRRQ
		(PRCo
		,Crew
		,PostDate
		,SheetNum
		,EMCo
		,EMGroup
		,Equipment
		,Employee
		,Phase1Usage
		,Phase1CType
		,Phase1Rev
		,Phase2Usage
		,Phase2CType
		,Phase2Rev
		,Phase3Usage
		,Phase3CType
		,Phase3Rev
		,Phase4Usage
		,Phase4CType
		,Phase4Rev
		,Phase5Usage
		,Phase5CType
		,Phase5Rev
		,Phase6Usage
		,Phase6CType
		,Phase6Rev
		,Phase7Usage
		,Phase7CType
		,Phase7Rev
		,Phase8Usage
		,Phase8CType
		,Phase8Rev
		,LineSeq
		,TotalUsage)
	(SELECT
		 @Key_PRCo		
		,@Key_Crew
		,@Key_PostDate
		,@Key_SheetNum
		,EMCo
		,EMGroup
		,Equipment
		,Employee
		,CASE WHEN @CopyHours = 1 THEN Phase1Usage ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase1CType ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase1Rev ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase2Usage ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase2CType ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase2Rev ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase3Usage ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase3CType ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase3Rev ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase4Usage ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase4CType ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase4Rev ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase5Usage ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase5CType ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase5Rev ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase6Usage ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase6CType ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase6Rev ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase7Usage ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase7CType ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase7Rev ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase8Usage ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase8CType ELSE NULL END
		,CASE WHEN @CopyHours = 1 THEN Phase8Rev ELSE NULL END
		,LineSeq
		,TotalUsage
	FROM PRRQ
	WHERE
		PRCo = @Key_PRCo
		AND Crew = @Key_Crew
		AND PostDate = @CopyFromPostDate
		AND SheetNum = @CopyFromSheet
	)
	
	vspExit:
		return @rcode
END
GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetCopy] TO [VCSPortal]
GO
