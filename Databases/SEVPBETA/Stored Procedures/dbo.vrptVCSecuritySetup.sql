SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Huy Huynh
-- Create date: 06/18/10
-- Description:	selecting security setup for connects
-- =============================================
CREATE PROCEDURE [dbo].[vrptVCSecuritySetup]
	(@BeginRole varchar(30),
	@EndRole varchar(30),
	@BeginSite varchar(50),
	@EndSite varchar(50)
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- initialize variables
	IF @BeginRole IS NULL OR @BeginRole = ''
		BEGIN
			SELECT @BeginRole = MIN(Name) FROM pvRoles
		END
	IF @EndRole IS NULL OR @EndRole = ''
		BEGIN
			SELECT @EndRole = MAX(Name) FROM pvRoles
		END
	IF @BeginSite IS NULL OR @BeginSite = ''
		BEGIN
			SELECT @BeginSite = MIN(Name) FROM pvSites
		END
	IF @EndSite IS NULL OR @EndSite = ''
		BEGIN
			SELECT @EndSite = MAX(Name) FROM pvSites
		END	
	
	SELECT 
	s.SiteID
	, s.Name + ' ' + CAST (s.SiteID AS VARCHAR) AS SiteName
	, t.Name + ' ' + CAST (t.PageSiteTemplateID AS VARCHAR) AS PageTempName
	, c.Name AS ControlName
	, r.Name AS RoleName
	, CASE 
			WHEN sc.AllowAdd= '0'
				THEN ''
				ELSE 'Y'
			END AS AAdd
	, CASE 
			WHEN sc.AllowEdit= '0'
				THEN ''
				ELSE 'Y'
			END AS Edit
	, CASE 
			WHEN sc.AllowDelete= '0'
				THEN ''
				ELSE 'Y'
			END AS DDelete
  
	FROM 
	pvPageSiteControlSecurity sc
	INNER JOIN pvSites s on s.SiteID = sc.SiteID
	INNER JOIN pvRoles r on r.RoleID = sc.RoleID 
	INNER JOIN pvPageSiteControls ps ON ps.PageSiteControlID = sc.PageSiteControlID
	INNER JOIN pvPortalControls c ON c.PortalControlID = ps.PortalControlID
	LEFT JOIN pvPageSiteTemplates t ON t.PageSiteTemplateID = ps.PageSiteTemplateID

	WHERE
	(r.Name >= @BeginRole AND r.Name <= @EndRole )	
	AND (s.Name >= @BeginSite AND s.Name <= @EndSite)
	AND (t.Name IS NOT NULL OR t.Name != '')
  
	ORDER BY RoleName, SiteName, PageTempName, ControlName
	
END

GO
GRANT EXECUTE ON  [dbo].[vrptVCSecuritySetup] TO [public]
GO
