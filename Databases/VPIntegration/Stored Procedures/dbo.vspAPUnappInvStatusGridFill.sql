SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspAPUnappInvStatusGridFill]
  
  /***********************************************************
   * CREATED BY: MV 12/18/07 - #29702 Unapproved Enhancement
   * MODIFIED By:   MV 07/17/08 - #129034 - apprvd and rejected varchar(1)
   *		TJL 10/06/08 - Issue #129923, Modify form code for International Dates
   *		
   *
   * Usage:
   *	Used by APUnappInvStatus form to fill the grid 
   *
   * Input params:
   *	@responsibleperson			
   *	@rejectedyn	
   *	@approvedyn
   *	@unapprovedyn	
   *
   * Output params:
   *	@msg		error message
   *
   * Return code:
   *	0 = success, 1 = failure
   *****************************************************/
  (@apco bCompany, @responsibleperson varchar(10),@rejectedyn bYN,@approvedyn bYN,@unapprovedyn bYN,
	@msg varchar(255)=null output)
  as
  set nocount on

  declare @table TABLE(APCo int,RevGroup varchar(10),Reviewer varchar(10),AppSeq smallint,
	UISeq smallint,Vendor varchar(60), APRef varchar(15),Line int,UIMth bMonth,Apprvd varchar(1) null, DateAppvd bDate null,
	AmtAppvd bDollar null,Rejected varchar(1) null,RejReason varchar(30) null,ReviewerMemo varchar(max) null,
	AttchID uniqueidentifier,RevEmail varchar(50))

  declare @rcode int
  select @rcode = 0

  /* check required input params */
  if @responsibleperson is null
  	begin
  	select @msg = 'Missing Reponsible Person.', @rcode = 1
  	goto vspexit
  	end
  
 
  if @rejectedyn = 'Y'
begin 
		insert into @table (APCo,RevGroup,Reviewer,AppSeq,UISeq,Vendor,APRef,Line,UIMth,Apprvd,DateAppvd,AmtAppvd,Rejected,RejReason,
	ReviewerMemo,AttchID,RevEmail)
	Select APUR.APCo,isnull(APUL.ReviewerGroup,APUI.ReviewerGroup),APUR.Reviewer,ApprovalSeq,APUR.UISeq,'','',APUR.Line,APUI.UIMth,ApprvdYN,DateApproved,
	AmountApproved,Rejected,RejReason,Memo,APUI.UniqueAttchID,HQRV.RevEmail
	From APUR with (nolock)
	join APUI with (nolock) on APUR.APCo=APUI.APCo and APUR.UIMth=APUI.UIMth and APUR.UISeq=APUI.UISeq
	join APUL with (nolock) on APUL.APCo=APUI.APCo and APUL.UIMth=APUI.UIMth and APUL.UISeq=APUI.UISeq
	left outer join HQRG with (nolock) on HQRG.ReviewerGroup=isnull(APUL.ReviewerGroup,APUI.ReviewerGroup)
	left outer join HQRV with (nolock) on HQRV.Reviewer = APUR.Reviewer
	Where APUR.APCo=@apco and HQRG.ResponsiblePerson=@responsibleperson and APUR.Line <> -1 and Rejected='Y' and APTrans is null
end

if @approvedyn = 'Y'
begin
		insert into @table (APCo,RevGroup,Reviewer,AppSeq,UISeq,Vendor,APRef,Line,UIMth,Apprvd,DateAppvd,AmtAppvd,Rejected,RejReason,
	ReviewerMemo,AttchID,RevEmail)
	Select APUR.APCo,isnull(APUL.ReviewerGroup,APUI.ReviewerGroup),APUR.Reviewer,ApprovalSeq,APUR.UISeq,'','',APUR.Line,APUI.UIMth,ApprvdYN,DateApproved,
	AmountApproved,Rejected,RejReason,Memo,APUI.UniqueAttchID,HQRV.RevEmail
	From APUR with (nolock)
	join APUI with (nolock) on APUR.APCo=APUI.APCo and APUR.UIMth=APUI.UIMth and APUR.UISeq=APUI.UISeq
	join APUL with (nolock) on APUL.APCo=APUI.APCo and APUL.UIMth=APUI.UIMth and APUL.UISeq=APUI.UISeq
	left outer join HQRG with (nolock) on HQRG.ReviewerGroup=isnull(APUL.ReviewerGroup,APUI.ReviewerGroup)
	left outer join HQRV with (nolock) on HQRV.Reviewer = APUR.Reviewer
	Where APUR.APCo=@apco and HQRG.ResponsiblePerson=@responsibleperson and APUR.Line <> -1 and ApprvdYN='Y' and APTrans is null
end

if @unapprovedyn = 'Y'
begin
	insert into @table (APCo,RevGroup,Reviewer,AppSeq,UISeq,Vendor,APRef,Line,UIMth,Apprvd,DateAppvd,AmtAppvd,Rejected,RejReason,
	ReviewerMemo,AttchID,RevEmail)
	Select APUR.APCo,isnull(APUL.ReviewerGroup,APUI.ReviewerGroup),APUR.Reviewer,ApprovalSeq,APUR.UISeq,'','',APUR.Line,APUI.UIMth,ApprvdYN,DateApproved,
	AmountApproved,Rejected,RejReason,Memo,APUI.UniqueAttchID,HQRV.RevEmail
	From APUR with (nolock)
	join APUI with (nolock) on APUR.APCo=APUI.APCo and APUR.UIMth=APUI.UIMth and APUR.UISeq=APUI.UISeq
	join APUL with (nolock) on APUL.APCo=APUI.APCo and APUL.UIMth=APUI.UIMth and APUL.UISeq=APUI.UISeq
	left outer join HQRG with (nolock) on HQRG.ReviewerGroup=isnull(APUL.ReviewerGroup,APUI.ReviewerGroup)
	left outer join HQRV with (nolock) on HQRV.Reviewer = APUR.Reviewer
	Where APUR.APCo=@apco and HQRG.ResponsiblePerson=@responsibleperson and APUR.Line <> -1 and Rejected='N' and ApprvdYN='N' and APTrans is null
end

-- Add Vendor and APRef
update @table set Vendor = Name, APRef=APUI.APRef
from @table t 
join APUI with (nolock) on APUI.APCo= t.APCo and APUI.UIMth=t.UIMth and APUI.UISeq=t.UISeq
join APVM with (nolock) on APVM.VendorGroup=APUI.VendorGroup and APVM.Vendor=APUI.Vendor
where APUI.APCo=t.APCo and APUI.UIMth=t.UIMth and APUI.UISeq=t.UISeq 
  
Select DISTINCT APCo, RevGroup,Reviewer,AppSeq,UISeq,Vendor,
		APRef,Line,'UIMth' = UIMth,
		Apprvd,'DateAppvd' = DateAppvd,AmtAppvd, Rejected,RejReason,ReviewerMemo,
		AttchID,RevEmail
From @table order by Reviewer,AppSeq		
	  
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPUnappInvStatusGridFill] TO [public]
GO
