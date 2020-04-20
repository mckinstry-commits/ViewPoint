CREATE TABLE [dbo].[bHRRC]
(
[HRCo] [smallint] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[DependSeq] [smallint] NOT NULL,
[CoverageTermDate] [dbo].[bDate] NULL,
[EligibleDate] [dbo].[bDate] NULL,
[QualEvent] [dbo].[bDesc] NULL,
[QualEventDate] [dbo].[bDate] NULL,
[NoticeDate] [dbo].[bDate] NULL,
[EnrollDate] [dbo].[bDate] NULL,
[Coverage] [dbo].[bDesc] NULL,
[ComplyDate] [dbo].[bDate] NULL,
[COBRAStart] [dbo].[bDate] NULL,
[COBRAEnd] [dbo].[bDate] NULL,
[DiscontinueDate] [dbo].[bDate] NULL,
[CompanyPay] [dbo].[bDollar] NOT NULL,
[EmployeePay] [dbo].[bDollar] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[QualEventValue] [char] (1) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[DateDeclined] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRRC] ON [dbo].[bHRRC] ([HRCo], [HRRef], [DependSeq], [CoverageTermDate]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRRC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE     trigger [dbo].[btHRRCi] on [dbo].[bHRRC] for INSERT as
   

	/*-----------------------------------------------------------------
    *  Created by: ae 11/19/99
    * 	Modified by: mh 6/18/03...need to encapsulate MiddleName and FirstName in isnull functions.
	*				 mh 10/12/06 - Removing the insert into HRDP for dependent seq 0.  Issue 122750
	*				 mh 10/28/2008 - 127008
    * 
    *
    *	This trigger places a record in bHRDP (Resource Dependents) upon insert
    *  of a record into bHRRC (Resource Cobra) if entering seq 0.
    *
    */----------------------------------------------------------------
   
	declare @errmsg varchar(255), @numrows int, @validcnt int
   
	declare @hrco bCompany, @hrref bHRRef, @seq int, @name varchar(30), @sex char(1)
   
	select @numrows = @@rowcount

	if @numrows = 0 return

	set nocount on
   
	select @validcnt = count(1) from inserted i join dbo.bHQCO h on i.HRCo =h.HQCo

	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid HR Company'
   		goto error
   	end
   
	select @validcnt = count(1) from inserted i join dbo.bHRRM h on i.HRCo = h.HRCo and i.HRRef = h.HRRef

	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid Resource'
   		goto error
   	end
  
	return
   
	error:
   
   	select @errmsg = @errmsg + ' - cannot insert HR Resource Dependent!' 	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 




GO
