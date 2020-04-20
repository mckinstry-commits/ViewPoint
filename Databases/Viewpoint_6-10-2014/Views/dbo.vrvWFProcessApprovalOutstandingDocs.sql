SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE VIEW [dbo].[vrvWFProcessApprovalOutstandingDocs]
  
/*==================================================================================          
    
Author:       
Scott Alvey      
    
Create date:       
05/30/2012       
    
Usage:
Returns a list of approvers per document approval instance, what step each approver is in,
flags the next approver in line to approve the instance, and various document details
relevant to the instance.
    
Things to keep in mind regarding this report and proc:
This view has 4 CTEs (notes of what each does is in the CTE code blocks) and feeds both
related work center queries at, at the time of writing this, a report as well. This was
done so that the code would only need to be written once. The work center queries just
look to who is next, so '"where NextApprover = Y" but the report looks at all approvers
in the instance and just marks what line is next. 

Regarding the concept of days in court, or how many days has an approver been sitting on 
his/her item to approve, the count start the day the instance is submitted. This means that
if an item is submitted for approval on 5/30/12 and then approved by the first person that
same day then the days in court value for this person is 1 as the approval was done in one day.
Subitted 5/30/12 and approved on 5/31/12 is 2 days and so on.

It is important to note that approvers may be option or required and if a step in the approval
instance only has one approver and that approver is optional the code will flag that 
line as the next approver line as Viewpoint sees this step as required. But if the step
has multiple reveiwers with at least one being optional the code the will skip over the 
optional person and flag the next required person as the next approver. This logic is contained
in the final data call subselect join.

If a process instance is rejected the WFProcessDetail.CurrentStepID field gets set to 0 but since
the next approver subselect section just looks to the next approver that needs to approve there
could be instances where a process instance is rejected, but the next approver flag would show on
the next approver after the approver who rejected the instance (please tell me that makes sense...).
So in the subselect where clause we add a "CurrentStepID <> 0" check so that it will only bring
back the next approver if the process instance IS NOT rejected.
    
Related reports: 
WF Documents Oustanding (ID: 1216)
VA Inquiries WFDocumentsAllOutstanding and WFDocumentsMyOustanding      
   
    
Revision History          
Date  Author   Issue      Description    
  
==================================================================================*/       
  
As

with 

DocumentDetails as

/*  
Notes:
This CTE will need to be modified as we new process entry points are added. Right
now it just looks to PO info and gives the returned data generic fields to be used 
in the final data call
       
Links:  
WFProcessDetail     
POPendingPurchaseOrderItem
POPendingPurchaseOrder
PMMF
POHD 
 
*/ 

(
	select
		detail.SourceView
		, detail.SourceKeyID
		, poheader.POCo as SourceCompany
		, poheader.PO as DocumentID
		, poheader.Description as DocumentIDDescription
		, poitem.POItem as DetailID
		, poitem.Description as DetailIDDescription
		, poitem.OrigCost as DetailDollarAmt
		, poheader.KeyID as hKeyID
		, 'POPendingPurchaseOrder' as FormName
		, vfWFPOStatusGet.POStatus as POStatusCode
		, case vfWFPOStatusGet.POStatus
			when 20 then 'No Activity' 
			when 30 then 'Partial'
			when 40 then 'Approved - Unprocessed'
			when 50 then 'Rejected'
			else 'N\A'
		  end as POStatusDescription	
	from
		WFProcessDetail detail
	join
		POPendingPurchaseOrderItem poitem on
			poitem.KeyID = detail.SourceKeyID
	join
		POPendingPurchaseOrder poheader on
			poheader.PO = poitem.PO
			and poheader.POCo = poitem.POCo
	outer apply
		vfWFPOStatusGet (2, poheader.KeyID)	
							
	union
	
	select
		detail.SourceView
		, detail.SourceKeyID
		, poheader.POCo as SourceCompany
		, poheader.PO as DocumentID
		, poheader.Description as DocumentIDDescription
		, poitem.POItem as DetailID
		, poitem.MtlDescription as DetailIDDescription
		, poitem.Amount as DetailDollarAmt
		, poheader.KeyID as hKeyID
		, 'PMPOHeader' as FormName 	
		, vfWFPOStatusGet.POStatus as POStatusCode
		, case vfWFPOStatusGet.POStatus
			when 20 then 'No Activity' 
			when 30 then 'Partial'
			when 40 then 'Approved - Unprocessed'
			when 50 then 'Rejected'
			else 'N\A'
		  end as POStatusDescription
	from
		WFProcessDetail detail
	join
		PMMF poitem on
			poitem.KeyID = detail.SourceKeyID
	join
		POHD poheader on
			poheader.PO = poitem.PO
			and poheader.POCo = poitem.POCo
	outer apply
		vfWFPOStatusGet (1, poheader.KeyID)
),

CurrentCreatedOn as

/*  
Notes:
each process table has a related history table and we need to look at the history of
changed records to see when something actually happens. Here we looking to see when
a process instance was created. If the instance was rejected and sent back for approval
many times we just want to grab the oldest created on date. Even though new history
lines are create for this process instance the created on date will stay the same for every
new linee of the instance so we can alway just grab the most recent one.
       
Links:
WFProcessDetailHistory          
 
*/ 

(
	select
		HeaderID
		, min(DateTime) as CreatedOn
	from
		WFProcessDetailHistory
	where
		Action = 'INSERT'
	group by 
		HeaderID
),

ApproverHistory as

/*  
Notes:
each process table has a related history table and we need to look at the history of
changed records to see when something actually happens. Here we are looking to the approver 
history and for the approver KeyID we are looking for the last record of activity. This last
record could be anything but we will use the final select to determine how to use this date.

Links: 
WFProcessDetailApproverHistory       
 
*/ 

(
	select
		KeyID
		, max(DateTime) as FinalActionDate
	from 
		WFProcessDetailApproverHistory
	where
		Action = 'UPDATE'
	group by
		KeyID
)

select
	dd.hKeyID as KeyID
	, dd.FormName
	, case d.SourceView
		when 'POPendingPurchaseOrderItem' then 'PO Pending Purchase Order'
		when 'PMMF' then 'PM Purchase Order'
		else 'Other'
	  end as SourceDocumentType
	, dd.SourceCompany as SourceCompanyID
	, dd.POStatusCode as DocumentApprovalStatusCode
	, dd.POStatusDescription as DocumentApprovalStatusDescription
	, dd.DocumentID 
	, dd.DocumentIDDescription
	, dd.DetailID
	, dd.DetailIDDescription
	, dd.DetailDollarAmt
	, d.InitiatedBy
	, DDUPCreator.FullName as InitiatedByFullName
	, c.CreatedOn as DateInitiatedOn
	, wfproc.Process as ProcessName
	, d.CurrentStepID as DetailCurrentStepID
	, nexta.CurrentStepID as NextApproverCurrentStepID
	, a.Approver as ApproverUserName
	, DDUPApprover.FullName as ApproverFullName
	, a.Status as ApproverStatus
	, case 
		when a.Status in (0,1)  then 'Pending'
		when a.Status = 2 then 'Approved'
		else 'Rejected'
	  end as ApproverStatusDescription
	, a.ApproverOptional as ApproverOptionalFlag
	, case 
		when nexta.NextToApproveKeyID is not null 
			then 'Y' 
			else 'N' 
		end as IsNextApproverFlag
	, a.ApprovalLimit
	, a.Comments
	, case 
		when nexta.NextToApproveKeyID is not null then datediff(day, c.CreatedOn, GetDate()) + 1
		when a.Status >=2 then datediff(day, c.CreatedOn, ah.FinalActionDate) + 1
		else 0
	  end as DaysInCourt
	, case 
		when a.Status >=2
			then ah.FinalActionDate 
			else null
		end as FinalActionDate		
	, a.KeyID as ApproverKeyID
	, s.Step as ApprovalProcessStep
	, d.HeaderID as WFProcessDetailHistoryHeaderID
from 
	WFProcessDetailApprover a  
join 
	WFProcessDetailStep s on 
		a.DetailStepID = s.KeyID 
join 
	WFProcessDetail d on 
		s.ProcessDetailID = d.KeyID
join
	DocumentDetails dd on
		d.SourceView = dd.SourceView
		and d. SourceKeyID = dd.SourceKeyID
join
	DDUP DDUPApprover on 
		a.Approver = DDUPApprover.VPUserName
join
	DDUP DDUPCreator on
		d.InitiatedBy = DDUPCreator.VPUserName
join
	WFProcess wfproc on
		d.ProcessID = wfproc.KeyID
join
	CurrentCreatedOn c on
		d.HeaderID = c.HeaderID
left outer join
	ApproverHistory ah on
		a.KeyID = ah.KeyID		
left outer join
	(
		select
			Min(app.KeyID) as NextToApproveKeyID
			, det.HeaderID
			, det.CurrentStepID  
		from 
			WFProcessDetailApprover app  
		join 
			WFProcessDetailStep st on 
				app.DetailStepID = st.KeyID 
		join 
			WFProcessDetail det on 
				st.KeyID = det.CurrentStepID
		where
			app.Status < 2
			and det.CurrentStepID <> 0
		group by 
			det.HeaderID
			, det.CurrentStepID
	) nexta on
		nexta.NextToApproveKeyID = a.KeyID
		and nexta.CurrentStepID = d.CurrentStepID
		and nexta.HeaderID = d.HeaderID		
where
	dd.POStatusCode not in (10,15,60)
GO
GRANT SELECT ON  [dbo].[vrvWFProcessApprovalOutstandingDocs] TO [public]
GRANT INSERT ON  [dbo].[vrvWFProcessApprovalOutstandingDocs] TO [public]
GRANT DELETE ON  [dbo].[vrvWFProcessApprovalOutstandingDocs] TO [public]
GRANT UPDATE ON  [dbo].[vrvWFProcessApprovalOutstandingDocs] TO [public]
GRANT SELECT ON  [dbo].[vrvWFProcessApprovalOutstandingDocs] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvWFProcessApprovalOutstandingDocs] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvWFProcessApprovalOutstandingDocs] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvWFProcessApprovalOutstandingDocs] TO [Viewpoint]
GO
