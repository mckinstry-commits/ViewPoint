SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetAvailableTemplates]
   /***********************************************************
    * CREATED BY: CC 09/10/2008
    * MODIFIED BY: AL #140509 09/19/2010
    *
    *
    *
    *
    * Usage: Gets list of templates availble to the user in the current company
    *
    * Input params:
    *	@username
    *	@Co
    *
    * Output params:
    *	Result set of available templates
    *
    * Return code:
    *	0 = success, 1 = failure
   ************************************************************/
   
    (@Co bCompany, @username bVPUserName)
   
   AS
   
   SET NOCOUNT ON
   
SELECT 
t.TemplateName
FROM VPCanvasSettingsTemplate t 
INNER JOIN
(
	SELECT DISTINCT TemplateName, COALESCE(MAX(CASE WHEN [Type] = 'User' THEN Access END) OVER(PARTITION BY TemplateName), MAX(CASE WHEN [Type] = 'Group' THEN Access END)OVER(PARTITION BY TemplateName)) AS 'Access'
	FROM
	(
		SELECT DISTINCT COALESCE(MAX(CASE WHEN [Type] ='OneCompany' THEN Access END) OVER(PARTITION BY TemplateName), MAX(CASE WHEN [Type] = 'AllCompany' THEN Access END) OVER(PARTITION BY TemplateName)) AS 'Access', TemplateName, 'User' AS 'Type'  FROM 
			(
				-- 1st check: Report security for user AND active company, Security Group -1
				SELECT Access, VPCanvasTemplateSecurity.TemplateName, 'OneCompany' AS 'Type'
				FROM dbo.VPCanvasTemplateSecurity WITH (NOLOCK)
				INNER JOIN VPCanvasSettingsTemplate ON VPCanvasTemplateSecurity.TemplateName = VPCanvasSettingsTemplate.TemplateName
				where Co = @Co AND SecurityGroup = -1 AND VPUserName = @username

				UNION ALL

				-- 2nd check: Report security for user across all companies, Security Group -1 AND Company = -1
				SELECT Access, VPCanvasTemplateSecurity.TemplateName, 'AllCompany' AS 'Type'
				FROM dbo.VPCanvasTemplateSecurity WITH (NOLOCK)
				INNER JOIN VPCanvasSettingsTemplate ON VPCanvasTemplateSecurity.TemplateName = VPCanvasSettingsTemplate.TemplateName
				where Co = -1 AND SecurityGroup = -1 AND VPUserName = @username
			)
			AS UserTemplateSecurity


			UNION 
			
		SELECT DISTINCT COALESCE(MIN(CASE WHEN [Type] = 'OneCompany' THEN Access END) OVER(PARTITION BY TemplateName), MIN(CASE WHEN [Type] = 'AllCompany' THEN Access END) OVER(PARTITION BY TemplateName), 2), TemplateName, 'Group' AS 'Type' FROM
			(
				-- 3rd check: Report security for groups that user is a member of within active company
				SELECT MIN(r.Access) OVER(partition by t.TemplateName) AS 'Access', t.TemplateName, 'OneCompany' AS 'Type'
				FROM VPCanvasSettingsTemplate t
				INNER JOIN VPCanvasTemplateSecurity r ON t.TemplateName = r.TemplateName AND r.SecurityGroup <> -1
				INNER JOIN DDSU s ON s.SecurityGroup = r.SecurityGroup AND s.VPUserName = @username
				where r.Co = @Co 

				UNION ALL

				-- 4th check: Report security for groups that user is a member of across all companies, Company = -1
				SELECT MIN(r.Access) OVER(partition by t.TemplateName) AS 'Access', t.TemplateName, 'AllCompany' AS 'Type'
				FROM VPCanvasSettingsTemplate t
				INNER JOIN VPCanvasTemplateSecurity r ON t.TemplateName = r.TemplateName AND r.SecurityGroup <> -1
				INNER JOIN DDSU s ON s.SecurityGroup = r.SecurityGroup AND s.VPUserName = @username
				where (r.Co = -1 OR r.Co IS NULL) 
			)
			AS GroupTemplateSecurity
	) 
	AS TemplateSecurity
) AS TemplateAccess ON t.TemplateName = TemplateAccess.TemplateName AND TemplateAccess.Access = 0
GO
GRANT EXECUTE ON  [dbo].[vspVPGetAvailableTemplates] TO [public]
GO
