use Viewpoint
go

--begin tran
--update SLHD set Status=2 
--from
--	JCJM jcjm 
--where
--		SLHD.JCCo=jcjm.JCCo
--	and SLHD.Job=jcjm.Job
--	and jcjm.JobStatus in (2,3)
--	and SLHD.Status not in (1,2)


select --(3745 row(s) affected)
	slhd.SLCo
,	slhd.SL
,	slhd.Status as SLStatus
,	case slhd.Status
		when 0 then '0 - Open'
		when 1 then '1 - Complete'
		when 2 then '2 - Closed'
		when 3 then '3 - Pending'
		else '? - Unknown'
	end as SLStatusDesc
,	slhd.Vendor
,	apvm.Name as VendorName
,	jcjm.JCCo
,	jcjm.Job
,	jcjm.JobStatus
,	case jcjm.JobStatus
		when 0 then '0-Pending'
		when 1 then '1-Open'
		when 2 then '2-Soft Close'
		when 3 then '3-Hard Close'
		else '?-Unknow'
	end as JobStatusDesc
,	slit.SLItem
,	slit.UM
,	slit.CurCost as SLItemCurCost
,	slit.InvCost as SLItemInvCost
,	slit.CurUnits
,	slit.InvUnits
,	case
		when slit.UM='LS' and slit.CurCost <> slit.InvCost then 'N'
		else 'Y'
	end as CostBalances
,	case
		when slit.UM<>'LS' and slit.CurUnits <> slit.InvUnits then 'N'
		else 'Y'
	end as UnitBalances
from
	SLHD slhd join
	JCJM jcjm on
		slhd.JCCo=jcjm.JCCo
	and slhd.Job=jcjm.Job
	and jcjm.JobStatus in (2,3)
	and slhd.Status not in (1,2) join
	SLIT slit on
		slhd.SLCo=slit.SLCo
	and slhd.SL=slit.SL left join
	APVM apvm on
		slhd.VendorGroup=apvm.VendorGroup
	and slhd.Vendor=apvm.Vendor
--where
--	slit.CurCost <> slit.InvCost
order by
	slhd.Status

