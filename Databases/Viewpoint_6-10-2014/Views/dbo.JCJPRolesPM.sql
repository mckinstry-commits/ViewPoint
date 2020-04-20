SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************
* Created By:	GF 01/20/2010 - issue #135527 JOB ROLES
* Modfied By:
*
* Provides a view of JC Job Phase Roles for use in PM Project Phases.
* Since PM forms uses PMCo and Project, need to
* alias JCCO as [PMCo] and Job as [Project] so that
* JC Job Phase Roles can be on a related tab in PM Project Phases form.
*
*****************************************/

CREATE view [dbo].[JCJPRolesPM] as
	select a.*, a.JCCo as [PMCo], a.Job as [Project]
from dbo.JCJPRoles a



GO
GRANT SELECT ON  [dbo].[JCJPRolesPM] TO [public]
GRANT INSERT ON  [dbo].[JCJPRolesPM] TO [public]
GRANT DELETE ON  [dbo].[JCJPRolesPM] TO [public]
GRANT UPDATE ON  [dbo].[JCJPRolesPM] TO [public]
GRANT SELECT ON  [dbo].[JCJPRolesPM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCJPRolesPM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCJPRolesPM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCJPRolesPM] TO [Viewpoint]
GO
