SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspPRAllowanceRuleDesc]
  /***********************************************************
   * CREATED BY: MV 11/06/2012 - B-11186 - PR Allowance Rule 
   * MODIFIED By : EN 1/8/2013 D-06433/TK-20653 Modified to pass in AllowanceRulesetName to use in looking up the desc
   *              
   *
   * USAGE:
   * Returns a PRAllowanceRules description
   * 
   * INPUT PARAMETERS
   *	PRCo   
   *	AllowanceRulesetName
   *	AllowanceRuleName
   *
   * OUTPUT PARAMETERS
   *	 
   *    @msg If Error, error message, otherwise description of AllowanceRulesetName
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@PRCo bCompany, @PRAllowRulesetName VARCHAR(16), @PRAllowRuleName VARCHAR(16), @msg VARCHAR(200)OUTPUT)
  AS
  
  SET NOCOUNT ON
  
  
  DECLARE @RCode int
  SELECT @RCode = 0
  	
 IF @PRCo IS NULL
 BEGIN
  	SELECT @msg = 'Missing PR Company', @RCode = 1
  	RETURN @RCode
 END
 
 IF @PRAllowRulesetName IS NULL
 BEGIN
  	SELECT @msg = 'Missing Allowance Ruleset Name', @RCode = 1
  	RETURN @RCode
 END
 
 IF @PRAllowRuleName IS NOT NULL
 BEGIN
	SELECT @msg = AllowanceRuleDesc  
	FROM dbo.vPRAllowanceRules 
	WHERE  PRCo = @PRCo AND 
		   AllowanceRulesetName = @PRAllowRulesetName AND
		   AllowanceRuleName = @PRAllowRuleName
 END
  
 RETURN @RCode


GO
GRANT EXECUTE ON  [dbo].[vspPRAllowanceRuleDesc] TO [public]
GO
