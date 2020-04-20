SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROC [dbo].[vspPR_AU_UnderPreservationAgeYN]
/***********************************************************/
-- CREATED BY: EN 3/07/2013  TFS-39860
-- MODIFIED BY: 
--
-- USAGE:
-- Determines if an employee is under the preservation (retirement) age for
-- ETP withholding tax computation.  Employee's birth date is compared to 
-- a preservation age change phase-in period that is for workers born from
-- 1 July 1960 through 30 June 1964.
--
-- 
-- INPUT PARAMETERS
--   @BirthDate	Employee's birth date
--
-- OUTPUT PARAMETERS
--	 @UnderPreservationAgeYN	'Y' if employee is under the preservation age
--   @Message					Error message if error occurs	
--
-- RETURN VALUE
--   0			Success
--   1			Failure
--
/******************************************************************/
(
 @BirthDate bDate = NULL,
 @UnderPreservationAgeYN bYN OUTPUT,
 @errmsg varchar(1000) OUTPUT
)
AS
SET NOCOUNT ON

-- validate BirthDate
IF @BirthDate IS NULL
BEGIN
	SELECT @errmsg = 'Missing Birth Date'
	RETURN 1
END

-- determine the Employee's age
DECLARE @EmployeeAge int

SELECT @EmployeeAge = FLOOR(DATEDIFF(DAY, @BirthDate, GETDATE()) / 365.25)

-- determine the Employee's preservation age
DECLARE @PreservationAge tinyint

SELECT @PreservationAge = CASE
							WHEN @BirthDate < '7/1/1960'					   THEN 55
							WHEN @BirthDate BETWEEN '7/1/1960' AND '6/30/1961' THEN 56
							WHEN @BirthDate BETWEEN '7/1/1961' AND '6/30/1962' THEN 57
							WHEN @BirthDate BETWEEN '7/1/1962' AND '6/30/1963' THEN 58
							WHEN @BirthDate BETWEEN '7/1/1963' AND '6/30/1964' THEN 59
							ELSE													60
						  END

-- determine employee's preservation age status							
IF @EmployeeAge < @PreservationAge 
BEGIN
	SELECT @UnderPreservationAgeYN = 'Y'
END
ELSE
BEGIN
	SELECT @UnderPreservationAgeYN = 'N'
END


RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPR_AU_UnderPreservationAgeYN] TO [public]
GO
