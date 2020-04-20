SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Charles Courchaine
-- Create date: 2/4/2008
-- Description:	This procedure returns source/routing preferences
-- =============================================
CREATE PROCEDURE [dbo].[vspDDGetNFPreferences]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select u.VPUserName, u.EMail, isnull(n.Destination,u.DefaultDestType) as Destination, Source  from DDUP u
	full outer join vDDNotificationPrefs n on n.VPUserName = u.VPUserName
	where u.EMail is not null
union
select u.VPUserName, u.EMail, u.DefaultDestType as Destination, null as Source  from DDUP u where u.EMail is not null
END

GO
GRANT EXECUTE ON  [dbo].[vspDDGetNFPreferences] TO [public]
GO
