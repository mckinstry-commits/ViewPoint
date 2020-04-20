SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION dbo.vfVPGetQuerySecurity
/**************************************************
* Created: CC 06/23/2011
* Modified: 
*			
* This procedure returns the security for the my viewpoint grid queries
*
* Inputs:
*	@Co & @user
*
* Output: table of queries and their security access
*
****************************************************/
(@user AS bVPUserName, @co AS bCompany)
RETURNS TABLE 
AS
RETURN 
(
  	SELECT DISTINCT QueryName, COALESCE(MAX(CASE WHEN [Type] = 'User' THEN Access END) OVER (PARTITION BY QueryName), MAX(CASE WHEN [Type] = 'Group' THEN Access END)OVER (PARTITION BY QueryName)) AS 'Access'
	FROM
	(
		SELECT DISTINCT COALESCE(MAX(CASE WHEN [Type] ='OneCompany' THEN Access END) OVER (PARTITION BY QueryName), MAX(CASE WHEN [Type] = 'AllCompany' THEN Access END) OVER (PARTITION BY QueryName)) AS 'Access', QueryName, 'User' AS 'Type'  FROM 
			(
				-- 1st check: Report security for user AND active company, Security Group -1
				SELECT Access, VPQuerySecurity.QueryName, 'OneCompany' AS 'Type'
				FROM dbo.VPQuerySecurity WITH (NOLOCK)
				INNER JOIN VPGridQueries ON VPQuerySecurity.QueryName = VPGridQueries.QueryName
				WHERE Co = @co AND SecurityGroup = -1 AND VPUserName = @user

				UNION ALL

				-- 2nd check: Report security for user across all companies, Security Group -1 AND Company = -1
				SELECT Access, VPQuerySecurity.QueryName, 'AllCompany' AS 'Type'
				FROM dbo.VPQuerySecurity WITH (NOLOCK)
				INNER JOIN VPGridQueries ON VPQuerySecurity.QueryName = VPGridQueries.QueryName
				WHERE Co = -1 AND SecurityGroup = -1 AND VPUserName = @user
			)
			AS UserGridSecurity

			UNION 
			
		SELECT DISTINCT COALESCE(MIN(CASE WHEN [Type] = 'OneCompany' THEN Access END) OVER (PARTITION BY QueryName), MIN(CASE WHEN [Type] = 'AllCompany' THEN Access END) OVER (PARTITION BY QueryName), 2), QueryName, 'Group' AS 'Type' FROM
			(
				-- 3rd check: Report security for groups that user IS a member of within active company
				SELECT MIN(r.Access) OVER (PARTITION BY t.QueryName) AS 'Access', t.QueryName, 'OneCompany' AS 'Type'
				FROM VPGridQueries t WITH (NOLOCK)
				INNER JOIN VPQuerySecurity r ON t.QueryName = r.QueryName AND r.SecurityGroup <> -1
				INNER JOIN DDSU s ON s.SecurityGroup = r.SecurityGroup AND s.VPUserName = @user
				WHERE r.Co = @co 

				UNION ALL

				-- 4th check: Report security for groups that user IS a member of across all companies, Company = -1
				SELECT MIN(r.Access) OVER (PARTITION BY t.QueryName) AS 'Access', t.QueryName, 'AllCompany' AS 'Type'
				FROM VPGridQueries t WITH (NOLOCK)
				INNER JOIN VPQuerySecurity r ON t.QueryName = r.QueryName AND r.SecurityGroup <> -1
				INNER JOIN DDSU s ON s.SecurityGroup = r.SecurityGroup AND s.VPUserName = @user
				WHERE (r.Co = -1 or r.Co IS NULL) 
			)
			AS GroupGridSecurity
	) 
	AS QuerySecurity
)
GO
GRANT SELECT ON  [dbo].[vfVPGetQuerySecurity] TO [public]
GO
