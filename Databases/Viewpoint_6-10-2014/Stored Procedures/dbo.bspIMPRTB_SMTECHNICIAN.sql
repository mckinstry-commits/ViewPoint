SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMPRTB_SMTECHNICIAN    Script Date: 8/28/99 9:34:28 AM ******/
   CREATE    proc [dbo].[bspIMPRTB_SMTECHNICIAN]
   /********************************************************
   * CREATED BY: EN/KK 9/9/2011
   * MODIFIED BY: 
   *
   * USAGE:
   * 	Validates employee for SM timecards to ensure that (s)he is setup as a technician.
   *
   * INPUT PARAMETERS:
   * PR Company
   * PR Employee
   * SM Company
   *
   * OUTPUT PARAMETERS:
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
	(@prco bCompany = 0, 
	@employee bEmployee, 
	@smco bCompany, 
	@msg varchar(60) OUTPUT) 

	AS
	SET NOCOUNT ON
   
	DECLARE @rcode int

	SELECT @rcode = 0
 
	IF NOT EXISTS  (SELECT * FROM dbo.vSMTechnician
					WHERE SMCo = @smco AND PRCo = @prco and Employee = @employee)
	BEGIN
		SELECT @msg = 'Employee must be set up as a technician.', @rcode = 1
	END
		    
   	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspIMPRTB_SMTECHNICIAN] TO [public]
GO
