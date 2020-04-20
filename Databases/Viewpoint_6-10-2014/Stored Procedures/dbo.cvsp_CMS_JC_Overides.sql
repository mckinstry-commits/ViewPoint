SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvsp_CMS_JC_Overides]
	( @fromco1	smallint
	, @fromco2	smallint
	, @fromco3	smallint
	, @toco		smallint
	, @errmsg	varchar(1000) output
	, @rowcount bigint output) 
as


alter table bJCOP disable trigger all
alter table bJCOR disable trigger all

begin tran
delete from bJCOP where JCCo = @toco
delete from bJCOR where JCCo = @toco
commit tran

BEGIN TRAN
BEGIN TRY
	/* Cost overrides */
	insert into bJCOP (JCCo, Job, Month, ProjCost, OtherAmount, Notes)
	select 
		  JCCo			= j.VPCo
		, Job			= j.VPJob
		, Month			= cast(cast(p.YYR as varchar(4))+'-'+cast(p.YMO as varchar(2))+'-01' as smalldatetime)
		, ProjCost		= p.YESCM
		, OtherAmount	= 0
		, Notes			= NULL
	from CV_CMS_SOURCE_TEST.dbo.JCPPRY p 
	join Viewpoint.dbo.budxrefJCJobs j 
		on j.JOBNUMBER = p.YJBNO 
		and j.COMPANYNUMBER = p.YCONO 
		and j.DIVISIONNUMBER = p.YDVNO 
		and j.SUBJOBNUMBER = p.YSJNO 
		and j.VPJob is not null
	join Viewpoint.dbo.JCJM jm on j.VPCo=jm.JCCo and j.VPJob=jm.Job
	WHERE j.COMPANYNUMBER in (@fromco1,@fromco2,@fromco3)


select @rowcount=@@rowcount;

	/* Revenue overrides */
	insert into bJCOR (JCCo, Contract, Month, RevCost, OtherAmount, Notes)
	select 
		  JCCo			= j.VPCo
		, Contract		= j.VPJob
		, Month			= cast(cast(p.YYR as varchar(4))+'-'+cast(p.YMO as varchar(2))+'-01' as smalldatetime)
		, RevCost		= p.YICCA
		, OtherAmount	= 0
		, Notes			= NULL
	from CV_CMS_SOURCE_TEST.dbo.JCPPRY p 
	join Viewpoint.dbo.budxrefJCJobs j 
		on j.JOBNUMBER = p.YJBNO 
		and j.COMPANYNUMBER = p.YCONO 
		and j.DIVISIONNUMBER = p.YDVNO 
		and j.SUBJOBNUMBER = p.YSJNO 
		and j.VPJob is not null
	join Viewpoint.dbo.JCJM jm on j.VPCo=jm.JCCo and j.VPJob=jm.Job
	WHERE j.COMPANYNUMBER in (@fromco1,@fromco2,@fromco3)


select @rowcount=@rowcount + @@rowcount;

COMMIT TRAN
END TRY

BEGIN CATCH
select @errmsg=isnull(ERROR_PROCEDURE(),'')+' '+convert(varchar(10),isnull(ERROR_LINE(),0))+' '+isnull(ERROR_MESSAGE(),'')
ROLLBACK
END CATCH;

alter table bJCOP enable trigger all
alter table bJCOR enable trigger all

return @@error
GO
