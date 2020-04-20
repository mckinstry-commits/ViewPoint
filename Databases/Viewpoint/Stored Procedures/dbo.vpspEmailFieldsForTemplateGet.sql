SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspEmailFieldsForTemplateGet]
/************************************************************
* CREATED:     2011-10-26 Chris Crewdson
* MODIFIED:    
*
* USAGE:
*   Gets the Email Fields from pEmailField that can be used on the template
*   
*
* CALLED FROM:
*   VC
*
* INPUT PARAMETERS
*    TemplateName
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@TemplateName varchar(255) = Null)
AS
    SET NOCOUNT ON;
    
SELECT 
    emailField.EmailFieldID,  
    emailField.FieldKey,  
    emailField.Description,  
    emailField.Lookup,  
    emailField.BuiltIn   
FROM 
    VCEmailField emailField with (nolock)
        INNER JOIN 
    VCEmailTemplateField emailTemplateField
        ON emailField.EmailFieldID = emailTemplateField.EmailFieldID
        INNER JOIN 
    VCEmailTemplate emailTemplate 
        ON emailTemplateField.EmailTemplateID = emailTemplate.EmailTemplateID 
WHERE emailTemplate.Name = @TemplateName

UNION ALL

SELECT 
    emailField.EmailFieldID,  
    emailField.FieldKey,  
    emailField.Description,  
    emailField.Lookup,  
    emailField.BuiltIn   
FROM VCEmailField emailField with (nolock)
WHERE emailField.BuiltIn = N'N'
GO
GRANT EXECUTE ON  [dbo].[vpspEmailFieldsForTemplateGet] TO [VCSPortal]
GO
