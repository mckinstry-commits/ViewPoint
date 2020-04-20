CREATE TABLE [dbo].[bHRAC]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[Accident] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[ClaimSeq] [int] NOT NULL,
[ClaimDate] [dbo].[bDate] NOT NULL,
[ClaimContact] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Cost] [dbo].[bDollar] NOT NULL,
[Deductible] [dbo].[bDollar] NOT NULL,
[PaidAmt] [dbo].[bDollar] NOT NULL,
[FiledYN] [dbo].[bYN] NOT NULL,
[PaidYN] [dbo].[bYN] NOT NULL,
[MedFacility] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRACd    Script Date: 2/3/2003 6:59:39 AM ******/
   CREATE   trigger [dbo].[btHRACd] on [dbo].[bHRAC] for Delete
    as
    

/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified:  mh 3/15/04 23061
	*				  mh 4/28/08 127008 - Corrected HRCO to bHRCO
    *
    *
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   /* Audit inserts */
   insert into bHQMA select 'bHRAC',  'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(d.Accident,'')) +
       'Seq: ' + convert(char(6),isnull(d.Seq,'')) + ' ClaimSeq: ' + convert(varchar(6),isnull(d.ClaimSeq,'')) + ' ClaimDate: ' + convert(varchar(10),isnull(d.ClaimDate,'')),
    	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    	from deleted d,  bHRCO e
       where e.HRCo = d.HRCo and e.AuditAccidentsYN  = 'Y'
   
    Return
    error:
    select @errmsg = (@errmsg + ' - cannot delete HRAC! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRACi    Script Date: 2/3/2003 6:56:53 AM ******/
   /****** Object:  Trigger dbo.btHRACi******/
   CREATE   trigger [dbo].[btHRACi] on [dbo].[bHRAC] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: ae  3/31/00
     * 	Modified by:  mh 3/15/04 23061
	 *				  mh 4/28/08 127008
     *
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* Audit inserts */
   if not exists (select * from inserted i, bHRCO e
    	where i.HRCo = e.HRCo and e.AuditAccidentsYN = 'Y')
    	return
   
   insert into bHQMA select 'bHRAC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       'Seq: ' + convert(char(6),isnull(i.Seq,'')) + ' ClaimSeq: ' + convert(varchar(6),isnull(i.ClaimSeq,'')) + ' ClaimDate: ' + convert(varchar(10),isnull(i.ClaimDate,'')),
      	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    	from inserted i,  bHRCO e
       where e.HRCo = i.HRCo and e.AuditAccidentsYN = 'Y'
   
   return
   
    error:
    	select @errmsg = @errmsg + ' - cannot insert into HRAC!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRACu    Script Date: 2/3/2003 7:00:52 AM ******/
   /****** Object:  Trigger dbo.btHRACu    Script Date: 8/28/99 9:37:38 AM ******/
   CREATE   trigger [dbo].[btHRACu] on [dbo].[bHRAC] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created by: ae 04/04/00
    * 	Modified by:  mh 4/28/08 - Issue 127008
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   insert into bHQMA select 'bHRAC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       'Seq: ' + convert(char(6),isnull(i.Seq,'')) + ' ClaimSeq: ' + convert(varchar(6),isnull(i.ClaimSeq,'')),
       i.HRCo, 'C','ClaimDate',
       convert(varchar(20),d.ClaimDate), Convert(varchar(20),i.ClaimDate),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.ClaimSeq = d.ClaimSeq
             and i.ClaimDate <> d.ClaimDate
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       'Seq: ' + convert(char(6),isnull(i.Seq,'')) + ' ClaimSeq: ' + convert(varchar(6),isnull(i.ClaimSeq,'')),
       i.HRCo, 'C','ClaimContact',
       convert(varchar(10),d.ClaimContact), Convert(varchar(10),i.ClaimContact),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.ClaimSeq = d.ClaimSeq
             and i.ClaimContact <> d.ClaimContact
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       'Seq: ' + convert(char(6),isnull(i.Seq,'')) + ' ClaimSeq: ' + convert(varchar(6),isnull(i.ClaimSeq,'')),
       i.HRCo, 'C','Cost',
       convert(varchar(12),d.Cost), Convert(varchar(12),i.Cost),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.ClaimSeq = d.ClaimSeq
             and i.Cost <> d.Cost
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       'Seq: ' + convert(char(6),isnull(i.Seq,'')) + ' ClaimSeq: ' + convert(varchar(6),isnull(i.ClaimSeq,'')),
       i.HRCo, 'C','Deductible',
       convert(varchar(12),d.Deductible), Convert(varchar(12),i.Deductible),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.ClaimSeq = d.ClaimSeq
             and i.Deductible <> d.Deductible
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       'Seq: ' + convert(char(6),isnull(i.Seq,'')) + ' ClaimSeq: ' + convert(varchar(6),isnull(i.ClaimSeq,'')),
       i.HRCo, 'C','PaidAmt',
       convert(varchar(12),d.PaidAmt), Convert(varchar(12),i.PaidAmt),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.ClaimSeq = d.ClaimSeq
             and i.PaidAmt <> d.PaidAmt
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       'Seq: ' + convert(char(6),isnull(i.Seq,'')) + ' ClaimSeq: ' + convert(varchar(6),isnull(i.ClaimSeq,'')),
       i.HRCo, 'C','FiledYN',
       convert(varchar(1),d.FiledYN), Convert(varchar(1),i.FiledYN),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.ClaimSeq = d.ClaimSeq
             and i.FiledYN <> d.FiledYN
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       'Seq: ' + convert(char(6),isnull(i.Seq,'')) + ' ClaimSeq: ' + convert(varchar(6),isnull(i.ClaimSeq,'')),
       i.HRCo, 'C','PaidYN',
       convert(varchar(1),d.PaidYN), Convert(varchar(1),i.PaidYN),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.ClaimSeq = d.ClaimSeq
             and i.PaidYN <> d.PaidYN
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAC', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       'Seq: ' + convert(char(6),isnull(i.Seq,'')) + ' ClaimSeq: ' + convert(varchar(6),isnull(i.ClaimSeq,'')),
       i.HRCo, 'C','MedFacility',
       convert(varchar(20),d.MedFacility), Convert(varchar(20),i.MedFacility),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.ClaimSeq = d.ClaimSeq
             and i.MedFacility <> d.MedFacility
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update HRAC!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRAC] ON [dbo].[bHRAC] ([HRCo], [Accident], [Seq], [ClaimSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRAC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRAC].[FiledYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRAC].[PaidYN]'
GO
