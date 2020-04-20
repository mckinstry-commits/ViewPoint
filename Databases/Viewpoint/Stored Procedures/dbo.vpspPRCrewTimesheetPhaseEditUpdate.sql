SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Chris Gall
-- Create date: 4/26/12
-- Description:	Updates the phases set for a Crew Timesheet in PRRH
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRCrewTimesheetPhaseEditUpdate]
	(@Key_PRCo bCompany, @Key_Crew varchar(10), @Key_PostDate bDate, @Key_SheetNum SMALLINT,
	 @Id int, @Phase bPhase)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @Old_Phase bPhase, @rcode INTEGER, @msg AS VARCHAR(255)

	IF @Id = 1
	BEGIN
		SELECT @Old_Phase = Phase1 FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum	
	END
	IF @Id = 2
	BEGIN
		SELECT @Old_Phase = Phase2 FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum	
	END
	IF @Id = 3
	BEGIN
		SELECT @Old_Phase = Phase3 FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum	
	END
	IF @Id = 4
	BEGIN							
		SELECT @Old_Phase = Phase4 FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum						
	END
	IF @Id = 5
	BEGIN
		SELECT @Old_Phase = Phase5 FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
	END
	IF @Id = 6
	BEGIN
		SELECT @Old_Phase = Phase6 FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum		
	END
	IF @Id = 7
	BEGIN
		SELECT @Old_Phase = Phase7 FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum	
	END
	IF @Id = 8
	BEGIN
		SELECT @Old_Phase = Phase8 FROM PRRH WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum		
	END
		
	-- Since users can type the phase in, lets format it for them, but only if its not blank
	IF @Phase IS NOT NULL AND @Phase <> ''
	BEGIN		
		DECLARE @InputMask VARCHAR(30), @FormattedValue VARCHAR(20)

		SELECT @InputMask = InputMask 
		FROM DDDTShared WITH (NOLOCK)
		WHERE Datatype = 'bPhase'
			
		--Reset formatted value
		SET @FormattedValue = NULL

		-- Format value to phase
		EXEC @rcode = dbo.bspHQFormatMultiPart @Phase, @InputMask, @FormattedValue OUTPUT
			
		IF @rcode = 0 
		BEGIN
			SET @Phase = @FormattedValue
		END
	END
		
	IF (@Old_Phase IS NULL AND @Phase IS NOT NULL AND @Phase <> '') OR (@Old_Phase <> @Phase)
	BEGIN
		DECLARE @JCCo as bCompany, @Job as bJob, @PhaseGroup bGroup
	
		-- Get the JCCo, Job for the crew timesheet
		SELECT 
			 @JCCo = JCCo
			,@Job = Job
			,@PhaseGroup = PhaseGroup
		FROM
			PRRH
		WHERE
			PRCo = @Key_PRCo
			AND Crew = @Key_Crew
			AND PostDate = @Key_PostDate
			AND SheetNum = @Key_SheetNum
	
		-- Validate the phase
		EXEC @rcode = bspPRTSPhaseVal @Key_PRCo, @Key_Crew, @JCCo, @Job, @PhaseGroup, @Phase, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @msg = 'Phase ' + CAST(@Id AS VARCHAR) + ' validation failed - ' + @msg
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
		
		-- UPDATE the PRRH and clear progress/employee/equipment data if exists
		IF @Id = 1
		BEGIN
			UPDATE PRRH SET Phase1 = @Phase, Phase1Units = NULL, Phase1CostType = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear employee hours (if exists)
			UPDATE PRRE SET Phase1RegHrs = NULL, Phase1OTHrs = NULL, Phase1DblHrs = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear equipment hours (if exists)
			UPDATE PRRQ SET Phase1Usage = NULL, Phase1CType = NULL, Phase1Rev = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum					
		END
		IF @Id = 2
		BEGIN
			UPDATE PRRH SET Phase2 = @Phase, Phase2Units = NULL, Phase2CostType = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear employee hours (if exists)
			UPDATE PRRE SET Phase2RegHrs = NULL, Phase2OTHrs = NULL, Phase2DblHrs = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear equipment hours (if exists)
			UPDATE PRRQ SET Phase2Usage = NULL, Phase2CType = NULL, Phase2Rev = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum					
		END
		IF @Id = 3
		BEGIN
			UPDATE PRRH SET Phase3 = @Phase, Phase3Units = NULL, Phase3CostType = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear employee hours (if exists)
			UPDATE PRRE SET Phase3RegHrs = NULL, Phase3OTHrs = NULL, Phase3DblHrs = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear equipment hours (if exists)
			UPDATE PRRQ SET Phase3Usage = NULL, Phase3CType = NULL, Phase3Rev = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum					
		END
		IF @Id = 4
		BEGIN
			UPDATE PRRH SET Phase4 = @Phase, Phase4Units = NULL, Phase4CostType = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear employee hours (if exists)
			UPDATE PRRE SET Phase4RegHrs = NULL, Phase4OTHrs = NULL, Phase4DblHrs = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear equipment hours (if exists)
			UPDATE PRRQ SET Phase4Usage = NULL, Phase4CType = NULL, Phase4Rev = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum					
		END
		IF @Id = 5
		BEGIN
			UPDATE PRRH SET Phase5 = @Phase, Phase5Units = NULL, Phase5CostType = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear employee hours (if exists)
			UPDATE PRRE SET Phase5RegHrs = NULL, Phase5OTHrs = NULL, Phase5DblHrs = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear equipment hours (if exists)
			UPDATE PRRQ SET Phase5Usage = NULL, Phase5CType = NULL, Phase5Rev = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum					
		END
		IF @Id = 6
		BEGIN
			UPDATE PRRH SET Phase6 = @Phase, Phase6Units = NULL, Phase6CostType = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear employee hours (if exists)
			UPDATE PRRE SET Phase6RegHrs = NULL, Phase6OTHrs = NULL, Phase6DblHrs = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear equipment hours (if exists)
			UPDATE PRRQ SET Phase6Usage = NULL, Phase6CType = NULL, Phase6Rev = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum					
		END
		IF @Id = 7
		BEGIN
			UPDATE PRRH SET Phase7 = @Phase, Phase7Units = NULL, Phase7CostType = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear employee hours (if exists)
			UPDATE PRRE SET Phase7RegHrs = NULL, Phase7OTHrs = NULL, Phase7DblHrs = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear equipment hours (if exists)
			UPDATE PRRQ SET Phase7Usage = NULL, Phase7CType = NULL, Phase7Rev = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum					
		END
		IF @Id = 8
		BEGIN
			UPDATE PRRH SET Phase8 = @Phase, Phase8Units = NULL, Phase8CostType = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear employee hours (if exists)
			UPDATE PRRE SET Phase8RegHrs = NULL, Phase8OTHrs = NULL, Phase8DblHrs = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum
			
			-- Clear equipment hours (if exists)
			UPDATE PRRQ SET Phase8Usage = NULL, Phase8CType = NULL, Phase8Rev = NULL
			WHERE PRCo = @Key_PRCo AND Crew = @Key_Crew AND PostDate = @Key_PostDate AND SheetNum = @Key_SheetNum					
		END
		
	END



	vspExit:
END

GO
GRANT EXECUTE ON  [dbo].[vpspPRCrewTimesheetPhaseEditUpdate] TO [VCSPortal]
GO
