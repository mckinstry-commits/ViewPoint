CREATE TABLE [dbo].[bHRCM]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[Code] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[SafetyYN] [dbo].[bYN] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[CertPeriod] [smallint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PTOTypeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRCM_PTOTypeYN] DEFAULT ('N'),
[PRLeaveCode] [dbo].[bLeaveCode] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bHRCM] ADD
CONSTRAINT [CK_bHRCM_SafetyYN] CHECK (([SafetyYN]='Y' OR [SafetyYN]='N' OR [SafetyYN] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE        trigger [dbo].[btHRCMd] on [dbo].[bHRCM] for DELETE as
   

/*----------------------------------------------------------
    *
    *    Created by: MH 7/17/00
    *    Modified by: allenn 03/18/2002
    *					mh 4/18/02 - Issue 17026
    *					MH 08/11/04 - Issue 25310
    *   			mh 11/08/07 - 125908 - added check for HRSP
    *
    *	Rejects delete in bHRCM (HR Code Master) if a
    *	dependent record is found in:
    *
    *        HREH, HRPR, HRRI, HRED, HRRP, HRRD, HRRS, HRET, HRAD, HRAI, HRES, HRCO
    *
    *
    */---------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check HREH */
   if exists(select 1 from dbo.bHREH h with (nolock), deleted d where h.Code = d.Code and d.Type = 'H'  and h.HRCo = d.HRCo)
   	begin
   	select @errmsg = 'Assigned as a code in HREmployment History'
   	goto error
   	end
   
   /* check HRRI */
   if exists(select 1 from dbo.bHRRI h with (nolock), deleted d where h.Code = d.Code and d.Type = 'R'  and h.HRCo = d.HRCo)
   	begin
   	select @errmsg = 'Assigned as a code in HRRating Group'
   	goto error
   	end
   
   /* check HRED */
   if exists(select 1 from dbo.bHRED h with (nolock), deleted d where h.Code = d.Code and d.Type = 'N'  and h.HRCo = d.HRCo)
   	begin
   	select @errmsg = 'Assigned as a code in HRResource Discipline'
   	goto error
   	end

	/* check HRSP */
	if exists(select 1 from dbo.bHRSP h with (nolock), deleted d where h.ReasonCode = d.Code and d.Type = 'N' and h.HRCo = d.HRCo)
	begin
		select @errmsg = 'Assigned as a code in HR Salary History - Salary Reasons'
		goto error
	end
   
   /* check HRRP */
   if exists(select 1 from dbo.bHRRP h with (nolock), deleted d where h.Code = d.Code and d.Type = 'R'  and h.HRCo = d.HRCo)
   	begin
   	select @errmsg = 'Assigned as a code in HRResource Review'
   	goto error
   	end
   
   /* check HRRD */
   if exists(select 1 from dbo.bHRRD h with (nolock), deleted d where h.Code = d.Code and d.Type = 'W'  and h.HRCo = d.HRCo)
   	begin
   	select @errmsg = 'Assigned as a code in HRResource Rewards'
   	goto error
   	end
   
   /* check HRRS */
   if exists(select 1 from dbo.bHRRS h with (nolock), deleted d where h.Code = d.Code and d.Type = 'S'  and h.HRCo = d.HRCo)
   	begin
   	select @errmsg = 'Assigned as a code in HRResource Skills'
   	goto error
   	end
   
   /* check HRET */
   if exists(select 1 from dbo.bHRET h with (nolock), deleted d where h.TrainCode = d.Code and d.Type = 'T' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HRResource Training'
           goto error
           end
   
   /* check HRDT */
   if exists(select 1 from dbo.bHRDT h with (nolock), deleted d where h.TestType = d.Code and d.Type = 'D'  and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as a code in HR Drug Testing'
           goto error
           end
   
   if exists(select 1 from dbo.bHRDT h with (nolock) join deleted d on h.HRCo = d.HRCo and h.TestStatus = d.Code and d.Type = 'U')
		   begin
		   select @errmsg = 'Assigned as a Test Status in HR Drug Testing'
		   goto error
		   end

   --Issue 17026, Need to check HRAccident
   /* check HRAD */
   if exists(select 1 from dbo.bHRAD h with (nolock), deleted d where d.Code = h.BodyPart and d.Type = 'B' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as a code in HR Accident Detail'
           goto error
           end	
   
   /* check HRAI */
   if exists(select 1 from dbo.bHRAI h with (nolock), deleted d where d.Code = h.AccidentCode and d.Type = 'A' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as a code in HR Accident Detail'
           goto error
           end	
   
   /* check HRES */
   if exists(select 1 from dbo.bHRES h with (nolock), deleted d where d.Code = h.ScheduleCode and d.Type = 'C' and h.HRCo = d.HRCo)
   		begin
   		select @errmsg = 'Assigned as a code in HR Resource Schedule'
   		goto error
   		end
   
   /* check HRTC */
   if exists(select 1 from dbo.bHRTC h with (nolock), deleted d where h.TrainCode = d.Code and d.Type = 'T' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Training Class Setup'
           goto error
           end
   
   /* check HRCO */
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.DependHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.BenefitHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.SalaryHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.ReviewHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.TrainHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.SkillsHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.RewardHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.DisciplineHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.GrievanceHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.AccidentHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
   if exists(select 1 from dbo.bHRCO h with (nolock), deleted d where h.DrugHistCode = d.Code and d.Type = 'H' and h.HRCo = d.HRCo)
           begin
           select @errmsg = 'Assigned as code in HR Company Parameters'
           goto error
           end
   
	   
   return
   
   error:
   
   	select @errmsg = @errmsg + ' - cannot delete HR Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btHRCMi    Script Date: 4/8/2003 12:47:43 PM ******/
   
   /****** Object:  Trigger dbo.btHRCMi    Script Date: 2/3/2003 9:32:35 AM ******/
   CREATE   trigger [dbo].[btHRCMi] on [dbo].[bHRCM] for INSERT as
   
	/********************
	*
	*  Created by: ??
	*  Modified MH 12/18/2007 Issue 126545 Subquery returning more then 1 row
	*
	*********************/
   

	declare @errmsg varchar(255)

	--126545   
--   if (Select Type from inserted) = 'P'
--   begin
--   	select @errmsg = 'Invalid Code Type "P". '
--   	goto error
--   end
   
	if exists(select Type from inserted where Type not in (select Type from bHRCT))
	begin
		select @errmsg = 'Invalid Code Type'
		goto error
	end

	return
   
	error:

	select @errmsg = @errmsg + ' - cannot insert HR Code Master!'
	RAISERROR(@errmsg, 11, -1);

	rollback transaction
   
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btHRCMu] on [dbo].[bHRCM] for Update as
   

/*-----------------------------------------------------------------
    *	Created by: mh 4/8/03 
	*   Modified MH 12/18/2007 Issue 126545 Subquery returning more then 1 row
    *
    *
    *	
    */----------------------------------------------------------------
    
   declare @errmsg varchar(255), @numrows int, @validcnt int
    
   	if update(Type)
   	begin
--   		if (Select Type from inserted) = 'P'
--   		begin
--   			select @errmsg = 'Invalid Code Type "P". '
--   			goto error
--   		end

		--Issue 126545
		if exists(select Type from inserted where Type not in (select Type from bHRCT))
		begin
			select @errmsg = 'Invalid Code Type'
			goto error
		end

   	end
    
    
   return
    
   error:
   	select @errmsg = @errmsg + ' - cannot update HR Code Master!'
   	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
    
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRCM] ON [dbo].[bHRCM] ([HRCo], [Type], [Code]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRCM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCM].[SafetyYN]'
GO
