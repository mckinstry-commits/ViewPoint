SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspPRAllowanceRuleSetVal]
  /***********************************************************
   * CREATED BY: MV 11/12/2012 - B-11189 - PR Allowance By Craft Master
   * MODIFIED By :	
   *              
   *
   * USAGE:
   * validates AllowanceRuleSName
   * 
   * INPUT PARAMETERS
   *	PRCo   
   *	AllowanceRuleName
   *
   * OUTPUT PARAMETERS
   *	 
   *    @msg If Error, error message, otherwise description of AllowanceRuleSetName
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@PRCo bCompany, @PRAllowRuleSetName VARCHAR(16), @msg VARCHAR(200)OUTPUT)
  AS
  
  SET NOCOUNT ON
  
  
  DECLARE @RCode int
  SELECT @RCode = 0
  	
 IF @PRCo IS NULL
 BEGIN
  	SELECT @msg = 'Missing PR Company', @RCode = 1
  	RETURN @RCode
 END
 
 IF @PRAllowRuleSetName IS NOT NULL
 BEGIN
	SELECT @msg = AllowanceRulesetDesc  
	FROM dbo.vPRAllowanceRuleSet 
	WHERE  PRCo=@PRCo AND AllowanceRulesetName=@PRAllowRuleSetName
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @msg = 'Invalid Allowance Rule Set Name.', @RCode = 1
  		RETURN @RCode
	END
 END
  
 RETURN @RCode


GO
GRANT EXECUTE ON  [dbo].[vspPRAllowanceRuleSetVal] TO [public]
GO
