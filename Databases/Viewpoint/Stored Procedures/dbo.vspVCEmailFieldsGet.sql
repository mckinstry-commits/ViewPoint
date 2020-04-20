SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVCEmailFieldsGet]
/************************************************************
* CREATED:     2011-10-19 Chris Crewdson
* MODIFIED:    
*
* USAGE:
*   Gets all Email Fields from VCEmailField
*
* CALLED FROM:
*   VC Module
*
* INPUT PARAMETERS
*    None
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
AS
    SET NOCOUNT ON;
SELECT 
    EmailFieldID,  
    FieldKey,  
    Description,  
    Lookup,  
    BuiltIn   
FROM VCEmailField with (nolock)
GO
GRANT EXECUTE ON  [dbo].[vspVCEmailFieldsGet] TO [public]
GO
