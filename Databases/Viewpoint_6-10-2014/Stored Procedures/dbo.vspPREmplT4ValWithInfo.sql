SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspPREmplT4ValWithInfo]
/************************************************************************
* CREATED:	MH 2/26/07    
* MODIFIED: EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
*			mh 09/15/09 - Added country output param for T4
*			LS 08/30/2010 - #140354 Added PensionNumber output param for T4
							Split out from W2Employee shared Stored Proc, to be more T4 Specific.
*
* Purpose of Stored Procedure
*
*    Return Name/Address info for Canada T4.
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
	@taxstate varchar(4) output, 
	@country char(2) output, 
	@cppqppexempt bYN output, 
	@eiexempt bYN output, 
	@ppipexempt bYN output,
	@RPPNumber varchar(7) output,
	@msg varchar(80) = '' output)


as
BEGIN
	set nocount on

    declare @returnCode int
    select @returnCode = 0

	declare @activeopt varchar(1), @inscode varchar(10), @dept bDept, @sortname varchar(15),
	@craft bCraft, @class bClass, @jcco bCompany, @job bJob

	select @activeopt = 'X'

	exec @returnCode = bspPREmplVal @prco, @empl, @activeopt, @emplout output, @sortname output, 
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
				@zip = Zip, 
				@taxstate = TaxState, 
				@country = Country, 
				@cppqppexempt = CPPQPPExempt, 
				@eiexempt = EIExempt, 
				@ppipexempt = PPIPExempt
		FROM PREH WHERE PRCo = @prco AND Employee = @emplout
		
		
	END

	-- Get the RPP Number from the Craft Level
	SELECT @RPPNumber = PensionNumber FROM PRCM WHERE PRCo = @prco AND Craft = @craft

	--SELECT @ssn = REPLACE(SSN,'-', '') FROM PREH WHERE PRCo = @prco AND Employee = @empl

	IF LEN(@ssn) <> 9 
	BEGIN 
		SELECT @ssn = null
	END 

	RETURN @returnCode
END



GO
GRANT EXECUTE ON  [dbo].[vspPREmplT4ValWithInfo] TO [public]
GO
