CREATE TABLE [dbo].[bHRAI]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[Accident] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[AccidentType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[HRRef] [dbo].[bHRRef] NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[PreventableYN] [dbo].[bYN] NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NULL,
[IllnessInjury] [char] (1) COLLATE Latin1_General_BIN NULL,
[IllnessType] [char] (1) COLLATE Latin1_General_BIN NULL,
[FatalityYN] [dbo].[bYN] NOT NULL,
[DeathDate] [dbo].[bDate] NULL,
[HospitalYN] [dbo].[bYN] NOT NULL,
[Hospital] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[HazMatYN] [dbo].[bYN] NOT NULL,
[MSDSYN] [dbo].[bYN] NOT NULL,
[ClaimCloseDate] [dbo].[bDate] NULL,
[MSDSDesc] [dbo].[bDesc] NULL,
[DOTReportableYN] [dbo].[bYN] NOT NULL,
[AccidentCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Supervisor] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ProjManager] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ObjSubCause] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Cause] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[IllnessInjuryDesc] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[FirstAidDesc] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Activity] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ThirdPartyName] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ThirdPartyAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ThirdPartyCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ThirdPartyState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ThirdPartyZip] [dbo].[bZip] NULL,
[ThirdPartyPhone] [dbo].[bPhone] NULL,
[WorkersCompYN] [dbo].[bYN] NOT NULL,
[WorkerCompClaim] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ClaimEstimate] [dbo].[bDollar] NOT NULL,
[AttendingPhysician] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[OSHALocation] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[EmergencyRoomYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRAI_EmergencyRoomYN] DEFAULT ('N'),
[HospOvernightYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRAI_HospOvernightYN] DEFAULT ('N'),
[EmplStartTime] [smalldatetime] NULL,
[HistSeq] [int] NULL,
[JobExpyr] [int] NULL,
[MineExpyr] [int] NULL,
[TotalExpyr] [int] NULL,
[JobExpwk] [int] NULL,
[MineExpwk] [int] NULL,
[TotalExpwk] [int] NULL,
[OSHA200Illness] [char] (1) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE      trigger [dbo].[btHRAId] on [dbo].[bHRAI] for Delete
   as
   

/**************************************************************
   * Created: 04/03/00 ae
   * Last Modified: mh 10/11/02 added HREH
   *				mh 2/20/03 Issue 20486
   *				mh 3/15/04 23061
   *				mh 4/28/08 127008
   *
   **************************************************************/
   
   declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, 
   @hrco bCompany, @hrref bHRRef, @seq int, @accidenthistcode varchar(10), @rcode int
   
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   	/* Audit inserts */
   	insert into bHQMA 
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' Accident: ' + 
   	convert(varchar(10),isnull(d.Accident,'')) +  ' Seq : ' + convert(varchar(10),isnull(d.Seq,'') ) + 
   	' AccidentType: ' + convert(varchar(1),isnull(d.AccidentType,'')),
    	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    	from deleted d join bHRCO e with (nolock) on
   	d.HRCo = e.HRCo 
   	where e.AuditAccidentsYN = 'Y'
   
   Return
   error:
   
   select @errmsg = (@errmsg + ' - cannot delete HRAI! ')
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE          trigger [dbo].[btHRAIi] on [dbo].[bHRAI] for INSERT as
   	

/*-----------------------------------------------------------------
   	*   	Created by: ae  3/31/00
   	* 		Modified by:
   	*					DC Issue 20935 - Add validation for MSHA ID and Mine Name
   	*					mh 3/15/04 23061
	*					mh 4/28/08 127008
   	*
   	*/----------------------------------------------------------------
   
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
   	@hrco bCompany, @hrref bHRRef, @seq int, @datechgd bDate, @acchistyn bYN, 
   	@acchistcode varchar(10), @accident varchar(10), @accseq int, @opencurs tinyint,
	@accdate bDate
    
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
    
   	/*insert HREH record if flag set in HRCO*/
   
   	declare insert_curs cursor local fast_forward for
   	select HRCo, Accident, Seq, HRRef 
   	from inserted 
   	where HRCo is not null and HRRef is not null and 
   	AccidentType = 'R'
   
   	open insert_curs
   	select @opencurs = 1
   
   	fetch next from insert_curs into @hrco, @accident, @accseq, @hrref
   
   	while @@fetch_status = 0
   	begin
   		select @acchistyn = AccidentHistYN, @acchistcode = AccidentHistCode 
   		from dbo.bHRCO with (nolock) 
   		where HRCo = @hrco
   
   		if @acchistyn = 'Y' and @acchistcode is not null
   		begin

			select @accdate = AccidentDate 
			from bHRAT where HRCo = @hrco and Accident = @accident

   			select @seq = isnull(max(Seq),0)+1, @datechgd = isnull(@accdate, convert(varchar(11), getdate()) )
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @seq, @acchistcode, @datechgd, 'H')
   
   			update bHRAI set HistSeq = @seq 
   			where HRCo = @hrco and Accident = @accident and Seq = @accseq
   		end		
   
   		fetch next from insert_curs into @hrco, @accident, @accseq, @hrref
   
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   		select @opencurs = 0
   	end
   
    
   	/* Audit inserts */
    
   	insert into bHQMA 
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + 
   	convert(varchar(10),isnull(i.Accident,'')) + ' Seq : ' + 
   	convert(varchar(10),isnull(i.Seq,'')),
     	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
     	from inserted i
   	join dbo.bHRCO e with (nolock) on e.HRCo = i.HRCo 
   	where e.AuditAccidentsYN = 'Y'
    
    return
    
     error:
     	select @errmsg = @errmsg + ' - cannot insert into HRAI!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
CREATE trigger [dbo].[btHRAIu] on [dbo].[bHRAI] for UPDATE as
/*-----------------------------------------------------------------
* Created: ae 04/04/00
* Modified:	mh 2/20/03 Issue 20486
*			DC 5/08/03  Issue 20935 - Add validation for MSHA ID and Mine Name
*			mh 3/15/04 23061
*			mh 7/9/2004 25059 - Cleaned up trigger and added missing audit entries
*			mh 4/28/08 - 127008
*			GG 06/06/08 - #128324 - fix key validation and auditing
*
*/----------------------------------------------------------------
    
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
	@hrco bCompany, @accident varchar(10), @seq int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

if update(HRCo) or update(Accident) or update(Seq)
	begin
	select @errmsg = 'Cannot change primary key values'
	goto error
	end
	
/*Audit changes*/
if update(AccidentType)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'AccidentType',
   		d.AccidentType, i.AccidentType, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where i.AccidentType <> d.AccidentType and e.AuditAccidentsYN = 'Y' 
if update(HRRef)  		
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'HRRef',
   		convert(varchar,d.HRRef), convert(varchar,i.HRRef), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where isnull(i.HRRef,'') <> isnull(d.HRRef,'') and e.AuditAccidentsYN = 'Y'
if update(EMCo)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'EMCo',
   		convert(varchar,d.EMCo), convert(varchar,i.EMCo), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where isnull(i.EMCo,0) <> isnull(d.EMCo,0) and e.AuditAccidentsYN = 'Y' 
if update(Equipment)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'Equipment',
   		d.Equipment, i.Equipment, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where isnull(i.Equipment,'') <> isnull(d.Equipment,'') and e.AuditAccidentsYN = 'Y' 
if update(PreventableYN)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'Preventable',
   		d.PreventableYN, i.PreventableYN, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where i.PreventableYN <> d.PreventableYN and e.AuditAccidentsYN = 'Y'
if update([Type])
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'Type',
   		d.Type, i.Type, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where isnull(i.Type,'') <> isnull(d.Type,'') and e.AuditAccidentsYN = 'Y' 
if update(IllnessInjury)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'IllnessInjury',
   		d.IllnessInjury, i.IllnessInjury, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where isnull(i.IllnessInjury,'') <> isnull(d.IllnessInjury,'') and e.AuditAccidentsYN = 'Y' 
if update(IllnessType)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'IllnessType',
   		d.IllnessType, i.IllnessType, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where isnull(i.IllnessType,'') <> isnull(d.IllnessType,'') and e.AuditAccidentsYN = 'Y' 
if update(FatalityYN)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'Fatality',
   		d.FatalityYN, i.FatalityYN, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where i.FatalityYN <> d.FatalityYN and e.AuditAccidentsYN = 'Y'
if update(DeathDate)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'DeathDate',
   		d.DeathDate, i.DeathDate, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where isnull(i.DeathDate,'') <> isnull(d.DeathDate,'') and e.AuditAccidentsYN = 'Y'
if update(HospitalYN)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'HospitalYN',
   		d.HospitalYN, i.HospitalYN, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where i.HospitalYN <> d.HospitalYN and e.AuditAccidentsYN = 'Y'
if update(Hospital)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'Hospital',
   		d.Hospital, i.Hospital, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where isnull(i.Hospital,'') <> isnull(d.Hospital,'') and e.AuditAccidentsYN = 'Y'
if update(HazMatYN)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'HazMatYN',
   		d.HazMatYN, i.HazMatYN, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where i.HazMatYN <> d.HazMatYN and e.AuditAccidentsYN = 'Y'
if update(MSDSYN)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'MSDSYN',
   		d.MSDSYN, i.MSDSYN, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where i.MSDSYN <> d.MSDSYN and e.AuditAccidentsYN = 'Y'
if update(ClaimCloseDate)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'ClaimCloseDate',
   		d.ClaimCloseDate, i.ClaimCloseDate, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where isnull(i.ClaimCloseDate,'') <> isnull(d.ClaimCloseDate,'') and e.AuditAccidentsYN = 'Y'
if update(MSDSDesc)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(varchar,i.HRCo) + ' Accident: ' + i.Accident +
   		' Seq: ' + convert(varchar,i.Seq), i.HRCo, 'C', 'MSDSDesc',
   		d.MSDSDesc, i.MSDSDesc, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   	join dbo.bHRCO e (nolock) on i.HRCo = e.HRCo
   	where isnull(i.MSDSDesc,'') <> isnull(d.MSDSDesc,'') and e.AuditAccidentsYN = 'Y'

-- remaining audit inserts should be cleaned up to match above --------------------
if update(DOTReportableYN)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','DOTReportableYN',
   	    convert(varchar(1),d.DOTReportableYN), Convert(varchar(1),i.DOTReportableYN),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.DOTReportableYN,'N') <> isnull(d.DOTReportableYN,'N') and e.AuditAccidentsYN  = 'Y'

if update(AccidentCode)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)   	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','AccidentCode',
   	    convert(varchar(10),d.AccidentCode), Convert(varchar(10),i.AccidentCode),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.AccidentCode,'') <> isnull(d.AccidentCode,'') and e.AuditAccidentsYN  = 'Y'

if update(Supervisor)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','Supervisor',
   	    convert(varchar(20),d.Supervisor), Convert(varchar(20),i.Supervisor),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.Supervisor,'') <> isnull(d.Supervisor,'') and e.AuditAccidentsYN  = 'Y'

if update(ProjManager)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)  
	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','ProjManager',
   	    convert(varchar(20),d.ProjManager), Convert(varchar(20),i.ProjManager),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.ProjManager,'') <> isnull(d.ProjManager,'') and e.AuditAccidentsYN  = 'Y'

if update(ObjSubCause)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','ObjSubCause',
   	    convert(varchar(20),d.ObjSubCause), Convert(varchar(20),i.ObjSubCause),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.ObjSubCause,'') <> isnull(d.ObjSubCause,'') and e.AuditAccidentsYN  = 'Y'

if update(ThirdPartyName)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','ThirdPartyName',
   	    convert(varchar(20),d.ThirdPartyName), Convert(varchar(20),i.ThirdPartyName),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.ThirdPartyName,'') <> isnull(d.ThirdPartyName,'') and e.AuditAccidentsYN  = 'Y'

if update(ThirdPartyAddress)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','ThirdPartyAddress',
   	    convert(varchar(60),d.ThirdPartyAddress), Convert(varchar(60),i.ThirdPartyAddress),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.ThirdPartyAddress,'') <> isnull(d.ThirdPartyAddress,'') and e.AuditAccidentsYN  = 'Y'

if update(ThirdPartyCity)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','ThirdPartyCity',
   	    convert(varchar(30),d.ThirdPartyCity), Convert(varchar(30),i.ThirdPartyCity),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.ThirdPartyCity,'') <> isnull(d.ThirdPartyCity,'') and e.AuditAccidentsYN  = 'Y'

if update(ThirdPartyState)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','ThirdPartyState',
   	    convert(varchar(2),d.ThirdPartyState), Convert(varchar(2),i.ThirdPartyState),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.ThirdPartyState,'') <> isnull(d.ThirdPartyState,'') and e.AuditAccidentsYN  = 'Y'

if update(ThirdPartyZip)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','ThirdPartyZip',
   	    convert(varchar(12),d.ThirdPartyZip), Convert(varchar(12),i.ThirdPartyZip),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.ThirdPartyZip,'') <> isnull(d.ThirdPartyZip,'') and e.AuditAccidentsYN  = 'Y'

if update(ThirdPartyPhone)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','ThirdPartyPhone',
   	    convert(varchar(20),d.ThirdPartyPhone), Convert(varchar(20),i.ThirdPartyPhone),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.ThirdPartyPhone,'') <> isnull(d.ThirdPartyPhone,'') and e.AuditAccidentsYN  = 'Y'

if update(WorkersCompYN)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','WorkersCompYN',
   	    convert(varchar(1),d.WorkersCompYN), Convert(varchar(1),i.WorkersCompYN),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where i.WorkersCompYN <> d.WorkersCompYN and e.AuditAccidentsYN  = 'Y'

if update(WorkerCompClaim)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     	
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','WorkerCompClaim',
   	    convert(varchar(20),d.WorkerCompClaim), Convert(varchar(20),i.WorkerCompClaim),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.WorkerCompClaim,'') <> isnull(d.WorkerCompClaim,'') and e.AuditAccidentsYN  = 'Y'
   
   --25059
if update(ClaimEstimate)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)  
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','ClaimEstimate',
   	    convert(varchar(20),d.ClaimEstimate), Convert(varchar(20),i.ClaimEstimate),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where i.ClaimEstimate <> d.ClaimEstimate and e.AuditAccidentsYN  = 'Y'

if update(AttendingPhysician)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','AttendingPhysician',
   	    convert(varchar(10),d.AttendingPhysician), Convert(varchar(10),i.AttendingPhysician),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.AttendingPhysician,'') <> isnull(d.AttendingPhysician,'') and e.AuditAccidentsYN  = 'Y'

if update(OSHALocation)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','OSHALocation',
   	    convert(varchar(20),d.OSHALocation), Convert(varchar(20),i.OSHALocation),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.OSHALocation,'') <> isnull(d.OSHALocation,'') and e.AuditAccidentsYN  = 'Y'

if update(EmergencyRoomYN)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','EmergencyRoomYN',
   	    convert(varchar(1),d.EmergencyRoomYN), Convert(varchar(1),i.EmergencyRoomYN),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where i.EmergencyRoomYN <> d.EmergencyRoomYN and e.AuditAccidentsYN  = 'Y'

if update(HospOvernightYN)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','HospOvernightYN',
   	    convert(varchar(1),d.HospOvernightYN), Convert(varchar(1),i.HospOvernightYN),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where i.HospOvernightYN <> d.HospOvernightYN and e.AuditAccidentsYN  = 'Y'

if update(EmplStartTime)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','EmplStartTime',
   	    right(d.EmplStartTime,7), right(i.EmplStartTime,7),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.EmplStartTime,'') <> isnull(d.EmplStartTime,'') and e.AuditAccidentsYN  = 'Y'

if update(JobExpyr)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','JobExpyr',
   	    convert(varchar(20),d.JobExpyr), Convert(varchar(20),i.JobExpyr),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.JobExpyr,0) <> isnull(d.JobExpyr,0) and e.AuditAccidentsYN  = 'Y'

if update(MineExpyr)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','MineExpyr',
   	    convert(varchar(20),d.MineExpyr), Convert(varchar(20),i.MineExpyr),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.MineExpyr,0) <> isnull(d.MineExpyr,0) and e.AuditAccidentsYN  = 'Y'

if update(TotalExpyr)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)  
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','TotalExpyr',
   	    convert(varchar(20),d.TotalExpyr), Convert(varchar(20),i.TotalExpyr),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.TotalExpyr,0) <> isnull(d.TotalExpyr,0) and e.AuditAccidentsYN  = 'Y'

if update(JobExpwk)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','JobExpwk',
   	    convert(varchar(20),d.JobExpwk), Convert(varchar(20),i.JobExpwk),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.JobExpwk,0) <> isnull(d.JobExpwk,0) and e.AuditAccidentsYN  = 'Y'

if update(MineExpwk)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','MineExpwk',
   	    convert(varchar(20),d.MineExpwk), Convert(varchar(20),i.MineExpwk),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.MineExpwk,0) <> isnull(d.MineExpwk,0) and e.AuditAccidentsYN  = 'Y'

if update(TotalExpwk)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
   	select 'bHRAI', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + 
   		' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
   		' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
   	    i.HRCo, 'C','TotalExpwk',
   	    convert(varchar(20),d.TotalExpwk), Convert(varchar(20),i.TotalExpwk),
   	 	getdate(), SUSER_SNAME()
   		from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.TotalExpwk,0) <> isnull(d.TotalExpwk,0) and e.AuditAccidentsYN  = 'Y'
   
    return
    
    error:
   
    	select @errmsg = @errmsg + ' - cannot update HRAI!'
    	RAISERROR(@errmsg, 11, -1);
    
    	rollback transaction
    
    
    
    
    
    
    
    
   
   
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bHRAI] WITH NOCHECK ADD CONSTRAINT [CK_bHRAI_DOTReportableYN] CHECK (([DOTReportableYN]='Y' OR [DOTReportableYN]='N'))
GO
ALTER TABLE [dbo].[bHRAI] WITH NOCHECK ADD CONSTRAINT [CK_bHRAI_EmergencyRoomYN] CHECK (([EmergencyRoomYN]='Y' OR [EmergencyRoomYN]='N'))
GO
ALTER TABLE [dbo].[bHRAI] WITH NOCHECK ADD CONSTRAINT [CK_bHRAI_FatalityYN] CHECK (([FatalityYN]='Y' OR [FatalityYN]='N'))
GO
ALTER TABLE [dbo].[bHRAI] WITH NOCHECK ADD CONSTRAINT [CK_bHRAI_HazMatYN] CHECK (([HazMatYN]='Y' OR [HazMatYN]='N'))
GO
ALTER TABLE [dbo].[bHRAI] WITH NOCHECK ADD CONSTRAINT [CK_bHRAI_HospOvernightYN] CHECK (([HospOvernightYN]='Y' OR [HospOvernightYN]='N'))
GO
ALTER TABLE [dbo].[bHRAI] WITH NOCHECK ADD CONSTRAINT [CK_bHRAI_HospitalYN] CHECK (([HospitalYN]='Y' OR [HospitalYN]='N'))
GO
ALTER TABLE [dbo].[bHRAI] WITH NOCHECK ADD CONSTRAINT [CK_bHRAI_MSDSYN] CHECK (([MSDSYN]='Y' OR [MSDSYN]='N'))
GO
ALTER TABLE [dbo].[bHRAI] WITH NOCHECK ADD CONSTRAINT [CK_bHRAI_PreventableYN] CHECK (([PreventableYN]='Y' OR [PreventableYN]='N'))
GO
ALTER TABLE [dbo].[bHRAI] WITH NOCHECK ADD CONSTRAINT [CK_bHRAI_WorkersCompYN] CHECK (([WorkersCompYN]='Y' OR [WorkersCompYN]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biHRAI] ON [dbo].[bHRAI] ([HRCo], [Accident], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRAI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
