SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspEmailTemplateGet]
/************************************************************
* CREATED:     2011-10-19 Chris Crewdson
* MODIFIED:    
*
* USAGE:
*   Gets the requested Email Template from pEmailTemplate
*   
*
* CALLED FROM:
*   ViewpointCS Portal
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

SELECT TOP 1
    EmailTemplateID,  
    Name,  
    Description,  
    FromAddress,  
    ToAddress,  
    CCAddress,  
    BCCAddress,  
    Subject,  
    Body  
FROM pEmailTemplate with (nolock)
WHERE Name = @TemplateName
GO
GRANT EXECUTE ON  [dbo].[vpspEmailTemplateGet] TO [VCSPortal]
GO
