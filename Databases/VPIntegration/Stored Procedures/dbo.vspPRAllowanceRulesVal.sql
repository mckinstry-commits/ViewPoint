SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspPRAllowanceRulesVal]
/***********************************************************
* CREATED BY:	DAN SO 12/06/2012 - B-11859 - TK-19733
* MODIFIED BY:	DAN SO 12/19/2012 - B-11859 - TK-19733 a little messaging clean up
*				DAN SO 12/26/2012 - B-12063 - TK-20377 - IF the RulesetName AND RuleName AND Threshold we all equal, but not hte Company, 
*									it would throw a NOT uniqie error
* 
*
* USAGE: Make sure that the Rules under a Rule Set are unique.  For Daily Rules, each day checked 
*			MUST have a different Threshold amount.  For Weekly Rules, they apply to everyday and 
*			MUST also have a different Threshold amount.
*		Called from PRAllowanceRulesDetail and used as Validation on the Threshold field.
* 
*
* INPUT PARAMETERS
*	@RuleName		Rule Name
*	@RuleSetName	RuleSet Name
*	@Holiday		Holiday
*	@Sun			Sunday
*	@Mon			Monday
*	@Tue			Tuesday
*	@Wed			Wednesday
*	@Thu			Thursday
*	@Fri			Friday
*	@Sat			Saturday
*	@Threshold		Threshold
*
* OUTPUT PARAMETERS
*	@msg			error message if a Rule IS NOT unique - will display each day that is in violation
*
* RETURN VALUE
*   0				success
*   1				Failure
*****************************************************/
(@PRCo bCompany, @RuleName VARCHAR(16), @RuleSetName VARCHAR(16), 
 @Holiday bYN, @Sun bYN, @Mon bYN, @Tue bYN, @Wed bYN, @Thu bYN, @Fri bYN, @Sat bYN,
 @Threshold bHrs,
 @msg VARCHAR(255) OUTPUT)

 AS
 SET NOCOUNT ON

	DECLARE @RuleViolated VARCHAR(16),
			@RulesViolated VARCHAR(160),
			@RulePeriod SMALLINT, 
			@rcode INT
	
	------------------
	-- PRIME VALUES --
	------------------
	SET @RuleViolated = ''
	SET	@RulesViolated = ''
	SET @RulePeriod = 0
	SET @rcode = 0


	---------------------------
	-- CHECK INPUT PARAMTERS --
	---------------------------
	IF @PRCo IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing Company!'
			GOTO vspExit
		END	
	
	IF @RuleName IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing Rule Name!'
			GOTO vspExit
		END
		
	IF @RuleSetName IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing RuleSet Name!'
			GOTO vspExit
		END
				
	IF (@Holiday IS NULL) OR (@Sun IS NULL) OR (@Mon IS NULL) OR (@Tue IS NULL) OR 
		(@Wed IS NULL) OR (@Thu IS NULL) OR (@Fri IS NULL) OR (@Sat IS NULL)
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing Holiday or a Day of Week!'
			GOTO vspExit
		END
		
	IF @Threshold IS NULL
		BEGIN
			SET @rcode = 1
			SET @msg = 'Missing Threshold!'
			GOTO vspExit
		END		
						
	--------------------
	-- GET RulePeriod --
	--------------------
	SELECT @RulePeriod = ThresholdPeriod FROM vPRAllowanceRuleSet WHERE AllowanceRulesetName = @RuleSetName
				   	
	------------
	-- WEEKLY --
	------------
	IF @RulePeriod = 4 
		BEGIN
						 
			SELECT	@rcode = 1,
					@msg = 'Threshold value conflicts with Rule: ' + dbo.vfToString(AllowanceRuleName) 
			  FROM	vPRAllowanceRules 
			 WHERE	PRCo = @PRCo -- B-12063 - TK-20377 --
			   AND  AllowanceRulesetName = @RuleSetName
			   AND	AllowanceRuleName <> ISNULL(@RuleName,'')
			   AND	Threshold = @Threshold		 
				
		END -- IF @RulePeriod = 4 --Weekly

	
	-----------
	-- DAILY --
	-----------	
	IF @RulePeriod = 2 
		BEGIN
		
			-- VERIFY AT LEAST 1 DAY IS CHECKED --
			IF (@Holiday = 'N' AND @Sun = 'N' AND @Mon = 'N' AND @Tue = 'N' AND 
			    @Wed = 'N' AND @Thu = 'N' AND @Fri  = 'N' AND @Sat = 'N')	
			    BEGIN
					SET @rcode = 1
					SET @msg = 'Daily Rules require at least 1 day to be checked!'
			    END
			    
			ELSE
				BEGIN
				
					-- VERIFY DAY/THRESHOLD COMBINATIONS ARE UNIQUE --
					SELECT	@rcode = 1, 
							@RulesViolated = dbo.vfToString(@RulesViolated) + AllowanceRuleName + ', ',
							@msg = dbo.vfToString(@msg) + 
								CASE WHEN Holiday = 'Y'				AND @Holiday = 'Y'	THEN 'Holiday, '	ELSE '' END +
								CASE WHEN DayOfWeekSunday = 'Y'		AND @Sun = 'Y'		THEN 'Sunday, '		ELSE '' END +
								CASE WHEN DayOfWeekMonday = 'Y'		AND @Mon = 'Y'		THEN 'Monday, '		ELSE '' END +
								CASE WHEN DayOfWeekTuesday = 'Y'	AND @Tue = 'Y'		THEN 'Tuesday, '	ELSE '' END +
								CASE WHEN DayOfWeekWednesday = 'Y'	AND @Wed = 'Y'		THEN 'Wednesday, '	ELSE '' END +
								CASE WHEN DayOfWeekThursday = 'Y'	AND @Thu = 'Y'		THEN 'Thursday, '	ELSE '' END + 
								CASE WHEN DayOfWeekFriday = 'Y'		AND @Fri = 'Y'		THEN 'Friday, '		ELSE '' END + 
								CASE WHEN DayOfWeekSaturday = 'Y'	AND @Sat = 'Y'		THEN 'Saturday, '	ELSE '' END
					  FROM	vPRAllowanceRules 
					 WHERE	PRCo = @PRCo -- B-12063 - TK-20377 --
					   AND  AllowanceRulesetName = @RuleSetName
					   AND	AllowanceRuleName <> ISNULL(@RuleName,'')
					   AND	Threshold = @Threshold
					   AND ((Holiday = 'Y'				AND @Holiday = 'Y') OR
							(DayOfWeekSunday = 'Y'		AND @Sun = 'Y')		OR
							(DayOfWeekMonday = 'Y'		AND @Mon = 'Y')		OR
							(DayOfWeekTuesday = 'Y'		AND @Tue = 'Y')		OR
							(DayOfWeekWednesday = 'Y'	AND @Wed = 'Y')		OR
							(DayOfWeekThursday = 'Y'	AND @Thu = 'Y')		OR
							(DayOfWeekFriday = 'Y'		AND @Fri = 'Y')		OR
							(DayOfWeekSaturday = 'Y'	AND @Sat = 'Y'))
															
					-------------------
					-- ERROR MESSAGE --
					-------------------
					IF @rcode = 1 
						BEGIN
							SET @msg = 'Day(s) selected: ' + LEFT(@msg, LEN(@msg) - 1) + char(10) + char(13) +
										'Threshold: ' + dbo.vfToString(@Threshold) + char(10) + char(13) +
										'Combination conflicts with the following Rule(s): ' + LEFT(@RulesViolated, LEN(@RulesViolated) - 1)
						END
				END
				
		END -- IF @RulePeriod = 2 --Daily
	
	
vspExit:
	RETURN @rcode






GO
GRANT EXECUTE ON  [dbo].[vspPRAllowanceRulesVal] TO [public]
GO
