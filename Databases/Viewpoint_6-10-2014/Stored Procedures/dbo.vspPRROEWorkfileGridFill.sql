SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRROEWorkfileGridFill]
/************************************************************************
* CREATED:	CHS 03/15/2013   
* MODIFIED: KK  05/03/2013 - 49177 - Validation modification to be for co/empl/roedate duplication, this will allow co/empl/roedate duplicates
*			MV	07/09/2013 - TFS-54008 - changed final message to 'record(s)'.
* Purpose of Stored Procedure
*
*    Fill the ROE Work File table
*           
* Notes about Stored Procedure
*	@ResultSet - allows this SP to be used by crystal reports which does not support multiple tables in one record set.
*		possible inputs are EmployeeHistory, InsurEarningsPPD, SSPayments & empty string.
*		empty string returns the 3 full records sets.
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@PRCo bCompany, 
 @ROEDate bDate, 
 @BeginSeparationDate bDate, 
 @EndSeparationDate bDate, 
 @Language char(1),
 @ProcessYN bYN, 
 @ReasonForRoe char(1), 
 @ContactFirstName varchar(20), 
 @ContactLastName varchar(28),
 @ContactAreaCode varchar(3), 
 @ContactPhoneNumber varchar(8), 
 @ContactExtension varchar(5),
 @RecallCode char(1), 
 @RecallDate bDate, 
 @Comments varchar(160),	
 @msg varchar(255) = '' OUTPUT)

AS
BEGIN
	SET NOCOUNT ON

	DECLARE @MyRowCount int,
			@vpusername bVPUserName;
	
	SET @vpusername = SUSER_SNAME();

	SELECT @msg = 'No records were found to fill the ROE Workfile.'

	IF ISNULL(@PRCo, '') = ''
		BEGIN
		SELECT @msg = 'Missing PR Company value.'
		RETURN 1
		END

	IF ISNULL(@BeginSeparationDate, '') = ''
		BEGIN
		SELECT @msg = 'Missing Begin Separation Date value.'
		RETURN 1
		END

	IF ISNULL(@EndSeparationDate, '') = ''
		BEGIN
		SELECT @msg = 'Missing End Separation Date value.'
		RETURN 1
		END

	SELECT @ProcessYN = ISNULL(@ProcessYN, 'N')

	INSERT INTO dbo.PRROEEmployeeWorkfile
		(PRCo, Employee, ROEDate, ProcessYN, Language, ReasonForROE, 
		ContactFirstName, ContactLastName, ContactAreaCode,
		ContactPhoneNbr, ContactPhoneExt, ExpectedRecallCode, 
		ExpectedRecallDate, Comments)

	SELECT 
		PRCo, Employee, @ROEDate, @ProcessYN, @Language, @ReasonForRoe, 
		@ContactFirstName, @ContactLastName, @ContactAreaCode,
		@ContactPhoneNumber, @ContactExtension, @RecallCode, 
		@RecallDate, @Comments
	FROM dbo.PREH
	WHERE PRCo = @PRCo 
		AND ISNULL(RecentSeparationDate, '1/1/1900') 
				   BETWEEN @BeginSeparationDate AND @EndSeparationDate
		AND Employee NOT IN (SELECT Employee 
							 FROM dbo.PRROEEmployeeWorkfile 
							 WHERE PRCo = @PRCo 
							   AND ROEDate = @ROEDate
							   AND VPUserName = @vpusername)
		
	SELECT @MyRowCount = @@ROWCOUNT

	IF @MyRowCount > 0
		BEGIN
		SELECT @msg = 'Successfully inserted ' + cast(@MyRowCount AS varchar(10)) + ' record(s) into the ROE Workfile.'
		END


	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[vspPRROEWorkfileGridFill] TO [public]
GO
