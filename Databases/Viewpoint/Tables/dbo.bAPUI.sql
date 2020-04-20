CREATE TABLE [dbo].[bAPUI]
(
[APCo] [dbo].[bCompany] NOT NULL,
[UIMth] [dbo].[bMonth] NOT NULL,
[UISeq] [smallint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NULL,
[APRef] [dbo].[bAPReference] NULL,
[Description] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NULL,
[DiscDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NULL,
[InvTotal] [dbo].[bDollar] NOT NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[PayControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[V1099YN] [dbo].[bYN] NOT NULL,
[V1099Type] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[V1099Box] [tinyint] NULL,
[PayOverrideYN] [dbo].[bYN] NOT NULL,
[PayName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PayAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PayCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PayState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[PayZip] [dbo].[bZip] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[PayAddInfo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[DocName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[SeparatePayYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPUI_SeparatePayYN] DEFAULT ('N'),
[Notes] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AddressSeq] [tinyint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ReviewerGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SLKeyID] [bigint] NULL,
[PayCountry] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biAPUI] ON [dbo].[bAPUI] ([APCo], [UIMth], [UISeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPUI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_bAPUI_SLKeyID] ON [dbo].[bAPUI] ([SLKeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biAPUIUniqueAttId] ON [dbo].[bAPUI] ([UniqueAttchID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biAPUIVendor] ON [dbo].[bAPUI] ([Vendor]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
  
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btAPUId    Script Date: 8/28/99 9:36:58 AM ******/
   CREATE     trigger [dbo].[btAPUId] on [dbo].[bAPUI] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:	EN 11/2/98
    * Modified By: EN 11/2/98
    *				GR 10/30/00 - deleted APUR records on delete of APUI record
    *				TV 09/24/01 - Delete HQAT attachment if it exists
    *				GF 08/11/2003 - issue #22112 - performance 
    *				ES 03/12/04 - #23061 isnull wrapping
    *				MV 03/22/04 - #23833 audit deletes
    *				MV 08/09/05 - #29158 fix keyfield string for attachement delete
	*				RM 05/03/07 - #119994 comment out deletion from HQAT.
	*				MV 08/20/09 - #135204 - isnull wrap key field string for HQMA audit.
	*				GF 11/12/2012 TK-19414 when from a SL claim reset status to pending
    *
    *	This trigger restricts deletion of any APUI records if
    *	lines or detail exist in APUL.
    *
    */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @keyfield varchar(128), @co bCompany, @uimth bMonth, 
            @uiseq smallint, @apmth bMonth, @aptrans int, @key varchar(30)
    
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
    
   if exists(select 1 from bAPUL a with (nolock), deleted d where a.APCo=d.APCo and a.UIMth=d.UIMth
    	and a.UISeq=d.UISeq)
    	begin
    	select @errmsg='Unapproved Invoice Line(s) exist for this header.'
    	goto error
    	end
    
   -- delete the reviewers for this APUI record
   delete bAPUR from bAPUR r, deleted d
   where r.APCo=d.APCo and r.UIMth=d.UIMth and r.UISeq=d.UISeq and r.APTrans is null and r.ExpMonth is null
    
   --delete Attachment in HQAT
   select @co = d.APCo, @uimth = d.UIMth, @uiseq = d.UISeq
   from Deleted d
   

---- TK-19414 update SLClaimHeader, set status to pending and null out certified columns
UPDATE dbo.vSLClaimHeader SET ClaimStatus = 10, CertifiedBy = NULL, CertifyDate = NULL
FROM Deleted d
INNER JOIN dbo.vSLClaimHeader h ON h.KeyID = d.SLKeyID
INNER JOIN dbo.bSLHD s ON s.SLCo = h.SLCo AND s.SL=h.SL
WHERE s.ApprovalRequired = 'Y'


   
   /* Audit delete */
   if exists (select 1 from bAPCO with (nolock) where APCo=@co and AuditUnappInv = 'Y')
   	begin
   	select @apmth=Mth, @aptrans=APTrans from bAPHB with (nolock) where Co=@co and UIMth=@uimth and UISeq=@uiseq
   	if	@apmth is not null and @aptrans is not null  --@@rowcount = 1
   		begin
   		select @key = ' APMth: ' + isnull(convert(char(8), @apmth,1),'') + ' APTrans: ' + isnull(convert(varchar(10),''), @aptrans)
   		end
   	else select @key=''
   	insert into bHQMA select 'bAPUI', ' UIMth: ' + isnull(convert(char(8), i.UIMth,1),'') 
		+ ' UISeq: ' + isnull(convert(varchar(10), i.UISeq),'') + isnull(@key,''),
   		i.APCo, 'D',NULL, NULL, NULL, getdate(), SUSER_SNAME() from deleted i
    	end
   
   return
    
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Unapproved Invoice Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btAPUIi] on [dbo].[bAPUI] for INSERT as
/*-----------------------------------------------------------------
* Created: EN 11/2/98
* Modified: EN 11/2/98
*			GG 09/27/02 - #18654 - added check for Seq#
*			MV 03/22/04 - #23833 - auditing
*			MV 02/11/08 - #29702 - insert reviewers from APUI.ReviewerGroup
*			MV 03/11/08 - #127347 International addresses
*			GG 06/06/08 - #128324 - fixed State/Country validation
*			GF 10/25/2010 - issue #141031
*
* Insert trigger on AP Unapproved Invoice Header
*
*/----------------------------------------------------------------

declare @errmsg varchar(255), @validcnt int,@validcnt2 int, @nullcnt int, @numrows int
   
SELECT @numrows = @@rowcount
IF @numrows = 0 return
SET nocount on

/* validate AP Company */
SELECT @validcnt = count(*)
FROM dbo.bAPCO c (nolock)
JOIN inserted i ON c.APCo = i.APCo
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid AP Company'
	GOTO error
	end
   	
 -- validate Country 
select @validcnt = count(1)
from dbo.bHQCountry c (nolock) 
join inserted i on i.PayCountry = c.Country
select @nullcnt = count(1) from inserted where PayCountry is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Pay Country'
	goto error
	end
-- validate Country/State combinations
select @validcnt = count(1) -- Country/State combos are unique
from inserted i
join dbo.bHQCO c (nolock) on c.HQCo = i.APCo	-- join to get Default Country
join dbo.bHQST s (nolock) on isnull(i.PayCountry,c.DefaultCountry) = s.Country and i.PayState = s.State
select @nullcnt = count(1) from inserted where PayState is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Pay Country and State combination'
	goto error
	end
  

-- check for Unapproved Invoice Review History
if exists(select 1 from bAPUR r join inserted i on r.APCo = i.APCo and r.UIMth = i.UIMth
   			and r.UISeq = i.UISeq)
   	begin
   	select @errmsg = 'Sequence # exists in AP Unapproved Invoice Review History, cannot be reused'
   	goto error
   	end

-- if APUI has a default Reviewer Group, add those reviewers to bAPUR as 'headers' (-1)
insert bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, DateApproved,
		AmountApproved, Rejected, RejReason, APTrans, ExpMonth, Memo, LoginName, UniqueAttchID, RejectDate, ReviewerGroup)
----#141031
select i.APCo,i.UIMth,i.UISeq,d.Reviewer,'N',-1,d.ApprovalSeq, dbo.vfDateOnly(),null,null,'N',null,
		null,null,null,null,null,null,i.ReviewerGroup
from inserted i
join vHQRD d on i.ReviewerGroup = d.ReviewerGroup
where d.ThresholdAmount is null and
	not exists (select 1 from bAPUR r where r.APCo=i.APCo and r.UIMth=i.UIMth and r.UISeq=i.UISeq
					and r.Reviewer=d.Reviewer) 

/* Audit inserts */
insert bHQMA
select 'bAPUI', ' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq),
   	i.APCo, 'A',NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i
join bAPCO a on a.APCo = i.APCo
where a.AuditUnappInv = 'Y'
   
return
   
error:
       SELECT @errmsg = @errmsg +  ' - cannot insert AP Unapproved Invoice Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btAPUIu] on [dbo].[bAPUI] for UPDATE as
/*-----------------------------------------------------------------
 * Created: EN 11/2/98
 * Modified: EN 11/2/98 
 *			MV 03/15/04 - #23993 - audit unapproved changes
 *			MV 07/09/04 - #25070 - increase InvTotal varchar size
 *			MV 02/12/08 - #29702 - delete old/add new ReviewerGroup Reviewer
 *			MV 03/11/08 - #127347 International addresses
 *			GG 06/06/08 - #128324 - fixed State/Country validation
 *			MV 11/05/08 - #130968 - don't delete header RG reviewers if same RG on line 
 *			GF 10/25/2010 - issue #141031
 *			GF 11/12/2012 TK-19306 update information in SL Claims
 *			MV 01/22/2013 TK-20779 use getdate() for DateAssigned insert to bAPUR.
 *
 *
 * Reject primary key changes.
 */----------------------------------------------------------------
    
    declare @errmsg varchar(255), @numrows int, @validcnt int, @reviewergroup varchar(10),
		@apco int, @uimth bMonth, @uiseq int,@validcnt2 int, @nullcnt int
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount ON
    
    /* check for key changes */
    select @validcnt = count(*) from deleted d
        join inserted i on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Cannot change key information.'
    	goto error
    	end
    	
-- validate PayState/PayCountry
if update(PayState) or update(PayCountry)
	begin
	select @validcnt = count(1) 
	from dbo.bHQCountry c with (nolock) 
	join inserted i on i.PayCountry = c.Country
	select @nullcnt = count(1) from inserted where PayCountry is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Pay Country'
		goto error
		end
	-- validate Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from inserted i
	join dbo.bHQCO c (nolock) on c.HQCo = i.APCo	-- join to get Default Country
	join dbo.bHQST s (nolock) on isnull(i.PayCountry,c.DefaultCountry) = s.Country and i.PayState = s.State
	select @nullcnt = count(1) from inserted where PayState is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Pay Country and State combination'
		goto error
		end
	end
    
if update(ReviewerGroup)
	begin
	--delete old reviewer group reviewers from bAPUR
	delete r 
	from bAPUR r
	join deleted d on r.APCo=d.APCo and r.UIMth=d.UIMth and r.UISeq=d.UISeq
            and r.ReviewerGroup=d.ReviewerGroup
	join bAPUL l on l.APCo=d.APCo and l.UIMth=d.UIMth and l.UISeq=d.UISeq and l.ReviewerGroup <> d.ReviewerGroup
	-- add new reviewer group reviewers to bAPUR as 'headers' (-1) - non threshold reviewers
	select @reviewergroup = ReviewerGroup from inserted
	if @reviewergroup is not null 
		begin
		insert into bAPUR (APCo, UIMth, UISeq, Reviewer, ApprvdYN, Line, ApprovalSeq, DateAssigned, DateApproved,
			AmountApproved, Rejected, RejReason, APTrans, ExpMonth, Memo, LoginName, UniqueAttchID, RejectDate, ReviewerGroup)
		----#141031
		select i.APCo,i.UIMth,i.UISeq,d.Reviewer,'N',-1,d.ApprovalSeq, getdate(),null,null,'N',null,
			null,null,null,null,null,null,i.ReviewerGroup
		from inserted i
			join vHQRD d on i.ReviewerGroup = d.ReviewerGroup where d.ThresholdAmount is null and
			not exists (select 1 from bAPUR r where r.APCo=i.APCo and r.UIMth=i.UIMth and r.UISeq=i.UISeq and r.Reviewer=d.Reviewer)
		-- add new reviewer group reviewers to bAPUR as lines and threshold reviewers 
		if exists(select 1 from bAPUL l join inserted i on l.APCo = i.APCo and l.UIMth = i.UIMth and l.UISeq = i.UISeq)
			begin
			select @apco=APCo, @uimth=UIMth, @uiseq=UISeq from inserted
			exec vspAPUIReviewerUpdate @apco, @uimth, @uiseq, @reviewergroup
			end
		end
	end	


---- TK-19306 update SLClaimHeader with changes to APRef, Invoice Date, or Invoice Description.
IF UPDATE(APRef) OR UPDATE([Description]) OR UPDATE(InvDate)
	BEGIN
    UPDATE dbo.vSLClaimHeader SET APRef = i.APRef, InvoiceDate = i.InvDate, InvoiceDesc = i.[Description]
	FROM inserted i
	INNER JOIN dbo.vSLClaimHeader h ON h.KeyID = i.SLKeyID
	END
  
    
    -- Check bAPCO to see if auditing changes. 
    if exists(select 1 from inserted i join bAPCO c with (nolock) on i.APCo=c.APCo where c.AuditUnappInv = 'Y')
    	begin
    
    	-- Insert records into HQMA for changes made to audited fields
    	if update(Vendor)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Vendor', convert(varchar(3),d.Vendor), convert(varchar(3),i.Vendor), getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.Vendor,'') <> isnull(i.Vendor,'') 
    	if update(APRef)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'AP Reference', d.APRef, i.APRef, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.APRef,'') <> isnull(i.APRef,'') 
    	if update(Description)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.Description,'') <> isnull(i.Description,'') 
    	if update(InvDate)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Invoice Date', convert(varchar(8),d.InvDate,1), convert(varchar(8),i.InvDate,1), getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.InvDate,'') <> isnull(i.InvDate,'') 
    	if update(DiscDate)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Discount Date', convert(varchar(8),d.DiscDate,1), convert(varchar(8),i.DiscDate,1), getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.DiscDate,'') <> isnull(i.DiscDate,'') 
    	if update(DueDate)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Due Date', convert(varchar(8),d.DueDate,1), convert(varchar(8),i.DueDate,1), getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.DueDate,'') <> isnull(i.DueDate,'') 
    	if update(InvTotal)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Invoice Total', convert(varchar(20),d.InvTotal), convert(varchar(20),i.InvTotal), getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.InvTotal,'') <> isnull(i.InvTotal,'') 
    	if update(HoldCode)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Hold Code', d.HoldCode, i.HoldCode, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.HoldCode,'') <> isnull(i.HoldCode,'') 
    	if update(PayControl)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Pay Control', d.PayControl, i.PayControl, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.PayControl,'') <> isnull(i.PayControl,'')
    	if update(PayMethod)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Pay Method', d.PayMethod, i.PayMethod, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.PayMethod,'') <> isnull(i.PayMethod,'')
    	if update(CMAcct)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'CM Account', convert(varchar(4),d.CMAcct), convert(varchar(4),i.CMAcct), getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.CMAcct,'') <> isnull(i.CMAcct,'') 
    	if update(V1099YN)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Vendor 1099', d.V1099YN, i.V1099YN, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.V1099YN,'') <> isnull(i.V1099YN,'') 
    	if update(V1099Type)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'1099 Type', convert(varchar(10),d.V1099Type), convert(varchar(10),i.V1099Type), getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.V1099Type,'') <> isnull(i.V1099Type,'') 
    	if update(V1099Box)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'1099 Box', convert(varchar(3),d.V1099Box), convert(varchar(3),i.V1099Box), getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.V1099Box,'') <> isnull(i.V1099Box,'') 
    	if update(PayOverrideYN)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Pay Address Override', d.PayOverrideYN, i.PayOverrideYN, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.PayOverrideYN,'') <> isnull(i.PayOverrideYN,'') 
    	if update(PayName)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Pay Name', d.PayName, i.PayName, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.PayName,'') <> isnull(i.PayName,'') 
    	if update(PayAddress)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Pay Address', d.PayAddress, i.PayAddress, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.PayAddress,'') <> isnull(i.PayAddress,'')
    	if update(PayCity)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Pay City', d.PayCity, i.PayCity, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.PayCity,'') <> isnull(i.PayCity,'')
    	if update(PayState)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Pay State', d.PayState, i.PayState, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.PayState,'') <> isnull(i.PayState,'') 
    	if update(PayZip)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Pay Zip', d.PayZip, i.PayZip, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.PayZip,'') <> isnull(i.PayZip,'')
		if update(PayCountry)
			insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    		'PayCountry', d.PayCountry, i.PayCountry, getdate(), SUSER_SNAME()
    		from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    		 and  d.PayCountry <> i.PayCountry 
    	if update(PayAddInfo)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Addtl Address Info', d.PayAddInfo, i.PayAddInfo, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.PayAddInfo,'') <> isnull(i.PayAddInfo,'')
    	if update(SeparatePayYN)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Separate Pay', d.SeparatePayYN, i.SeparatePayYN, getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.SeparatePayYN,'') <> isnull(i.SeparatePayYN,'')  
    	if update(AddressSeq)
    		insert into bHQMA select 'bAPUI',
    		' UIMth: ' + convert(char(8), i.UIMth,1) + ' UISeq: ' + convert(varchar(10), i.UISeq), i.APCo, 'C',
    	 	'Address Sequence', convert(varchar(3),d.AddressSeq), convert(varchar(3),i.AddressSeq), getdate(), SUSER_SNAME()
    	 	from inserted i
    	     join deleted d on d.APCo = i.APCo and d.UIMth = i.UIMth and d.UISeq = i.UISeq
    	    where isnull(d.AddressSeq,'') <> isnull(i.AddressSeq,'')     
    	end	
    return
    
    error:
    	select @errmsg = @errmsg + ' - cannot update Unapproved Invoice Header!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
    
    
    
   
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bAPUI].[CMAcct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPUI].[V1099YN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPUI].[PayOverrideYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPUI].[SeparatePayYN]'
GO
