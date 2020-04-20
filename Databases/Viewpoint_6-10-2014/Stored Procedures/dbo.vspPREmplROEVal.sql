SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPREmplROEVal]
/************************************************************************
* CREATED:	CHS 02/15/2013   
* MODIFIED:	CHS 03/26/2013 
*			CHS 03/26/2013 change @Employe to varchar(15) to allow switcheroo
*
* Purpose of Stored Procedure
*
*    Return Name/Address info for ROE/Empl.
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
    @Employee varchar(15), 
	@ROEDate bDate,
    @EmployeeOut bEmployee output, 
	@SSN char(9) output, 
	@FirstName varchar(20) output, 
	@MidName varchar(4) output, 
	@LastName varchar(28) output, 
	@AddressLine1 varchar(35) output, 
	@AddressLine2 varchar(35) output, 
	@AddressLine3 varchar(35) output, 
	@RecentRehireDate bDate output,
	@RecentSeparationDate bDate output,
	@PayPeriodType char(1) output,
	@Occupation varchar(40) output,
	@msg varchar(255) = '' output)

AS
BEGIN
	SET NOCOUNT ON

    DECLARE @returnCode INT
    SELECT @returnCode = 0

	Declare @inscode VARCHAR(10), 
			@dept bDept, 
			@sortname varchar(15),
			@craft bCraft, 
			@class bClass, 
			@jcco bCompany, 
			@job bJob,
			@PRGroup bGroup

	EXEC @returnCode = bspPREmplVal @PRCo, @Employee, 'X', @EmployeeOut output, @sortname output, 
			@LastName output, @FirstName output, @inscode output, @dept output, @craft output,
			@class output, @jcco output, @job output, @msg output

	IF @returnCode = 0 AND @EmployeeOut IS NOT NULL
		BEGIN
		SELECT	
				@SSN = replace(SSN,'-',''), 
				@MidName = SUBSTRING(MidName,1,4),
				@AddressLine1 = SUBSTRING(Address,1,35), 
				@AddressLine2 = SUBSTRING(City,1,35),
				@AddressLine3 = SUBSTRING
                                  (
                                    ISNULL(State,'') + (CASE WHEN State IS NULL THEN '' ELSE ', ' END) + 
                                    ISNULL(Country,'') + (CASE WHEN Country IS NULL THEN '' ELSE ', ' END) + 
                                    ISNULL(Zip,''),
                                    1,35
                                  ),

				@PRGroup = PRGroup,
				@RecentRehireDate = RecentRehireDate,
				@RecentSeparationDate = RecentSeparationDate,
				@Occupation = PROP.Description
		FROM dbo.PREH (nolock)
			Left Join dbo.PROP (nolock) on PREH.PRCo=PROP.PRCo and PREH.OccupCat=PROP.OccupCat 
		WHERE PREH.PRCo = @PRCo 
			AND Employee = @EmployeeOut

		SELECT 
			@PayPeriodType = PayFreq
		FROM PRGR
		WHERE 
			PRCo = @PRCo 
			AND PRGroup = @PRGroup


		IF ISNULL(@RecentRehireDate, '') = '' AND ISNULL(@RecentSeparationDate, '') = ''
			BEGIN
			SELECT @returnCode = 1, @msg = 'The most recent rehire date and the most recent separation date for this employee has not been entered in PR Employees.'
			RETURN @returnCode
			END


		IF ISNULL(@RecentRehireDate, '') = ''
			BEGIN
			SELECT @returnCode = 1, @msg = 'The most recent rehire date for this employee has not been entered in PR Employees.'
			RETURN @returnCode
			END

		
		IF ISNULL(@RecentSeparationDate, '') = ''
			BEGIN
			SELECT @returnCode = 1, @msg = 'The most recent separation date for this employee has not been entered in PR Employees.'
			RETURN @returnCode
			END
		END


	RETURN @returnCode
END


GO
GRANT EXECUTE ON  [dbo].[vspPREmplROEVal] TO [public]
GO
