SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/*****************************************
* Created By:	GF 11/15/2009 - issue #135527 JOB ROLES
* Modfied By:
*
* Provides a view of JC Job Roles for use in PM Projects.
* Since PMProjects form uses PMCo and Project, need to
* alias JCCO as [PMCo] and Job as [Project] so that
* JC Job Roles can be on a related tab in PM Projects form.
*
*****************************************/


CREATE view [dbo].[JCJobRolesPM] as
	select a.JCCo as [PMCo], a.Job as [Project], a.*
From vJCJobRoles a








GO
GRANT SELECT ON  [dbo].[JCJobRolesPM] TO [public]
GRANT INSERT ON  [dbo].[JCJobRolesPM] TO [public]
GRANT DELETE ON  [dbo].[JCJobRolesPM] TO [public]
GRANT UPDATE ON  [dbo].[JCJobRolesPM] TO [public]
GO
