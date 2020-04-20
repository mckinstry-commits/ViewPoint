use Viewpoint
go

/*
2014.12.29 - LWO - Script to add "ZZZ" Reviewer to all APUL records that are missing Reviewers.
Only updating rows that are not associated to Jobs or Subcontracts (e.g. GL only)

*/
begin tran

insert APUR
(
	APCo	
,	UIMth	
,	UISeq	
,	Reviewer	
,	ApprvdYN	
,	Line	
,	ApprovalSeq	
,	DateAssigned	
,	DateApproved	
,	AmountApproved	
,	Rejected	
,	RejReason	
,	APTrans	
,	ExpMonth	
,	Memo	
,	LoginName	
,	UniqueAttchID	
,	RejectDate	
--,	KeyID	
,	ReviewerGroup
)
select 
	apul.APCo
,	apul.UIMth
,	apul.UISeq
--,	substring(apul.GLAcct,10,4) as GLDept
--,	apul.JCCo
--,	apul.Job
,	'ZZZ'
,	'N'
,	1
,	1
,	getdate()
,	null
,	null
,	'N'
,	null	--RejReason	
,	null	--APTrans	
,	null	--ExpMonth	
,	'BUM: ' + coalesce(pmpm.LastName + ',','') + coalesce(pmpm.FirstName + ' ','') --Memo	
,	null	--LoginName	
,	null	--UniqueAttchID	
,	null	--RejectDate	
--,	--KeyID	
,	null	--ReviewerGroup
--,	count(apur.KeyID) as ReviewerCount
from
	APUI apui 
	JOIN APUL apul on
		apui.APCo=apul.APCo
	and apui.UIMth=apul.UIMth
	and apui.UISeq=apul.UISeq
	LEFT OUTER JOIN APUR apur on
		apul.APCo=apur.APCo
	and apul.UIMth=apur.UIMth
	and apul.UISeq=apur.UISeq 
	LEFT OUTER JOIN udGLDept ud on
		ud.Co=apui.APCo
	and ud.GLDept=substring(apul.GLAcct,10,4) 
	LEFT OUTER JOIN PMPM pmpm on
		ud.ResponsiblePerson=pmpm.ContactCode
WHERE
	apui.APCo < 100
AND ( apul.Job is null and apul.SL is null)
group by 
	apul.APCo
,	apul.UIMth
,	apul.UISeq
,	'BUM: ' + coalesce(pmpm.LastName + ',','') + coalesce(pmpm.FirstName + ' ','')
--,	substring(apul.GLAcct,10,4)
--,	apul.JCCo
--,	apul.Job
having
	count(apur.KeyID)=0
order by
	apul.APCo
,	apul.UIMth
,	apul.UISeq

if @@ERROR=0
	COMMIT TRAN
else
	ROLLBACK TRAN
go


--select * from PM
--select * from APUR where APCo < 100 order by KeyID desc
