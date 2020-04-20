CREATE TABLE [dbo].[bSLHD]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[CompGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Status] [tinyint] NOT NULL,
[MthClosed] [dbo].[bMonth] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Purge] [dbo].[bYN] NOT NULL,
[Approved] [dbo].[bYN] NULL,
[ApprovedBy] [dbo].[bVPUserName] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[AddedMth] [dbo].[bMonth] NULL,
[AddedBatchID] [dbo].[bBatchID] NULL,
[OrigDate] [dbo].[bDate] NULL CONSTRAINT [DF_bSLHD_OrigDate] DEFAULT (''),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SLCloseBatchID] [dbo].[bBatchID] NULL,
[MaxRetgOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bSLHD_MaxRetgOpt] DEFAULT ('N'),
[MaxRetgPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_bSLHD_MaxRetgPct] DEFAULT ((0.0000)),
[MaxRetgAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLHD_MaxRetgAmt] DEFAULT ((0.00)),
[InclACOinMaxYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bSLHD_InclACOinMaxYN] DEFAULT ('Y'),
[MaxRetgDistStyle] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bSLHD_MaxRetgDistStyle] DEFAULT ('C'),
[ApprovalRequired] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bSLHD_ApprovalRequired ] DEFAULT ('N'),
[udSLContractNo] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btSLHDd    Script Date: 8/28/99 9:38:17 AM ******/
CREATE  trigger [dbo].[btSLHDd] on [dbo].[bSLHD] for DELETE as

/***  basic declares for SQL Triggers ****/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
   /*--------------------------------------------------------------
    *
    *  Delete trigger for SLHD
    *  Created By: kb
    *  Date: 6/18/97
    *  Modified By:  LM 10/7/99 - changed delete of PMSL items to just removing SL & SLItem #'s
    *                EN 3/30/00 - added HQ Audit and check to see if entries exist in SLIT or SLWH
    *                BC 02/08/01- added a check to see if any compliance details related to the subcontract
    *                             exist. Removed the delete statement that deleted compliance details
    *                             after checking if any exist.
    *                GF 04/10/2001 - If deleting a pending SL, then delete compliance
    *				  GF 09/30/2002 - Changed PMSL update, now will not throw error. #18628
    *				  GF 01/15/2003 - Issue #19956 Changed PMSL update to not set Send flag to 'N'
	*				GF 02/14/2006 - issue #120167 when purging to not update bPMSL.
	*				GF 01/25/2007 - issue #123690 use delete purge flag not SLHD (related to #120167)
	*				GF 04/24/2008 - issue #125958 delete PM distribution audit
	*				JonathanP 05/29/2009 - issue 133440 - added attachment deletion code.
	*				GF 12/21/2010 - issue #141957 record association
	*				GF 01/26/2011 - tfs #398
	*				GF 02/22/2011 - VONE B-02851
	*
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount
    if @numrows = 0 return
   
   set nocount on
   
   -- check for SL Items
   if exists(select * from deleted d join bSLIT t on d.SLCo = t.SLCo and d.SL = t.SL)
   	begin
   	select @errmsg = 'SL Items exist '
   	goto error
   	end
   
   -- check for Worksheets
   if exists(select * from deleted d join bSLWH t on d.SLCo = t.SLCo and d.SL = t.SL)
   	begin
   	select @errmsg = 'Worksheet(s) found '
   	goto error
   	end
   
   -- check compliance detail, if status is 3 - Pending compliance detail will be deleted
   if exists(select * from deleted d join bSLCT t on d.SLCo = t.SLCo and d.SL = t.SL and d.Status <> 3)
   	begin
   	select @errmsg = 'Compliance Detail exists for this Subcontract '
   	goto error
   	end



---- Update related PMSL records
---- if not purging SL's then set interface date to null
---- otherwise do not do anything with PMSL records
update bPMSL Set SL = null, SLItem = null, InterfaceDate = null
from bPMSL p join deleted d on p.SLCo=d.SLCo and p.SL=d.SL and d.Purge = 'N'

---- delete subcontract co (PMSubcontractCO) B-02851
DELETE dbo.vPMSubcontractCO FROM dbo.vPMSubcontractCO s JOIN deleted d ON s.SLCo=d.SLCo AND s.SL=d.SL

---- remove from PM send to info if exists in PMSS
delete bPMSS from bPMSS s join deleted d on s.PMCo=d.JCCo and s.Project=d.Job and s.SLCo=d.SLCo and s.SL=d.SL

---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='SLHD' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='SLHD' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='SLHD' and i.SourceKeyId=d.KeyID

---- delete compliance detail for SL
delete bSLCT
from bSLCT, deleted d
where bSLCT.SLCo=d.SLCo and bSLCT.SL=d.SL


---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bSLHD' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bSLHD', d.KeyID, null, null, x.Issue, 'D',
		'SLCo: ' + CONVERT(VARCHAR(3), ISNULL(d.SLCo,'')) + ' MO: ' + ISNULL(d.SL,'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'SLHD' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bSLHD', d.KeyID, null, null, x.Issue, 'D',
		'SLCo: ' + CONVERT(VARCHAR(3), ISNULL(d.SLCo,'')) + ' SL: ' + ISNULL(d.SL,'') + ' : ' + ISNULL(d.Description,'')
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'SLHD' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='SLHD' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='SLHD' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


---- HQ Audit
insert into bHQMA
select 'bSLHD',' SL: ' + d.SL, d.SLCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d
join bSLCO c ON d.SLCo = c.SLCo
join bSLHD h ON d.SLCo = h.SLCo and d.SL = h.SL
where c.AuditSLs = 'Y' and h.Purge = 'N'


-- Delete attachments if they exist. Make sure UniqueAttchID is not null
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
  select AttachmentID, suser_name(), 'Y' 
	  from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
	  where d.UniqueAttchID is not null    

return


error:
      select @errmsg = @errmsg + ' - cannot remove SL Header'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btSLHDi    Script Date: 8/28/99 9:38:17 AM ******/   
CREATE        trigger [dbo].[btSLHDi] on [dbo].[bSLHD] for INSERT as
/*--------------------------------------------------------------
 *
 *  Insert trigger for SLHD
 *  Created By: SE
 *  Date: 6/3/97
 *  Modified kb 11/5/98 - trying to insert an SLCT record for a compliance code that didn't exist in bHQCP
 *  Modified kb 2/1/99
 *           EN 3/29/00 - added HQ auditing and validation for SLCo, JCCo, Job, VendorGroup, HoldCode, and PayTerms
 *           EN 3/29/00 - status must be 0 (open) or 3 (pending); MthClosed, InUseMth and InUseBatchId must be null; Purge must be 'N'
 *           EN 4/4/00 - hold code and pay terms validation fixed to allow nulls
 *			  MV 2/11/03 - #17821 - add compliance code to SLCT if not AllInvoice type.
 *			  MV 5/02/03 - #20533 - don't insert bSLCT if all invoice comp code
 *			  GF 03/25/2004 - #24094 verify SL company exists in SLCO.
 *			 DC 02/26/2010 - #129892 - Handle max retainage
 *			GF 06/30/2010 - issue #135813 expanded subcontract to 30 characters
 *
 *--------------------------------------------------------------*/
	/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int, @typecnt int,
    		@slco bCompany, @sl VARCHAR(30), @vendorgroup bGroup, @compcode bCompCode,
    		@description bItemDesc, --bDesc, DC #135813
    		@seq smallint, @vendor bVendor, @verify bYN,
    		@compgroup varchar(10), @expdate bDate, @complied bYN, @status tinyint
   
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /* Validate SL */
   
    /* validate SL Company */
    select @validcnt = count(1) from bHQCO c join inserted i on c.HQCo = i.SLCo
    if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Company '
   		goto error
   		end
   
    /* validate JC Company */
    select @validcnt = count(1) from bHQCO c join inserted i on c.HQCo = i.JCCo
    if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid JC Company '
   		goto error
   		end
   
    -- validate SL Company
    select @validcnt = count(1)
    from bSLCO c
    JOIN inserted i on i.SLCo = c.SLCo
    if @validcnt<>@numrows
        begin
     	select @errmsg = 'Invalid SL Company '
     	goto error
     	end
   
    /* validate Job */
    select @validcnt = count(1) from bJCJM c join inserted i on c.JCCo = i.JCCo and c.Job = i.Job
    if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Job '
   		goto error
   		end
   
    /* validate Vendor Group */
    select @validcnt = count(1) from bHQGP c join inserted i on c.Grp = i.VendorGroup
    if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Vendor Group '
   		goto error
   		end
   
    /*validate vendor */
    select @validcnt = count(1) from bAPVM r
           JOIN inserted i on i.VendorGroup=r.VendorGroup and i.Vendor=r.Vendor
    if @validcnt<>@numrows
    	begin
    	select @errmsg = 'Invalid Vendor '
    	goto error
    	end
   
    /* validate Hold Code */
    select @validcnt = count(1) from inserted where HoldCode is not null
    select @validcnt2 = count(1) from bHQHC c join inserted i on c.HoldCode = i.HoldCode
        where i.HoldCode is not null
    if @validcnt <> @validcnt2
   		begin
   		select @errmsg = 'Invalid Hold Code '
   		goto error
   		end
   
    /* validate Pay Terms */
    select @validcnt = count(1) from inserted where PayTerms is not null
    select @validcnt2 = count(1) from bHQPT c join inserted i on c.PayTerms = i.PayTerms
       where i.PayTerms is not null
    if @validcnt <> @validcnt2
   		begin
   		select @errmsg = 'Invalid Pay Terms '
   		goto error
   		end
   
    /*validate compliance */
    select @validcnt2 = count(1) from inserted where CompGroup is Null
   
    select @validcnt = count(1) from bHQCG r JOIN inserted i on i.CompGroup=r.CompGroup
           where not i.CompGroup is null
   
    if (@validcnt+@validcnt2)<>@numrows
    	begin
    	select @errmsg = 'Invalid compliance group. '
    	goto error
    	end
    select @slco=MIN(SLCo) from inserted
    while @slco is not null
        begin
        select @sl=MIN(SL) from inserted where SLCo=@slco
        while @sl is not null
    		begin
    		select @vendorgroup=VendorGroup, @vendor=Vendor, @compgroup=CompGroup, @status=Status from inserted 
    			where SLCo=@slco and SL=@sl
    		select @compcode=Min(CompCode) from bAPVC where APCo=@slco and VendorGroup=@vendorgroup and Vendor=@vendor
    		while @compcode is not null /*and @status <> 3*/
    			begin
    			if exists (select 1 from bSLCT where SLCo=@slco and SL=@sl and CompCode=@compcode) goto endAPVC
    			/*select @description=c.Description, @verify=a.Verify, @expdate=a.ExpDate, @complied=a.Complied
    			from bAPVC a, bHQCP c where a.APCo=@slco and a.VendorGroup=@vendorgroup and a.Vendor=@vendor and
    			a.CompCode=@compcode */
    			select @description=c.Description, @verify=a.Verify, @expdate=a.ExpDate, @complied=a.Complied
    			from bHQCP c, bAPVC a 
    			where a.APCo=@slco and a.VendorGroup=@vendorgroup and a.Vendor=@vendor
    				and a.CompCode=c.CompCode and a.CompCode=@compcode and c.AllInvoiceYN='N'	--17821
    			if @@rowcount=0 goto endAPVC
    			select @seq=isnull(max(Seq),0)+1 from bSLCT where SLCo=@slco and SL=@sl and CompCode=@compcode
   
    			insert into bSLCT(SLCo, SL, CompCode, Seq, Description, Verify, ExpDate, Complied, VendorGroup)
    			values(@slco, @sl, @compcode, @seq, @description, @verify, @expdate, @complied, @vendorgroup)
   
    			endAPVC:
    			select @compcode=Min(CompCode) from APVC 
    			where APCo=@slco and VendorGroup=@vendorgroup and Vendor=@vendor and CompCode>@compcode
    			if @@rowcount=0 select @compcode=null
    			end
    		select @compcode=Min(x.CompCode) from bHQCX x where x.CompGroup=@compgroup
    		while @compcode is not null /*and @status <> 3*/
    			begin
    			if exists (select 1 from bSLCT where SLCo=@slco and SL=@sl and CompCode=@compcode) goto endHQCP
    			select @description=Description, @verify=Verify, @complied= case CompType when 'F' then
    				'N' else null end 
    			from bHQCP, bHQCX 
    			where bHQCP.CompCode=bHQCX.CompCode
    				and bHQCX.CompGroup=@compgroup and bHQCP.CompCode=@compcode and bHQCP.AllInvoiceYN='N' --17821
   				if @@rowcount=0 goto endHQCP	--#20533
    			select @seq=isnull(max(Seq),0)+1 from bSLCT where SLCo=@slco and SL=@sl and CompCode=@compcode
   		
    			insert into bSLCT(SLCo, SL, CompCode, Seq, Description, Verify, VendorGroup, Complied)      
    			values(@slco, @sl, @compcode, @seq, @description, @verify, @vendorgroup, @complied)
   
    			endHQCP:
    			select @compcode=Min(x.CompCode) from bHQCX x where x.CompGroup=@compgroup and CompCode>@compcode
    			if @@rowcount=0 select @compcode=null
    			end
   
    	select @sl=MIN(SL) from inserted where SLCo=@slco and SL>@sl
    	if @@rowcount=0 select @sl=null
    	end
    select @slco=MIN(SLCo) from inserted where SLCo>@slco
    if @@rowcount=0 select @slco=null
    end
   
    /* validate Status */
    select @validcnt = count(1) from inserted where Status = 0 or Status = 3
    if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Status must be 0 (open) or 3 (pending) '
   		goto error
   		end
   
   --DC #129892
    /* validate MaxRetgOpt */
    select @validcnt = count(1) from inserted where MaxRetgOpt = 'N' or MaxRetgOpt = 'P' or MaxRetgOpt = 'A'
    if @validcnt <> @numrows
   		begin
   		select @errmsg = 'MaxRetgOpt must be N (None) or P (Percent) or A (Amount)'
   		goto error
   		end
   
   --DC #129892
    /* validate MaxRetgDistStyle */
    select @validcnt = count(1) from inserted where MaxRetgDistStyle = 'C' or MaxRetgDistStyle = 'I'
    if @validcnt <> @numrows
   		begin
   		select @errmsg = 'MaxRetgOpt must be C (Composite Percentage same on all Items) or I (Use Items Percentage value from invoice)'
   		goto error
   		end
    
    /* validate MthClosed */
    select @validcnt = count(1) from inserted where MthClosed is null
    if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Month Closed must be null '
   		goto error
   		end
   
    /* validate InUseMth and InUseBatchId */
    select @validcnt = count(1) from inserted where InUseMth is null and InUseBatchId is null
    if @validcnt <> @numrows
   		begin
   		select @errmsg = 'InUseMth and InUseBatchId must be null '
   		goto error
   		end
   
    /* validate Purge */
    select @validcnt = count(1) from inserted where Purge = 'N'
    if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Purge flag must be ''N'' '
   		goto error
   		end
   
    -- HQ Auditing
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'A', null, null, null, getdate(), SUSER_SNAME()
    from inserted i
    join bSLCO c on i.SLCo = c.SLCo
    where c.AuditSLs = 'Y'
   
   
    return
   
    error:
       select @errmsg = @errmsg + ' - cannot insert SL Header'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE trigger [dbo].[btSLHDu] on [dbo].[bSLHD] for UPDATE as
/*--------------------------------------------------------------
*
*  Update trigger for SLHD
*  Created By: SAE
*  Modified By: LM 11/2/98 - If Vendor changed and record exists in PM, change Vendor in PM
*  Modified : TV 02/22/2001 - to update PMSL OrigDate
*  Date: 6/3/97
*  Modified by: EN 3/29/00 - reject key changes; validate JCCo, Job, VendorGroup, Vendor, HoldCode, PayTerms, and CompGroup
*               EN 3/29/00 - MthClosed must be null unless Status is 2 (closed)
*               EN 3/29/00 - if Purge = 'Y', Status must be 2
*               EN 3/30/00 - validate Status changes and add HQ Auditing
*               EN 4/5/00 - was not allowing for HoldCode or PayTerms to be null on validation
*               GF 03/08/2001 - changed update vendor in PMSL to only update if vendor changes
*				 GF 12/13/2001 - added code to create compliance codes if the SL status is pending(3)
*								 and the old compliance group is null and new compliance group is not. issue #15583
*				 MV 03/06/03 - #20094 add compliance codes for any SL status.
*				DC 08/09/07 - #121008 - Wrong date format being sent to HQMA when closing SL's.
*				DC 02/12/08 - #30178 - SLHD/POHD update triggers should not add All Invoice Comp Codes
*				GF 08/11/2008 - issue #129360 fix for @oldcompgroup <> '' skip, s/b @oldcompgroup<>@compgroup
*   			JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
*				DC 03/24/09 - #129889 - AUS SL - Track Claimed  and Certified amounts
*				CHS 08/05/2009 - #134782
*				JVH 01/21/2010 - #137679 Moved PMSS updates to within Vendor change block
*				DC 02/26/2010 - #129892 Handle max retainage
*				GF 06/30/2010 - issue #135813 expanded subcontract to 30 characters
*				GF 11/09/2012 TK-18033 SL Claim Enhancement. Changed to Use ApprovalRequired
*				
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int,
		@typecnt int, @slco bCompany, @sl VARCHAR(30), @vendorgroup bGroup, @compcode bCompCode,
		@description bItemDesc, --bDesc, DC #135813
		@seq smallint, @vendor bVendor, @verify bYN,
		@compgroup varchar(10), @expdate bDate, @complied bYN, @oldcompgroup varchar(10)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

	--If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bSLHD', 'UniqueAttchID') = 1
		BEGIN 
		goto Trigger_Skip
		END    

select @validcnt2=0, @validcnt=0
   
-- check for key changes
select @validcnt = count(1) from deleted d join inserted i on i.SLCo=d.SLCo and i.SL=d.SL
if @validcnt <> @numrows
	begin
	select @errmsg = 'Cannot change Primary key'
	goto error
	end

-- validate JC Company
if update(JCCo)
	begin
	select @validcnt = count(1) from bHQCO c join inserted i on c.HQCo = i.JCCo
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid JC Company '
		goto error
		end
	end

-- validate Job
if update(Job)
	begin
	select @validcnt = count(1) from bJCJM c join inserted i on c.JCCo = i.JCCo and c.Job = i.Job
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid Job '
		goto error
		end
	end

-- validate Vendor Group
if update(VendorGroup)
	begin
	select @validcnt = count(1) from bHQGP c join inserted i on c.Grp = i.VendorGroup
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid Vendor Group '
		goto error
		end
	end

-- validate vendor
if update(Vendor)
	begin
	select @validcnt = count(1) from bAPVM r
	JOIN inserted i on i.VendorGroup=r.VendorGroup and i.Vendor=r.Vendor
	if @validcnt<>@numrows
		begin
		select @errmsg = 'Invalid Vendor '
		goto error
		end
	end

-- validate Hold Code
if update(HoldCode)
	begin
	select @validcnt = count(1) from inserted where HoldCode is not null
	select @validcnt2 = count(1) from bHQHC c join inserted i on c.HoldCode = i.HoldCode where i.HoldCode is not null
	if @validcnt <> @validcnt2
		begin
		select @errmsg = 'Invalid Hold Code '
		goto error
		end
   	end

-- validate Pay Terms
if update(PayTerms)
	begin
	select @validcnt = count(1) from inserted where PayTerms is not null
	select @validcnt2 = count(1) from bHQPT c join inserted i on c.PayTerms = i.PayTerms where i.PayTerms is not null
	if @validcnt <> @validcnt2
		begin
		select @errmsg = 'Invalid Pay Terms '
		goto error
		end
	end

-- validate compliance
if update(CompGroup)
	begin
	select @validcnt2 = count(1) from inserted where CompGroup is Null
	select @validcnt = count(1) from bHQCG r JOIN inserted i on i.CompGroup=r.CompGroup
	where i.CompGroup is not null
	if (@validcnt+@validcnt2)<>@numrows
		begin
		select @errmsg = 'Invalid compliance group. '
		goto error
		end
	end

-- validate MthClosed
select @validcnt = count(1) from inserted where Status <> 2 and MthClosed is not null
if @validcnt <> 0
	begin
	select @errmsg = 'Month Closed must be null unless Status is 2 (closed) '
	goto error
	end

-- if Purge = 'Y' Status must be 2
select @validcnt = count(1) from inserted where Purge = 'Y' and Status <> 2
if @validcnt <> 0
	begin
	select @errmsg = 'If Purge flag is ''Y'' then Status must be 2 (closed) '
	goto error
	end

-- validate Status changes
if update(Status)
   begin
   if exists(select 1 from inserted i join bSLIT t on i.SLCo = t.SLCo and i.SL = t.SL
       where i.Status = 2 and t.UM = 'LS' and t.CurCost <> t.InvCost)
       begin
       select @errmsg = 'Completed SLs require Current and Invoiced costs to be equal on all Lump Sum Items '
       goto error
       end
   if exists(select 1 from inserted i join bSLIT t on i.SLCo = t.SLCo and i.SL = t.SL
       where i.Status = 2 and t.UM <> 'LS' and t.CurUnits <> t.InvUnits)
       begin
       select @errmsg = 'Completed SLs require Current and Invoiced units to be equal on all unit based Items '
       goto error
       end
   end

-- if vendor changes and originated in PM, change it in PM
if update(Vendor)
   begin
   if exists(select 1 from bPMSL p JOIN inserted i ON p.SLCo=i.SLCo and p.SL=i.SL and p.Vendor<>i.Vendor)
       begin
       update bPMSL set bPMSL.Vendor=inserted.Vendor
       from bPMSL JOIN inserted ON bPMSL.SLCo=inserted.SLCo and bPMSL.SL=inserted.SL
       if @@rowcount = 0
           begin
           select @errmsg = 'Unable to update Vendor in PMSL. '
           goto error
           end
       
       ---- added code below to manage PMSS info when vendor changes #134782, 137679

       update dbo.bPMSS set bPMSS.SendToFirm = f.FirmNumber, bPMSS.SendToContact = null
       from dbo.bPMSS s
       join inserted i on s.SLCo = i.SLCo and s.SL = i.SL
       left join dbo.bPMFM f on f.VendorGroup = i.VendorGroup and f.Vendor = i.Vendor
       where f.Vendor is not null 
       
       update bPMSS set bPMSS.SendToFirm = null, bPMSS.SendToContact = null
       from bPMSS s
       join inserted i on s.SLCo=i.SLCo and s.SL=i.SL
       left join dbo.bPMFM f on f.VendorGroup = i.VendorGroup and f.Vendor = i.Vendor
       where f.Vendor is null 
		
       end
       
   end

-- added this section for PM only. If the compliance group has changed and the
-- status of the subcontract is pending (3) only and the old compliance group is null
-- and the new compliance group is not null, then initialize the compliance codes for
-- the new compliance group
if update(CompGroup)
BEGIN
	select @slco=min(SLCo) from inserted
	while @slco is not null
	begin
		select @sl=min(SL) from inserted where SLCo=@slco
		while @sl is not null
		begin
			-- get inserted subcontract info
			select @vendorgroup=VendorGroup, @vendor=Vendor, @compgroup=CompGroup
			from inserted where SLCo=@slco and SL=@sl
			-- get deleted subcontract info
			select @oldcompgroup=CompGroup from deleted where SLCo=@slco and SL=@sl
			-- skip if @compgroup is null or @oldcompgroup=@compgroup #129360
			if isnull(@compgroup,'') = '' goto next_inserted
			if isnull(@oldcompgroup,'') = isnull(@compgroup,'') goto next_inserted

			select @compcode=Min(CompCode)
			from bAPVC where APCo=@slco and VendorGroup=@vendorgroup and Vendor=@vendor
			while @compcode is not null
				begin
				-- check if currently exists
				if exists (select 1 from bSLCT with (nolock) where SLCo=@slco and SL=@sl and CompCode=@compcode) goto endAPVC

				select @description=c.Description, @verify=a.Verify, @expdate=a.ExpDate, @complied=a.Complied
				from bHQCP c, bAPVC a where a.APCo=@slco and a.VendorGroup=@vendorgroup and a.Vendor=@vendor
				and a.CompCode=c.CompCode and a.CompCode=@compcode and c.AllInvoiceYN='N'	--DC 30178
				if @@rowcount=0 goto endAPVC

				select @seq=isnull(max(Seq),0)+1 from bSLCT where SLCo=@slco and SL=@sl and CompCode=@compcode

				insert into bSLCT(SLCo, SL, CompCode, Seq, Description, Verify, ExpDate, Complied, VendorGroup)
				values(@slco, @sl, @compcode, @seq, @description, @verify, @expdate, @complied, @vendorgroup)
   
    		endAPVC:
    		select @compcode=Min(CompCode)
   			from APVC where APCo=@slco and VendorGroup=@vendorgroup and Vendor=@vendor and CompCode>@compcode
    		if @@rowcount=0 select @compcode=null
    		end
   
   			select @compcode=Min(x.CompCode) from bHQCX x where x.CompGroup=@compgroup
    		while @compcode is not null
    		begin
    			if exists (select 1 from bSLCT with (nolock) where SLCo=@slco and SL=@sl and CompCode=@compcode) goto endHQCP
    			select @description=Description, @verify=Verify, @complied= case CompType when 'F' then
    				'N' else null end from bHQCP, bHQCX where bHQCP.CompCode=bHQCX.CompCode
    				and bHQCX.CompGroup=@compgroup and bHQCP.CompCode=@compcode and bHQCP.AllInvoiceYN='N' --DC 30178
    			if @@rowcount=0 goto endHQCP --DC 30178

				select @seq=isnull(max(Seq),0)+1 from bSLCT where SLCo=@slco and SL=@sl and CompCode=@compcode
   
    			insert into bSLCT(SLCo, SL, CompCode, Seq, Description, Verify, VendorGroup, Complied)
    			values(@slco, @sl, @compcode, @seq, @description, @verify, @vendorgroup, @complied)
   
    			endHQCP:
    		select @compcode=Min(x.CompCode) from bHQCX x where x.CompGroup=@compgroup and CompCode>@compcode
    		if @@rowcount=0 select @compcode=null
    		end
   
		next_inserted:
		select @sl=MIN(SL) from inserted where SLCo=@slco and SL>@sl
		if @@rowcount=0 select @sl=null
		end
	select @slco=MIN(SLCo) from inserted where SLCo>@slco
	if @@rowcount=0 select @slco=null
	end
END

   
   -- HQ auditing
   if exists(select 1 from inserted i join bSLCO a on i.SLCo = a.SLCo and a.AuditSLs = 'Y')
       begin
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'JC Company', Convert(varchar(3),d.JCCo), Convert(varchar(3),i.JCCo), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where i.JCCo <> d.JCCo --and c.AuditSLs = 'Y'
   
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'Job', convert(varchar(10),d.Job), convert(varchar(10),i.Job), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
      -- join bSLCO c on c.SLCo = i.SLCo
       where i.Job <> d.Job --and c.AuditSLs = 'Y'
   
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where isnull(i.Description,'') <> isnull(d.Description,'') --and c.AuditSLs = 'Y'
   
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'Vendor Group', convert(varchar(3),d.VendorGroup), convert(varchar(3),i.VendorGroup), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where i.VendorGroup <> d.VendorGroup --and c.AuditSLs = 'Y'
   
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'Vendor', convert(varchar(6),d.Vendor), convert(varchar(6),i.Vendor), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where i.Vendor <> d.Vendor --and c.AuditSLs = 'Y'
   
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'Hold Code', d.HoldCode, i.HoldCode, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where isnull(i.HoldCode,'') <> isnull(d.HoldCode,'') --and c.AuditSLs = 'Y'
   
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'Pay Terms', d.PayTerms, i.PayTerms, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where isnull(i.PayTerms,'') <> isnull(d.PayTerms,'') --and c.AuditSLs = 'Y'
   
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'Compliance Group', d.CompGroup, i.CompGroup, getdate(), SUSER_SNAME()
		from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where isnull(i.CompGroup,'') <> isnull(d.CompGroup,'') --and c.AuditSLs = 'Y'
   
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'Status', convert(varchar(1),d.Status), convert(varchar(1),i.Status), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where i.Status <> d.Status --and c.AuditSLs = 'Y'
   
		-- #121008 Wrong date format being sent to HQMA when closing SL's.
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'Month Closed', convert(varchar(8),d.MthClosed,1), convert(varchar(8),i.MthClosed,1), getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where isnull(i.MthClosed,0) <> isnull(d.MthClosed,0) --and c.AuditSLs = 'Y'
   
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'Approved', d.Approved, i.Approved, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where isnull(i.Approved,'') <> isnull(d.Approved,'') --and c.AuditSLs = 'Y'
   
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'ApprovedBy', d.ApprovedBy, i.ApprovedBy, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       --join bSLCO c on c.SLCo = i.SLCo
       where isnull(i.ApprovedBy,'') <> isnull(d.ApprovedBy,'') --and c.AuditSLs = 'Y'
       
       ----TK-18033
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'ApprovalRequired', d.ApprovalRequired, i.ApprovalRequired, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       where isnull(i.ApprovalRequired,'') <> isnull(d.ApprovalRequired,'') 

       --DC #129892
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'MaxRetgOpt', d.MaxRetgOpt, i.MaxRetgOpt, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       where isnull(i.MaxRetgOpt,'') <> isnull(d.MaxRetgOpt,'') 

       --DC #129892
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'MaxRetgPct', d.MaxRetgPct, i.MaxRetgPct, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       where isnull(i.MaxRetgPct,'') <> isnull(d.MaxRetgPct,'') 

       --DC #129892
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'MaxRetgAmt', d.MaxRetgAmt, i.MaxRetgAmt, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       where isnull(i.MaxRetgAmt,'') <> isnull(d.MaxRetgAmt,'') 

       --DC #129892
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'InclACOinMaxYN', d.InclACOinMaxYN, i.InclACOinMaxYN, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       where isnull(i.InclACOinMaxYN,'') <> isnull(d.InclACOinMaxYN,'') 

       --DC #129892
       insert into bHQMA select 'bSLHD', 'SL:' + i.SL, i.SLCo, 'C',
        	'MaxRetgDistStyle', d.MaxRetgDistStyle, i.MaxRetgDistStyle, getdate(), SUSER_SNAME()
       from inserted i
       join deleted d on i.SLCo = d.SLCo and i.SL = d.SL
       where isnull(i.MaxRetgDistStyle,'') <> isnull(d.MaxRetgDistStyle,'') 

       end
   
Trigger_Skip:
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update SL Header'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction

GO
ALTER TABLE [dbo].[bSLHD] ADD CONSTRAINT [CK_bSLHD_ApprovalRequired] CHECK (([ApprovalRequired]='N' OR [ApprovalRequired]='Y'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bSLHD] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bSLHD_SL] ON [dbo].[bSLHD] ([SLCo], [SL]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLHD].[Purge]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bSLHD].[Purge]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLHD].[Approved]'
GO
