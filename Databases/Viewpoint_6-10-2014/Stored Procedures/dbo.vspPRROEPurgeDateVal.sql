SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRROEPurgeDateVal]
/************************************************************************
* CREATED:	MV 03/18/2013   ROE Project   
* MODIFIED:
*
* Purpose of Stored Procedure
*
*    validate the ROEDate entered in PR Purge
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@PRCo bCompany, 
	@ROEDate bDate,
	@msg varchar(255) = '' output)

AS
BEGIN
	SET NOCOUNT ON

    DECLARE @returnCode INT
    SELECT @returnCode = 0

	SELECT * 
	FROM dbo.PRROEEmployeeHistory r
	WHERE  r.PRCo = @PRCo AND r.ROEDate = @ROEDate
	IF @@Rowcount = 0
	BEGIN
		SELECT
			@returnCode = 1, 
			@msg = 'Invalid ROE Date.'
			RETURN @returnCode
		END

	RETURN @returnCode
END


GO
GRANT EXECUTE ON  [dbo].[vspPRROEPurgeDateVal] TO [public]
GO
