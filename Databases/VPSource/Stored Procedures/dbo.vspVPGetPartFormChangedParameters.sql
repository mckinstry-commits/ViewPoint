SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY: CJG 03/11/11
* MODIFIED BY: 
*
*
*
*
* Usage: Gets the Part Changed FormName/Title and the Parameters for the
*		 given template.
*
* Input params:
*	@username
*	@TemplateName
*
* Output params:
*	none
*
* Return code:
*	
************************************************************/
CREATE PROCEDURE [dbo].[vspVPGetPartFormChangedParameters] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT FormName, FormTitle FROM VPPartFormChangedMessages
    ORDER BY FormName;
    
    SELECT m.FormName, p.ColumnName, p.Name, p.SqlType, p.ParameterValue, p.ViewName, p.ParameterOrder
	FROM VPPartFormChangedMessages m
	INNER JOIN VPPartFormChangedParameters p ON p.FormChangedID = m.KeyID
	ORDER BY m.FormName, p.ParameterOrder
    
END


GO
GRANT EXECUTE ON  [dbo].[vspVPGetPartFormChangedParameters] TO [public]
GO
