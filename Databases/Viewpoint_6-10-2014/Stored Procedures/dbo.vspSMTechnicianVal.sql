SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/16/10
-- Modified:  MarkH 08/25/10 - Added @Rate output
--			  LaneG 08/23/11 - Added Employee Inactive Check
--            EricV 07/07/13 - Added @PRCoLimit parameter to validate the Technician is linked to a specific PRCo
--			  SKA	05/14/13 - Added Craft/Class output
-- Description:	Validation for SM technician
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTechnicianVal]
	@SMCo bCompany, 
	@Technician varchar(15), 
	@PRCoLimit bCompany = NULL,
	@PRCo bCompany = NULL OUTPUT, 
	@Rate bUnitCost = NULL OUTPUT, 
	@INCo bCompany = NULL OUTPUT,
	@INLocation bLoc = NULL OUTPUT,
	@Craft bCraft = NULL OUTPUT,
	@Class bClass = NULL OUTPUT,
	@msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company.'
		RETURN 1
	END
	
	IF @Technician IS NULL
	BEGIN
		SET @msg = 'Missing SM Technician.'
		RETURN 1
	END

	DECLARE @ActiveYN bYN

	SELECT 
		@msg = FullName, 
		@PRCo = SMTechnicianInfo.PRCo, 
		@Rate = ISNULL(Rate,0),
		@INCo = INCo,
		@INLocation = INLocation,
		@ActiveYN = bPREH.ActiveYN,
		@Craft = bPREH.Craft,
		@Class = bPREH.Class
	FROM dbo.SMTechnicianInfo
		INNER JOIN bPREH ON SMTechnicianInfo.Employee = bPREH.Employee 
			AND SMTechnicianInfo.PRCo = bPREH.PRCo
	WHERE SMCo = @SMCo AND Technician = @Technician

	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Technician has not been set up.'
		RETURN 1
	END
	
	IF (@INCo IS NULL OR @INLocation IS NULL)
	BEGIN
		-- Default the INCo from the SMCompany parameters
		SELECT @INCo = INCo, @INLocation = NULL FROM dbo.SMCO WHERE SMCo = @SMCo
	END

	IF @ActiveYN = 'N'
	BEGIN
		SET @msg = 'Employee is Inactive.'
		RETURN 1
	END

	IF @PRCoLimit IS NOT NULL AND NOT @PRCoLimit = @PRCo
	BEGIN
		SET @msg = 'Technician is not valid for PR Company ' + convert(varchar, @PRCoLimit)
		RETURN 1
	END
	
	RETURN 0
END






GO
GRANT EXECUTE ON  [dbo].[vspSMTechnicianVal] TO [public]
GO
