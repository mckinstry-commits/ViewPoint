CREATE TABLE [dbo].[bHRAT]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[Accident] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[AccidentDate] [dbo].[bDate] NOT NULL,
[AccidentTime] [smalldatetime] NULL,
[EmployerPremYN] [dbo].[bYN] NOT NULL,
[JobSiteYN] [dbo].[bYN] NOT NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[ReportedBy] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DateReported] [dbo].[bDate] NULL,
[TimeReported] [smalldatetime] NULL,
[Location] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ClosedDate] [dbo].[bDate] NULL,
[CorrectiveAction] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Witness1] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Witness2] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[MSHAID] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[MineName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bHRAT] ADD
CONSTRAINT [CK_bHRAT_EmployerPremYN] CHECK (([EmployerPremYN]='Y' OR [EmployerPremYN]='N'))
ALTER TABLE [dbo].[bHRAT] ADD
CONSTRAINT [CK_bHRAT_JobSiteYN] CHECK (([JobSiteYN]='Y' OR [JobSiteYN]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btHRATd    Script Date: 2/3/2003 8:42:11 AM ******/
    CREATE    trigger [dbo].[btHRATd] on [dbo].[bHRAT] for Delete
     as
     

/**************************************************************
     * Created: 04/03/00 ae
     * Last Modified: mh 3/15/04 23061
     * 				mh 4/28/04 Date in keystring being truncated
	 *				mh 10/28/2008 - Issue 127008
     *
     **************************************************************/
     declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
    
    
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
    
	/*Check HRAI for related records */

	if exists(select 1 from bHRAI h join deleted d on h.HRCo = d.HRCo and h.Accident = d.Accident)
	begin
		select @errmsg = 'Related detail records exist in HRAI.'
		goto error
	end

	if exists (select 1 from bHRAW h join deleted d on h.HRCo = d.HRCo and h.Accident = d.Accident)
	begin
		select @errmsg = 'Related witness records exist in HRAW.'
		goto error
	end

    /* Audit inserts */
    insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(d.Accident,'')) +
        ' AccidentDate: ' + convert(varchar(11),isnull(d.AccidentDate,'')),
     	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
     	from deleted d,  bHRCO e
        where e.HRCo = d.HRCo and e.AuditAccidentsYN  = 'Y'
    
     Return
     error:
     select @errmsg = (@errmsg + ' - cannot delete HRAT! ')
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
    
    
    
    
    
    
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btHRATi    Script Date: 2/3/2003 8:41:24 AM ******/
    /****** Object:  Trigger dbo.btHRATi******/
    CREATE        trigger [dbo].[btHRATi] on [dbo].[bHRAT] for INSERT as
     

/*-----------------------------------------------------------------
      *   	Created by: ae  3/31/00
      * 	Modified by:
      *			DC Issue 20935.  Add validation for MSHA ID and Mine Name
      *			mh 3/15/04 23061
      *			mh 4/28/04 Date in keystring being truncated
      *
      */----------------------------------------------------------------
     declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
    	@mshaid varchar(10), @minename varchar(30) -- DC Issue 20935
    
    
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
/*    
    --DC Issue 20935 ----------Start-------------------------------------------
    select @mshaid = i.MSHAID, @minename = i.MineName
    from inserted i, HRAT t
    where i.HRCo = t.HRCo and i.Accident = t.Accident
    
    --if @mshaid = null and @minename <> null 
    if @mshaid is null and @minename is not null 
    	begin
    	select @errmsg = 'MSHA ID required if you enter a Mine Name'
    	goto error
    	end
    
    --if @minename = null and @mshaid <> null 
    if @minename is null and @mshaid is not null 
    	begin
    	select @errmsg = 'Mine Name required if you enter a MSHA ID'
    	goto error
    	end
    
    if @minename = '[Enter Mine Name]'
    	begin
    	select @errmsg = 'Mine Name required if you enter a MSHA ID'
    	goto error
    	end
    	
    --DC Issue 20935 ----------End-------------------------------------------
*/    
     /* Audit inserts */
    if not exists (select * from inserted i, HRCO e
     	where i.HRCo = e.HRCo and e.AuditAccidentsYN = 'Y')
     	return
    
    insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
        ' AccidentDate: ' + convert(varchar(11),isnull(i.AccidentDate,'')),
       	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
     	from inserted i,  bHRCO e
        where e.HRCo = i.HRCo and e.AuditAccidentsYN = 'Y'
    
    return
    
     error:
     	select @errmsg = @errmsg + ' - cannot insert into HRAT!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
    
    
    
    
    
    
    
    
    
    
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   CREATE       trigger [dbo].[btHRATu] on [dbo].[bHRAT] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created by: ae 04/04/00
    * 	Modified by:
    *		DC Issue 20935  - Add validation for MSHA ID and Mine Name
    *		mh 03/15/04 23061 
	*		mh 9/12/06 - Issue 122030 - Removing MSHA code.  Is now handled by
	*					by table bHRMN
	*		mh 1/15/08 - Issue 119853
	*		mh 9/27/2008 - Issue 129880
	*		mh 10/28/2008 - Issue 127008
    */----------------------------------------------------------------
   
	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
	@mshaid varchar(10), @minename varchar(30), -- DC Issue 20935
	@hrco bCompany, @hrref bHRRef, @accident varchar(10), @accidenthistcode varchar(10), 
	@accidenthistyn bYN, @opencurs tinyint, @histseq int, @accidentdate bDate, @seq int,
	@accidenttype char(1), @accidentseq int   

	select @numrows = @@rowcount
	if @numrows = 0 return
	set nocount on

/*  Begin 122030
   --DC Issue 20935---------------Start -----------------------------
   select @mshaid = i.MSHAID, @minename = i.MineName
   from inserted i, HRAT t
   where i.HRCo = t.HRCo and i.Accident = t.Accident
   
   --if @mshaid = null and @minename <> null 
   if @mshaid is null and @minename is not null 
   	begin
   	select @errmsg = 'MSHA ID required if you enter a Mine Name'
   	goto error
   	end
   
   --if @minename = null and @mshaid <> null 
   if @minename is null and @mshaid is not null 
   	begin
   	select @errmsg = 'Mine Name required if you enter a MSHA ID'
   	goto error
   	end
   
   if @minename = '[Enter Mine Name]'
   	begin
   	select @errmsg = 'Mine Name required if you enter a MSHA ID'
   	goto error
   	end
   
   --mark test
   /*
   if @mshaid is null and @minename is null
   begin
   	update HRAI set Type = 'N', IllnessInjury = null, IllnessType = null,
   	FatalityYN = 'N', DeathDate = null, OSHALocation = null 
   	from HRAI h
   	join inserted i on h.HRCo = i.HRCo and h.Accident = i.Accident
   end
   */
   --mark
   
   --DC Issue 20935---------------End -----------------------------
  */ 

--119853
	if update(AccidentDate)
	begin
		declare update_curs cursor local fast_forward for 
			select i.HRCo, i.Accident, i.AccidentDate, h.HRRef, h.Seq, h.HistSeq, h.AccidentType
			from inserted i
			join bHRAI h on i.HRCo = h.HRCo and i.Accident = h.Accident 
			where h.AccidentType = 'R' and h.HRRef is not null
		
		open update_curs
		select @opencurs = 1

		fetch next from update_curs into @hrco, @accident, @accidentdate, @hrref, @accidentseq, @histseq, @accidenttype
		
		while @@fetch_status = 0
		begin

			if @accidentseq is not null and @accidenttype = 'R' and @hrref is not null
			begin

				if @histseq is not null -- assume no history records were ever created.
				begin

					select @accidenthistcode = AccidentHistCode, @accidenthistyn = AccidentHistYN 
					from dbo.bHRCO with (nolock) where HRCo = @hrco

					if @accidenthistyn = 'Y' and @accidenthistcode is not null and @hrref is not null
					begin
						if not exists(select 1 from bHREH where HRCo = @hrco and HRRef = @hrref and Seq = @histseq)
						begin
							goto inserthreh
						end
						else
						begin
							update bHREH set DateChanged = isnull(@accidentdate, convert(varchar(11), getdate()))
							where HRCo = @hrco and HRRef = @hrref and Seq = @histseq
							goto endloop
						end
					end
				end
				else
				begin
					goto inserthreh
				end

				inserthreh:
					--Issue 129880 - Not using @histseq for inserts and updates back to HRAI.  Use @seq.  mh
					select @seq = isnull(max(Seq), 0) + 1
					from dbo.bHREH with (nolock)
					where HRCo = @hrco and HRRef = @hrref

					insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
					values (@hrco, @hrref, @seq, @accidenthistcode, isnull(@accidentdate, convert(varchar(11), getdate())), 'H')
	   
					update dbo.bHRAI 
					set HistSeq = @seq 
					where HRCo = @hrco and Accident = @accident and HRRef = @hrref
					and Seq = @seq

					goto endloop
			end

			endloop:
				fetch next from update_curs into @hrco, @accident, @accidentdate, @hrref, @accidentseq, @histseq, @accidenttype

		end	

		if @opencurs = 1 
		begin
			close update_curs
			deallocate update_curs
		end
	end
--end 199853		
		
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','AccidentDate',
       convert(varchar(20),d.AccidentDate), Convert(varchar(20),i.AccidentDate),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.AccidentDate <> d.AccidentDate
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','AccidentTime',
       convert(varchar(20),d.AccidentTime), Convert(varchar(20),i.AccidentTime),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.AccidentTime <> d.AccidentTime
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','EmployerPremYN',
       convert(varchar(1),d.EmployerPremYN), Convert(varchar(1),i.EmployerPremYN),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.EmployerPremYN <> d.EmployerPremYN
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','JobSiteYN',
       convert(varchar(1),d.JobSiteYN), Convert(varchar(1),i.JobSiteYN),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.JobSiteYN <> d.JobSiteYN
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','JCCo',
       convert(varchar(5),d.JCCo), Convert(varchar(5),i.JCCo),
  
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.JCCo <> d.JCCo
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','Job',
       convert(varchar(10),d.Job), Convert(varchar(10),i.Job),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.Job <> d.Job
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','PhaseGroup',
       convert(varchar(6),d.PhaseGroup), Convert(varchar(6),i.PhaseGroup),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.PhaseGroup <> d.PhaseGroup
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','Phase',
       convert(varchar(20),d.Phase), Convert(varchar(20),i.Phase),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.Phase <> d.Phase
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','ReportedBy',
       convert(varchar(30),d.ReportedBy), Convert(varchar(30),i.ReportedBy),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.ReportedBy <> d.ReportedBy
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','DateReported',
       convert(varchar(20),d.DateReported), Convert(varchar(20),i.DateReported),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.DateReported <> d.DateReported
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','TimeReported',
       convert(varchar(20),d.TimeReported), Convert(varchar(20),i.TimeReported),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.TimeReported <> d.TimeReported
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','Location',
       convert(varchar(30),d.Location), Convert(varchar(30),i.Location),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.Location <> d.Location
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','ClosedDate',
       convert(varchar(20),d.ClosedDate), Convert(varchar(20),i.ClosedDate),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.ClosedDate <> d.ClosedDate
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','Witness1',
       convert(varchar(10),d.Witness1), Convert(varchar(10),i.Witness1),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.Witness1 <> d.Witness1
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','Witness2',
       convert(varchar(10),d.Witness2), Convert(varchar(10),i.Witness2),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.Witness2 <> d.Witness2
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update HRAT!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
   
   
   
   
   
   
   
   
  
 




GO
CREATE UNIQUE CLUSTERED INDEX [biHRAT] ON [dbo].[bHRAT] ([HRCo], [Accident]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRAT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRAT].[EmployerPremYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRAT].[JobSiteYN]'
GO
