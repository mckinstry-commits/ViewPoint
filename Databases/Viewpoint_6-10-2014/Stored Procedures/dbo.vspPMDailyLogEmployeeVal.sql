SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspPMDailyLogEmployeeVal]

  /*************************************
  * CREATED BY:		GP 07/25/2008
  * Modified By:
  *
  *		Validates employee in PMPM and PREH and returns the employee name.
  *		Used by PMDailyLogs - Employee Detail
  *
  *		INPUT Parameters:
  *			PMCo - Project Management Company
  *			PRCo - Payroll Company
  *			Employee - Employee Number
  *			VendorGroup - Vendor Group
  *			FirmNumber - Firm Number
  *			ContactCode - Conatact Code
  *  
  *		OUTPUT Parameters:
  *			rcode - 0 Success
  *					1 Failure
  *			msg - Return Message
  *
  *			FirstName - First Name
  *			LastName - Last Name
  *			MiddleName - Middle Name or Initial
  *		
  **************************************/
	(@PMCo bCompany = null, @PRCo bCompany = null, @VendorGroup bGroup = null, 
	@FirmNumber bFirm = null, @ContactCode bEmployee = null, @msg varchar(255) output)

	as
	SET nocount on

	DECLARE @rcode int
	SET @rcode = 0

	BEGIN TRY

	------------------------------
	-- Check PMPM for employee  --
	------------------------------
	IF @VendorGroup is not null and @FirmNumber is not null and @ContactCode is not null
	BEGIN
		SELECT FirstName, LastName, MiddleInit FROM PMPM with(nolock) 
			WHERE VendorGroup = @VendorGroup and FirmNumber = @FirmNumber and ContactCode = @ContactCode
		IF @@rowcount > 0
		BEGIN
			GOTO vspexit
		END
	END
	
	------------------------------
	-- Check PREH for employee  --
	------------------------------
	IF exists(SELECT TOP 1 1 FROM PMCO with(nolock) WHERE PMCo = @PMCo and PRInUse = 'Y') and @PRCo is not null
	BEGIN
		SELECT FirstName, LastName, MidName FROM PREHName with(nolock) WHERE PRCo = @PRCo and Employee = @ContactCode
		IF @@rowcount > 0
		BEGIN
			EXEC dbo.bspPMFirmContactInitialize @PMCo, @VendorGroup, @FirmNumber, @ContactCode, 
				@ContactCode, 'N', null
			
			UPDATE PMPM
			SET ExcludeYN = 'Y'
			WHERE VendorGroup = @VendorGroup and FirmNumber = @FirmNumber and ContactCode = @ContactCode
		END
		ELSE
		BEGIN
			GOTO vspexit
		END
	END

	END TRY

	BEGIN CATCH
		GOTO vspexit
	END CATCH

	vspexit:
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDailyLogEmployeeVal] TO [public]
GO
