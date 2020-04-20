CREATE TABLE [dbo].[bHRRS]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[Code] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CertDate] [dbo].[bDate] NULL,
[ExpireDate] [dbo].[bDate] NULL,
[SkillTester] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[HistSeq] [int] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHRRS_Type] DEFAULT ('S'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE        trigger [dbo].[btHRRSd] on [dbo].[bHRRS] for Delete
   as
   
   	

	/**************************************************************
   	*		Created: 04/03/00 ae
   	* 		Last Modified:  mh Added update to HREH
   	*					mh 2/20/03 Issue 20486
   	*					mh 3/17/04 23061
	*					mh 10/29/2008 - 127008
   	*
   	*
   	**************************************************************/
   	declare @errmsg varchar(255), @validcnt int, @validcnt2 int, 
   	@errno int, @numrows int, @nullcnt int, @rcode int, @hrco bCompany, 
   	@hrref bHRRef, @seq int, @skillshistyn bYN, @skillshistcode varchar(10), 
   	@datechgd bDate, @opencurs tinyint
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/*Insert HREH record*/
   
   	declare delete_curs cursor local fast_forward for
   	select d.HRCo, d.HRRef 
   	from deleted d
   	where d.HRCo is not null and d.HRRef is not null and d.Code is not null
   
   	open delete_curs
   	select @opencurs = 1
   
   	fetch next from delete_curs into @hrco, @hrref
   
   	while @@fetch_status = 0
   	begin
   
   		select @skillshistyn = SkillsHistYN, @skillshistcode = SkillsHistCode 
   		from dbo.bHRCO with (nolock) 
   		where HRCo = @hrco
   
   		if @skillshistyn = 'Y' and @skillshistcode is not null
   		begin
   			select @seq = isnull(max(Seq),0)+1, @datechgd = convert(varchar(11), getdate()) 
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @seq, @skillshistcode, @datechgd, 'H')
   
   		end
   
   		fetch next from delete_curs into @hrco, @hrref
   
   	end
   
   	if @opencurs = 1
   	begin
   		close delete_curs
   		deallocate delete_curs
   		select @opencurs = 0
   	end
   
   	/* Audit inserts */
   
   	insert into dbo.bHQMA 
   	select 'bHRRS', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + 
   	' HRRef: ' + isnull(convert(varchar(6),d.HRRef),'') +
       ' Code: ' + isnull(convert(varchar(10), d.Code),'') + 
   	' CertDate: ' + isnull(convert(varchar(11), d.CertDate),''),
    	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    	from deleted d join dbo.bHRCO e with (nolock) on
       e.HRCo = d.HRCo 
   	where e.AuditSkillsYN = 'Y'
   
   	return
   
   error:
   
   	if @opencurs = 1
   	begin
   		close delete_curs
   		deallocate delete_curs
   	end
   
   	select @errmsg = (@errmsg + ' - cannot delete HRRS! ')
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE           trigger [dbo].[btHRRSi] on [dbo].[bHRRS] for INSERT as
   	

/*-----------------------------------------------------------------
   	*   Created by: kb 2/25/99
   	* 	Modified by: ae 03/31/00  added audits.
   	*				mh 3/17/04 23061
   	*				mh 7/7/04 - 25029
	*				mh 10/29/2008 - 127008
   	*
   	*
   	*	This trigger rejects update in bHRRS (Resource Skills) if the
   	*	following error condition exists:
   	*
   	*		Invalid HQ Company number
   	*		Invalid HR Resource number
   	*
   	*
   	*	Adds HR Employment History Record if HRCO_SkillHistYN = 'Y'
   	*/----------------------------------------------------------------
   
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, 
   	@datechgd bDate, @hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10), 
   	@skillcode varchar(10), @opencurs tinyint, @skillshistyn bYN, 
   	@skillshistcode varchar(10)
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* check for key changes */
   	select @validcnt = count(i.HRCo) 
   	from inserted i join dbo.bHQCO h with (nolock) on 
   	i.HRCo = h.HQCo
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid HR Company'
   		goto error
   	end
   
   	select @validcnt = count(i.HRCo) 
   	from inserted i join dbo.bHRRM h with (nolock) on 
   	i.HRCo = h.HRCo and i.HRRef = h.HRRef
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid Resource'
   		goto error
   	end
   
   	/* validate train code*/
   	select @validcnt = count(i.HRCo) 
   	from inserted i join dbo.bHRCM h with (nolock) on
   	i.HRCo = h.HRCo and h.Code = i.Code 
   	where h.Type = 'S'
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid Skill Code'
   		goto error
   	end
   
   	/*Insert HREH Record*/
   	declare insert_curs cursor local fast_forward for
   	select HRCo, HRRef, Code from inserted i
   	where i.HRCo is not null and i.HRRef is not null and i.Code is not null
   
   	open insert_curs
   
   	select @opencurs = 1
   
   	fetch next from insert_curs into @hrco, @hrref, @skillcode
   
   	while @@fetch_status = 0
   	begin
   		select @skillshistyn = SkillsHistYN, @skillshistcode = SkillsHistCode 
   		from dbo.bHRCO with (nolock) 
   		where HRCo = @hrco
   
   		if @skillshistyn = 'Y' and @skillshistcode is not null
   		begin
   			select @seq = isnull(max(Seq),0)+1, @datechgd = convert(varchar(11), getdate()) 
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @seq, @skillshistcode, @datechgd, 'H')
   
   	  		update dbo.bHRRS 
   			set HistSeq = @seq 
   			where HRCo = @hrco and HRRef = @hrref
     			and Code = @skillcode
   		end
   
   		fetch next from insert_curs into @hrco, @hrref, @skillcode
   
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   		select @opencurs = 0
   	end		
   
   	/* Audit inserts */
   
   	insert into dbo.bHQMA 
   	select 'bHRRS', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   	' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
       ' Code: ' + convert(varchar(10),isnull(i.Code,'')) + 
   	' CertDate: ' + isnull(convert(varchar(11),i.CertDate),''),
    	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    	from inserted i join dbo.bHRCO e on 
   	i.HRCo = e.HRCo
   	where e.AuditSkillsYN = 'Y'
   
   	return
   
   error:
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   	end		
   
     	select @errmsg = @errmsg + ' - cannot insert HR Resource Skills!'
     	RAISERROR(@errmsg, 11, -1);
   
     	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE           trigger [dbo].[btHRRSu] on [dbo].[bHRRS] for UPDATE as
    	

/*-----------------------------------------------------------------
    	*   	Created by: 	kb 2/25/99
    	* 		Modified by: 	ae 4/04/00 added triggers.
    	*					 	mh 9/5/02 added update to HREH
    	*						mh 2/20/03 Issue 20486
    	*						mh 23061 3/17/04
    	*						mh 25029 7/7/04
   		*						mh 4/29/2005 - 28581 - Change HRRef conversion from varchar(5) to varchar(6)
		*						mh 10/29/2008 - 127008
    	*	
    	*	This trigger rejects update in bHRRS (Companies) if the
    	*	following error condition exists:
    	*
    	*
    	*	Adds HR Employment History Record if HRCO_SkillsHistYN = 'Y'
    	*/----------------------------------------------------------------
    
    	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
    	@hrco bCompany, @hrref bHRRef, @seq int, @skillcode varchar(10), 
    	@histchg bDate, @opencurs tinyint, @skillshistyn bYN, @skillshistcode varchar(10)
    	
    	select @numrows = @@rowcount
    	if @numrows = 0 return
    	set nocount on
    
    	/* check for key changes */
    	if update(HRCo)
    	begin
    		select @validcnt = count(i.HRCo) from inserted i join deleted d
    		on i.HRCo = d.HRCo
    		if @validcnt <> @numrows
    		begin
    			select @errmsg = 'Cannot change HR Company'
    			goto error
    		end
    	end
    
    	if update(HRRef)
    	begin
    		select @validcnt = count(i.HRCo) from inserted i join deleted d on
    		i.HRCo = d.HRCo and i.HRRef = d.HRRef
    
    		if @validcnt <> @numrows
    		begin
    			select @errmsg = 'Cannot change HR Resource'
    			goto error
    		end
    	end
    
    	if update(Code)
    	begin
    		select @validcnt = count(i.HRCo) from inserted i join deleted d on 
    		i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Code = d.Code
    
    		if @validcnt <> @numrows
    		begin
    			select @errmsg = 'Cannot change Skill Code'
    			goto error
    		end
      	end
    
    	/*insert HREH record if flag set in HRCO*/
    
    	declare update_curs cursor local fast_forward for
    	select HRCo, HRRef, Code from inserted i
    	where i.HRCo is not null and i.HRRef is not null and i.Code is not null
    
    	open update_curs
    
    	select @opencurs = 1
    
    	fetch next from update_curs into @hrco, @hrref, @skillcode
    
    	while @@fetch_status = 0
    	begin
    		select @skillshistyn = SkillsHistYN, @skillshistcode = SkillsHistCode 
    		from dbo.bHRCO with (nolock) 
    		where HRCo = @hrco
    
    		if @skillshistyn = 'Y' and @skillshistcode is not null
    		begin
    			select @seq = isnull(max(Seq),0)+1, @histchg = convert(varchar(11), getdate()) 
    			from dbo.bHREH with (nolock) 
    			where HRCo = @hrco and HRRef = @hrref
    
    
    			if not update(HistSeq)
    			begin
    				insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
    				values (@hrco, @hrref, @seq, @skillshistcode, @histchg, 'H')
    
    		  		update dbo.bHRRS 
    				set HistSeq = @seq 
    				from dbo.bHRRS where HRCo = @hrco and HRRef = @hrref
    	  			and Code = @skillcode
    			end
    		end
    
    		fetch next from update_curs into @hrco, @hrref, @skillcode
    
    	end
    
    	if @opencurs = 1
    	begin
    		close update_curs
    		deallocate update_curs
    		select @opencurs = 0
    	end		
    
    	/*Insert HQMA records*/
    
    	if update(CertDate)
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRRS', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
    		' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
    		' Code: ' + convert(varchar(10),isnull(i.Code,'')), i.HRCo, 'C','CertDate',
    		convert(varchar(20),d.CertDate), Convert(varchar(20),i.CertDate),
    		getdate(), SUSER_SNAME()
    		from inserted i
    		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Code = d.Code
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.CertDate,'') <> isnull(d.CertDate,'') and e.AuditSkillsYN = 'Y'
    
		if update([ExpireDate])    
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRRS', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
    		' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' Code: ' + convert(varchar(10),isnull(i.Code,'')), i.HRCo, 'C','ExpireDate',
			convert(varchar(20),d.ExpireDate), Convert(varchar(20),i.ExpireDate),
     		getdate(), SUSER_SNAME()
     		from inserted i
    		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Code = d.Code
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.ExpireDate,'') <> isnull(d.ExpireDate,'') and e.AuditSkillsYN = 'Y'
    
		if update(SkillTester)    
    		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRRS', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
    		' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
    		' Code: ' + convert(varchar(10),isnull(i.Code,'')), i.HRCo, 'C','SkillTester',
    		convert(varchar(30),d.SkillTester), Convert(varchar(30),i.SkillTester),
    		getdate(), SUSER_SNAME()
     		from inserted i
    		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Code = d.Code
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.SkillTester,'') <> isnull(d.SkillTester,'') and e.AuditSkillsYN  = 'Y'
    
      return
    
    error:
      	select @errmsg = @errmsg + ' - cannot update HR Resource Training!'
      	RAISERROR(@errmsg, 11, -1);
    
      	rollback transaction
    
    
    
    
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRRS] ON [dbo].[bHRRS] ([HRCo], [HRRef], [Code]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRRS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
