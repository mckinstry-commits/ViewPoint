SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBSeqResequence    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBSeqResequence]
/***********************************************************
* CREATED BY	: bc 08/16/00
* MODIFIED BY	: bc 10/02/01 - Redimensioned Employee to int
* 		kb 2/19/2 - issue #16147
*		TJL 09/13/02 - Issue #18557, Repair Resequencing of Line Sequences.
*		TJL 10/16/02 - Issue #19025, Increase APRef col to 15 Char on #DetailReseq temp table
*		TJL 08/08/03 - Issue #22010, Correct APRef problem, other improvements
*		TJL 09/15/03 - Issue #22126, Improved performance when resequencing, suspend triggers
*		TJL 07/09/07 - Issue #124993, (5x Issue #124752) Description column for Table Variables must match the associated table.
*		TJL 01/29/09 - Issue #132365, Customer looses JBID Notes.
*		DC 6/29/10 - #135813 - expand subcontract number
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*
* USAGE:  when this bsp is run, the sequences should already be in the correct order.
*         the funtcion of this code is to create space inbetween existing sequences by increments of 10
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/   
(@co bCompany, @billmth bMonth, @billnum int, @line int, @msg varchar(255) output)
as

set nocount on

declare @rcode int, @sortorder char(1), @oldseq int, @newseq int, @seqcnt int, @seqcnt2 int

select @rcode = 0, @newseq = 0

select @seqcnt = count(1)
from JBID with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   
/* Suspend triggers during resequence process.  Since values in these and related tables already exist
  and this process only changes Sequence numbering without changing original values in any table, we can
  simply re-insert the values into the respective tables without the time consuming updates to 
  related tables.  No Auditing will occur. (Same as when a bill gets deleted.) */
update bJBID
set Purge = 'Y', AuditYN = 'N'
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line

update bJBIJ
set Purge = 'Y', AuditYN = 'N'
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   
--create table #DetailReseq
declare @DetailReseq table
([NewSeq] [int] NOT NULL,
	[Source] [char](2) NULL,
	[PhaseGroup] [dbo].[bGroup] NULL,
	[CostType] [dbo].[bJCCType] NULL,
	[CostTypeCategory] [char](1) NULL,
	[PRCo] [dbo].[bCompany] NULL,
	[Employee] [dbo].[bEmployee] NULL,
	[EarnType] [dbo].[bEarnType] NULL,
	[Craft] [dbo].[bCraft] NULL,
	[Class] [dbo].[bClass] NULL,
	[Factor] [dbo].[bRate] NULL,
	[Shift] [tinyint] NULL,
	[LiabilityType] [dbo].[bLiabilityType] NULL,
	[APCo] [dbo].[bCompany] NULL,
	[VendorGroup] [dbo].[bGroup] NULL,
	[Vendor] [dbo].[bVendor] NULL,
	[APRef] [dbo].[bAPReference] NULL,
	[PreBillYN] [dbo].[bYN] NOT NULL,
	[INCo] [dbo].[bCompany] NULL,
	[MatlGroup] [dbo].[bGroup] NULL,
	[Material] [dbo].[bMatl] NULL,
	[Location] [dbo].[bLoc] NULL,
	[MSTicket] [dbo].[bTic] NULL,
	[StdUM] [dbo].[bUM] NULL,
	[StdPrice] [dbo].[bUnitCost] NOT NULL,
	[StdECM] [dbo].[bECM] NULL,
	[SL] [varchar](30) NULL,  --[dbo].[bSL] NULL,  --DC #135813
	[SLItem] [dbo].[bItem] NULL,
	[PO] [varchar](30) NULL,
	[POItem] [dbo].[bItem] NULL,
	[EMCo] [dbo].[bCompany] NULL,
	[EMGroup] [dbo].[bGroup] NULL,
	[Equipment] [dbo].[bEquip] NULL,
	[RevCode] [dbo].[bRevCode] NULL,
	[JCMonth] [dbo].[bMonth] NULL,
	[JCTrans] [dbo].[bTrans] NULL,
	[JCDate] [dbo].[bDate] NULL,
	[Category] [varchar](10) NULL,
	[Description] [dbo].[bItemDesc] NULL,
	[UM] [dbo].[bUM] NULL,
	[Units] [dbo].[bUnits] NOT NULL,
	[UnitPrice] [dbo].[bUnitCost] NOT NULL,
	[ECM] [dbo].[bECM] NULL,
	[Hours] [dbo].[bHrs] NOT NULL,
	[SubTotal] [numeric](15, 5) NOT NULL,
	[MarkupRate] [dbo].[bUnitCost] NOT NULL,
	[MarkupAddl] [dbo].[bDollar] NOT NULL,
	[MarkupTotal] [numeric](15, 5) NOT NULL,
	[Total] [dbo].[bDollar] NOT NULL,
	[Template] [varchar](10) NULL,
	[TemplateSeq] [int] NULL,
	[TemplateSortLevel] [tinyint] NULL,
	[TemplateSeqSumOpt] [tinyint] NULL,
	[TemplateSeqGroup] [int] NULL,
	[DetailKey] [varchar](500) NULL,
	[Notes] [varchar](8000) NULL,
	[UniqueAttchID] [uniqueidentifier] NULL,
	[AuditYN] [dbo].[bYN] NOT NULL,
	[Purge] [dbo].[bYN] NOT NULL
)
--CREATE UNIQUE CLUSTERED INDEX  btiTempDetail ON #DetailReseq(NewSeq)	--REM'D ISSUE #22010
   
--create table #JBIJReseq
declare @JBIJReseq table
([NewSeq] [int] NOT NULL,
	[JCMonth] [dbo].[bMonth] NOT NULL,
	[JCTrans] [dbo].[bTrans] NOT NULL,
	[BillStatus] [char](1) NULL,
	[Hours] [dbo].[bHrs] NOT NULL DEFAULT ((0)),
	[Units] [dbo].[bUnits] NOT NULL DEFAULT ((0)),
	[Amt] [numeric](15, 5) NOT NULL DEFAULT ((0)),
	[AuditYN] [dbo].[bYN] NOT NULL DEFAULT ('Y'),
	[Purge] [dbo].[bYN] NOT NULL DEFAULT ('N'),
	[UnitPrice] [dbo].[bUnitCost] NOT NULL DEFAULT ((0)),
	[UniqueAttchID] [uniqueidentifier] NULL,
	[UM] [dbo].[bUM] NULL,
	[EMGroup] [dbo].[bGroup] NULL,
	[EMRevCode] [dbo].[bRevCode] NULL
)
--CREATE UNIQUE CLUSTERED INDEX  btiTempJBIJ ON #JBIJReseq(NewSeq,JCMonth,JCTrans)	--REM'D ISSUE #22010
   
/* Place Current table data in Table variable with New Sequence Number */
select @oldseq = min(Seq)
from bJBID with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
while @oldseq is not null
	begin
	select @newseq = isnull(@newseq,0)+10

	insert @DetailReseq
	select @newseq,Source,PhaseGroup,CostType,CostTypeCategory,PRCo,Employee,EarnType,Craft,Class,Factor,Shift,
		   LiabilityType,APCo,VendorGroup,Vendor,APRef,PreBillYN,INCo,MatlGroup,Material,Location,MSTicket,
		   StdUM,StdPrice,StdECM,SL,SLItem,PO,POItem,EMCo,EMGroup,Equipment,RevCode,
		   JCMonth,JCTrans,JCDate,Category,[Description],UM,Units,UnitPrice,ECM,Hours,SubTotal,
		   MarkupRate,MarkupAddl,MarkupTotal,Total,Template,TemplateSeq,TemplateSortLevel,TemplateSeqSumOpt,TemplateSeqGroup,
		   DetailKey,Notes,UniqueAttchID,AuditYN,Purge
	from bJBID with (nolock)
	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line and Seq = @oldseq

	insert @JBIJReseq
	select @newseq,JCMonth,JCTrans,BillStatus,Hours,Units,Amt,AuditYN,Purge,UnitPrice,UniqueAttchID,UM,EMGroup,EMRevCode
	from bJBIJ with (nolock)
	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line and Seq = @oldseq

	select @oldseq = min(Seq)
	from bJBID with (nolock)
	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line and Seq > @oldseq
	if @@rowcount = 0 select @oldseq = null
	end
   
select @seqcnt2 = count(1)
from @DetailReseq

if @seqcnt <> @seqcnt2
begin
select @msg = 'Error inserting detail into temporary table for processing.', @rcode = 1
goto bspexit
end

begin transaction

/* Clear out Tables.  Triggers have been suspended. */
delete bJBID where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
delete bJBIJ where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   
/* Insert from Table variables into Tables with New Sequence Numbering.  Triggers have been suspended. */
select @newseq = null
select @newseq = min(NewSeq)
from @DetailReseq
while @newseq is not null
	begin
	insert into bJBIJ (JBCo,BillMonth,BillNumber,Line,Seq,JCMonth,JCTrans,BillStatus,Hours,Units,Amt,AuditYN,Purge,UnitPrice,
		UniqueAttchID,UM,EMGroup,EMRevCode)
	select @co,@billmth,@billnum,@line,NewSeq,JCMonth,JCTrans,BillStatus,Hours,Units,Amt,AuditYN,Purge,UnitPrice,
		UniqueAttchID,UM,EMGroup,EMRevCode
	from @JBIJReseq
	where NewSeq = @newseq

	insert into bJBID (JBCo,BillMonth,BillNumber,Line,Seq,Source,PhaseGroup,CostType,CostTypeCategory,PRCo,Employee,EarnType,Craft,Class,Factor,Shift,
		   LiabilityType,APCo,VendorGroup,Vendor,APRef,PreBillYN,INCo,MatlGroup,Material,Location,MSTicket,
		   StdUM,StdPrice,StdECM,SL,SLItem,PO,POItem,EMCo,EMGroup,Equipment,RevCode,
		   JCMonth,JCTrans,JCDate,Category,[Description],UM,Units,UnitPrice,ECM,Hours,SubTotal,
		   MarkupRate,MarkupAddl,MarkupTotal,Total,Template,TemplateSeq,TemplateSortLevel,TemplateSeqSumOpt,TemplateSeqGroup,
		   DetailKey,Notes,UniqueAttchID,AuditYN,Purge)
	select @co,@billmth,@billnum,@line,NewSeq,Source,PhaseGroup,CostType,CostTypeCategory,PRCo,Employee,EarnType,Craft,Class,Factor,Shift,
		   LiabilityType,APCo,VendorGroup,Vendor,APRef,PreBillYN,INCo,MatlGroup,Material,Location,MSTicket,
		   StdUM,StdPrice,StdECM,SL,SLItem,PO,POItem,EMCo,EMGroup,Equipment,RevCode,
		   JCMonth,JCTrans,JCDate,Category,[Description],UM,Units,UnitPrice,ECM,Hours,SubTotal,
		   MarkupRate,MarkupAddl,MarkupTotal,Total,Template,TemplateSeq,TemplateSortLevel,TemplateSeqSumOpt,TemplateSeqGroup,
		   DetailKey,Notes,UniqueAttchID,AuditYN,Purge
	from @DetailReseq
	where NewSeq = @newseq

	select @newseq = min(NewSeq)
	from @DetailReseq
	where NewSeq > @newseq

	end
   
if (select count(1) from JBID with (nolock) where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line) <> @seqcnt2
	begin
	select @msg = 'Error inserting resequenced rows back into JBID', @rcode = 1
	goto error
	end

commit transaction
goto bspexit

error:
rollback transaction
goto bspexit

bspexit:
/* Reset flags, basically to re-enable triggers. */
update bJBID
set Purge = 'N', AuditYN = 'N'
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line

update bJBIJ
set Purge = 'N', AuditYN = 'N'
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line

return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBSeqResequence] TO [public]
GO
