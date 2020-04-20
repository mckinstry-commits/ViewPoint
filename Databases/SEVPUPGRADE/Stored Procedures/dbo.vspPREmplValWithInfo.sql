SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPREmplValWithInfo]
/************************************************************************
* CREATED:	MH 2/26/07    
* MODIFIED: EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
*			mh 09/15/09 - Added country output param for T4
*			LS 08/20/2010 - #137685 Include Zip Code when Country is NULL, and SQL standards
*			LS 02/22/2011 - #127269 Added Birthdate output param for PAYG
*			EN 12/10/2012 D-04513/TK-19975/#145818 Changed to default zip extension correctly
*
* Purpose of Stored Procedure
*
*    Return Name/Address info for W2/Unempl.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@prco bCompany, 
    @empl varchar(15), 
    @emplout bEmployee output, 
    @pensionplan bYN output, 
	@ssn char(9) output, 
	@firstname varchar(30) output, 
	@midname varchar(15) output, 
	@lastname varchar(30) output, 
	@suffix varchar(4) output, 
	@locaddress varchar(22) output, 
	@deladdress varchar(40) output, 
	@city varchar(22) output, 
	@state varchar(4) output, 
	@zip bZip output, 
	@zipext varchar(4) output, 
	@taxstate varchar(4) output,
	@BirthDate bDate output, 
	@hiredate bDate output,
	@termdate bDate output, 
	@country char(2) output, 
	@cppqppexempt bYN output, 
	@eiexempt bYN output, 
	@ppipexempt bYN output, 
	@msg varchar(80) = '' output)

AS
BEGIN
	SET NOCOUNT ON

    DECLARE @returnCode INT
    SELECT @returnCode = 0

	DECLARE @activeopt VARCHAR(1), 
			@inscode VARCHAR(10), 
			@dept bDept, 
			@sortname varchar(15),
			@craft bCraft, 
			@class bClass, 
			@jcco bCompany, 
			@job bJob

	SELECT @activeopt = 'X'

	EXEC @returnCode = bspPREmplVal @prco, @empl, @activeopt, @emplout output, @sortname output, 
	@lastname output, @firstname output, @inscode output, @dept output, @craft output,
	@class output, @jcco output, @job output, @msg output

	
	IF @returnCode = 0 AND @emplout IS NOT NULL
	BEGIN
		SELECT	@pensionplan = PensionYN, 
				@ssn = replace(SSN,'-',''), 
				@midname = MidName,
				@suffix = Suffix, 
				@locaddress = substring(Address2,1,22), 
				@deladdress = substring([Address],1,40), 
				@city = substring(City, 1, 22), 
				@state = [State], 
				@zip = CASE  
							WHEN Country = 'CA' THEN Zip  
							ELSE 
								substring(Zip, 1, 5)
					   END, 
				@zipext = CASE WHEN Country = 'US' OR Country IS NULL THEN 
							  (CASE WHEN LEN(SUBSTRING(dbo.vfStripNonNumerics(Zip),6,4)) = 4 
  							   THEN SUBSTRING(dbo.vfStripNonNumerics(Zip),6,4) 
  							   ELSE '' 
  							   END)
						  END,
				@taxstate = TaxState, 
				@country = Country, 
				@BirthDate = BirthDate,
				@cppqppexempt = CPPQPPExempt, 
				@eiexempt = EIExempt, 
				@ppipexempt = PPIPExempt 
		FROM PREH WHERE PRCo = @prco AND Employee = @emplout
		
		
	END


	--SELECT @ssn = REPLACE(SSN,'-', '') FROM PREH WHERE PRCo = @prco AND Employee = @empl

	IF LEN(@ssn) <> 9 
	BEGIN 
		SELECT @ssn = null
	END 

	RETURN @returnCode
END


GO
GRANT EXECUTE ON  [dbo].[vspPREmplValWithInfo] TO [public]
GO
