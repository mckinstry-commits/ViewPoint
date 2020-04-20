SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRPayPeriodValforROE]
	/******************************************************
	* CREATED BY:	MV 2/25/2013  TFS #40979
	* MODIFIED By: 
	*
	* Usage:	Validates Pay Period for PR ROE Insurable Earnings
	*	
	*
	* Input params:
	*	
	*	@prco bCompany
	*	@employee bEmployee 
	*	@enddate bDate - Pay period end date
	*
	* Output params:
	*
	*	@msg		error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
	(
		 @prco bCompany,
		 @employee bEmployee,
		 @enddate bDate,
		 @msg varchar(100) output
	 )

	AS 
	SET NOCOUNT ON
	DECLARE	@rcode int,
			@PRGroup bGroup,
			@RecentRehireDate bDate

	SELECT @rcode = 0

	SELECT @PRGroup = PRGroup, @RecentRehireDate = RecentRehireDate 
	FROM dbo.PREH
	WHERE PRCo=@prco AND Employee=@employee
	
	IF NOT EXISTS
			(
				SELECT * 
				FROM dbo.PRPC
				WHERE PRCo=@prco
					AND PRGroup=@PRGroup
					AND PREndDate=@enddate
			)
	BEGIN
		SELECT @msg = 'Invalid Pay Period Date. ', @rcode = 1

	END
	ELSE
	BEGIN
		IF @enddate < @RecentRehireDate
		BEGIN
			SELECT @msg = 'The pay period ending date selected is prior to the employee''s rehire date. ', @rcode = 1
		END
	END
	
	 
	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPRPayPeriodValforROE] TO [public]
GO
