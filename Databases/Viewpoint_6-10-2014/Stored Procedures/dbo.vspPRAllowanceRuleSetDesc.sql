SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspPRAllowanceRuleSetDesc]
  /***********************************************************
   * CREATED BY: MV 11/06/2012 - B-11186 - PR Allowance Rule Set 
   * MODIFIED By :	
   *              
   *
   * USAGE:
   * Returns a PRAllowanceRuleSet description
   * 
   * INPUT PARAMETERS
   *	PRCo   
   *	AllowanceRulesetName
   *
   * OUTPUT PARAMETERS
   *	 
   *    @msg If Error, error message, otherwise description of AllowanceRulesetName
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
 END
  
 RETURN @RCode


GO
GRANT EXECUTE ON  [dbo].[vspPRAllowanceRuleSetDesc] TO [public]
GO
