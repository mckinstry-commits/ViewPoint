SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Huy Huynh
-- Create date: 07/01/10
-- Description:	selecting security setup for connects 
-- by PortalControlID
-- =============================================
CREATE PROCEDURE [dbo].[vrptVCSecuritySetupByID]
	(@BeginRole varchar(30),
	@EndRole varchar(30),
	@BeginControl varchar(50),
	@EndControl varchar(50)
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
	IF @BeginControl IS NULL OR @BeginControl = ''
		BEGIN
			SELECT @BeginControl = MIN(Name) FROM pvPortalControls
		END
	IF @EndControl IS NULL OR @EndControl = ''
		BEGIN
			SELECT @EndControl = MAX(Name) FROM pvPortalControls
		END	

	SELECT pvPortalControlSecurityTemplate.PortalControlID
		, CASE
			WHEN pvPortalControls.ChildControl = '0'
				THEN 'Parent'
				ELSE 'Child'
			END AS Node
		, pvPortalControls.Name AS PageTemplateCtrlName
		, pvRoles.Name AS RoleName
		, CASE 
				WHEN pvPortalControlSecurityTemplate.AllowAdd= '0'
					THEN ''
					ELSE 'Y'
				END AS AAdd
		, CASE 
				WHEN pvPortalControlSecurityTemplate.AllowEdit= '0'
					THEN ''
					ELSE 'Y'
				END AS Edit
		, CASE 
				WHEN pvPortalControlSecurityTemplate.AllowDelete= '0'
					THEN ''
					ELSE 'Y'
				END AS DDelete

	FROM pvPortalControlSecurityTemplate
	LEFT JOIN pvPortalControls 
		ON pvPortalControlSecurityTemplate.PortalControlID = pvPortalControls.PortalControlID
	LEFT JOIN pvRoles 
		ON pvPortalControlSecurityTemplate.RoleID = pvRoles.RoleID

	WHERE
	(pvRoles.Name >= @BeginRole AND pvRoles.Name <=@EndRole)
	AND (pvPortalControls.Name >= @BeginControl 
			AND pvPortalControls.Name <= @EndControl)

	Order by pvPortalControls.Name, pvRoles.Name
END -- proc


GO
GRANT EXECUTE ON  [dbo].[vrptVCSecuritySetupByID] TO [public]
GO
