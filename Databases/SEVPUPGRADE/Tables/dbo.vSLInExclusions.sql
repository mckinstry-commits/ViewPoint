CREATE TABLE [dbo].[vSLInExclusions]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Co] [dbo].[bCompany] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[Type] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PhaseGroup] [tinyint] NULL,
[Phase] [dbo].[bPhase] NULL,
[Detail] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DateEntered] [dbo].[bDate] NOT NULL,
[EnteredBy] [dbo].[bVPUserName] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.vtSLInExclusionsD    Script Date: 09/27/2010 11:37:51 ******/
CREATE       trigger [dbo].[vtSLInExclusionsD] on [dbo].[vSLInExclusions] for DELETE as
/*--------------------------------------------------------------
 *
 *  Delete trigger for SLInExclusions
 *  Created By: JG
 *  Date: 9/27/2010
 *  Modified:
 *
 *--------------------------------------------------------------*/
	/***  basic declares for SQL Triggers ****/
	declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int, @typecnt int
   
	select @numrows = @@rowcount
	if @numrows = 0 return

	set nocount on
    
	/* HQ Auditing */
	insert bHQMA select 'vSLInExclusions', 'SL:' + d.SL + ' Inclusion/Exclusion:' + convert(varchar(6),d.Seq),
			d.Co, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
	from deleted d
	join bSLCO c on d.Co = c.SLCo
	join bSLHD h on d.Co = h.SLCo and d.SL = h.SL
	where c.AuditSLs = 'Y' and h.Purge = 'N'  -- check audit and purge flags



	return



	error:
		select @errmsg = isnull(@errmsg,'') + ' - cannot delete from SLInExclusions'
		RAISERROR(@errmsg, 11, -1);
		rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.vtSLInExclusionsI    Script Date: 09/27/2010 11:37:51 ******/
CREATE       trigger [dbo].[vtSLInExclusionsI] on [dbo].[vSLInExclusions] for INSERT as
/*--------------------------------------------------------------
 *
 *  Insert trigger for SLInExclusions
 *  Created By: JG
 *  Date: 9/27/2010
 *  Modified:
 *
 *--------------------------------------------------------------*/
	/***  basic declares for SQL Triggers ****/
	declare @numrows int, @validcnt int, @errmsg varchar(255), @rcode int

	select @numrows = @@rowcount
	if @numrows = 0 return
		set nocount on

	select @rcode = 0

	/* Validate SL */
     
	select @validcnt = count(1) from SLHD c 
	join inserted i on i.Co = c.SLCo and i.SL = c.SL
	if @validcnt <> @numrows
	begin
		select @errmsg = 'Missing Subcontract Header ' + convert(varchar(5), @validcnt)
		goto error
	end
	
	select @validcnt = count(1) from inserted
	where [Type] = 'Inclusion' or [Type] = 'Exclusion'
	if @validcnt <> @numrows
	begin
	   select @errmsg = 'Type must be Inclusion or Exclusion '
	   goto error
	end
	
	---- NOT REQUIRED GF 09/28/2010
	----select @validcnt = count(1) from JCPM c
	----join inserted i on i.PhaseGroup = c.PhaseGroup and i.Phase = c.Phase
	----if @validcnt <> @numrows
	----begin
	----   select @errmsg = 'Missing Valid Phase' + convert(varchar(5), @validcnt)
	----   goto error
	----end
	
	
	/* HQ Auditing */
	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vSLInExclusions', 'SL:' + i.SL + ' Inclusion/Exclusion:' + convert(varchar(6),i.Seq), i.Co, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	join bSLCO c on i.Co = c.SLCo
	where c.AuditSLs = 'Y'
     
     
	return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert SL InExclusions'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.vtSLInExclusionsU    Script Date: 09/27/2010 11:37:51 ******/
CREATE trigger [dbo].[vtSLInExclusionsU] on [dbo].[vSLInExclusions] for UPDATE as
/*--------------------------------------------------------------
 *
 *  Update trigger for SLInExclusions
 *  Created By: JG
 *  Date: 9/27/2010
 *  Modified:
 *
 *--------------------------------------------------------------*/
	/***  basic declares for SQL Triggers ****/
	declare @numrows int, @validcnt int, @errmsg varchar(255), @rcode int

	select @numrows = @@rowcount
	if @numrows = 0 return
		set nocount on

	select @rcode = 0

	/* Validate SL */
     
	/* Check for key changes */
	if update(KeyID) or update(Co) or update(SL) or update(Seq)
	begin
		select @errmsg = 'Cannot change Primary key'
		goto error
	end
	
	/* HQ Auditing */
	-- Insert records into HQMA for changes made to audited fields
	if not exists (select top 1 1 from inserted i join bSLCO c with (nolock) on c.SLCo = i.Co where c.AuditSLs = 'Y')
	return

	if update([Type])
			insert into bHQMA select 'vSLInExclusions', 'SL:' + i.SL + ' Inclusion/Exclusion: ' + convert(varchar(6),i.Seq), i.Co, 'C',
    		'Type', d.[Type], i.[Type], getdate(), SUSER_SNAME()
	   from inserted i
	   join deleted d on i.Co = d.Co and i.SL = d.SL and i.Seq = d.Seq
	   join bSLCO c with (nolock) on c.SLCo = i.Co
	   where i.[Type] <> d.[Type] and c.AuditSLs = 'Y'

	if update(PhaseGroup)
	   		insert into bHQMA select 'vSLInExclusions', 'SL:' + i.SL + ' Inclusion/Exclusion: ' + convert(varchar(6),i.Seq), i.Co, 'C',
    		'PhaseGroup', convert(varchar(3),d.PhaseGroup), convert(varchar(3),i.PhaseGroup), getdate(), SUSER_SNAME()
	   from inserted i
	   join deleted d on i.Co = d.Co and i.SL = d.SL and i.Seq = d.Seq
	   join bSLCO c with (nolock) on c.SLCo = i.Co
	   where ISNULL(i.PhaseGroup,'') <> ISNULL(d.PhaseGroup,'') and c.AuditSLs = 'Y'

	if update(Phase)
	   		insert into bHQMA select 'vSLInExclusions', 'SL:' + i.SL + ' Inclusion/Exclusion: ' + convert(varchar(6),i.Seq), i.Co, 'C',
    		'Phase', d.Phase, i.Phase, getdate(), SUSER_SNAME()
	   from inserted i
	   join deleted d on i.Co = d.Co and i.SL = d.SL and i.Seq = d.Seq
	   join bSLCO c with (nolock) on c.SLCo = i.Co
	   where ISNULL(i.Phase,'') <> ISNULL(d.Phase,'') and c.AuditSLs = 'Y'

	if update(Detail)
	   		insert into bHQMA select 'vSLInExclusions', 'SL:' + i.SL + ' Inclusion/Exclusion: ' + convert(varchar(6),i.Seq), i.Co, 'C',
    		'Detail', d.Detail, i.Detail, getdate(), SUSER_SNAME()
	   from inserted i
	   join deleted d on i.Co = d.Co and i.SL = d.SL and i.Seq = d.Seq
	   join bSLCO c with (nolock) on c.SLCo = i.Co
	   where isnull(i.Detail, '') <> isnull(d.Detail, '') and c.AuditSLs = 'Y'

	if update(DateEntered)
	   		insert into bHQMA select 'vSLInExclusions', 'SL:' + i.SL + ' Inclusion/Exclusion: ' + convert(varchar(6),i.Seq), i.Co, 'C',
    		'DateEntered', convert(varchar(10),d.DateEntered), convert(varchar(10),i.DateEntered), getdate(), SUSER_SNAME()
	   from inserted i
	   join deleted d on i.Co = d.Co and i.SL = d.SL and i.Seq = d.Seq
	   join bSLCO c with (nolock) on c.SLCo = i.Co
	   where i.DateEntered <> d.DateEntered and c.AuditSLs = 'Y'

	if update(EnteredBy)
	   		insert into bHQMA select 'vSLInExclusions', 'SL:' + i.SL + ' Inclusion/Exclusion: ' + convert(varchar(6),i.Seq), i.Co, 'C',
    		'EnteredBy', d.EnteredBy, i.EnteredBy, getdate(), SUSER_SNAME()
	   from inserted i
	   join deleted d on i.Co = d.Co and i.SL = d.SL and i.Seq = d.Seq
	   join bSLCO c with (nolock) on c.SLCo = i.Co
	   where i.EnteredBy <> d.EnteredBy and c.AuditSLs = 'Y'

	if update(Notes)
	   		insert into bHQMA select 'vSLInExclusions', 'SL:' + i.SL + ' Inclusion/Exclusion: ' + convert(varchar(6),i.Seq), i.Co, 'C',
    		'Notes', d.Notes, i.Notes, getdate(), SUSER_SNAME()
	   from inserted i
	   join deleted d on i.Co = d.Co and i.SL = d.SL and i.Seq = d.Seq
	   join bSLCO c with (nolock) on c.SLCo = i.Co
	   where isnull(i.Notes, '') <> isnull(d.Notes, '') and c.AuditSLs = 'Y'

     
	return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update SL Inclusion/Exclusion'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO
ALTER TABLE [dbo].[vSLInExclusions] ADD CONSTRAINT [PK_vSLInExclusions] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
