SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/24/09
-- Modified By:	09/05/2010 GF - issue #131041 changed to use function vfDateOnly
--              10/10/2012 JA via Tom J - Made procedure able to handle no JCCompany being entered
--
-- Description:	Updates the detail record from vPRMyTimesheetDetail
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyTimeSheetApprovalDetailUpdate]
	(@StartDate bDate, @UserName bVPUserName, @Key_PRCo bCompany, @Key_EntryEmployee bEmployee, @Key_StartDate bDate, @Key_Sheet SMALLINT, @Key_Seq_Seq SMALLINT, @JCCo bCompany, @Job bJob, @Phase bPhase, @EarnCode bEDLCode, @Craft bCraft, @Class bClass, @Shift TINYINT, @DayOne bHrs, @DayTwo bHrs, @DayThree bHrs, @DayFour bHrs, @DayFive bHrs, @DaySix bHrs, @DaySeven bHrs, @Original_BoolApproved BIT, @BoolApproved BIT, @Original_Approved bYN, @Approved bYN, @ApprovedBy bVPUserName, @ApprovedOn AS SMALLDATETIME, @ShortDatePattern VARCHAR(20))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @rcode AS INTEGER,
		@msg AS VARCHAR(255)

	DECLARE @InputMask VARCHAR(30), 
		@FormattedValue VARCHAR(20),
		@PhaseGroup bGroup,
		@AllowNoPhase bYN

	-- Set values to null if they are empty strings
	SELECT @Job = CASE WHEN dbo.vpfIsNullOrEmpty(@Job) = 1 THEN NULL ELSE @Job END,
		@Phase = CASE WHEN dbo.vpfIsNullOrEmpty(@Phase) = 1 THEN NULL ELSE @Phase END,
		@Craft = CASE WHEN dbo.vpfIsNullOrEmpty(@Craft) = 1 THEN NULL ELSE @Craft END,
		@Class = CASE WHEN dbo.vpfIsNullOrEmpty(@Class) = 1 THEN NULL ELSE @Class END
		
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

	--Determine Approval changes (Approval may be changed by the bool - used in the datagrid or by the bYN used in the details control)
	IF @BoolApproved <> @Original_BoolApproved
	BEGIN
		IF @BoolApproved = 0
			BEGIN
				SELECT @Approved = 'N', @ApprovedBy = NULL, @ApprovedOn = NULL
			END
		ELSE
			BEGIN
				SELECT @Approved = 'Y', @ApprovedBy = @UserName,
						----#141031
						@ApprovedOn = dbo.vfDateOnly()
			END
	END
	ELSE IF @Approved <> @Original_Approved
	BEGIN
		IF @Approved = 'N'
			BEGIN
				SELECT @ApprovedBy = NULL, @ApprovedOn = NULL
			END
		ELSE
			BEGIN
				SELECT @ApprovedBy = @UserName,
						----#141031
						@ApprovedOn = dbo.vfDateOnly()
			END
	END
	
	UPDATE dbo.PRMyTimesheetDetail
	   SET JCCo = @JCCo
		  ,Job = @Job
		  ,PhaseGroup = @PhaseGroup
		  ,Phase = @Phase
		  ,EarnCode = @EarnCode
		  ,Craft = @Craft
		  ,Class = @Class
		  ,Shift = @Shift
		  ,DayOne = @DayOne
		  ,DayTwo = @DayTwo
		  ,DayThree = @DayThree
		  ,DayFour = @DayFour
		  ,DayFive = @DayFive
		  ,DaySix = @DaySix
		  ,DaySeven = @DaySeven
		  ,Approved = @Approved
		  ,ApprovedBy = @ApprovedBy
		  ,ApprovedOn = @ApprovedOn
	 WHERE PRCo = @Key_PRCo AND EntryEmployee = @Key_EntryEmployee AND StartDate = @Key_StartDate AND Sheet = @Key_Sheet AND Seq = @Key_Seq_Seq
	 
	 EXEC vpspPRMyTimeSheetApprovalDetailGet @StartDate, @UserName, 0, @ShortDatePattern, @Key_PRCo, @Key_EntryEmployee, @Key_StartDate, @Key_Sheet, @Key_Seq_Seq
	 
	 vspExit:
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyTimeSheetApprovalDetailUpdate] TO [VCSPortal]
GO
