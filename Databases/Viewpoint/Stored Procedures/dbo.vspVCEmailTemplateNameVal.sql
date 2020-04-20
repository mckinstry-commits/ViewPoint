SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[vspVCEmailTemplateNameVal]
/************************************************************
* CREATED:     2011-10-19 Chris Crewdson
* MODIFIED:    
*
* USAGE:
*   Validates if the template given exists in the pEmailTemplate table
*   
*
* CALLED FROM:
*   VC Module
*
* INPUT PARAMETERS
*    TemplateName
*
* OUTPUT PARAMETERS
*   @msg		Description of error if one occured.
*   
* RETURN VALUE
*   0         success
*   1         Failure
************************************************************/
(@TemplateName varchar(255) = Null, @msg varchar(255) output)
AS
    SET NOCOUNT ON;

declare @rcode int
set @rcode = 0

--Validate
if @TemplateName is null
begin
    select @msg = 'Missing template name.', @rcode = 1
end
else
begin
    SELECT Name FROM pEmailTemplate with (nolock) where Name = @TemplateName
    if @@rowcount = 0
    begin
        select @msg = 'Invalid template name.', @rcode = 1
    end
end
return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVCEmailTemplateNameVal] TO [public]
GO
