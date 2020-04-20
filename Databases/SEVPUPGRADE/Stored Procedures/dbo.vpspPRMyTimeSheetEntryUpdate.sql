SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 06/24/09
-- Modified:    09/25/12 JA via TEJ TK-18041 Made changes to VC stored procs to conform to new V6 stored proc signature
--
-- Description:	Updates the detail record from vPRMyTimesheetDetail
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetEntryUpdate]
	(@PersonalTimeSheet bYN, @Original_Key_PRCo bCompany, @Original_Key_EntryEmployee bEmployee, @Original_Key_StartDate bDate, @Original_Key_Sheet SMALLINT, @Original_Key_Seq_Seq SMALLINT, @Key_PRCo bCompany, @Key_EntryEmployee bEmployee, @Key_StartDate bDate, @Key_Sheet SMALLINT, @Key_Seq_Seq SMALLINT, @Employee bEmployee, @JCCo bCompany, @Job bJob, @Phase bPhase, @EarnCode bEDLCode, @Craft bCraft, @Class bClass, @Shift TINYINT, @DayOne bHrs, @DayTwo bHrs, @DayThree bHrs, @DayFour bHrs, @DayFive bHrs, @DaySix bHrs, @DaySeven bHrs, @ShortDatePattern VARCHAR(20), @Memo VARCHAR(500))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode AS INTEGER,
		@msg AS VARCHAR(255)
	
	IF dbo.vpIsMyTimeSheetInStatus(@Key_PRCo, @Key_EntryEmployee, @Key_StartDate, @Key_Sheet, 1) = 1
	BEGIN
		RAISERROR('This time sheet is locked down. To update records change the time sheet''s status to "Unlocked".', 16, 1)
		GOTO vspExit
	END

	DECLARE @InputMask VARCHAR(30), 
		@FormattedValue VARCHAR(20),
		@PhaseGroup bGroup,
		@AllowNoPhase bYN

	-- Set values to null if they are empty strings
	SELECT @Job = CASE WHEN dbo.vpfIsNullOrEmpty(@Job) = 1 THEN NULL ELSE @Job END,
		@Phase = CASE WHEN dbo.vpfIsNullOrEmpty(@Phase) = 1 THEN NULL ELSE @Phase END,
		@Craft = CASE WHEN dbo.vpfIsNullOrEmpty(@Craft) = 1 THEN NULL ELSE @Craft END,
		@Class = CASE WHEN dbo.vpfIsNullOrEmpty(@Class) = 1 THEN NULL ELSE @Class END
		
	IF NOT EXISTS(SELECT TOP 1 1
		FROM PREH EntryEmployee CROSS JOIN PREH Employee
		WHERE EntryEmployee.PRCo = @Key_PRCo AND EntryEmployee.Employee = @Key_EntryEmployee
			AND Employee.PRCo = @Key_PRCo AND Employee.Employee = @Employee
			AND EntryEmployee.PRGroup = Employee.PRGroup)
	BEGIN
		SELECT @rcode = 1, @msg = 'Employee validation failed. - You must select an employee that is in the same PRGroup as you.'
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END
	
	SELECT @AllowNoPhase = AllowNoPhase
	FROM PRCO WITH (NOLOCK)
	WHERE PRCo = @Key_PRCo

	IF @JCCo IS NULL AND @Job IS NULL AND @Phase IS NULL
	BEGIN
		GOTO skipJCCO_Job_Phase_validation
	END
	
	--JCCo validation
	IF @JCCo IS NULL
	BEGIN
		IF @AllowNoPhase <> 'Y'
		BEGIN
			SET @msg = 'JCCo validation failed. JCCo required for Phase.'
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END
	ELSE
	BEGIN
		EXEC @rcode = bspPRJCCompanyVal @jcco = @JCCo, @phasegrp = @PhaseGroup OUTPUT, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @msg = 'JCCo validation failed - ' + @msg
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END
	
	--Job Validation
	IF @Job IS NULL
	BEGIN
		IF @AllowNoPhase <> 'Y'
		BEGIN
			SET @msg = 'Job validation failed. Job required for Phase.'
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END
	ELSE
	BEGIN
		SELECT @InputMask = InputMask 
		FROM DDDTShared WITH (NOLOCK)
		WHERE Datatype = 'bJob'
			
		--Reset formatted value
		SET @FormattedValue = NULL
		
		-- Format value to job
		EXEC @rcode = dbo.bspHQFormatMultiPart @Job, @InputMask, @FormattedValue OUTPUT
			
		IF @rcode = 0 
		BEGIN
			SET @Job = @FormattedValue
		END
	
		EXEC @rcode = bspPRTSJobVal @jcco = @JCCo, @job = @Job, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @msg = 'Job validation failed - ' + @msg
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END
	
	--Phase Validation
	IF @Phase IS NULL
	BEGIN
		IF @AllowNoPhase <> 'Y'
		BEGIN
			SET @msg = 'Phase validation failed. Phase required.'
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END
	ELSE
	BEGIN
		-- Get input mask for bPhase
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
	
		EXEC @rcode = bspPRPhaseVal @prco = @Key_PRCo, @jcco = @JCCo, @job = @Job, @phasegrp = @PhaseGroup, @phase = @Phase, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @msg = 'Phase validation failed - ' + @msg
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END
	
	skipJCCO_Job_Phase_validation:
		
	--EarnCode Validation
	IF @EarnCode IS NOT NULL
	BEGIN
		DECLARE @jccosttype bJCCType
		
		EXEC @rcode = vspPRRemoteTCEarnCodeVal @prco = @Key_PRCo, @jccosttype = @jccosttype OUTPUT, @earncode = @EarnCode, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @msg = 'EarnCode validation failed - ' + @msg
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END
	ELSE
	BEGIN
		SET @msg = 'Earn Code validation failed - You must enter a value for Earn Code'
		RAISERROR(@msg, 16, 1)
		GOTO vspExit
	END
	
	--Craft Validation
	IF @Craft IS NOT NULL
	BEGIN
		EXEC @rcode = bspPRCraftVal @prco = @Key_PRCo, @craft = @Craft, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @msg = 'Craft validation failed - ' + @msg
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END

	--Class Validation
	IF @Class IS NOT NULL
	BEGIN
		EXEC @rcode = bspPRCraftClassVal @prco = @Key_PRCo, @craft = @Craft, @class = @Class, @msg = @msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SET @msg = 'Class validation failed - ' + @msg
			RAISERROR(@msg, 16, 1)
			GOTO vspExit
		END
	END

	--Always set approved to N so that it goes through the apporval process again 
	DECLARE @Approved AS bYN, @ApprovedBy AS bVPUserName, @ApprovedOn AS bDate
	SELECT @Approved = 'N', @ApprovedBy = NULL, @ApprovedOn = NULL

	UPDATE [dbo].[PRMyTimesheetDetail]
	   SET [PRCo] = @Key_PRCo
		  ,[EntryEmployee] = @Key_EntryEmployee
		  ,[StartDate] = @Key_StartDate
		  ,[Sheet] = @Key_Sheet
		  ,[Seq] = @Key_Seq_Seq
		  ,[Employee] = @Employee
		  ,[JCCo] = @JCCo
		  ,[Job] = @Job
		  ,[PhaseGroup] = @PhaseGroup
		  ,[Phase] = @Phase
		  ,[EarnCode] = @EarnCode
		  ,[Craft] = @Craft
		  ,[Class] = @Class
		  ,[Shift] = @Shift
		  ,[DayOne] = @DayOne
		  ,[DayTwo] = @DayTwo
		  ,[DayThree] = @DayThree
		  ,[DayFour] = @DayFour
		  ,[DayFive] = @DayFive
		  ,[DaySix] = @DaySix
		  ,[DaySeven] = @DaySeven
		  ,[Approved] = @Approved
		  ,[ApprovedBy] = @ApprovedBy
		  ,[ApprovedOn] = @ApprovedOn
		  ,[Memo] = @Memo
	 WHERE [PRCo] = @Original_Key_PRCo AND [EntryEmployee] = @Original_Key_EntryEmployee AND [StartDate] = @Original_Key_StartDate AND [Sheet] = @Original_Key_Sheet AND [Seq] = @Original_Key_Seq_Seq
	 
	 EXEC vpspPRMyTimeSheetEntryGet @PersonalTimeSheet, @Key_PRCo, @Key_EntryEmployee, @Key_StartDate, @Key_Sheet, @ShortDatePattern, @Key_Seq_Seq
	 
	 vspExit:
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetEntryUpdate] TO [VCSPortal]
GO
