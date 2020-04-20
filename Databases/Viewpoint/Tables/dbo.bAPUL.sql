CREATE TABLE [dbo].[bAPUL]
(
[APCo] [dbo].[bCompany] NOT NULL,
[Line] [smallint] NOT NULL,
[UIMth] [dbo].[bMonth] NOT NULL,
[UISeq] [smallint] NOT NULL,
[LineType] [tinyint] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POItem] [dbo].[bItem] NULL,
[ItemType] [tinyint] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[JCCType] [dbo].[bJCCType] NULL,
[EMCo] [dbo].[bCompany] NULL,
[WO] [dbo].[bWO] NULL,
[WOItem] [dbo].[bItem] NULL,
[Equip] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[Description] [dbo].[bDesc] NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Supplier] [dbo].[bVendor] NULL,
[PayType] [tinyint] NULL,
[GrossAmt] [dbo].[bDollar] NOT NULL,
[MiscAmt] [dbo].[bDollar] NOT NULL,
[MiscYN] [dbo].[bYN] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL,
[Retainage] [dbo].[bDollar] NOT NULL,
[Discount] [dbo].[bDollar] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PayCategory] [int] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ReviewerGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[InvOriginator] [dbo].[bVPUserName] NULL,
[SLDetailKeyID] [bigint] NULL,
[Receiver#] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SLKeyID] [bigint] NULL,
[SMCo] [dbo].[bCompany] NULL,
[SMWorkOrder] [int] NULL,
[Scope] [int] NULL,
[POItemLine] [int] NULL,
[SMCostType] [smallint] NULL,
[SMJCCostType] [dbo].[bJCCType] NULL,
[SMPhaseGroup] [dbo].[bGroup] NULL,
[SMPhase] [dbo].[bPhase] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biAPUL] ON [dbo].[bAPUL] ([APCo], [UIMth], [UISeq], [Line]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPUL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_bAPUL_SLDetailKeyID] ON [dbo].[bAPUL] ([SLDetailKeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_bAPUL_SLKeyID] ON [dbo].[bAPUL] ([SLKeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE     trigger [dbo].[btAPULd] on [dbo].[bAPUL] for Delete as
   

/*-----------------------------------------------------------------
* Created:  EN 11/2/98
* Modified: EN 11/2/98 
*           TV 02/27/02 Reviewer Delete
*           TV 06/20/02 Redo Delete
*			 GG 06/21/02 - cleanup, fix join to bAPUR
*			 GF 08/11/2003 - issue #22112 - performance
*			 MV 03/23/04 - #23833 audit deletes
*			 MV 02/13/09 - #123778 - clear PORD invoice info
*			CHS	08/08/2011	- B-05526
*
* Delete trigger for AP Unapproved Invoice Lines.
*
*/----------------------------------------------------------------
    
   declare @errmsg varchar(255), @numrows int, @apmth bMonth, @aptrans int,
   	@apco int, @uimth bMonth, @uiseq int, @line int, @key varchar (60),
   	@cursoropen int
   
   select @numrows = @@rowcount, @cursoropen = 0
   if @numrows = 0 return
   
   set nocount on
    
   -- remove Reviewers associated with deleted line(s)
   delete bAPUR 
   from deleted d
   join bAPUR r with (nolock) on r.APCo = d.APCo and r.UIMth = d.UIMth and r.UISeq = d.UISeq and r.Line = d.Line 
   where r.APTrans is null and r.ExpMonth is null 

	-- clear bPORD Unapproved invoice info if APUL was not posted
	if (exists(select 1 from bAPUR r with (nolock) join deleted d on r.APCo=d.APCo and r.UIMth=d.UIMth and r.UISeq=d.UISeq
		and r.Line=d.Line where r.APTrans is null and r.ExpMonth is null))
	or
		(not exists(select 1 from bAPUR r with (nolock) join deleted d on r.APCo=d.APCo and r.UIMth=d.UIMth and r.UISeq=d.UISeq
		and r.Line=d.Line))
	begin
		if exists (select 1 from dbo.bPORD r join deleted d on r.POCo=d.APCo 
		and r.PO=d.PO and r.POItem=d.POItem and r.POItemLine=d.POItemLine AND (r.Receiver# is not null and r.Receiver#=d.Receiver#)
		where r.UIMth=d.UIMth and r.UISeq=d.UISeq and r.UILine=d.Line)
		begin
		update bPORD set UIMth= null, UISeq=null, UILine=null
			from bPORD r join deleted d on r.POCo=d.APCo and r.PO=d.PO
			and r.POItem=d.POItem and r.POItemLine=d.POItemLine and r.Receiver#=d.Receiver#
			where r.UIMth=d.UIMth and r.UISeq=d.UISeq and r.UILine=d.Line
		end
	end

   /* Audit delete */
   if exists (select 1 from bAPCO c with (nolock)join deleted d on c.APCo=d.APCo where AuditUnappInv = 'Y')
   	begin
   	if @numrows = 1
   		begin
   			select @apco=APCo, @uimth = UIMth, @uiseq= UISeq, @line=Line from deleted
   			select @apmth=Mth, @aptrans=APTrans from bAPHB h with (nolock)
   			 join deleted d on h.Co=d.APCo and h.UIMth=d.UIMth and h.UISeq=d.UISeq 
   			if @@rowcount = 1
   				begin
   				select @key = ' APMth: ' + convert(char(8), @apmth,1) +
   					 ' APTrans: ' + convert(varchar(10), @aptrans)
   				end
   			else select @key=''
   		end
   	else
   		begin
   		-- use a cursor to build a key all lines
   		declare bcAPUL_update cursor for
   		select APCo, UIMth, UISeq, Line
   		from deleted 
   	
   		open bcAPUL_update
   		select @cursoropen = 1
   
   		fetch next from bcAPUL_update into @apco, @uimth, @uiseq, @line
   		if @@fetch_status <> 0 
   			begin
   			select @errmsg = 'Cursor error'
   			close bcAPUL_update
   	 		deallocate bcAPUL_update
   			select @cursoropen = 0
   			goto error
   			end
   audit_insert:		
   		select @apmth=Mth, @aptrans=APTrans from bAPHB with (nolock)
   		 	where Co=@apco and UIMth=@uimth and UISeq=@uiseq
   		if @@rowcount = 1
   			begin
   			select @key = ' APMth: ' + convert(char(8), @apmth,1) + ' APTrans: ' + convert(varchar(10), @aptrans)
   			end
   		else select @key=''
   		end
   	-- add deleted line to audit table
   	insert into bHQMA select 'bAPUL', 'UIMth: ' + convert(char(8), UIMth,1) 
   		+ ' UISeq: ' + convert(varchar(10), UISeq)
   		+ ' Line: ' + convert (varchar(10), Line)+ isnull(@key,''),
   		APCo, 'D',NULL, NULL, NULL, getdate(), SUSER_SNAME() from deleted 
   			where APCo=@apco and UIMth=@uimth and UISeq=@uiseq and Line=@line
   	-- get next line 
   	if @numrows > 1
   	 	begin
   	 	fetch next from bcAPUL_update into @apco, @uimth, @uiseq, @line
   	 	if @@fetch_status = 0
   	 		goto audit_insert
   		else
   			begin
   	 		close bcAPUL_update
   	 		deallocate bcAPUL_update
   			select @cursoropen = 0
   			end
   		end
   	end
   
   return
    
   error:
   	if @cursoropen= 1
   		begin
    		close bcAPUL_update
    		deallocate bcAPUL_update
   		end
   	select @errmsg = isnull(@errmsg, '') + ' - cannot delete Unapproved Invoice Line(s)!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btAPULi    Script Date: 8/28/99 9:36:59 AM ******/
   CREATE           trigger [dbo].[btAPULi] on [dbo].[bAPUL] for INSERT as
   

/*-----------------------------------------------------------------
*  Created: EN 11/2/98
*  Modified: EN 11/2/98
*            TV 1/15/02 - Moving reviewer to line.
*			GG 06/21/02 - cleanup, handle multiple rows
*            TV 11/21/02-Rewrote Cursor
*			MV 03/23/04 - #23833 audit inserts
*			MV 02/10/05 - #26977 pass INCo and Loc to reviewer sp
*			MV 05/09/07 - #27747 insert header reviewers (-1)
*			MV 02/12/08 - #29702 - insert reviewer group reviewers
*           MV 06/23/08 - #128715 - threshold reviewers
*			MV 02/09/09 - #123778 - update bPORD with unapproved inv info
*			GF 10/25/2010 - issue #141031
*			CHS	08/08/2011	- B-05526
*			MV 01/15/2013 - D-05483/TK-20779 replaced vfDateOnly with getdate for DateAssigned in APUR insert. Notifier query needs hours/minutes.
*
* Insert trigger for AP Unapproved Invoice Lines
*
*/----------------------------------------------------------------
   
   
	declare @errmsg varchar(255), @validcnt int, @numrows int, @apco bCompany, @uimth bMonth,
	@uiseq int, @line int, @jcco bCompany, @job bJob, @emco bCompany, @equip bEquip,
	@vendorgroup bGroup,@vendor bVendor, @linetype tinyint, @inco bCompany, @loc bLoc,
	@insertcursor tinyint, @reviewergroup varchar(10), @amount bDollar, @receiver# varchar(20)

	SELECT @numrows = Count(*)from Inserted
	IF @numrows = 0 return

	SET nocount on

	select @insertcursor = 0

	/* check Unapproved Invoice Header */
	SELECT @validcnt = count(*) FROM dbo.bAPUI h (nolock)
	JOIN inserted i ON h.APCo = i.APCo and h.UIMth = i.UIMth
	and h.UISeq = i.UISeq

	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Unapproved Invoice Header does not exist'
		GOTO error
	END

	-- add bAPUR Header Reviewers (-1) to inserted Lines
	if exists(select top 1 1 from dbo.bAPUR r (nolock) JOIN inserted i ON r.APCo = i.APCo and r.UIMth = i.UIMth
		and r.UISeq = i.UISeq where r.Line = -1)
	begin
		insert bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Memo, Line, ApprovalSeq, DateAssigned,
		DateApproved, AmountApproved, Rejected, RejReason, APTrans, ExpMonth, ReviewerGroup)
		select i.APCo, i.UIMth, i.UISeq, r.Reviewer, 'N', r.Memo, i.Line, r.ApprovalSeq,
		getdate(),
		r.DateApproved, r.AmountApproved, 'N', r.RejReason, r.APTrans, r.ExpMonth,r.ReviewerGroup
		from bAPUR r join inserted i 
		on r.APCo = i.APCo and r.UIMth = i.UIMth and r.UISeq = i.UISeq  
		where r.Line = -1 and r.APTrans is null and r.ExpMonth is null and 
		not exists (select 1 from bAPUR r2 join inserted i2 on i2.APCo=r2.APCo and i2.UIMth=r2.UIMth 
			and i2.UISeq=r2.UISeq and i2.Line=r2.Line 
			where i.APCo = i2.APCo and i.UIMth = i2.UIMth and i.UISeq = i2.UISeq and
			i.Line = i2.Line and r2.Reviewer = r.Reviewer and  /*r.ApprovalSeq = r2.ApprovalSeq and */
			r.APTrans is null and r.ExpMonth is null)
	end 
   
   -- add Job/Loc/Equip/Vendor/ReviewerGroup reviewers to inserted Lines 
	declare bcAPUL_insert cursor local fast_forward for
		select i.APCo, i.UIMth, i.UISeq, i.Line, i.LineType, i.JCCo, i.Job, i.EMCo, i.Equip,
		u.VendorGroup, u.Vendor, i.INCo, i.Loc, i.ReviewerGroup,i.GrossAmt, i.Receiver#
		from inserted i join dbo.bAPUI u (nolock) on i.APCo = u.APCo and i.UIMth = u.UIMth and i.UISeq = u.UISeq

		open bcAPUL_insert

		select @insertcursor = 1
   
reviewer_insert:

	fetch next from bcAPUL_insert into @apco, @uimth, @uiseq, @line, @linetype, @jcco, @job,
	@emco, @equip, @vendorgroup, @vendor, @inco, @loc, @reviewergroup, @amount,@receiver#

	if @@fetch_status <> 0
	begin
		goto bspexit
	end	

   -- add Job/Loc/Equip/Vendor Reviewers to bAPUR for this Line
	exec bspAPUNApprovedReviewerGet @apco, @uimth, @uiseq, @line, @linetype, @jcco, @job, @emco, @equip,
		@vendorgroup, @vendor, @inco, @loc

	-- add Reviewer Group Reviewers to bAPUR for this line
	if @reviewergroup is not null --128715 
	begin
	exec vspAPURUpdateReviewerGroup @apco, @uimth, @uiseq, @line,@reviewergroup, @amount, @errmsg
	end
	
     -- add threshold Reviewers to bAPUR for this line
	exec vspAPUnappThresholdReviewers @apco, @uimth, @uiseq, @line

	-- update bPORD with Unapproved invoice info
	if @receiver# is not null
		begin
		update bPORD set UIMth=i.UIMth, UISeq=i.UISeq, UILine=i.Line
		from bPORD r join inserted i on r.POCo=i.APCo and r.PO=i.PO and r.POItem=i.POItem and r.POItemLine=i.POItemLine and r.Receiver#=@receiver#
		end

	goto reviewer_insert
   
bspexit:	

	if @insertcursor = 1
	begin
		close bcAPUL_insert
		deallocate bcAPUL_insert
	end
   
	/* Audit inserts */
	insert into bHQMA select 'bAPUL', 'UIMth: ' + convert(char(8), i.UIMth,1) 
	+ ' UISeq: ' + convert(varchar(10), i.UISeq)
	+ ' Line: ' + convert (varchar(10), i.Line),
	i.APCo, 'A',NULL, NULL, NULL, getdate(), SUSER_SNAME()
	from inserted i
	join APCO a on a.APCo = i.APCo
	where a.AuditUnappInv = 'Y'		
   
   return
   
error:

	if @insertcursor = 1
	begin
		close bcAPUL_insert
		deallocate bcAPUL_insert
	end
   
	SELECT @errmsg = @errmsg +  ' - cannot insert AP Unapproved Invoice Line!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE         trigger [dbo].[btAPULu] on [dbo].[bAPUL] for UPDATE as
   

/*-----------------------------------------------------------------
*  Created: EN 11/2/98
*  Modified: EN 11/2/98 
*            TV 05/09/02 Added reviewer check  
*			GG 06/21/02 - cleanup, fixed call to add reviewers 
*			MV 03/23/04 - #23833 - audit changes
*			MV 06/08/04 - #24730 - increased Varchar size of Units, Unitcost, GrossAmt in auditing
*			MV 12/01/07 - #29702 - add ReviewerGroup to Audit
*			MV 02/12/08 - #29702 - add/delete reviewers when data changes
*           MV 06/23/08 - #128715 - add threshold reviewers when amount changes
*			MV 08/01/08 - #129254 - delete/add reviewers on changed data if bHQRG ActionOnChanged data is 3
*			MV 01/28/09 - #132033 - fix cursor selects - include INCo and Loc
*			MV 02/10/09 - #123778 - if APUL PO/POItem changes, clear bPORD invoice info
*			MV 03/10/09 - #132547 - don't include ApprovalSeq in APUR insert 'does not exist' test
*			MV 04/15/09 - #133256 - add RG and threshold reviewers to bAPUR before job/loc/equip reviewers
*			MV 06/01/09 - #133815 - added cursor close/ deallocate
*			GF 10/25/2010 - issue #141031
*			CHS	08/08/2011	- B-05526
*			MV 01/15/2013 - D-05483/TK-20779 replaced vfDateOnly with getdate for DateAssigned in APUR insert. Notifier query needs hours/minutes.
*
* Reject primary key changes.
*/----------------------------------------------------------------
   
	declare @errmsg varchar(255), @validcnt int, @numrows int, @apco bCompany, @uimth bMonth,
	@uiseq int, @line int, @jcco bCompany, @job bJob, @emco bCompany,@reviewergroup varchar(10),
	@equip bEquip, @vendorgroup bGroup,	@vendor bVendor, @linetype tinyint, @amount bDollar,
	@inco bCompany, @loc bLoc, @cursoropen int
   
	select @numrows = @@rowcount, @cursoropen = 0
	if @numrows = 0 return

	set nocount on


	/* check for key changes */
	select @validcnt = count(*) from deleted d
	join inserted i on d.APCo = i.APCo and d.Line = i.Line and d.UIMth = i.UIMth
	and d.UISeq = i.UISeq
	if @validcnt <> @numrows
	begin
		select @errmsg = 'Cannot change primary key values.'
		goto error
	end
   
	-- update reviewers to bAPUR for this bAPUL line
	if @numrows = 1
		begin
		select @apco = i.APCo, @uimth = i.UIMth, @uiseq = i.UISeq, @line = i.Line, @linetype = i.LineType,
		@jcco = i.JCCo, @job = i.Job, @emco = i.EMCo, @equip = i.Equip, @vendorgroup = u.VendorGroup,
		@vendor = u.Vendor, @reviewergroup=i.ReviewerGroup, @amount=i.GrossAmt,@inco=i.INCo, @loc=i.Loc
		from inserted i join bAPUI u on i.APCo = u.APCo and i.UIMth = u.UIMth and i.UISeq = u.UISeq
		end
	else
   		begin
   		-- use a cursor to process all lines
   		declare bcAPUL_update cursor for
   		select i.APCo, i.UIMth, i.UISeq, i.Line, i.LineType, i.JCCo, i.Job, i.EMCo, i.Equip,
   		u.VendorGroup, u.Vendor,i.ReviewerGroup,i.GrossAmt,i.INCo,i.Loc
   		from inserted i join dbo.bAPUI u (nolock) on i.APCo = u.APCo and i.UIMth = u.UIMth and i.UISeq = u.UISeq
   
   		open bcAPUL_update
   
		select @cursoropen = 1

   		fetch next from bcAPUL_update into @apco, @uimth, @uiseq, @line, @linetype, @jcco, @job,
   		@emco, @equip, @vendorgroup, @vendor,@reviewergroup,@amount,@inco, @loc

   		if @@fetch_status <> 0
   			begin
   			select @errmsg = 'Cursor error'
   			goto error
   			end
   		end
reviewer_insert:
	-- if user changes Job/Loc/Equip/ReviewerGroup delete all reviewers and re-add
   if update(ReviewerGroup) or update (Job) or update (Loc) or update (Equip) 
	begin
		if update(ReviewerGroup)
		-- delete reviewers from reviewer group
		delete r 
		from dbo.bAPUR r (nolock) 
		join deleted d on r.APCo=d.APCo and r.UIMth=d.UIMth and r.UISeq=d.UISeq and r.Line=d.Line and r.ReviewerGroup=d.ReviewerGroup
		--delete job/loc/equip reviewers
		if (update (Job) or update (Loc) or update (Equip))
		begin
		--delete all reviewers if the line reviewergroup's "Action on Changed Data" is to roll back prior approval on changed data.
		if exists (select * from dbo.vHQRG (nolock) where ReviewerGroup=@reviewergroup and ActionOnChangedData=3)
			begin
			delete r from dbo.bAPUR r join deleted d on r.APCo=d.APCo and r.UIMth=d.UIMth and r.UISeq=d.UISeq and r.Line=d.Line
			end
		else
			--delete job/loc/equip reviewers
			begin
			if update (Job)
				begin
				delete r from dbo.bAPUR r (nolock) 
					join deleted d on r.APCo=d.APCo and r.UIMth=d.UIMth and r.UISeq=d.UISeq and r.Line=d.Line
					join dbo.bJCJR j (nolock) on d.JCCo=j.JCCo and d.Job=j.Job and r.Reviewer=j.Reviewer
					where r.APCo=@apco and r.UIMth=@uimth and r.UISeq=@uiseq and r.Line=@line 
				end
			if update (Loc)
				begin
				delete r from dbo.bAPUR r (nolock) 
					join deleted d on r.APCo=d.APCo and r.UIMth=d.UIMth and r.UISeq=d.UISeq and r.Line=d.Line
					join dbo.bINLM l (nolock) on l.INCo=d.INCo and l.Loc=d.Loc and l.InvReviewer=r.Reviewer
					where r.APCo=@apco and r.UIMth=@uimth and r.UISeq=@uiseq and r.Line=@line 
				end
			if update (Equip)
				begin
				delete r from dbo.bAPUR r (nolock)
					join deleted d on r.APCo=d.APCo and r.UIMth=d.UIMth and r.UISeq=d.UISeq and r.Line=d.Line
					join dbo.bEMEM e (nolock) on e.EMCo=d.EMCo and e.Equipment=d.Equip
					join dbo.bEMDM m (nolock) on m.EMCo=e.EMCo and m.Department=e.Department and m.Reviewer=r.Reviewer
					where r.APCo=@apco and r.UIMth=@uimth and r.UISeq=@uiseq and r.Line=@line 
				end
			end
		end
		
		-- add bAPUR Header Reviewers (-1) 
		if exists(select top 1 1 from dbo.bAPUR r (nolock) JOIN inserted i ON r.APCo = i.APCo and r.UIMth = i.UIMth
			and r.UISeq = i.UISeq where r.Line = -1)
		begin
			insert bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Memo, Line, ApprovalSeq, DateAssigned,
			DateApproved, AmountApproved, Rejected, RejReason, APTrans, ExpMonth, ReviewerGroup)
			select i.APCo, i.UIMth, i.UISeq, r.Reviewer, 'N', r.Memo, i.Line, r.ApprovalSeq,
			getdate(),
			r.DateApproved, r.AmountApproved, 'N', r.RejReason, r.APTrans, r.ExpMonth,r.ReviewerGroup
			from inserted i 
			join dbo.bAPUR r (nolock)	on r.APCo = i.APCo and r.UIMth = i.UIMth and r.UISeq = i.UISeq  
			where r.Line = -1 and r.APTrans is null and r.ExpMonth is null and 
				not exists (select 1 from bAPUR r2 where i.APCo = r2.APCo and i.UIMth = r2.UIMth and i.UISeq = r2.UISeq and
				i.Line = r2.Line and r2.Reviewer = r.Reviewer /*and r.ApprovalSeq = r2.ApprovalSeq #132547*/ and 
				r.APTrans is null and r.ExpMonth is null)
		end 

	   -- add Reviewer Group Reviewers to bAPUR for this bAPUL line
		if @reviewergroup is not null
		begin
		exec vspAPURUpdateReviewerGroup @apco, @uimth, @uiseq, @line, @reviewergroup, @amount, @errmsg
		end
		-- add threshold reviewers
        exec vspAPUnappThresholdReviewers @apco, @uimth, @uiseq, @line

		-- add Job/Loc/Equip/Vendor reviewers to bAPUR for this bAPUL line
		exec bspAPUNApprovedReviewerGet @apco, @uimth, @uiseq, @line, @linetype, @jcco, @job, @emco, @equip,
			 @vendorgroup, @vendor, @inco, @loc

		if @numrows > 1
		begin
			fetch next from bcAPUL_update into @apco, @uimth, @uiseq, @line, @linetype, @jcco, @job,
			@emco, @equip, @vendorgroup, @vendor,@reviewergroup,@amount,@inco,@loc

			if @@fetch_status = 0
				goto reviewer_insert
			else
			if @cursoropen = 1
			begin
			close bcAPUL_update
			deallocate bcAPUL_update
			select @cursoropen = 0
			end
		end
   end

    if update (GrossAmt)
    /*If Gross Amount changes threshold reviewers may need to be added to the line. */
    begin
    if @numrows = 1 select @line=Line from inserted
        begin
	    exec vspAPUnappThresholdReviewers @apco, @uimth, @uiseq, @line
        end
    end 


	if (update (PO) or update (POItem) or update (POItemLine))
	-- if the PO or PO Item changes and there is a PORD record associated with the old PO or POItem, break the invoice link with PORD.
	begin
	if exists (select 1 from dbo.bPORD r join deleted d on r.POCo=d.APCo 
		and r.PO=d.PO and r.POItem=d.POItem and r.POItemLine=d.POItemLine and (r.Receiver# is not null and r.Receiver#=d.Receiver#)
		where r.UIMth=d.UIMth and r.UISeq=d.UISeq and r.UILine=d.Line)
		begin
		update bPORD set UIMth= null, UISeq=null, UILine=null
			from bPORD r join deleted d on r.POCo=d.APCo and r.PO=d.PO
			and r.POItem=d.POItem and r.POItemLine=d.POItemLine and r.Receiver#=d.Receiver#
			where r.UIMth=d.UIMth and r.UISeq=d.UISeq and r.UILine=d.Line
		end 
	end  


   -- Check bAPCO to see if auditing changes. 
   if exists(select 1 from inserted i join bAPCO c with (nolock) on i.APCo=c.APCo where c.AuditUnappInv = 'Y')
   	begin
   
   	-- Insert records into HQMA for changes made to audited fields
   	if update(LineType)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Line Type', convert(varchar(1),d.LineType), convert(varchar(1),i.LineType),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.LineType,'') <> isnull(i.LineType,'') 
   	if update(PO)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'PO', d.PO, i.PO,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.PO,'') <> isnull(i.PO,'') 
   	if update(POItem)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'PO Item', convert(varchar(5),d.POItem), convert(varchar(5),i.POItem),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.POItem,'') <> isnull(i.POItem,'') 
   	    
   	if update(POItemLine)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'PO Item Line', convert(varchar(5),d.POItemLine), convert(varchar(5),i.POItemLine),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.POItemLine,'') <> isnull(i.POItemLine,'')    
   	       	    
   	if update(ItemType)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'PO Item', convert(varchar(3),d.ItemType), convert(varchar(3),i.ItemType),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.ItemType,'') <> isnull(i.ItemType,'') 
   	if update(SL)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'SL', d.SL, i.SL,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.SL,'') <> isnull(i.SL,'') 
   	if update(SLItem)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'SL Item', convert(varchar(5),d.SLItem), convert(varchar(5),i.SLItem),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.SLItem,'') <> isnull(i.SLItem,'') 
   	if update(JCCo)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'JC Company', convert(varchar(3),d.JCCo), convert(varchar(3),i.JCCo),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.JCCo,'') <> isnull(i.JCCo,'') 
   	if update(Job)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Job', d.Job, i.Job,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Job,'') <> isnull(i.Job,'') 
   	if update(Phase)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Phase', d.Phase, i.Phase,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Phase,'') <> isnull(i.Phase,'') 
   	if update(JCCType)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'JC Cost Type', convert(varchar(3),d.JCCType), convert(varchar(3),i.JCCType),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.JCCType,'') <> isnull(i.JCCType,'') 
   	if update(EMCo)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'EM Company', convert(varchar(3),d.EMCo), convert(varchar(3),i.EMCo),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.EMCo,'') <> isnull(i.EMCo,'') 
   	if update(WO)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'WO', d.WO, i.WO,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.WO,'') <> isnull(i.WO,'')
   	if update(WOItem)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'WO Item', convert(varchar(3),d.WOItem), convert(varchar(3),i.WOItem),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.WOItem,'') <> isnull(i.WOItem,'') 
   	if update(Equip)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Equipment', d.Equip, i.Equip,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Equip,'') <> isnull(i.Equip,'')
   	if update(CostCode)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Cost Code', d.CostCode, i.CostCode,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.CostCode,'') <> isnull(i.CostCode,'') 
    	if update(EMCType)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'EM Cost Type', convert(varchar(5),d.EMCType), convert(varchar(5),i.EMCType),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.EMCType,'') <> isnull(i.EMCType,'') 
   	if update(CompType)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Comp Type', d.CompType, i.CompType,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.CompType,'') <> isnull(i.CompType,'') 
   	if update(Component)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Component', d.Component, i.Component,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Component,'') <> isnull(i.Component,'')
   	if update(INCo)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'IN Company', convert(varchar(3),d.INCo), convert(varchar(3),i.INCo),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.INCo,'') <> isnull(i.INCo,'') 
   	if update(Loc)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Location', d.Loc, i.Loc,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Loc,'') <> isnull(i.Loc,'')
   	if update(Material)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Material', d.Material, i.Material,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Material,'') <> isnull(i.Material,'')
   	if update(GLCo)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'GL Company', convert(varchar(3),d.GLCo), convert(varchar(3),i.GLCo),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.GLCo,'') <> isnull(i.GLCo,'') 
   	if update(GLAcct)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'GL Acct', d.GLAcct, i.GLAcct,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.GLAcct,'') <> isnull(i.GLAcct,'')
   	if update(Description)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Description', d.Description, i.Description,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Description,'') <> isnull(i.Description,'')
   	if update(UM)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'UM', d.UM, i.UM,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.UM,'') <> isnull(i.UM,'')
   	if update(Units)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Units', convert(varchar(20),d.Units), convert(varchar(20),i.Units),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Units,'') <> isnull(i.Units,'') 
   	if update(UnitCost)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Unit Cost', convert(varchar(20),d.UnitCost), convert(varchar(20),i.UnitCost),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.UnitCost,'') <> isnull(i.UnitCost,'') 
   	if update(ECM)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'ECM', d.ECM, i.ECM,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.ECM,'') <> isnull(i.ECM,'') 
   	if update(Supplier)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Supplier', convert(varchar(4),d.Supplier), convert(varchar(4),i.Supplier),
   		getdate(), SUSER_SNAME()
   
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Supplier,'') <> isnull(i.Supplier,'')
   	if update(PayCategory)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Payable Category', convert(varchar(8),d.PayCategory), convert(varchar(8),i.PayCategory),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.PayCategory,'') <> isnull(i.PayCategory,'') 
   	if update(PayType)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Pay Type', convert(varchar(3),d.PayType), convert(varchar(3),i.PayType),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.PayType,'') <> isnull(i.PayType,'') 
   	if update(GrossAmt)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Gross Amount', convert(varchar(20),d.GrossAmt), convert(varchar(20),i.GrossAmt),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.GrossAmt,'') <> isnull(i.GrossAmt,'') 
   	if update(MiscAmt)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Misc Amount', convert(varchar(20),d.MiscAmt), convert(varchar(20),i.MiscAmt),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.MiscAmt,'') <> isnull(i.MiscAmt,'') 
   	if update(MiscYN)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Include Misc Amt ', d.MiscYN, i.MiscYN,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.MiscYN,'') <> isnull(i.MiscYN,'') 
   	if update(TaxCode)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Tax Code', d.TaxCode, i.TaxCode,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.TaxCode,'') <> isnull(i.TaxCode,'')
   	if update(TaxType)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Tax Type', convert(varchar(1),d.TaxType), convert(varchar(1),i.TaxType),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.TaxType,'') <> isnull(i.TaxType,'')
   	if update(TaxBasis)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Tax Basis', convert(varchar(20),d.TaxBasis), convert(varchar(20),i.TaxBasis),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.TaxBasis,'') <> isnull(i.TaxBasis,'') 
   	if update(TaxAmt)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Tax Amount', convert(varchar(20),d.TaxAmt), convert(varchar(20),i.TaxAmt),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.TaxAmt,'') <> isnull(i.TaxAmt,'') 
   	if update(Retainage)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Retainage', convert(varchar(20),d.Retainage), convert(varchar(20),i.Retainage),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Retainage,'') <> isnull(i.Retainage,'') 
   	if update(Discount)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'Discount', convert(varchar(20),d.Discount), convert(varchar(20),i.Discount),
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.Discount,'') <> isnull(i.Discount,'') 
	if update(ReviewerGroup)
   		insert into bHQMA select 'bAPUL',
   		'UIMth: ' + convert(char(8), i.UIMth,1) +
   		' UISeq: ' + convert(varchar(10), i.UISeq) +
   		' Line: ' + convert (varchar(10), i.Line), i.APCo, 'C',
   	 	'ReviewerGroup',d.ReviewerGroup, i.ReviewerGroup,
   		getdate(), SUSER_SNAME()
   	 	from inserted i	join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth
   			and d.UISeq = i.UISeq and d.Line=i.Line
   	    where isnull(d.ReviewerGroup,'') <> isnull(i.ReviewerGroup,'')  
   	end	
   
	if @cursoropen = 1
			begin
			close bcAPUL_update
			deallocate bcAPUL_update
			end
   return
   
   error:

	if @cursoropen = 1
			begin
			close bcAPUL_update
			deallocate bcAPUL_update
			end

   	select @errmsg = @errmsg + ' - cannot update Unapproved Invoice Line!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bAPUL].[UnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bAPUL].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPUL].[MiscYN]'
GO
