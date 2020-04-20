SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/9/2010
-- Modified by: GP 1/5/2012 TK-11525 Changed @JCCo select to look at ARCO.ARCo
-- Description:	Validation for SM Company. Looks first to validate the SM Company number and then the SM Company ID. Either value can be supplied.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMCoVal]
	@SMCo AS bCompany = NULL, 
	@GLCo AS bCompany = NULL OUTPUT, 
	@JCCo AS bCompany = NULL OUTPUT, 
	@ARCo AS bCompany = NULL OUTPUT,
	@APCo AS bCompany = NULL OUTPUT,
	@PRCo AS bCompany = NULL OUTPUT,
	@INCo AS bCompany = NULL OUTPUT,
	@EMCo as bCompany = NULL OUTPUT,
	@DefaultCountry AS char(2) = NULL OUTPUT,
	@ContactGroup AS bGroup = NULL OUTPUT,
	@PhaseGroup AS bGroup = NULL OUTPUT, 
	@CustGroup AS bGroup = NULL OUTPUT, 
	@HQMatlGroup AS bGroup = NULL OUTPUT,
	@DefaultServiceCenter AS varchar(10) = NULL OUTPUT, 
	@TaxGroup AS bGroup = NULL OUTPUT,
	@AttachBatchReports AS bYN = NULL OUTPUT,
	@LicenseLevel as tinyint = NULL OUTPUT,
	@msg AS varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @LicenseLevel = LicLevel
	FROM dbo.vDDMO
	WHERE Mod = 'SM'
	
	--If null is being passed in like it is in the SM Company Parameters form
	--then all that is really needed is the SM license level and the rest of proc
	--doesn't need to be executed.
	IF @SMCo IS NULL RETURN 0

    SELECT 
		@GLCo = SMCO.GLCo, 
		@JCCo = ARCO.JCCo, 
		@ARCo = SMCO.ARCo, 
		@APCo = SMCO.APCo, 
		@PRCo = SMCO.PRCo, 
		@INCo = SMCO.INCo,
		@EMCo = SMCO.EMCo,
		@ContactGroup = HQCO.ContactGroup,
		@HQMatlGroup = HQCO.MatlGroup, 
		@msg = HQCO.Name,
		@DefaultCountry = HQCO.DefaultCountry, 
		@PhaseGroup = JCCO.PhaseGroup, 
		@CustGroup = hqARCO.CustGroup,
		@TaxGroup = hqARCO.TaxGroup,
		@AttachBatchReports = SMCO.AttachBatchReportsYN
    FROM dbo.SMCO
		LEFT JOIN dbo.HQCO ON SMCO.SMCo = HQCO.HQCo
		LEFT JOIN dbo.HQCO JCCO ON SMCO.JCCo = JCCO.HQCo
		LEFT JOIN dbo.HQCO hqARCO ON SMCO.ARCo = hqARCO.HQCo
		LEFT JOIN dbo.HQCO INCO ON SMCO.INCo = INCO.HQCo
		LEFT JOIN dbo.ARCO ON SMCO.ARCo = ARCO.ARCo	
	WHERE SMCO.SMCo = @SMCo
    
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Company not setup for Service Management.'
		RETURN 1
	END
	
	--Find a default service center for service site if there is only 1 
	--service center exists for the sm company
	SELECT @DefaultServiceCenter = ServiceCenter
	FROM dbo.SMServiceCenter
	WHERE SMCo = @SMCo AND Active = 'Y'
	
	IF @@rowcount <> 1
	BEGIN
		SET @DefaultServiceCenter = NULL
	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMCoVal] TO [public]
GO
