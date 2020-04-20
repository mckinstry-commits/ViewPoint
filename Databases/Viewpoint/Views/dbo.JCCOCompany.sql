SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/*****************************************
* Created By:	DANF 06/01/2005
* Modified By:
*
* Used in JC Company Form. 6.x
*
*****************************************/

CREATE view [dbo].[JCCOCompany] as 
select top 100 percent 
JCCO.JCCo, HJCCO.Name as 'JCName', HGLCO.Name as 'GLName', HARCO.Name as 'ARName', HINCO.Name as 'INName', HPRCO.Name as 'PRName',
CstGLJR.Description as 'CstJrnl', RevGLJR.Description as 'RevJrnl', ClsGLJR.Description as 'ClsJrnl', MatGLJR.Description as 'MatJrnl', MatGLAC.Description as 'MatAcct'
from JCCO JCCO with (nolock)
left join HQCO HJCCO with (nolock) on HJCCO.HQCo = JCCO.JCCo
left join HQCO HGLCO with (nolock) on HGLCO.HQCo = JCCO.GLCo
left join HQCO HARCO with (nolock) on HARCO.HQCo = JCCO.ARCo
left join HQCO HINCO with (nolock) on HINCO.HQCo = JCCO.INCo
left join HQCO HPRCO with (nolock) on HPRCO.HQCo = JCCO.PRCo
left join GLJR CstGLJR with (nolock) on CstGLJR.GLCo = JCCO.GLCo and CstGLJR.Jrnl = JCCO.GLCostJournal
left join GLJR RevGLJR with (nolock) on RevGLJR.GLCo = JCCO.GLCo and RevGLJR.Jrnl = JCCO.GLRevJournal
left join GLJR ClsGLJR with (nolock) on ClsGLJR.GLCo = JCCO.GLCo and ClsGLJR.Jrnl = JCCO.GLCloseJournal
left join GLJR MatGLJR with (nolock) on MatGLJR.GLCo = JCCO.GLCo and MatGLJR.Jrnl = JCCO.GLMatJournal
left join GLAC MatGLAC with (nolock) on MatGLAC.GLCo = JCCO.GLCo and MatGLAC.GLAcct = JCCO.GLMiscMatAcct
order by JCCO.JCCo






GO
GRANT SELECT ON  [dbo].[JCCOCompany] TO [public]
GRANT INSERT ON  [dbo].[JCCOCompany] TO [public]
GRANT DELETE ON  [dbo].[JCCOCompany] TO [public]
GRANT UPDATE ON  [dbo].[JCCOCompany] TO [public]
GO
