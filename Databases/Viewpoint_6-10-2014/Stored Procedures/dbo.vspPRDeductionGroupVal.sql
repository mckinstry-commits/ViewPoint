SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRDeductionGroupVal    Script Date: 10/19/2010 16:25:35 ******/
   CREATE  proc [dbo].[vspPRDeductionGroupVal]
   /***********************************************************
    * CREATED BY: Liz S	10/19/2010
    * MODIFIED By : 
    *
    * USAGE:
    * validates PR Deduction Group from PRDeductionGroup
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   @PRCo   PR Co to validate against
    *   @DeductionGroup PR Deduction Group to validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of PR Garnishment Group
    * RETURN VALUE
    *   0         Success
    *   1         Failure
    *****************************************************/ 
   
   	(@PRCo bCompany = 0, @DeductionGroup bGroup = null, @msg varchar(60) output)
   AS
   BEGIN
   
		SET NOCOUNT ON
	   
		IF @PRCo IS NULL
   		BEGIN
   			SET @msg = 'Missing PR Company!'
   			RETURN 1
   		END
	   
		IF @DeductionGroup IS NULL
   		BEGIN
   			SET @msg = 'Missing PR Deduction Group!'
   			RETURN 1
   		END
	   
		SELECT @msg = Description
   		FROM PRDeductionGroup
   		WHERE PRCo = @PRCo and DednGroup=@DeductionGroup 
		IF @@rowcount = 0
   		BEGIN
   			SET @msg = 'PR Deduction Group not found!'
   			RETURN 1
   		END
	   
   		RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspPRDeductionGroupVal] TO [public]
GO
