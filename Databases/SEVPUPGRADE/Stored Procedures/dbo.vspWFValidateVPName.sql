SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************************
* Author:		CC
* Create date:  7/29/2008
* Description:	Verifies the form/report name exists
* Modified:		CC	07/14/09 - #129922 - Added link for form header to culture text & change to use report ID /form name
*
*	Inputs:
*	@Type		Form/Report
*	@Name		Form/Report name to check
*
*	Outputs:
*	@msg		Error message if form/report not found
*	@rcode		Return code 0 valid, 1 invalid
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFValidateVPName] 
	-- Add the parameters for the stored procedure here
	@Type int = null, 
	@Name VARCHAR(60) = null,
	@culture	INT = NULL,
    @msg VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @Type = 1 -- 1 = Form
	BEGIN
		SELECT @msg = ISNULL(CultureText.CultureText, f.Title)
		FROM DDFHShared f (NOLOCK)
		INNER JOIN DDMO m (NOLOCK) ON m.Mod = f.Mod
		LEFT OUTER JOIN DDCTShared AS CultureText ON CultureText.CultureID = @culture AND CultureText.TextID = f.TitleID
		WHERE m.Active = 'Y' 
				AND f.Mod <> 'DD' 
				AND f.AssemblyName IS NOT NULL 
				AND f.ShowOnMenu = 'Y' 
				AND (m.LicLevel > 0 AND m.LicLevel >= f.LicLevel)
				AND f.Form = @Name

		IF ISNULL(@msg, '') <> ''
			RETURN 0
		ELSE
			BEGIN
				SELECT @msg = 'Invalid form name, please check your spelling or select a form from the lookup '
				RETURN 1
			END
	END

	IF @Type = 2 -- 2 = Report
	BEGIN
		SELECT @msg = Title
			FROM RPRTShared (NOLOCK)
			WHERE ShowOnMenu='Y' 
				AND ReportID = CAST(@Name AS INT)			
			
		IF ISNULL(@msg, '') <> ''
			RETURN 0
		ELSE		
			BEGIN
				SELECT @msg = 'Invalid report ID, please check your spelling or select a report from the lookup '
				RETURN 1
			END		
	END


RETURN 0

END	


GO
GRANT EXECUTE ON  [dbo].[vspWFValidateVPName] TO [public]
GO
