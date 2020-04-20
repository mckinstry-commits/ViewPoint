SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspPRAllowanceTypeVal]
  /***********************************************************
   * CREATED BY: MV 11/12/2012 - B-11189 - PR Allowance Rule Set by Craft 
   * MODIFIED By :	
   *              
   *
   * USAGE:
   * Returns a PRAllowanceType description
   * 
   * INPUT PARAMETERS
   *	PRCo   
   *	AllowanceTypeName
   *
   * OUTPUT PARAMETERS
   *	 
   *    @msg If Error, error message, otherwise description of PRAllowanceType
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@AllowanceTypeName VARCHAR(16), @TableName VARCHAR(128), @msg VARCHAR(200)OUTPUT)
  AS
  
  SET NOCOUNT ON
  
  DECLARE @RCode int
  SELECT @RCode = 0
  	
 
 IF @TableName IS NULL
 BEGIN
  	SELECT @msg = 'Missing Table Name', @RCode = 1
  	RETURN @RCode
 END
 
 
 IF @AllowanceTypeName IS NOT NULL
 BEGIN
	SELECT @msg = AllowanceDescription  
	FROM dbo.vPRAllowanceType 
	WHERE  AllowanceTypeName=@AllowanceTypeName
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @msg = 'Allowance type Rule Set Locator is invalid for this form.', @RCode =1
		RETURN @RCode
	END
	ELSE
	BEGIN
		SELECT * 
		FROM dbo.PRAllowanceType
		WHERE	AllowanceTypeName=@AllowanceTypeName AND
				TableName = @TableName
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @msg = 'Allowance Type Name invalid for this form.', @RCode =1
			RETURN @RCode
		END
 
	END
 END
  
 RETURN @RCode


GO
GRANT EXECUTE ON  [dbo].[vspPRAllowanceTypeVal] TO [public]
GO
