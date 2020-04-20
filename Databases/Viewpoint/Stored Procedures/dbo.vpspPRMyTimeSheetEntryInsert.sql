SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/24/09
-- Description:	Inserts the detail record from vPRMyTimesheetDetail
-- Modification: George Clingerman - Issue 137692, changed stored procedure so that now if Craft/Class
--               are being inserted with NULL values, the defaults setup for the Employee in PREH are used
--				06/06/11 EN D-02028 when insert into PRMyTimesheetDetail, plug CreatedOn date with no timestamp by using dbo.vfDateOnly() rather than GETDATE()
--              09/25/12 JA via TEJ - TK-18041 Made changes to VC stored procs to conform to new V6 stored proc signature
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetEntryInsert]
	(@PersonalTimeSheet bYN, @Key_PRCo bCompany, @Key_EntryEmployee bEmployee, @Key_StartDate bDate, @Key_Sheet SMALLINT, @Key_Seq_Seq SMALLINT, @Employee bEmployee = NULL, @JCCo bCompany, @Job bJob, @Phase bPhase, @EarnCode bEDLCode, @Craft bCraft, @Class bClass, @Shift TINYINT, @DayOne bHrs, @DayTwo bHrs, @DayThree bHrs, @DayFour bHrs, @DayFive bHrs, @DaySix bHrs, @DaySeven bHrs, @CreatedBy bVPUserName, @ShortDatePattern VARCHAR(20), @Memo VARCHAR(500))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode AS INTEGER,
		@msg AS VARCHAR(255)

	IF dbo.vpIsMyTimeSheetInStatus(@Key_PRCo, @Key_EntryEmployee, @Key_StartDate, @Key_Sheet, 1) = 1
	BEGIN
		RAISERROR('This time sheet is locked down. To add more records change the time sheet''s status to "Unlocked".', 16, 1)
		GOTO vspExit
	END
	
	IF @Key_Seq_Seq IS NULL
	BEGIN
		SELECT @Key_Seq_Seq = ISNULL(MAX(Seq), 0) + 1
		FROM PRRemoteTCEmpDetail WITH (NOLOCK)
		WHERE PRCo = @Key_PRCo AND EntryEmployee = @Key_EntryEmployee AND StartDate = @Key_StartDate AND Sheet = @Key_Sheet
	END
	ELSE IF NOT (@Key_Seq_Seq >= 1 AND @Key_Sheet <= 255)
	BEGIN
		RAISERROR('Seq must be a number between 1 and 255.', 1, 16)
		GOTO vspExit
	END

	DECLARE @InputMask VARCHAR(30), 
		@FormattedValue VARCHAR(20),
		@PhaseGroup bGroup,
		@AllowNoPhase bYN

	-- Set values to null if they are empty strings
	SELECT @Job = CASE WHEN dbo.vpfIsNullOrEmpty(@Job) = 1 THEN NULL ELSE @Job END,
		@Phase = CASE WHEN dbo.vpfIsNullOrEmpty(@Phase) = 1 THEN NULL ELSE @Phase END	
    	
	IF @PersonalTimeSheet = 'Y'
	BEGIN
		SET @Employee = @Key_EntryEmployee
	END
	
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

    --If the Craft AND Class are both empty then assign the defaults from PREH for the given employee	
 	IF dbo.vpfIsNullOrEmpty(@Craft) = 1 AND dbo.vpfIsNullOrEmpty(@Class) = 1 
	BEGIN
      SELECT @Craft = CASE WHEN PRCT.JobCraft IS NULL THEN PREH.Craft ELSE PRCT.JobCraft END, 
      @Class = CASE WHEN PRCT.JobCraft IS NULL THEN PREH.Class ELSE NULL END
      FROM PREH
		LEFT JOIN JCJM WITH (NOLOCK) ON JCJM.JCCo = PREH.JCCo AND JCJM.Job = PREH.Job
		LEFT JOIN PRCT WITH (NOLOCK) ON PRCT.PRCo = PREH.PRCo AND PRCT.Craft = PREH.Craft 
		AND PRCT.Template = JCJM.CraftTemplate AND RecipOpt = 'O'
		WHERE PREH.PRCo = @Key_PRCo AND PREH.Employee = @Employee	
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

	--Declare and set defaults
	DECLARE @CreatedOn SMALLDATETIME, @Approved bYN, @LineType char(1)
	
	SELECT @CreatedOn = dbo.vfDateOnly(), @Approved = 'N', @LineType = 'J' --We are only supporting job line types in Connects right now.

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
		   ,[Memo])
	 VALUES
		   (@Key_PRCo
		   ,@Key_EntryEmployee
		   ,@Key_StartDate
		   ,@Key_Sheet
		   ,@Key_Seq_Seq
		   ,@Employee
		   ,@JCCo
		   ,@Job
		   ,@PhaseGroup
		   ,@Phase
		   ,@EarnCode
		   ,@Craft
		   ,@Class
		   ,@Shift
		   ,@DayOne
		   ,@DayTwo
		   ,@DayThree
		   ,@DayFour
		   ,@DayFive
		   ,@DaySix
		   ,@DaySeven
		   ,@CreatedBy
		   ,@CreatedOn
		   ,@Approved
		   ,@LineType
		   ,@Memo)
	           
	EXEC vpspPRMyTimeSheetEntryGet @PersonalTimeSheet, @Key_PRCo, @Key_EntryEmployee, @Key_StartDate, @Key_Sheet, @ShortDatePattern, @Key_Seq_Seq
	
	vspExit:
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetEntryInsert] TO [VCSPortal]
GO
