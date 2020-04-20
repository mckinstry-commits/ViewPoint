SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvSLClaimPaymentSchedule]
AS 

  
/***********************************************************************        
Author:     
Scott Alvey
       
Create date:     
12/10/2012 
        
Usage:  
The related report needs to pull data from two somewhat similar locations 
(Claim Item and Claim Variation) and needs to keep this data in two different 
sections. To do this we introduce a GroupType column in the header so that we can
then use it in the report to separate the types of data. The CTE is there to
help keep us from repeating the same common fields twice, on each side of the union,
and to make it eaiser if we need to add extra header fields.

Note: After creating this view, and the related report, it was determined by the powers
that be that the Variation portion of the code was not going to be used by the report
at this time. I am leaving the code in this view as it will proabably be used 'as-is'
at a later date. The report did not need to be modified as it will just act like a 
claim has no variation section.
    
Parameters:  
NA    
    
Related reports: 
SL Claim Payment Schedule (ID: 1232)   

        
Revision History        
Date  Author  Issue     Description    
    
***********************************************************************/      

with

ClaimHeader

as

(
	select
		SLCo
		, SL
		, ClaimNo
		, Description as ClaimHeaderDescription
		, ClaimDate
		, RecvdClaimDate
		, APRef
		, InvoiceDate
		, Notes as ClaimHeaderNotes
	from
		SLClaimHeader s 
		
)

select
	'I' as GroupType
	, h.*
	, i.SLItem as SLItemOrVarSeq
	, null as SubReference
	, i.Description
	, i.ClaimAmount
	, i.ApproveAmount
	, i.Notes
from
	ClaimHeader h 
join
	SLClaimItem i on
		h.SLCo = i.SLCo
		and h.SL = i.SL
		and h.ClaimNo = i.ClaimNo
		
		
--union


--select
--	'V' as GroupType
--	, h.*
--	, s.Seq as SLItemOrVarSeq
--	, SubReference
--	, s.Description
--	, s.ClaimAmount
--	, s.ApproveAmount
--	, s.Notes
--from
--	ClaimHeader h 
--join
--	SLClaimItemVariation s on
--		h.SLCo = s.SLCo
--		and h.SL = s.SL
--		and h.ClaimNo = s.ClaimNo

  
GO
GRANT SELECT ON  [dbo].[vrvSLClaimPaymentSchedule] TO [public]
GRANT INSERT ON  [dbo].[vrvSLClaimPaymentSchedule] TO [public]
GRANT DELETE ON  [dbo].[vrvSLClaimPaymentSchedule] TO [public]
GRANT UPDATE ON  [dbo].[vrvSLClaimPaymentSchedule] TO [public]
GRANT SELECT ON  [dbo].[vrvSLClaimPaymentSchedule] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSLClaimPaymentSchedule] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSLClaimPaymentSchedule] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSLClaimPaymentSchedule] TO [Viewpoint]
GO
