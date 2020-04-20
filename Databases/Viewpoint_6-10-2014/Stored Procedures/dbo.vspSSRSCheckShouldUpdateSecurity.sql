SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ==============================================================================
-- Author:      Chris Crewdson
-- Create date: 2012-05-18
-- Description: Determines if SSRS security need to be updated. This is used 
--              during DDFS setting to see if Sys Admins and Sys Users need to 
--              be synchronized out to the SSRS server. 
--              This is currently done by selecting the count of SSRS reports.
--              If the count is greater than 0, the code will update SSRS.
-- Modified:    HH TK-15495 Added check for URL type and server to reduce unnecessary records
-- ==============================================================================
CREATE PROCEDURE [dbo].[vspSSRSCheckShouldUpdateSecurity]
-- Add the parameters for the stored procedure here
(@msg varchar(80) = '' output)

AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    declare @rcode int
    select @rcode = 0

    SELECT COUNT(*)
    FROM [dbo].[RPRTShared] t
    INNER JOIN [dbo].[RPRL] l ON l.Location = t.Location
    INNER JOIN [dbo].[RPRSServer] s ON s.ServerName = l.ServerName
    WHERE t.AppType = 'SQL Reporting Services'
			AND l.LocType = 'URL'
			AND (s.[Server] IS NOT NULL OR s.[Server] <> '')
    

    return @rcode

bsperror:
    
    if @rcode <> 0 select @msg = @msg + char(13) + char(20) + '[vspSSRSCheckShouldUpdateSecurity]'
    return @rcode

END
GO
GRANT EXECUTE ON  [dbo].[vspSSRSCheckShouldUpdateSecurity] TO [public]
GO
