SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[HQSAExclusions] 
AS 
/***********************************************************************
*	Created by: 	CC 05/07/2009 - View to get list of excluded audit records
*	Checked by:		JonathanP 5/26/09
*
*	Altered by: 	
*
*	Returns:		A list of Audit IDs in HQMA that the current user should not be able to view					
*
***********************************************************************/

	SELECT	  Audit.AuditID
			--, Users.VPUserName
			--, Audit.Qualifier
			--, Audit.Instance
			--, SecurityLinks.InUse
			--, DataTypes.Secure
			--, Audit.Datatype
	FROM HQSA AS Audit
	LEFT OUTER JOIN DDDTShared AS DataTypes 
		ON	Audit.Datatype = DataTypes.Datatype
	LEFT OUTER JOIN DDSLShared AS SecurityLinks 
		ON	Audit.TableName = SecurityLinks.TableName
			AND Audit.Datatype = SecurityLinks.Datatype
	LEFT OUTER JOIN DDDU AS Users
		ON	Audit.Datatype = Users.Datatype
			AND Audit.Qualifier = Users.Qualifier
			AND Audit.Instance = Users.Instance
			AND SUSER_NAME() = Users.VPUserName
	WHERE	Audit.Instance IS NOT NULL
			AND Users.VPUserName IS NULL
			AND SecurityLinks.InUse = 'Y'
			AND DataTypes.Secure = 'Y'
GO
GRANT SELECT ON  [dbo].[HQSAExclusions] TO [public]
GRANT INSERT ON  [dbo].[HQSAExclusions] TO [public]
GRANT DELETE ON  [dbo].[HQSAExclusions] TO [public]
GRANT UPDATE ON  [dbo].[HQSAExclusions] TO [public]
GRANT SELECT ON  [dbo].[HQSAExclusions] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQSAExclusions] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQSAExclusions] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQSAExclusions] TO [Viewpoint]
GO
