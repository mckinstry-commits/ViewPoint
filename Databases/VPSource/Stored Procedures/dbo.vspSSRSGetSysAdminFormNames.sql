SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ==============================================================================
-- Author:      Chris Crewdson
-- Create date: 2012-05-18
-- Description: This is the list of forms that means the user given access 
--              should be set as an SSRS Admin
-- Modified:    
-- ==============================================================================
CREATE PROCEDURE [dbo].[vspSSRSGetSysAdminFormNames]
-- Add the parameters for the stored procedure here
(@msg varchar(80) = '' output)

AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    declare @rcode int
    select @rcode = 0

    SELECT 'RPReportCopy' As Form
    UNION
    SELECT 'RPRT' As Form
    UNION
    SELECT 'VARS' As Form

    return @rcode

bsperror:
    
    if @rcode <> 0 select @msg = @msg + char(13) + char(20) + '[vspSSRS]'
    return @rcode

END
GO
GRANT EXECUTE ON  [dbo].[vspSSRSGetSysAdminFormNames] TO [public]
GO
