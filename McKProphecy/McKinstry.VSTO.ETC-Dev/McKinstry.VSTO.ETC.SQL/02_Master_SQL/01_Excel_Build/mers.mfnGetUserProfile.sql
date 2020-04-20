use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnGetUserProfile' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnGetUserProfile'
	DROP FUNCTION mers.mfnGetUserProfile
end
go

print 'CREATE FUNCTION mers.mfnGetUserProfile'
go

create function mers.mfnGetUserProfile
(
	@JCCo	bCompany
,	@Login	sysname
)
-- ========================================================================
-- mers.mfnGetUserProfile
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	Prophecy Project - McKinstry Projections
-- Update Hist: USER--------DATE-------DESC-----------
--				J.Ziebell   7/27/2016  Remove Project Manager Restriction
-- ========================================================================
returns table as return

select
	ddup.VPUserName
,	ddup.PRCo
,	CASE WHEN ddup.Employee IS NOT NULL THEN ddup.Employee
		 WHEN ddup.Employee IS NULL THEN CAST('10001' AS INT) END AS Employee
,	ddup.FullName
,	ddup.EMail
,	jcmp.JCCo
,	jcmp.ProjectMgr
,	jcmp.Name as ProjecdtMgrName
,	ddup.PRGroup
,	preh.Craft
,	prcm.Description as CraftDesc
,	preh.Class
,	prcc.Description as ClassDesc
,	preh.PRDept
,	prdp.Description as PRDeptName
,	glac.Part3 as GLDept
,	glpi.Description as GLDeptName
from DDUP ddup 
	INNER JOIN HQCO HQ
		ON ddup.DefaultCompany = HQ.HQCo
				AND ((HQ.udTESTCo ='N') OR (HQ.udTESTCo IS NULL))
	LEFT OUTER JOIN	JCMP jcmp 
		ON ddup.PRCo=jcmp.udPRCo
		AND ddup.Employee=jcmp.udEmployee 
		AND ddup.EMail = jcmp.Email
	LEFT OUTER JOIN	PREHName preh 
		ON ddup.PRCo=preh.PRCo
		AND ddup.Employee=preh.Employee 
	LEFT OUTER JOIN	PRCM prcm 
		ON preh.PRCo=prcm.PRCo
		AND preh.Craft=prcm.Craft 
	LEFT OUTER JOIN	PRCC prcc 
		ON preh.PRCo=prcc.PRCo
		AND preh.Craft=prcc.Craft
		AND preh.Class=prcc.Class 
	LEFT OUTER JOIN	PRDP prdp 
		ON preh.PRCo=prdp.PRCo
		AND preh.PRDept=prdp.PRDept 
	LEFT OUTER JOIN	GLAC glac 
		ON prdp.GLCo=glac.GLCo
		AND prdp.JCFixedRateGLAcct=glac.GLAcct 
	LEFT OUTER JOIN	GLPI glpi
		ON glac.GLCo=glpi.GLCo
		AND glac.Part3=glpi.Instance
		AND glpi.PartNo=3
where
	(
			( @Login is not null and upper(ddup.VPUserName)=upper(@Login) )
		or ( @Login is null and upper(ddup.VPUserName)=upper(SUSER_SNAME()) ) 
		or ( upper(@Login) = 'ALL' )
	)
/*and (
		jcmp.JCCo=@JCCo or @JCCo is null
	)*/

go