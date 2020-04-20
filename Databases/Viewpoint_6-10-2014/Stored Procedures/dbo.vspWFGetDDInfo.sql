SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		Charles Courchaine
* Create date:  12/19/2007
* Description:	This procedure retrieves information from DDFH required to launch a form given a form Title
* Modified:		CC 07/16/2009 - Issue #129922 - Correct issues with form i18n
*
*	Inputs:
*		@formTitle	Title of the form in DDFH
*
*	Outputs:
*		@assemblyName	Name of the assembly the form resides in
*		@formClassName	Name of the class in the assembly
*		@DDFormName		Name of the Form in DDFH
*
*****************************************************/

CREATE PROCEDURE [dbo].[vspWFGetDDInfo] 
	-- Add the parameters for the stored procedure here
	@DDFormName varchar(30) = NULL,
	@assemblyName varchar(50) = NULL OUTPUT,
	@formClassName varchar(50) = NULL OUTPUT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT	  @assemblyName = f.AssemblyName
			, @formClassName = f.FormClassName
	FROM DDFHShared f WITH (NOLOCK)
	INNER JOIN vDDMO m WITH (NOLOCK) ON m.Mod = f.Mod
	WHERE	m.Active = 'Y' 
			AND f.Mod <> 'DD' 
			AND f.AssemblyName IS NOT NULL 
			AND f.ShowOnMenu = 'Y'
			AND (m.LicLevel > 0 AND m.LicLevel >= f.LicLevel) 
			AND f.Form = @DDFormName;
END


GO
GRANT EXECUTE ON  [dbo].[vspWFGetDDInfo] TO [public]
GO
