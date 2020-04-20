CREATE TABLE [dbo].[bPOHD]
(
[POCo] [dbo].[bCompany] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[OrderDate] [dbo].[bDate] NULL,
[OrderedBy] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ExpDate] [dbo].[bDate] NULL,
[Status] [tinyint] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[ShipLoc] [dbo].[bShipLoc] NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[ShipIns] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[CompGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[MthClosed] [dbo].[bMonth] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Approved] [dbo].[bYN] NULL,
[ApprovedBy] [dbo].[bVPUserName] NULL,
[Purge] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[AddedMth] [dbo].[bMonth] NULL,
[AddedBatchID] [dbo].[bBatchID] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Attention] [dbo].[bDesc] NULL,
[PayAddressSeq] [tinyint] NULL,
[POAddressSeq] [tinyint] NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[POCloseBatchID] [dbo].[bBatchID] NULL,
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

/****** Object:  Trigger dbo.btPOHDd    Script Date: 8/28/99 9:38:06 AM ******/
CREATE  trigger [dbo].[btPOHDd] on [dbo].[bPOHD] for DELETE as

/*--------------------------------------------------------------
    *  Created By: kb 6/18/97
    *  Modified: EN 11/12/98
    *	         LM 10/7/99 - changed delete of PMMF items to just removing PO & POItem #'s
    *           GG 10/26/99 - cleanup
    *			 GF 09/30/2002 - Issue #18628 Changed PMMF update to set PO and POItem to null.
    *			 GF 01/15/2003 - Issue #19956 Changed PMMF update to not set Send flag to 'N'
	*			 GF 02/14/2006 - issue #120167 when purging to not update bPMMF.
	*			 JonathanP 05/29/2009 - Issue 133438 Added attachment deletion code.
	*				GF 12/21/2010 - issue #141957 record association
	*			GF 01/26/2011 - tfs #398
	*			GF 04/06/2011 - TK-03569
	*			GP 06/11/2012 - TK-15642 Added update to Requisition Lines to clear PO
	*
    *
    *  Delete trigger for PO Header
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for PO Items
   if exists(select * from deleted d join bPOIT t on d.POCo = t.POCo and d.PO = t.PO)
   	begin
   	select @errmsg = 'PO Items exist '
   	goto error
   	end
   
   -- remove Compliance entries
   delete bPOCT
   from bPOCT b join deleted d on b.POCo = d.POCo and b.PO = d.PO



-- -- -- Update PMMF entries, set PO and POItem to null
-- -- -- if running PO Purge and POHD.Purge flag is 'Y'
-- -- -- then do not update PMMF.
update bPMMF set PO = null, POItem = null, InterfaceDate = null
from bPMMF p join deleted d on p.POCo = d.POCo and p.PO = d.PO and d.Purge = 'N'

-- Delete reference to this PO on requisition records
UPDATE dbo.bRQRL
SET PO = NULL, POItem = NULL
FROM dbo.bRQRL r
JOIN DELETED d ON d.POCo = r.RQCo AND d.PO = r.PO

---- delete purchase order co (PMPOCO) TK-03569
DELETE dbo.vPMPOCO FROM dbo.vPMPOCO s JOIN deleted d ON s.POCo=d.POCo AND s.PO=d.PO

---- delete PM distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='POHD' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='POHD' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='POHD' and i.SourceKeyId=d.KeyID

---- when the record is related to a project issue PMIM
---- we need to add a delete action recorded in history for the issue
---- noting that the type and code with a description ws deleted.
---- record side. TFS #398
---- delete
DELETE dbo.vPMIssueHistory FROM deleted d WHERE RelatedTableName = 'bPOHD' AND RelatedKeyID = d.KeyID
---- insert
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPOHD', d.KeyID, null, null, x.Issue, 'D',
		'POCo: ' + CONVERT(VARCHAR(3), ISNULL(d.POCo,'')) + ' PO: ' + ISNULL(d.PO,'') + ' : ' + ISNULL(d.Description,'')	
from deleted d
JOIN dbo.vPMRelateRecord r ON r.RecTableName = 'POHD' AND r.RECID = d.KeyID AND r.LinkTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.LINKID
WHERE d.KeyID=r.RECID
---- link side
INSERT dbo.vPMIssueHistory (IssueKeyID,RelatedTableName,RelatedKeyID,Co,Project,Issue,ActionType,RelatedDeleteAction)
SELECT x.KeyID, 'bPOHD', d.KeyID, null, null, x.Issue, 'D',
		'POCo: ' + CONVERT(VARCHAR(3), ISNULL(d.POCo,'')) + ' PO: ' + ISNULL(d.PO,'') + ' : ' + ISNULL(d.Description,'')
from deleted d
JOIN dbo.vPMRelateRecord r ON r.LinkTableName = 'POHD' AND r.LINKID = d.KeyID AND r.RecTableName = 'PMIM'
JOIN dbo.bPMIM x ON x.KeyID = r.RECID
WHERE d.KeyID=r.LINKID

---- delete associations if any from both sides - #141957
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='POHD' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='POHD' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


-- -- -- HQ Audit
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPOHD',' PO: ' + d.PO, d.POCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d
join bPOCO c ON d.POCo = c.POCo
where c.AuditPOs = 'Y' and d.Purge = 'N'


-- Delete attachments if they exist. Make sure UniqueAttchID is not null
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
  select AttachmentID, suser_name(), 'Y' 
	  from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
	  where d.UniqueAttchID is not null    


return



error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PO Header (bPOHD)'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPOHDi    Script Date: 8/28/99 9:38:07 AM ******/
   CREATE    trigger [dbo].[btPOHDi] on [dbo].[bPOHD] for INSERT as
    

/*--------------------------------------------------------------
      *  Created By:
      *  Modified: EN 11/11/98
      *            LM 11/24/98 - Status may be open or pending (inserted as pending when coming from PM)
      *            kb 2/1/99
      *            GG 10/27/99 - Cleanup
      *            GF 09/20/2000 - Not adding vendor compliance, error occurs if dups between
      *                            vendor and group compliance codes.
      *			CMW 07/08/02 - Vendor compliance missing on ADD if CompGroup is NULL in POHD.
      *			MV 02/11/03 - #17821 - don't add compliance code to POCT if it's AllInvoiceYN.
      *			GF 10/25/2004 - issue #24165 need to set ship address to Job address when POHD record
      *							added from PM (status 3).
      *			MV 10/25/04 - #25834 don't insert POCT if no HQ compliance codes.
	*			DC 03/07/08 - Issue #127075:  Modify PO/RQ  for International addresses
	*			GP 7/27/2011 - TK-07144 changed bPO to varchar(30)
	*
      *
      * Insert trigger for PO Header
      * Adds PO Compliance entries
      *--------------------------------------------------------------*/
   declare @numrows int, @opencursor tinyint, @errmsg varchar(255), @validcnt int, @nullcnt int,
   	@poco bCompany, @po varchar(30), @compcode bCompCode,  @vendorgroup bGroup,
   	@vendor bVendor, @compgroup varchar(10), @description bDesc, @verify bYN,
   	@expdate bDate, @complied bYN, @ctseq int, @jcco bCompany, @job bJob, @status tinyint,
   	@address varchar(60), @city varchar(30), @state varchar(4), @zip bZip, @address2 varchar(60)
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
    -- validate PO Company
    select @validcnt = count(*)
    from bPOCO c
    JOIN inserted i on i.POCo = c.POCo
    if @validcnt<>@numrows
        begin
     	select @errmsg = 'Invalid PO Company '
     	goto error
     	end
    --validate Vendor Group
    select @validcnt = count(*)
    from bHQGP g
    JOIN inserted i on i.VendorGroup = g.Grp
    if @validcnt <> @numrows
        begin
     	select @errmsg = 'Invalid Vendor Group '
     	goto error
     	end
    select @validcnt = count(*)
    from bHQCO c
    JOIN inserted i on i.POCo = c.HQCo and i.VendorGroup = c.VendorGroup
    if @validcnt <> @numrows
     	begin
     	select @errmsg = 'Invalid Vendor Group for this Company '
     	goto error
     	end
    --validate Vendor
    select @validcnt = count(*)
    from bAPVM r
    JOIN inserted i on i.VendorGroup = r.VendorGroup and i.Vendor = r.Vendor
    if @validcnt <> @numrows
     	begin
     	select @errmsg = 'Invalid Vendor '
     	goto error
     	end
    select @validcnt = count(*)
    from bAPVM r
    JOIN inserted i on i.VendorGroup = r.VendorGroup and i.Vendor = r.Vendor and r.ActiveYN = 'Y'
    if @validcnt <> @numrows
     	begin
     	select @errmsg = 'Inactive Vendor '
     	goto error
     	end
    --validate Hold Code */
    select @nullcnt = count(*) from inserted where HoldCode is null
    select @validcnt = count(*)
    from bHQHC r
    join inserted i on r.HoldCode = i.HoldCode
    where i.HoldCode is not null
    if @validcnt + @nullcnt <> @numrows
     	begin
     	select @errmsg = 'Invalid Hold Code.'
     	goto error
     	end
    --validate Pay Terms
    select @nullcnt = count(*) from inserted where PayTerms is null
    select @validcnt = count(*)
    from bHQPT p
    join inserted i on p.PayTerms = i.PayTerms
    where i.PayTerms is not null
    if @validcnt + @nullcnt <> @numrows
     	begin
     	select @errmsg = 'Invalid Payment Terms.'
     	goto error
     	end
    --validate Compliance Group
    select @nullcnt = count(*) from inserted where CompGroup is null
    select @validcnt = count(*)
    from bHQCG r
    JOIN inserted i on r.CompGroup = i.CompGroup
    where i.CompGroup is not null
    if @validcnt + @nullcnt <> @numrows
     	begin
     	select @errmsg = 'Invalid Compliance Group.'
     	goto error
     	end
    -- validate Status
    if exists(select * from inserted where Status not in (0,3))
     	begin
     	select @errmsg = 'Status must be (Pending or Open) '
     	goto error
     	end
    --validate Month Closed
    if exists(select * from inserted where MthClosed is not null)
     	begin
     	select @errmsg = 'Month Closed must be null '
     	goto error
     	end
    --validate InUseMth
    if exists(select * from inserted where InUseMth is not null)
     	begin
     	select @errmsg = '(InUseMonth) must be null '
     	goto error
     	end
    --validate InUseBatchId
    if exists(select * from inserted where InUseBatchId is not null)
        begin
     	select @errmsg = '(InUseBatchId) must be null '
     	goto error
     	end
    --validate Purge flag
    if exists(select * from inserted where Purge <> 'N')
     	begin
     	select @errmsg = 'Purge flag must be set to N '
     	goto error
     	end
   
   
   
   -- -- -- if status = pending(3) then from PM need to update job address info
   -- -- -- initialize Compliance for all new POs (Pending or Open)
   -- begin process
   if @numrows = 1
   	select @poco=POCo, @po=PO, @jcco=JCCo, @job=Job, @vendorgroup=VendorGroup, @vendor=Vendor, 
   			@compgroup=CompGroup, @status=Status
   	from inserted
   else
   	begin
   	-- use a cursor to process each updated row
   	declare bPOHD_insert cursor LOCAL FAST_FORWARD
   	for select POCo, PO, JCCo, Job, VendorGroup, Vendor, CompGroup, Status
   	from inserted
   
   	open bPOHD_insert
   	set @opencursor = 1
   	
   	fetch next from bPOHD_insert into @poco, @po, @jcco, @job, @vendorgroup, @vendor, @compgroup, @status
   	
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   
   insert_check:
   -- -- -- if @job is not null and status = pending(3) then get JCJM info
   if @job is not null and @status = 3
   	begin
   	-- -- -- get JCJM info
   	select @address=ShipAddress, @city=ShipCity, @state=ShipState,
   		   @zip=ShipZip, @address2=ShipAddress2
   	from bJCJM WITH (NOLOCK) where JCCo = @jcco and Job = @job
   
   	-- -- -- update PO with JCJM info if missing
   	update bPOHD set Address=@address, City=@city, State=@state, Zip=@zip, Address2=@address2
   	where POCo=@poco and PO=@po and Address is null and City is null and State is null
   	and Zip is null and Address2 is null
   	end
   
   
   -- -- -- cycle through Vendor Compliance
   set @compcode = null
   select @compcode = min(CompCode) from bAPVC 
   where APCo=@poco and VendorGroup=@vendorgroup and Vendor=@vendor
   while @compcode is not null
   begin
   	-- -- -- skip if already in PO Compliance Tracking
   	if exists (select * from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode) goto APVC_end
   	-- -- -- get default info
   	select @description=c.Description, @verify=a.Verify, @expdate=a.ExpDate, @complied=a.Complied
   	from bHQCP c, bAPVC a where a.APCo=@poco and a.VendorGroup=@vendorgroup and a.Vendor=@vendor
   	and a.CompCode=c.CompCode and a.CompCode=@compcode and c.AllInvoiceYN='N' --17821
   	if @@rowcount=0 goto APVC_end
   	-- -- -- add to PO Compliance Tracking
   	select @ctseq=isnull(max(Seq),0)+1 from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode
   	insert into bPOCT(POCo, PO, CompCode, Seq, VendorGroup, Description, Verify, ExpDate, Complied)
   	values(@poco, @po, @compcode, @ctseq, @vendorgroup, @description, @verify, @expdate, @complied)
   APVC_end:
   select @compcode = min(CompCode) from bAPVC 
   where APCo=@poco and VendorGroup=@vendorgroup and Vendor=@vendor and CompCode>@compcode
   if @@rowcount = 0 select @compcode = null
   end
   
   
   -- cycle through Compliance Codes in Compliance Group
   set @compcode=null
   select @compcode=min(CompCode) from bHQCX where CompGroup=@compgroup
   while @compcode is not null
   begin
   	-- -- --skip if already in PO Compliance Tracking
   	if exists (select * from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode) goto HQCP_end
   	-- -- -- get default info
   	select @description=Description, @verify=Verify, 
   			@complied= case CompType when 'F' then 'N' else null end 
   	from bHQCP, bHQCX where bHQCP.CompCode=bHQCX.CompCode
   	and bHQCX.CompGroup=@compgroup and bHQCP.CompCode=@compcode and bHQCP.AllInvoiceYN = 'N' --17821
   	if @@rowcount=0 goto HQCP_end --#25834
   	-- -- -- insert compliance code
   	select @ctseq=isnull(max(Seq),0)+1 from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode
   	insert into bPOCT(POCo, PO, CompCode, Seq, VendorGroup, Description, Verify, Complied)
   	values(@poco, @po, @compcode, @ctseq, @vendorgroup, @description, @verify, @complied)
   HQCP_end:
   select @compcode=min(CompCode) from bHQCX where CompGroup=@compgroup and CompCode >@compcode
   if @@rowcount = 0 select @compcode = null
   end
   
   
   -- finished with validation and updates (except HQ Audit)
   Valid_Finished:
   if @numrows > 1
   	begin
   	fetch next from bPOHD_insert into @poco, @po, @jcco, @job, @vendorgroup, @vendor, @compgroup, @status
    	if @@fetch_status = 0
    		goto insert_check
    	else
    		begin
    		close bPOHD_insert
    		deallocate bPOHD_insert
   		set @opencursor = 0
    		end
    	end
   
   
   
   -- -- -- -- initialize Compliance for all new POs (Pending or Open)
   -- -- -- select @compcode = null
   -- -- -- select @poco = min(POCo) from inserted  -- get 1st PO Company
   -- -- -- while @poco is not null
   -- -- --   begin
   -- -- --   select @po = min(PO) from inserted where POCo = @poco   -- get 1st PO for Company
   -- -- --   while @po is not null
   -- -- --     begin
   -- -- --     -- get PO Header info
   -- -- --     select @vendorgroup=VendorGroup, @vendor=Vendor, @compgroup=CompGroup
   -- -- --     from inserted where POCo=@poco and PO=@po
   -- -- -- 	-- CMW 07/08/02 issue # 17639
   -- -- --     -- if @compgroup is not null
   -- -- --     --  begin
   -- -- --       -- cycle through Vendor Compliance
   -- -- --       select @compcode = min(CompCode) from bAPVC where APCo=@poco and VendorGroup=@vendorgroup and Vendor=@vendor
   -- -- --       while @compcode is not null
   -- -- --         begin
   -- -- --         -- skip if already in PO Compliance Tracking
   -- -- --         if exists (select * from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode) goto APVC_end
   -- -- --         -- get default info
   -- -- --  		select @description=c.Description, @verify=a.Verify, @expdate=a.ExpDate, @complied=a.Complied
   -- -- --  		from bHQCP c, bAPVC a where a.APCo=@poco and a.VendorGroup=@vendorgroup and a.Vendor=@vendor
   -- -- --  		and a.CompCode=c.CompCode and a.CompCode=@compcode and c.AllInvoiceYN='N' --17821
   -- -- --  		if @@rowcount=0 goto APVC_end
   -- -- --         -- add to PO Compliance Tracking
   -- -- --         select @ctseq=isnull(max(Seq),0)+1 from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode
   -- -- --         insert into bPOCT(POCo, PO, CompCode, Seq, VendorGroup, Description, Verify, ExpDate, Complied)
   -- -- --         values(@poco, @po, @compcode, @ctseq, @vendorgroup, @description, @verify, @expdate, @complied)
   -- -- --         APVC_end:
   -- -- --         select @compcode = min(CompCode) from bAPVC where APCo=@poco and VendorGroup=@vendorgroup and Vendor=@vendor and CompCode>@compcode
   -- -- --         if @@rowcount = 0 select @compcode = null
   -- -- --         end
   -- -- -- 
   -- -- --       -- cycle through Compliance Codes in Compliance Group
   -- -- --       select @compcode=null
   -- -- --       select @compcode=min(CompCode) from bHQCX where CompGroup=@compgroup
   -- -- --       while @compcode is not null
   -- -- --         begin
   -- -- --         -- skip if already in PO Compliance Tracking
   -- -- --         if exists (select * from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode) goto HQCP_end
   -- -- --         -- get default info
   -- -- --  		select @description=Description, @verify=Verify, @complied= case CompType when 'F' then
   -- -- --  		'N' else null end from bHQCP, bHQCX where bHQCP.CompCode=bHQCX.CompCode
   -- -- --         and bHQCX.CompGroup=@compgroup and bHQCP.CompCode=@compcode and bHQCP.AllInvoiceYN = 'N' --17821
   -- -- --         -- insert compliance code
   -- -- --  		select @ctseq=isnull(max(Seq),0)+1 from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode
   -- -- --         insert into bPOCT(POCo, PO, CompCode, Seq, VendorGroup, Description, Verify, Complied)
   -- -- --         values(@poco, @po, @compcode, @ctseq, @vendorgroup, @description, @verify, @complied)
   -- -- --         HQCP_end:
   -- -- --         select @compcode=min(CompCode) from bHQCX where CompGroup=@compgroup and CompCode >@compcode
   -- -- --         if @@rowcount = 0 select @compcode = null
   -- -- --         end
   -- -- --       --end
   -- -- --       -- get next PO
   -- -- --       select @po = min(PO) from inserted where POCo = @poco and PO > @po
   -- -- --       if @@rowcount = 0 select @po = null
   -- -- --     end
   -- -- --     -- get next PO Company
   -- -- --     select @poco = min(POCo) from inserted where POCo > @poco
   -- -- --     if @@rowcount = 0 select @poco = null
   -- -- -- end
   
   
   -- -- -- HQ Auditing
   INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bPOHD',' PO: ' + i.PO, i.POCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i
   join bPOCO c on c.POCo = i.POCo
   where i.POCo = c.POCo and c.AuditPOs = 'Y'
   
   
   
   return
   
   
   
   error:
   	if @opencursor = 1
    		begin
    		close bPOHD_insert
    		deallocate bPOHD_insert
   		set @opencursor = 0
    		end
   		
   	select @errmsg = @errmsg + ' - cannot insert PO Header'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPOHDu    Script Date: 8/28/99 9:38:07 AM ******/
   CREATE   trigger [dbo].[btPOHDu] on [dbo].[bPOHD] for UPDATE as
   

/*--------------------------------------------------------------
    *  Created By : EN 11/12/98
    *  Modified By: EN 1/23/99
    *          GR 8/10/99  typo at the select statement of @Status corrected
    *          GG 10/26/99 - removed pseudo cursor for PMMF update
    *                      - cleaned up HQ auditing
    *          kb 10/1/1  issue #14729
    *			GF 06/13/2002 - added code to create compliance codes if the PO status is pending(3)
    *							and the old compliance group is null and new compliance group is not. issue #17640
    *			MV 03/06/03 - #20094 - create compliance codes for any PO status, not just pending(3).
    *			ES 03/30/04 - #24146 - only check Compliance Group if it is updated
	*			DC 02/12/08 - #30178 - SLHD/POHD update triggers should not add All Invoice Comp codes.  
	*			JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
	*			DC 01/26/09 - #129105 - Improve Compliance handling in PO
    *			DC 03/26/10 - #137268 - Performance issue when clearing large POXB batch
				AR 05/11/10	- #137268 - Removed unpivot when testing on another server reveal performance was on par
											with with original method, checking if the column is updated now, to reduce
											the overhead of unessecary compares. To reduce more overhead, create
											FKs instead of doing the weird count checks, probably gain 15-20% perf
	*			GP 7/27/2011 - TK-07144 changed bPO to varchar(30)							
	*			
	*										
    *  Update trigger for PO Header
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int,
    		@poco bCompany, @po varchar(30), @vendorgroup bGroup, @compcode bCompCode,
    		@description bDesc, @seq smallint, @vendor bVendor, @verify bYN,
    		@compgroup varchar(10), @expdate bDate, @complied bYN, @status tinyint,
   		@oldcompgroup varchar(10)
   
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
    --If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bPOHD', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_Skip
	END    
   
   -- verify primary key not changed
   select @validcnt = count(*) from inserted i
   join deleted d on d.POCo = i.POCo and d.PO = i.PO
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change PO Co# or PO '
    	goto error
    	end
   -- validate Compliance Group
   if update(CompGroup)
      begin
      select @nullcnt = count(*) from inserted where CompGroup is null
      select @validcnt = count(*)
      from inserted i
      join bHQCG r on r.CompGroup = i.CompGroup
      where i.CompGroup is not null
      if @validcnt + @nullcnt <> @numrows
                begin
    	select @errmsg = 'Invalid Compliance Group '
    	goto error
    	end
      end
   -- validate Vendor Group
   select @validcnt = count(*) from inserted i
   join bHQGP g on i.VendorGroup = g.Grp

   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Invalid Vendor Group '
    	goto error
    	end
   select @validcnt = count(*) from inserted i
   join bHQCO c on i.POCo = c.HQCo and i.VendorGroup = c.VendorGroup
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Vendor Group for this Company '
    	goto error
    	end
   -- validate Vendor
   select @validcnt = count(*) from inserted i
   join bAPVM r on i.VendorGroup = r.VendorGroup and i.Vendor = r.Vendor
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Invalid Vendor '
    	goto error
    	end
   if update(Vendor) -- issue #14729
       begin
       select @validcnt = count(*) from inserted i
         join bAPVM r on i.VendorGroup = r.VendorGroup and i.Vendor = r.Vendor
         where r.ActiveYN = 'Y'
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Inactive Vendor '
        	goto error
        	end
       end
   -- validate Hold Code
   select @nullcnt = count(*) from inserted where HoldCode is null
   select @validcnt = count(*) from inserted i
   join bHQHC r on r.HoldCode = i.HoldCode
   where i.HoldCode is not null
   if @validcnt + @nullcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Hold Code '
    	goto error
    	end
   -- validate Pay Terms
   if update(PayTerms)
       begin
       select @nullcnt = count(*) from inserted where PayTerms is null
       select @validcnt = count(*) from inserted i
       join bHQPT p on p.PayTerms = i.PayTerms
       where i.PayTerms is not null
       if @validcnt + @nullcnt <> @numrows
        	begin
        	select @errmsg = 'Invalid Payment Terms '
        	goto error
        	end
       end
   -- check Month Closed
   if exists(select * from inserted where (MthClosed is null and Status = 2)
       or (MthClosed is not null and Status <> 2))
       begin
    	select @errmsg = 'Month Closed must not be set unless PO is Closed '
    	goto error
    	end
   
   -- validate Purge flag - mut be 'closed'
   if exists(select * from inserted where Purge = 'Y' and Status <> 2)
       begin
    	select @errmsg = 'POs must be (closed) before purging.'
    	goto error
    	end
   
   
   -- validate Status changes
   if exists(select * from inserted i join bPOIT t on i.POCo = t.POCo and i.PO = t.PO
       where i.Status = 1 and t.UM = 'LS' and t.RecvdCost <> t.InvCost)
       begin
       select @errmsg = 'Completed POs require Received and Invoiced costs to be equal on all Lump Sum Items '
       goto error
       end
   if exists(select * from inserted i join bPOIT t on i.POCo = t.POCo and i.PO = t.PO
       where i.Status = 1 and t.UM <> 'LS' and t.RecvdUnits <> t.InvUnits)
       begin
       select @errmsg = 'Completed POs require Received and Invoiced units to be equal on all unit based Items '
       goto error
       end
   
   -- update Required Date on PM Materials
   update bPMMF set ReqDate = i.ExpDate
   from bPMMF m
   join inserted i on m.POCo = i.POCo and m.PO = i.PO
   join deleted d on i.POCo = d.POCo and i.PO = d.PO
   where isnull(d.ExpDate,'') <> isnull(i.ExpDate,'') and i.ExpDate is not null
   and m.ReqDate is null     -- only if null
   
   -- update Vendor on PM Materials
   update bPMMF set VendorGroup = i.VendorGroup, Vendor = i.Vendor
   from bPMMF m
   join inserted i on m.POCo = i.POCo and m.PO = i.PO
   join deleted d on i.POCo = d.POCo and i.PO = d.PO
   where d.VendorGroup <> i.VendorGroup or d.Vendor <> i.Vendor
   
   
   /* added this section for PM only. If the compliance group has changed and the
    status of the purchase order is pending (3) only and the old compliance group is null
    and the new compliance group is not null, then initialize the compliance codes for
    the new compliance group*/
   if update(CompGroup)
   BEGIN
   	select @poco=min(POCo) from inserted
   	while @poco is not null
       begin
       select @po=min(PO) from inserted where POCo=@poco
       while @po is not null
    	begin
   		-- get inserted subcontract info
    		select @vendorgroup=VendorGroup, @vendor=Vendor, @compgroup=CompGroup, @status=Status
   		from inserted where POCo=@poco and PO=@po
   		-- get deleted purchase order info
   		select @oldcompgroup=CompGroup from deleted where POCo=@poco and PO=@po
   		-- skip if status not 3 or @oldcompgroup not null or @oldcompgroup=@compgroup
   		--if isnull(@status,0) <> 3 goto next_inserted	-- #20094 - add comp codes for any status
   		--if isnull(@oldcompgroup,'') <> '' goto next_inserted  --DC #129105
   		if isnull(@compgroup,'') = '' goto next_inserted  
   
   		select @compcode=Min(CompCode)
   		from bAPVC where APCo=@poco and VendorGroup=@vendorgroup and Vendor=@vendor
    		while @compcode is not null
    		begin
   			-- check if currently exists
   	 		if exists (select POCo from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode) goto endAPVC
   	
   	 		select @description=c.Description, @verify=a.Verify, @expdate=a.ExpDate, @complied=a.Complied
   	 		from bHQCP c, bAPVC a where a.APCo=@poco and a.VendorGroup=@vendorgroup and a.Vendor=@vendor
   	 		and a.CompCode=c.CompCode and a.CompCode=@compcode and c.AllInvoiceYN = 'N' --DC 30178
   	 		if @@rowcount=0 goto endAPVC
   	
   	 		select @seq=isnull(max(Seq),0)+1 from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode
   	
   	 		insert into bPOCT(POCo, PO, CompCode, Seq, Description, Verify, ExpDate, Complied, VendorGroup)
   	 		values(@poco, @po, @compcode, @seq, @description, @verify, @expdate, @complied, @vendorgroup)
   
    		endAPVC:
           select @compcode = min(CompCode) from bAPVC where APCo=@poco and VendorGroup=@vendorgroup and Vendor=@vendor and CompCode>@compcode
           if @@rowcount = 0 select @compcode = null
           end
   
   		-- cycle through Compliance Codes in Compliance Group
   		select @compcode=null
   		select @compcode=min(CompCode) from bHQCX where CompGroup=@compgroup
   		while @compcode is not null
           begin
   	        -- skip if already in PO Compliance Tracking
   	        if exists (select * from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode) goto endHQCP
   	        -- get default info
   	 		select @description=Description, @verify=Verify, @complied= case CompType when 'F' then
   	 		'N' else null end from bHQCP, bHQCX where bHQCP.CompCode=bHQCX.CompCode
   	        and bHQCX.CompGroup=@compgroup and bHQCP.CompCode=@compcode and bHQCP.AllInvoiceYN = 'N' --DC 30178
   	        if @@rowcount=0 goto endHQCP --DC 30178

			-- insert compliance code
   	 		select @seq=isnull(max(Seq),0)+1 from bPOCT where POCo=@poco and PO=@po and CompCode=@compcode

   	        insert into bPOCT(POCo, PO, CompCode, Seq, VendorGroup, Description, Verify, Complied)
   	        values(@poco, @po, @compcode, @seq, @vendorgroup, @description, @verify, @complied)
   	        
			endHQCP:
   	        select @compcode=min(CompCode) from bHQCX where CompGroup=@compgroup and CompCode >@compcode
   	        if @@rowcount = 0 select @compcode = null
           end
   
   	next_inserted:
   	select @po=MIN(PO) from inserted where POCo=@poco and PO>@po
    	if @@rowcount=0 select @po=null
    	end
   	select @poco=MIN(POCo) from inserted where POCo>@poco
       if @@rowcount=0 select @poco=null
       end
   END
     
   -- HQ Auditing
   IF EXISTS ( SELECT   1
               FROM     inserted i
                        JOIN bPOCO a ON i.POCo = a.POCo
                                        AND a.AuditPOs = 'Y' ) 
    BEGIN
    -- 137268: removing the unpivot because timing did not improve significantly, reads did improve
    -- pivot pushes from disk to CPU because of the algorithms 
    -- when under load on test server.  Using a more tedious method of checking if the column is updated
    -- this prevents excess reads to the database and improves performance
    -- will break down when a lot of the columns are updated versus the pivot
        IF UPDATE(VendorGroup) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'VendorGroup',
                                CONVERT(varchar(3), d.VendorGroup),
                                CONVERT(varchar(3), i.VendorGroup),
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   d.VendorGroup <> i.VendorGroup
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(Vendor) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'Vendor',
                                CONVERT(varchar(6), d.Vendor),
                                CONVERT(varchar(6), i.Vendor),
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   d.Vendor <> i.Vendor
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE([Description]) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'Description',
                                d.Description,
                                i.Description,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.Description, '') <> ISNULL(i.Description,
                                                              '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(OrderDate) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'OrderDate',
                                CONVERT(varchar(8), d.OrderDate, 1),
                                CONVERT(varchar(8), i.OrderDate, 1),
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.OrderDate, '') <> ISNULL(i.OrderDate,
                                                              '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(OrderedBy) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'OrderedBy',
                                d.OrderedBy,
                                i.OrderedBy,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.OrderedBy, '') <> ISNULL(i.OrderedBy,
                                                              '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(ExpDate) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'ExpDate',
                                CONVERT(varchar(8), d.ExpDate, 1),
                                CONVERT(varchar(8), i.ExpDate, 1),
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.ExpDate, '') <> ISNULL(i.ExpDate, '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE([Status]) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'Status',
                                CONVERT(varchar(3), d.Status),
                                CONVERT(varchar(3), i.Status),
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   d.Status <> i.Status
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(JCCo) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'JCCo',
                                CONVERT(varchar(3), d.JCCo),
                                CONVERT(varchar(3), i.JCCo),
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.JCCo, 0) <> ISNULL(i.JCCo, 0)
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(Job) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'Job',
                                CONVERT(varchar(10), d.Job),
                                CONVERT(varchar(10), i.Job),
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.Job, '') <> ISNULL(i.Job, '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(INCo) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'INCo',
                                CONVERT(varchar(3), d.INCo),
                                CONVERT(varchar(3), i.INCo),
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.INCo, 0) <> ISNULL(i.INCo, 0)
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(Loc) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'Location',
                                d.Loc,
                                i.Loc,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.Loc, '') <> ISNULL(i.Loc, '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(ShipLoc) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'ShipLoc',
                                d.ShipLoc,
                                i.ShipLoc,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.ShipLoc, '') <> ISNULL(i.ShipLoc, '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE([Address]) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'Address',
                                d.Address,
                                i.Address,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.Address, '') <> ISNULL(i.Address, '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(City) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'City',
                                d.City,
                                i.City,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.City, '') <> ISNULL(i.City, '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE([State]) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'State',
                                d.State,
                                i.State,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.State, '') <> ISNULL(i.State, '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(Zip) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'Zip',
                                d.Zip,
                                i.Zip,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.Zip, '') <> ISNULL(i.Zip, '')
                                AND a.AuditPOs = 'Y'
            END
		--DC 127571
        IF UPDATE(Country) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'Country',
                                d.Country,
                                i.Country,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.Country, '') <> ISNULL(i.Country, '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(ShipIns) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'ShipIns',
                                d.ShipIns,
                                i.ShipIns,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.ShipIns, '') <> ISNULL(i.ShipIns, '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(HoldCode) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'HoldCode',
                                d.HoldCode,
                                i.HoldCode,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.HoldCode, '') <> ISNULL(i.HoldCode,
                                                              '')
                                AND a.AuditPOs = 'Y'
            END
		
        IF UPDATE(PayTerms) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'PayTerms',
                                d.PayTerms,
                                i.PayTerms,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.PayTerms, '') <> ISNULL(i.PayTerms,
                                                              '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(CompGroup) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'CompGroup',
                                d.CompGroup,
                                i.CompGroup,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.CompGroup, '') <> ISNULL(i.CompGroup,
                                                              '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(MthClosed) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'MthClosed',
                                CONVERT(varchar(8), d.MthClosed, 1),
                                CONVERT(varchar(8), i.MthClosed, 1),
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.MthClosed, '') <> ISNULL(i.MthClosed,
                                                              '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(Approved) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
									
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'Approved',
                                d.Approved,
                                i.Approved,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.Approved, '') <> ISNULL(i.Approved,
                                                              '')
                                AND a.AuditPOs = 'Y'
            END
        IF UPDATE(ApprovedBy) 
            BEGIN
                INSERT  INTO dbo.bHQMA
                        ( [TableName],
                          [KeyString],
                          [Co],
                          [RecType],
                          [FieldName],
                          [OldValue],
                          [NewValue],
                          [DateTime],
                          [UserName]	
                        )
                        SELECT  'bPOHD',
                                ' PO: ' + i.PO,
                                i.POCo,
                                'C',
                                'ApprovedBy',
                                d.ApprovedBy,
                                i.ApprovedBy,
                                GETDATE(),
                                SUSER_SNAME()
                        FROM    inserted i
                                JOIN deleted d ON d.POCo = i.POCo
                                                  AND d.PO = i.PO
                                JOIN bPOCO a ON a.POCo = i.POCo
                        WHERE   ISNULL(d.ApprovedBy, '') <> ISNULL(i.ApprovedBy,
                                                              '')
                                AND a.AuditPOs = 'Y'
            END
    END
   
   
   Trigger_Skip:
   
   return
   
    error:
       select @errmsg = @errmsg + ' - cannot update PO Header'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOHD] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPOHD_POCO_PO] ON [dbo].[bPOHD] ([PO], [POCo]) INCLUDE ([Status], [Vendor], [VendorGroup]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPOHD] ON [dbo].[bPOHD] ([POCo], [PO]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPOHDUniqueAttId] ON [dbo].[bPOHD] ([UniqueAttchID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biPOHDVendor] ON [dbo].[bPOHD] ([Vendor]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOHD].[Approved]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOHD].[Purge]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPOHD].[Purge]'
GO
