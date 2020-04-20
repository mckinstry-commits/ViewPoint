CREATE TABLE [dbo].[bJBID]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[Line] [int] NOT NULL,
[Seq] [int] NOT NULL,
[Source] [char] (2) COLLATE Latin1_General_BIN NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[CostType] [dbo].[bJCCType] NULL,
[CostTypeCategory] [char] (1) COLLATE Latin1_General_BIN NULL,
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
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[EMCo] [dbo].[bCompany] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[Equipment] [dbo].[bEquip] NULL,
[RevCode] [dbo].[bRevCode] NULL,
[JCMonth] [dbo].[bMonth] NULL,
[JCTrans] [dbo].[bTrans] NULL,
[JCDate] [dbo].[bDate] NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[SubTotal] [numeric] (15, 5) NOT NULL,
[MarkupRate] [dbo].[bUnitCost] NOT NULL,
[MarkupAddl] [dbo].[bDollar] NOT NULL,
[MarkupTotal] [numeric] (15, 5) NOT NULL,
[Total] [dbo].[bDollar] NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TemplateSeq] [int] NULL,
[TemplateSortLevel] [tinyint] NULL,
[TemplateSeqSumOpt] [tinyint] NULL,
[TemplateSeqGroup] [int] NULL,
[DetailKey] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBID_AuditYN] DEFAULT ('Y'),
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBID_Purge] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bJBID] ADD
CONSTRAINT [CK_bJBID_AuditYN] CHECK (([AuditYN]='Y' OR [AuditYN]='N'))
ALTER TABLE [dbo].[bJBID] ADD
CONSTRAINT [CK_bJBID_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M' OR [ECM] IS NULL))
ALTER TABLE [dbo].[bJBID] ADD
CONSTRAINT [CK_bJBID_PreBillYN] CHECK (([PreBillYN]='Y' OR [PreBillYN]='N'))
ALTER TABLE [dbo].[bJBID] ADD
CONSTRAINT [CK_bJBID_Purge] CHECK (([Purge]='Y' OR [Purge]='N'))
ALTER TABLE [dbo].[bJBID] ADD
CONSTRAINT [CK_bJBID_StdECM] CHECK (([StdECM]='E' OR [StdECM]='C' OR [StdECM]='M' OR [StdECM] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btJBIDd] ON [dbo].[bJBID]
FOR DELETE AS
   
/**************************************************************
*  Created by: kb 5/15/00
*  Modified by: ALLENN 11/16/2001 Issue #13667
*  		kb 2/19/2 - issue #16147
*		TJL 11/06/02 - Issue #18740, No need to update JBIL or JBIJ when bill is purged
*		bc 05/15/03 - Issue #21279, Removed previously REM'D code only!
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 06/24/04 - Issue #24915, Increase Accuracy of JBID.SubTotal
*		TJL 08/08/08 - Issue #128962, JB International Sales Tax, Problem with update to JBIL
*
*	This trigger rejects delete of bJBID
*	 if the following error condition exists:
*		none
*
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int,
   	@co bCompany, @mth bMonth, @billnum int, @line int, @seq int,
   	@purgeyn bYN, @openJBIDcursor int,
   	@dtotal bDollar, @lrate bUnitCost, @lbasis bDollar, @lmarkupaddl bDollar
   
select @numrows = @@rowcount, @openJBIDcursor = 0

if @numrows = 0 return
set nocount on

declare bJBID_delete cursor local fast_forward for
select JBCo, BillMonth, BillNumber, Line, Seq, Purge
from deleted

open bJBID_delete
select @openJBIDcursor = 1

fetch next from bJBID_delete into @co, @mth, @billnum, @line, @seq, @purgeyn
while @@fetch_status = 0
   	begin
   	/* If purge flag is set to 'Y', three conditions may exist.
   		1) If this is a single Bill being deleted by hitting 'Delete' Key
   		   then exit immediately to skip all unnecessary updates to detail
   		   records that are also being deleted.
   		2) If this is a True Purge then multiple Bills may exist in the 
   		   'delete' queue.  Again, it is OK to exit immediately since the
   		   'delete' queue will contain ONLY Bills (Detail Tables will contain
   		   ONLY records) marked for PURGE.  Therefore there is no sense in
   		   cycling through each Bill because they are ALL marked to be Purged.
   		3) Bill Lines or Detail sequences are being resequenced.  Since all values
   		   have already been established in all related tables, there is no need
   		   to perform trigger updates.  
   
   		****NOTE**** 
   		JB is unique in that a user is allowed to delete a bill and its detail
   		from a JB Bill Header form.  There is potential for leaving detail out
   		there if a JBIN record is removed ADHOC but user insist on this capability. */
   	if @purgeyn = 'Y' 
   		begin
   		if @openJBIDcursor = 1
   			begin
   			close bJBID_delete
   			deallocate bJBID_delete
   			select @openJBIDcursor = 0
   			end
   		return
   		end
   
   	select  @dtotal = sum(isnull(d.Total,0)), @lrate = l.MarkupRate, @lmarkupaddl = l.MarkupAddl 
   	from bJBIL l with (nolock)
   	left join bJBID d with (nolock) on l.JBCo = d.JBCo and l.BillMonth = d.BillMonth and l.BillNumber = d.BillNumber
   		and l.Line = d.Line
   	where l.JBCo = @co and l.BillMonth = @mth and l.BillNumber = @billnum and l.Line = @line
   	group by l.MarkupRate, l.MarkupAddl
   
   	/* Reverse calculate Line Basis.  Due to Rounding at the JBID level as well as possible mixed
   	   MarkupRates and Addl Markups at the sequence level (Hidden Markups), Basis must be reverse 
   	   calculated inorder for the JBIL line Basis * MarkupRate = Total */
   	select @lbasis = isnull(@dtotal,0) / (1 + isnull(@lrate,0))
   
   	update bJBIL
   	set Basis = isnull(@lbasis,0), 
   		MarkupTotal = ((isnull(@dtotal,0) + isnull(@lmarkupaddl,0)) - isnull(@lbasis,0)), 
   		Total = (isnull(@dtotal,0) + isnull(@lmarkupaddl,0)),
   		AuditYN = 'N'
   	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
   
   	update bJBIL 
   	set AuditYN = 'Y'
   	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
   
	update bJBIJ 
   	set AuditYN = 'N' 
   	where JBCo = @co and BillMonth = @mth
       	and BillNumber = @billnum and Line = @line and Seq = @seq
   		
	delete bJBIJ 
   	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
   		and Line = @line and Seq = @seq
   
   	fetch next from bJBID_delete into @co, @mth, @billnum, @line, @seq, @purgeyn
   	end
   
if @openJBIDcursor = 1
   	begin
   	close bJBID_delete
   	deallocate bJBID_delete
   	select @openJBIDcursor = 0
   	end
   
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   /*
   select @co = min(JBCo) 
   from deleted d
   while @co is not null
   	begin
   	select @mth = min(BillMonth) 
   	from deleted d 
   	where JBCo = @co
    	while @mth is not null
       	begin
      		select @billnum = min(BillNumber) 
   		from deleted d 
   		where JBCo = @co and BillMonth = @mth
          	while @billnum is not null
        		begin
            	select @line = min(Line) 
   			from deleted d 
   			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
           	while @line is not null
               	begin
              		select @seq = min(Seq) 
   				from deleted d 
   				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
                	while @seq is not null
                 		begin
   					select @purgeyn = Purge
   					from deleted d
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
   						and Line = @line and Seq = @seq
   
                   	select @seq = min(Seq) 
   					from deleted d 
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
   						and Line = @line and Seq > @seq
                    	end
   
              		select @line = min(Line) 
   				from deleted d 
   				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
   					and Line > @line
                  	end
   
           	select @billnum = min(BillNumber) 
   			from deleted d 
   			where JBCo = @co and BillMonth = @mth and BillNumber > @billnum
               end
   
         	select @mth = min(BillMonth) 
   		from deleted d 
   		where JBCo = @co and BillMonth > @mth
        	end
      	select @co = min(JBCo) 
   	from deleted d 
   	where JBCo > @co
   	end
   */
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   
/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,
  	[DateTime], UserName)
Select 'bJBID',
   	'JBCo: ' + convert(varchar(3),d.JBCo) + 'BillMonth: ' + convert(varchar(8), d.BillMonth,1)
     	+ 'BillNumber: ' + convert(varchar(10),d.BillNumber)
     	+ 'Line: ' + convert(varchar(10),d.Line) + 'Seq: ' + convert(varchar(10),d.Seq),
     	d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME()
From deleted d
Join bJBCO c on c.JBCo = d.JBCo
Where c.AuditBills = 'Y' and d.AuditYN = 'Y'

return

error:
select @errmsg = @errmsg + ' - cannot delete JBID!'

if @openJBIDcursor = 1
   	begin
   	close bJBID_delete
   	deallocate bJBID_delete
   	select @openJBIDcursor = 0
   	end
   
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btJBIDi] ON [dbo].[bJBID]
FOR INSERT AS
   
/**************************************************************
*	This trigger rejects insert of bJBID
*	 if the following error condition exists:
*		none
*
*  Created by: kb 5/15/00
*  Modified by: ALLENN 11/16/2001 Issue #13667
*  		kb 2/19/2 - issue #16147
*		kb 8/5/2 - issue #18207 - changed view usage to tables
*		bc 05/15/03 - Issue #21279, Removed previously REM'D code only!
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor, suspend during Resequencing
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 06/24/04 - Issue #24915, Increase Accuracy of JBID.SubTotal
*		TJL 08/08/08 - Issue #128962, JB International Sales Tax, Problem with update to JBIL
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int, @co bCompany, 
   	@mth bMonth, @billnum int, @line int, @seq int, @openJBIDcursor int, @purgeyn bYN, 
   	@dtotal bDollar, @lrate bUnitCost, @lbasis bDollar, @lmarkupaddl bDollar
   
select @numrows = @@rowcount, @openJBIDcursor = 0

if @numrows = 0 return
set nocount on

declare bJBID_insert cursor local fast_forward for
select JBCo, BillMonth, BillNumber, Line, Seq, Purge
from inserted

open bJBID_insert
select @openJBIDcursor = 1

fetch next from bJBID_insert into @co, @mth, @billnum, @line, @seq, @purgeyn
while @@fetch_status = 0
   	begin
   	/* If purge flag is set to 'Y', one condition may exist.
   		1) Bill Lines or Detail sequences are being resequenced.  Since all values
   		   have already been established in all related tables, there is no need
   		   to perform trigger updates.  */
   	if @purgeyn = 'Y' 
   		begin
   		if @openJBIDcursor = 1
   			begin
   			close bJBID_insert
   			deallocate bJBID_insert
   			select @openJBIDcursor = 0
   			end
   		return
   		end
   
   	select  @dtotal = sum(isnull(d.Total,0)), @lrate = l.MarkupRate, @lmarkupaddl = l.MarkupAddl 
   	from bJBIL l with (nolock)
   	left join bJBID d with (nolock) on l.JBCo = d.JBCo and l.BillMonth = d.BillMonth and l.BillNumber = d.BillNumber
   		and l.Line = d.Line
   	where l.JBCo = @co and l.BillMonth = @mth and l.BillNumber = @billnum and l.Line = @line
   	group by l.MarkupRate, l.MarkupAddl

   	/* Reverse calculate Line Basis.  Due to Rounding at the JBID level as well as possible mixed
   	   MarkupRates and Addl Markups at the sequence level (Hidden Markups), Basis must be reverse 
   	   calculated inorder for the JBIL line Basis * MarkupRate = Total */
   	select @lbasis = @dtotal / (1 + @lrate)
   
   	update bJBIL
   	set Basis = @lbasis, MarkupTotal = ((@dtotal + @lmarkupaddl) - @lbasis), Total = (@dtotal + @lmarkupaddl),
   		AuditYN = 'N'
   	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
   
   	update bJBIL 
   	set AuditYN = 'Y'
   	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
   
   	fetch next from bJBID_insert into @co, @mth, @billnum, @line, @seq, @purgeyn
 
   	end
   
if @openJBIDcursor = 1
   	begin
   	close bJBID_insert
   	deallocate bJBID_insert
   	select @openJBIDcursor = 0
   	end
   
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   /*
   select @co = min(JBCo) 
   from inserted i
   while @co is not null
   	begin
    	select @mth = min(BillMonth) 
   	from inserted i 
   	where JBCo = @co
     	while @mth is not null
       	begin
        	select @billnum = min(BillNumber) 
   		from inserted i 
   		where JBCo = @co and BillMonth = @mth
         	while @billnum is not null
           	begin
             	select @line = min(Line) 
   			from inserted i 
   			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
            	while @line is not null
               	begin
                  	select @seq = min(Seq) 
   				from inserted i 
   				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
                	while @seq is not null
                   	begin
   
                    	select @seq = min(Seq) 
   					from inserted i 
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
   						and Line = @line and Seq > @seq
     					end
   
               	select @line = min(Line) 
   				from inserted i 
   				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line > @line
                	end
   
          		select @billnum = min(BillNumber) 
   			from inserted i 
   			where JBCo = @co and BillMonth = @mth and BillNumber > @billnum
               end
   
        	select @mth = min(BillMonth) 
   		from inserted i 
   		where JBCo = @co and BillMonth > @mth
        	end
   
    	select @co = min(JBCo) 
   	from inserted i 
   	where JBCo > @co
   	end
   */
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   
/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME()
From inserted i
Join bJBCO c on c.JBCo = i.JBCo
Where c.AuditBills = 'Y' and i.AuditYN = 'Y'

return

error:
select @errmsg = @errmsg + ' - cannot insert JBID!'

if @openJBIDcursor = 1
   	begin
   	close bJBID_insert
   	deallocate bJBID_insert
   	select @openJBIDcursor = 0
   	end
   
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btJBIDu] ON [dbo].[bJBID]
FOR UPDATE AS
   
/**************************************************************
*	This trigger rejects update of bJBID
*	 if the following error condition exists:
*		none
*
*  Created by: kb 5/15/00
*  Modified by: kb 6/25/01
*  		ALLENN 11/16/2001 Issue #13667
*      	kb 2/19/2 - issue #16147
*     	kb 5/1/2 - issue #17095
*		kb 8/5/2 - issue #18207 - changed view usage to tables
*		TJL 11/06/02 - Issue #18740, Exit if (Purge) Column is updated
*		TJL 01/27/03 - Issue #20090, Total Addons do not always Update when JBIL line deleted
*		RBT 08/05/03 - Issue #22019, Convert bDollar and bUnits to varchar(13) in auditing.
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 05/12/04 - Issue #24592, Corrected (where isnull(d.Factor,99.999999) <> isnull(i.Factor,99.999999)) during HQMA update
*		TJL 06/24/04 - Issue #24915, Increase Accuracy of JBID.SubTotal
*		TJL 09/29/04 - Issue #25622, Remove #JBIDTemp Table
*		TJL 08/04/08 - Issue #128962, Unrelated change.  Removed unnecessary call to "bspJBTandMUpdateSeqAddons".  Gets called in JBIL
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int,@numrows int,
   	@co bCompany, @mth bMonth, @billnum int, @line int, @seq int, 
   	@oldunits bUnits, @subtotal numeric(15,5), @markuptot numeric(15,5),
   	@linekey varchar(100), @template varchar(10),
	@tempseq int, @rcode int, @newunits bUnits, @openJBIDcursor int,
   	@dtotal bDollar, @lrate bUnitCost, @lbasis bDollar, @lmarkupaddl bDollar
   
select @numrows = @@rowcount, @openJBIDcursor = 0

if @numrows = 0 return
set nocount on

select @rcode = 0
    
/*Issue 13667*/
If Update(Purge)
	begin
	return
	end

If Update(JBCo)
	Begin
	select @errmsg = 'Cannot change JBCo'
 	GoTo error
  	End

If Update(BillMonth)
 	Begin
  	select @errmsg = 'Cannot change BillMonth'
  	GoTo error
  	End
    
If Update(BillNumber)
 	Begin
 	select @errmsg = 'Cannot change BillNumber'
 	GoTo error
 	End

If Update(Line)
 	Begin
 	select @errmsg = 'Cannot change Line'
 	GoTo error
  	End

If Update(Seq)
 	Begin
 	select @errmsg = 'Cannot change Seq'
  	GoTo error
 	End
    
if update(SubTotal) or update(MarkupTotal) or update(Units) or update(Hours)
   	begin
   	declare bJBID_insert cursor local fast_forward for
   	select JBCo, BillMonth, BillNumber, Line, Seq, SubTotal, MarkupTotal, Units
   	from inserted
   	
   	open bJBID_insert
   	select @openJBIDcursor = 1
   	
   	fetch next from bJBID_insert into @co, @mth, @billnum, @line, @seq, @subtotal, @markuptot, @newunits
   	while @@fetch_status = 0
   		begin

   		select  @dtotal = sum(isnull(d.Total,0)), @lrate = l.MarkupRate, @lmarkupaddl = l.MarkupAddl,
			 @linekey = l.LineKey, @template = l.Template, @tempseq = l.TemplateSeq 
   		from bJBIL l with (nolock)
   		left join bJBID d with (nolock) on l.JBCo = d.JBCo and l.BillMonth = d.BillMonth and l.BillNumber = d.BillNumber
   			and l.Line = d.Line
   		where l.JBCo = @co and l.BillMonth = @mth and l.BillNumber = @billnum and l.Line = @line
   		group by l.MarkupRate, l.MarkupAddl, l.LineKey, l.Template, l.TemplateSeq
   
   		/* Reverse calculate Line Basis.  Due to Rounding at the JBID level as well as possible mixed
   		   MarkupRates and Addl Markups at the sequence level (Hidden Markups), Basis must be reverse 
   		   calculated inorder for the JBIL line Basis * MarkupRate = Total */	
   		select @lbasis = @dtotal / (1 + @lrate)
   	
   		update bJBIL
   		set Basis = @lbasis, MarkupTotal = ((@dtotal + @lmarkupaddl) - @lbasis), Total = (@dtotal + @lmarkupaddl), 
   			AuditYN = 'N'
   		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
   	
   		update bJBIL 
   		set AuditYN = 'Y'
   		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
    
   		fetch next from bJBID_insert into @co, @mth, @billnum, @line, @seq, @subtotal, @markuptot, @newunits
   		end
   
   	if @openJBIDcursor = 1
   		begin
   		close bJBID_insert
   		deallocate bJBID_insert
   		select @openJBIDcursor = 0
   		end
   	end
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   /*
     	select @co = min(JBCo) 
   	from inserted i
      	while @co is not null
           begin
           select @mth = min(BillMonth) 
   		from inserted i 
   		where JBCo = @co
           while @mth is not null
               begin
               select @billnum = min(BillNumber) 
   			from inserted i 
   			where JBCo = @co and BillMonth = @mth
               while @billnum is not null
                   begin
                   select @line = min(Line) 
   				from inserted i 
   				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
                   while @line is not null
                       begin
                       select @contract = Contract, @item = Item, @linekey = LineKey,
    					 @template = Template, @tempseq = TemplateSeq
                     	from bJBIL 
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
                       select @seq = min(Seq) 
   					from inserted i 
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
                       while @seq is not null
                           begin
   				    	select @subtotal = SubTotal, @markuptot = MarkupTotal,
   				 			@newunits = Units
   				       	from inserted
   						where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line and Seq = @seq
   
   */
   -------------------------  This entire next section was REM'd prior to removing the psuedo cursor ----------------
   -------------------------  Do Not Un'Rem.  Not part of Issue #22126 ----------------------------------------------
   						/*
                           update bJBIL
                           set Basis = l.Basis + i.SubTotal - d.SubTotal,
                               MarkupTotal = l.MarkupTotal + i.MarkupTotal - d.MarkupTotal,
                               Total = l.Total + i.SubTotal + i.MarkupTotal
                               - d.SubTotal - d.MarkupTotal
                           from inserted i
                           join JBIL l on i.JBCo=l.JBCo and i.BillMonth = l.BillMonth
                           	and i.BillNumber = l.BillNumber and i.Line = l.Line
                           join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth
                           	and d.BillNumber = i.BillNumber and d.Line = i.Line
        						and d.Seq = i.Seq
                           where i.JBCo = @co and i.BillMonth = @mth
                           	and i.BillNumber = @billnum and i.Line = @line and i.Seq = @seq
    						
                           select l.Line, i.Seq 
   						from inserted i
                           join JBIL l on i.JBCo=l.JBCo and i.BillMonth = l.BillMonth
                           	and i.BillNumber = l.BillNumber and i.Line = l.Line
                           join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth
                           	and d.BillNumber = i.BillNumber and d.Line = i.Line
                           	and d.Seq = i.Seq
                           where i.JBCo = @co and i.BillMonth = @mth
       						and i.BillNumber = @billnum and i.Line = @line and i.Seq = @seq
    						*/
   
                           /*now if the item this seq is for is a 'Both' type then we
                           also need to update JBIT for units because we do not carry
                           units in JBIL*/
   						/*
                           select @jbidum = i.UM, @units = i.Units, @oldunits = d.Units
                        	from inserted i 
   						join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
                           	and d.Line = i.Line and d.Seq = i.Seq
                         	where i.JBCo = @co and i.BillMonth = @mth
                             	and i.BillNumber = @billnum and i.Line = @line and i.Seq = @seq
   
                           select @jccium = UM, @billtype = BillType
                          	from bJCCI 
   						where JCCo = @co and Contract = @contract and Item = @item
    
                           if @jbidum = @jccium and @billtype = 'B'
                           	begin
                               update bJBIT 
   							set WCUnits = WCUnits - @oldunits + @units
                            	from bJBIT 
   							where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item
                               end
       					*/
   
   ------------------------------- Above Not part of Issue #22126 -----------------------------------------------------
   /*
                           select @seq = min(Seq)
                           from inserted i
                           where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line and Seq > @seq
                           if @@rowcount = 0 select @seq = null
                           end
    
                       select @line = min(Line) from inserted i where JBCo = @co and BillMonth = @mth and
                         BillNumber = @billnum and Line > @line
                       if @@rowcount = 0 select @seq = null
                       end
    
                 select @billnum = min(BillNumber) from inserted i where JBCo = @co and BillMonth = @mth
                   and BillNumber > @billnum
                 if @@rowcount = 0 select @billnum = null
                 end
    
               select @mth = min(BillMonth) from inserted i where JBCo = @co and BillMonth > @mth
               if @@rowcount = 0 select @mth = null
               end
            select @co = min(JBCo) from inserted i where JBCo > @co
            if @@rowcount = 0 select @co = null
            end
        end
   */
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   
   /*Issue 13667*/
   If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where c.AuditBills = 'Y')
     BEGIN
     If Update(Source)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Source', d.Source, i.Source, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Source,'') <> isnull(i.Source,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(PhaseGroup)
   
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'PhaseGroup', convert(varchar(3), d.PhaseGroup), convert(varchar(3), i.PhaseGroup), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.PhaseGroup,0) <> isnull(i.PhaseGroup,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(CostType)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'CostType', convert(varchar(3), d.CostType), convert(varchar(3), i.CostType), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.CostType,0) <> isnull(i.CostType,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(CostTypeCategory)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'CostTypeCategory', d.CostTypeCategory, i.CostTypeCategory, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.CostTypeCategory,'') <> isnull(i.CostTypeCategory,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(PRCo)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'PRCo', convert(varchar(3), d.PRCo), convert(varchar(3), i.PRCo), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.PRCo,0) <> isnull(i.PRCo,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Employee)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Employee', convert(varchar(10), d.Employee), convert(varchar(10), i.Employee), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Employee,'') <> isnull(i.Employee,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(EarnType)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'EarnType', convert(varchar(5), d.EarnType), convert(varchar(5), i.EarnType), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.EarnType,-32768) <> isnull(i.EarnType,-32768)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Craft)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Craft', d.Craft, i.Craft, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Craft,'') <> isnull(i.Craft,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Class)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Class', d.Class, i.Class, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Class,'') <> isnull(i.Class,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Factor)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Factor', convert(varchar(9), d.Factor), convert(varchar(9), i.Factor), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Factor,99.999999) <> isnull(i.Factor,99.999999)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Shift)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Shift', convert(varchar(3), d.Shift), convert(varchar(3), i.Shift), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Shift,0) <> isnull(i.Shift,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(LiabilityType)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'LiabilityType', convert(varchar(5), d.LiabilityType), convert(varchar(5), i.LiabilityType), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.LiabilityType,-32768) <> isnull(i.LiabilityType,-32768)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
   
     If Update(APCo)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'APCo', convert(varchar(3), d.APCo), convert(varchar(3), i.APCo), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.APCo,0) <> isnull(i.APCo,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(VendorGroup)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'VendorGroup', convert(varchar(3), d.VendorGroup), convert(varchar(3), i.VendorGroup), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.VendorGroup,0) <> isnull(i.VendorGroup,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Vendor)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Vendor', convert(varchar(10), d.Vendor), convert(varchar(10), i.Vendor), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Vendor,-2147483648) <> isnull(i.Vendor,-2147483648)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(APRef)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'APRef', d.APRef, i.APRef, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.APRef,'') <> isnull(i.APRef,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(PreBillYN)
          Begin
      	   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'PreBillYN', d.PreBillYN, i.PreBillYN, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where d.PreBillYN <> i.PreBillYN
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(INCo)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'INCo', convert(varchar(3), d.INCo), convert(varchar(3), i.INCo), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.INCo,0) <> isnull(i.INCo,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(MatlGroup)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'MatlGroup', convert(varchar(3), d.MatlGroup), convert(varchar(3), i.MatlGroup), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.MatlGroup,0) <> isnull(i.MatlGroup,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Material)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Material', d.Material, i.Material, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Material,'') <> isnull(i.Material,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Location)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Location', d.Location, i.Location, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Location,'') <> isnull(i.Location,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(MSTicket)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'MSTicket', d.MSTicket, i.MSTicket, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.MSTicket,'') <> isnull(i.MSTicket,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(StdUM)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'StdUM', d.StdUM, i.StdUM, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.StdUM,'') <> isnull(i.StdUM,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(StdPrice)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'StdPrice', convert(varchar(17), d.StdPrice), convert(varchar(17), i.StdPrice), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where d.StdPrice <> i.StdPrice
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(StdECM)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'StdECM', d.StdECM, i.StdECM, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.StdECM,'') <> isnull(i.StdECM,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(SL)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'SL', d.SL, i.SL, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.SL,'') <> isnull(i.SL,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(SLItem)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'SLItem', convert(varchar(5), d.SLItem), convert(varchar(5), i.SLItem), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.SLItem,'') <> isnull(i.SLItem,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(PO)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'PO', d.PO, i.PO, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.PO,'') <> isnull(i.PO,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(POItem)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'POItem', convert(varchar(5), d.POItem), convert(varchar(5), i.POItem), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.POItem,-32768) <> isnull(i.POItem,-32768)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(EMCo)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'EMCo', convert(varchar(3), d.EMCo), convert(varchar(3), i.EMCo), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.EMCo,0) <> isnull(i.EMCo,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(EMGroup)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'EMGroup', convert(varchar(3), d.EMGroup), convert(varchar(3), i.EMGroup), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.EMGroup,0) <> isnull(i.EMGroup,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Equipment)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Equipment', d.Equipment, i.Equipment, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Equipment,'') <> isnull(i.Equipment,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(RevCode)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'RevCode', d.RevCode, i.RevCode, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.RevCode,'') <> isnull(i.RevCode,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(JCMonth)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'JCMonth', convert(varchar(8), d.JCMonth, 1), convert(varchar(8), i.JCMonth, 1), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.JCMonth,'') <> isnull(i.JCMonth,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(JCTrans)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'JCTrans', convert(varchar(10), d.JCTrans), convert(varchar(10), i.JCTrans), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.JCTrans,-2147483648) <> isnull(i.JCTrans,-2147483648)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(JCDate)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'JCDate', convert(varchar(8), d.JCDate,1), convert(varchar(8), i.JCDate,1), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.JCDate,'') <> isnull(i.JCDate,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Category)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Category', d.Category, i.Category, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Category,'') <> isnull(i.Category,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Description)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Description,'') <> isnull(i.Description,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(UM)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
    	   Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.UM,'') <> isnull(i.UM,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Units)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Units', convert(varchar(13), d.Units), convert(varchar(13), i.Units), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where d.Units <> i.Units
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(UnitPrice)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'UnitPrice', convert(varchar(17), d.UnitPrice), convert(varchar(17), i.UnitPrice), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where d.UnitPrice <> i.UnitPrice
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(ECM)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'ECM', d.ECM, i.ECM, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.ECM,'') <> isnull(i.ECM,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Hours)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Hours', convert(varchar(11), d.Hours), convert(varchar(11), i.Hours), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where d.Hours <> i.Hours
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(SubTotal)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'SubTotal', convert(varchar(16), d.SubTotal), convert(varchar(16), i.SubTotal), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where d.SubTotal <> i.SubTotal
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(MarkupRate)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'MarkupRate', convert(varchar(17), d.MarkupRate), convert(varchar(17), i.MarkupRate), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where d.MarkupRate <> i.MarkupRate
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(MarkupAddl)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'MarkupAddl', convert(varchar(13), d.MarkupAddl), convert(varchar(13), i.MarkupAddl), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where d.MarkupAddl <> i.MarkupAddl
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(MarkupTotal)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'MarkupTotal', convert(varchar(16), d.MarkupTotal), convert(varchar(16), i.MarkupTotal), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where d.MarkupTotal <> i.MarkupTotal
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Total)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Total', convert(varchar(13), d.Total), convert(varchar(13), i.Total), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where d.Total <> i.Total
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(Template)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'Template', d.Template, i.Template, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
        Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.Template,'') <> isnull(i.Template,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(TemplateSeq)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'TemplateSeq', convert(varchar(10), d.TemplateSeq), convert(varchar(10), i.TemplateSeq), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.TemplateSeq,-2147483648) <> isnull(i.TemplateSeq,-2147483648)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(TemplateSortLevel)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'TemplateSortLevel', convert(varchar(3), d.TemplateSortLevel), convert(varchar(3), i.TemplateSortLevel), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.TemplateSortLevel,0) <> isnull(i.TemplateSortLevel,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(TemplateSeqSumOpt)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'TemplateSeqSumOpt', convert(varchar(3), d.TemplateSeqSumOpt), convert(varchar(3), i.TemplateSeqSumOpt), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.TemplateSeqSumOpt,0) <> isnull(i.TemplateSeqSumOpt,0)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(TemplateSeqGroup)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'TemplateSeqGroup', convert(varchar(10), d.TemplateSeqGroup), convert(varchar(10), i.TemplateSeqGroup), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.TemplateSeqGroup,-2147483648) <> isnull(i.TemplateSeqGroup,-2147483648)
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
    
     If Update(DetailKey)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line) + 'Seq: ' + convert(varchar(10),i.Seq),i.JBCo, 'C', 'DetailKey', d.DetailKey, i.DetailKey, getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
          Where isnull(d.DetailKey,'') <> isnull(i.DetailKey,'')
          and c.AuditBills = 'Y' and i.AuditYN = 'Y'
          End
     END
    
   return
    
   error:
   select @errmsg = @errmsg + ' - cannot update JBID!'
    
   if @openJBIDcursor = 1
   	begin
   	close bJBID_insert
   	deallocate bJBID_insert
   	select @openJBIDcursor = 0
   	end
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* Custom trigger to capture when JBID.Notes are being erased */
CREATE               trigger [dbo].[utJBIDu] on [dbo].[bJBID] 
  for UPDATE 
as

declare @errmsg varchar(255)

	if update(Notes)
          Begin
          Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
          Select 'bJBID', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), 
			i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + 
			convert(varchar(10),i.Line) + 'Seq: ' + 
			convert(varchar(10),i.Seq),i.JBCo, 'C', 'Notes', 
			convert(varchar(10), 'Unknown'), 
			convert(varchar(10), 'Unknown'), getdate(), SUSER_SNAME()
          From inserted i
          Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line and d.Seq = i.Seq
          Join bJBCO c on c.JBCo = i.JBCo
    End

 return
  error:
  select @errmsg = isnull(@errmsg,'') + ' - custom VP Support Trigger utJCIDu'
             RAISERROR(@errmsg, 11, -1);
             rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biJBID] ON [dbo].[bJBID] ([JBCo], [BillMonth], [BillNumber], [Line], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBID] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBID].[PreBillYN]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJBID].[StdECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bJBID].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBID].[AuditYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBID].[Purge]'
GO
