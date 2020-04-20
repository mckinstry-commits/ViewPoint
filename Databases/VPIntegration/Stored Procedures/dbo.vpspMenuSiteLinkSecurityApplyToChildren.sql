SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspMenuSiteLinkSecurityApplyToChildren
(
	@MenuSiteLinkID int,
	@SiteID int,
	@Parent bit = 1
)
	
AS
SET NOCOUNT OFF;
DECLARE @childmenusitelinkID int
SELECT @childmenusitelinkID = MIN(MenuSiteLinkID) FROM pMenuSiteLinks 
	WHERE ParentID = @MenuSiteLinkID AND SiteID= @SiteID 
	AND (MenuSiteLinkID > @childmenusitelinkID OR @childmenusitelinkID IS NULL)
WHILE @childmenusitelinkID IS NOT NULL
BEGIN
	DELETE pMenuSiteLinkRoles WHERE MenuSiteLinkID = @childmenusitelinkID AND SiteID = @SiteID
	
	INSERT INTO pMenuSiteLinkRoles (MenuSiteLinkID, RoleID, SiteID, AllowAccess)
		 (SELECT @childmenusitelinkID, RoleID, @SiteID, AllowAccess FROM pMenuSiteLinkRoles
		  WHERE MenuSiteLinkID = @MenuSiteLinkID AND SiteID = @SiteID)
		
	PRINT 'SECURITY RECORDS INSERTED'
	IF EXISTS (SELECT Top 1 1 FROM pMenuSiteLinks WHERE ParentID = @childmenusitelinkID AND SiteID = @SiteID)
	BEGIN
		exec vpspMenuSiteLinkSecurityApplyToChildren @childmenusitelinkID, @SiteID, 0
		PRINT 'RECURSIVE CALL DONE'
	END
	SELECT @childmenusitelinkID = MIN(MenuSiteLinkID) FROM pMenuSiteLinks 
		WHERE ParentID = @MenuSiteLinkID AND SiteID= @SiteID 
		AND (MenuSiteLinkID > @childmenusitelinkID OR @childmenusitelinkID IS NULL)
END
IF @Parent = 1
BEGIN
	--Give full permission to Viewpoint, Portal Admin
	UPDATE pMenuSiteLinkRoles SET AllowAccess = 1 WHERE RoleID = 0 OR RoleID = 1
	PRINT 'SECURITY RECORDS UPDATED FOR ADMINS'
END


GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinkSecurityApplyToChildren] TO [VCSPortal]
GO
