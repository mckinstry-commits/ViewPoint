CREATE TABLE [dbo].[vDDUP]
(
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[ShowRates] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_ShowRates] DEFAULT ('N'),
[HotKeyForm] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[RestrictedBatches] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_RestrictedBatches] DEFAULT ('N'),
[FullName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Phone] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[EMail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ConfirmUpdate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_ConfirmUpdate] DEFAULT ('N'),
[DefaultCompany] [dbo].[bCompany] NOT NULL CONSTRAINT [DF_vDDUP_DefaultCompany] DEFAULT ((1)),
[EnterAsTab] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_EnterAsTab] DEFAULT ('Y'),
[ExtendControls] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_ExtendControls] DEFAULT ('N'),
[SavePrinterSettings] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_SavePrinterSettings] DEFAULT ('N'),
[SmartCursor] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_SmartCursor] DEFAULT ('N'),
[ToolTipHelp] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_ToolTipHelp] DEFAULT ('Y'),
[Project] [dbo].[bJob] NULL,
[PRGroup] [dbo].[bGroup] NULL,
[PREndDate] [dbo].[bDate] NULL,
[JBBillMth] [dbo].[bMonth] NULL,
[JBBillNumber] [int] NULL,
[MenuColWidth] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LastNode] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[LastSubFolder] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MinimizeUse] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_MinimizeUse] DEFAULT ('N'),
[AccessibleOnly] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_AccessibleOnly] DEFAULT ('N'),
[ViewOptions] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ReportOptions] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SmartCursorColor] [int] NULL,
[AccentColor1] [int] NULL,
[UseColorGrad] [dbo].[bYN] NULL,
[FormColor1] [int] NULL,
[FormColor2] [int] NULL,
[GradDirection] [tinyint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[MenuAdmin] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_MenuAdmin] DEFAULT ('N'),
[AccentColor2] [int] NULL,
[ReqFieldColor] [int] NULL,
[IconSize] [tinyint] NULL,
[FontSize] [tinyint] NULL,
[FormAdmin] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_FormAdmin] DEFAULT ('N'),
[MultiFormInstance] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_MultiFormInstance] DEFAULT ('N'),
[PayCategory] [int] NULL,
[HideModFolders] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_HideModFolders] DEFAULT ('N'),
[FolderSize] [tinyint] NULL,
[Job] [dbo].[bJob] NULL,
[Contract] [dbo].[bContract] NULL,
[MenuInfo] [tinyint] NOT NULL CONSTRAINT [DF_vDDUP_MenuInfo] DEFAULT ((0)),
[LastReportID] [int] NULL,
[ColorSchemeID] [int] NULL,
[MappingID] [int] NULL,
[ImportId] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[JBTMBillMth] [dbo].[bMonth] NULL,
[JBTMBillNumber] [int] NULL,
[PMTemplate] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[MergeGridKeys] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_MergeGridKeys] DEFAULT ('N'),
[MaxLookupRows] [int] NULL,
[MaxFilterRows] [int] NULL,
[PMViewName] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DefaultColorSchemeID] [int] NULL,
[AltGridRowColors] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_AltGridRowColors] DEFAULT ('Y'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[HRCo] [dbo].[bCompany] NULL,
[HRRef] [dbo].[bHRRef] NULL,
[DefaultDestType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vDDUP_DefaultDestType] DEFAULT ('EMail'),
[WindowsUserName] [dbo].[bVPUserName] NULL,
[SelectedTemplate] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[RQEntyHeaderID] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PRCo] [dbo].[bCompany] NULL,
[Employee] [dbo].[bEmployee] NULL,
[RQQuoteEditHeaderID] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[MyTimesheetRole] [tinyint] NOT NULL CONSTRAINT [DF_vDDUP_MyTimesheetRole] DEFAULT ((1)),
[AttachmentGrouping] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[IsHelpUpToDate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_IsHelpUpToDate] DEFAULT ('Y'),
[LabelBackgroundColor] [int] NULL,
[LabelTextColor] [int] NULL,
[LabelBorderStyle] [int] NULL,
[ShowLogoPanel] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_ShowLogoPanel] DEFAULT ('Y'),
[ShowMainToolbar] [dbo].[bYN] NOT NULL CONSTRAINT [DF__vDDUP__ShowMainT__434A9E6E] DEFAULT ('Y'),
[UserType] [smallint] NOT NULL CONSTRAINT [DF_vDDUP_UserType] DEFAULT ((0)),
[SaveLastUsedParameters] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vDDUP_SaveLastUsedParameters] DEFAULT ('N'),
[ReportViewerOptions] [tinyint] NOT NULL CONSTRAINT [DF_vDDUP_ReportViewerOptions] DEFAULT ((2)),
[ThumbnailMaxCount] [int] NULL,
[udReviewer] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[FourProjectsUserName] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[FourProjectsPassword] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[SendViaSmtp] [dbo].[bYN] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 9/6/2013
-- Description:	Adds a JC Project Manager from a PR Employee 
--				and launches a stored proc to add a reviewer.  Based on Security Group membership
-- 
-- =============================================
CREATE TRIGGER [dbo].[mckUpdateUserRecords] 
   ON  [dbo].[vDDUP] 
   AFTER INSERT,UPDATE
AS 
	DECLARE @VPUserName varchar(50)
	--IF UPDATE(Employee)	OR UPDATE(PRCo)
	DECLARE User_cursor CURSOR FOR 
	SELECT VPUserName FROM INSERTED
	WHERE Employee IS NOT NULL

	OPEN User_cursor
	FETCH NEXT FROM User_cursor INTO @VPUserName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

		DECLARE @Company int; 
		DECLARE @Employee int;
		

		SET @Company = (SELECT i.PRCo FROM inserted i)
		SET @Employee = (SELECT i.Employee FROM inserted i)
		SET @VPUserName = (Select i.VPUserName FROM inserted i)
		-- Insert statements for trigger here
		--IF Part of PM Security Groups
		IF EXISTS(
			SELECT * 
			FROM vDDSU g
			INNER JOIN inserted i ON i.VPUserName = g.VPUserName
			WHERE g.SecurityGroup = 200 OR g.SecurityGroup = 201 OR g.SecurityGroup = 202
			AND i.Employee IS NOT NULL) 
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM dbo.JCUO WHERE JCCo = @Company AND UserName = @VPUserName)
				BEGIN
					EXEC mckspJCCPColDef @Company, @VPUserName
				END
			--IF employee not already created as PM
			IF NOT EXISTS(
			SELECT TOP 1 1 
			FROM bJCMP p
			INNER JOIN inserted u ON p.udPRCo = u.PRCo AND p.udEmployee = u.Employee
			)
				BEGIN
			--INSERT Project Manager record from Employee table.
				INSERT INTO bJCMP
				(JCCo, udPRCo, ProjectMgr, udEmployee, Name, Phone, MobilePhone, Email)
					SELECT e.PRCo, e.PRCo, (SELECT Max(ProjectMgr) FROM bJCMP)+ 1, e.Employee, e.FirstName + ' ' + e.LastName, ISNULL(e.Phone,i.Phone), e.CellPhone, ISNULL(e.Email,i.EMail)
					FROM bPREH e
					INNER JOIN inserted i ON e.PRCo = i.PRCo AND i.Employee = e.Employee
				END
					
			END
			--WHERE i.PRCo = e.PRCo AND i.Employee = e.Employee
		--Insert Reviewer
		IF EXISTS(SELECT i.Employee 
			FROM INSERTED i
			WHERE i.udReviewer IS NULL AND i.Employee IS NOT NULL)
			BEGIN
			IF EXISTS(
				SELECT g.VPUserName 
				FROM vDDSU g
				INNER JOIN inserted i ON i.VPUserName = g.VPUserName
				WHERE g.SecurityGroup = 200 OR g.SecurityGroup = 201 OR g.SecurityGroup = 202 OR 
					g.SecurityGroup = 10 OR g.SecurityGroup = 11 OR g.SecurityGroup = 12
				) 
				BEGIN
					
				
				
					EXEC dbo.mckInsertReviewer @Company, @Employee, @VPUserName
				END
			END
		FETCH NEXT FROM User_cursor INTO @VPUserName
	END
	CLOSE User_cursor
	DEALLOCATE User_cursor
	-- NEED TO ENFORCE INTEGRITY BETWEEN USER PROFILE AND REVIEWER TABLE.  
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[vtDDUPd] on [dbo].[vDDUP] for DELETE  
/*-----------------------------------------------------------------  
 * Created: GG 01/26/06  
 * Modified:  Dave C 6/23/09 Changed proc to appropraitely delete from the following table:
 *			vVPCanvasTemplateSecurity
 *			  GPT 04/24/2013 - TFS 47567- Use ORIGINAL_LOGIN for audit of DDUP delete.
 *  
 *  Delete trigger on vDDUP (DD User Profile)  
 *  
 * This trigger rejects delete in vDDUP if security, preference,   
 * sub-folder, or other user specific entries still exist for the user.   
 *  
 */----------------------------------------------------------------  
    
as  
      
  
declare @errmsg varchar(255), @validcnt int     
if @@rowcount = 0 return  
  
set nocount on  
      
-- check DD Data Security   
if exists (select top 1 1 from deleted d join dbo.vDDDU u with (nolock) on u.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'Data Security entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
--check DD Form Security   
if exists (select top 1 1 from deleted d join dbo.vDDFS s with (nolock) on s.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'Form Security entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
--check User Forms preferences  
if exists (select top 1 1 from deleted d join dbo.vDDFU u with (nolock) on u.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'Form preference entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
--check User Subfolders   
if exists (select top 1 1 from deleted d join dbo.vDDSF f with (nolock) on f.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'User subfolders exist in the Menu. User must be removed using the delete user form.'  
 goto error  
 end  
--check Security Groups   
if exists (select top 1 1 from deleted d join dbo.vDDSU u with (nolock) on  u.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'Security Groups entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
--check Tab Security   
if exists (select top 1 1 from deleted d join dbo.vDDTS s with (nolock) on  s.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'Tab Security entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
--check User Defaults  
if exists (select top 1 1 from deleted d join dbo.vDDUI u with (nolock) on u.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'User default entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
--check User Lookup  
if exists (select top 1 1 from deleted d join dbo.vDDUL u with (nolock) on u.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'User lookup preference entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
--check User Web Links  
if exists (select top 1 1 from deleted d join dbo.vDDWL w with (nolock) on w.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'User Web Links exist. User must be removed using the delete user form.'  
 goto error  
 end  
--check Report Security  
if exists (select top 1 1 from deleted d join dbo.vRPRS s with (nolock) on s.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'Report Security entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
--check Report Preferences  
if exists (select top 1 1 from deleted d join dbo.vRPUP u with (nolock) on u.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'Report preference entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
      
--check Reveiwers  
if exists (select top 1 1 from deleted d join dbo.bHQRP m with (nolock) on m.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'Reveiwers entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
   
 --check VP Query Security   
if exists (select top 1 1 from deleted d join dbo.vVPQuerySecurity s with (nolock) on s.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'My VP Query Security entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
      
--check VP Template Security  
if exists (select top 1 1 from deleted d join dbo.vVPCanvasTemplateSecurity s with (nolock) on s.VPUserName = d.VPUserName)  
 begin  
 select @errmsg = 'My VP Custom Template Security entries exist. User must be removed using the delete user form.'  
 goto error  
 end  
   
--clear Payroll Processing table of any entries remaining for this user  
select @validcnt = count(*) from deleted d join dbo.bPRPE b with (nolock) on b.VPUserName = d.VPUserName  
if @validcnt<>0  
 delete dbo.bPRPE from dbo.bPRPE b with (nolock) join deleted d on b.VPUserName = d.VPUserName  
      
/* Audit deletions to bHQMA*/  
insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)  
 select 'vDDUP', 'VPUserName: ' + VPUserName,  
 null, 'D', null, null, null, getdate(), ORIGINAL_LOGIN() from deleted  
      
      
return  
      
error:  
        select @errmsg = isnull(@errmsg,'') + ' - cannot delete User!'  
        RAISERROR(@errmsg, 11, -1);
        rollback transaction  
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[vtDDUPi] on [dbo].[vDDUP] for INSERT 
/*-----------------------------------------------------------------
 * Created: GG 8/22/03
 * Modified: Dan Sochacki 11/09/2007 - Added Validation for 2 newly added columns
 *			 CC 02/03/2009 - Remove validation for HRCo & HRRef
 *			GPT 04/24/2013 - TFS 47567- Use ORIGINAL_LOGIN for audit of DDUP insert.
 *
 *	This trigger rejects insertion in vDDUP (User Profile) if
 *	any of the following error conditions exist:
 *
 *	None
 *
 * 	Audits insert in bHQMA
 *
 */----------------------------------------------------------------
as
declare @errmsg varchar(255), @numrows int, @validcnt int, @user bVPUserName, @nullcnt int

select @numrows = @@rowcount, @validcnt=0
if @numrows = 0 return 
 
set nocount on
select @user = i.VPUserName
from inserted i

-- validate user
select @validcnt = count(*)
--from master..syslogins l
from sys.server_principals l
--join inserted i on l.name = i.VPUserName
where l.name = @user

/*if @validcnt <> @numrows
	begin
 	select @errmsg = 'Invalid User, not setup as a SQL Login'
 	goto error
 	end	*/-- removed validation because trusted connections do not require individual SQL logins

/*
--JRK attempt to reinstate the no such account check, this time seeing if the user might be a domain user.
if @validcnt <> 1
begin
	-- See if this might be a domain user.
	declare @pos bigint
	select @pos = charindex('\',@user) -- Is there a "\" in the user name.
	--print @pos
	if @pos > 0
	begin -- Yes, there is a "\".
		declare @domain bVPUserName -- Get the domain from the user name (text preceding the "\").
		select @domain = substring(@user,0,@pos)
		declare @domusers bVPUserName -- Buid up the full account name for the Domain Users account.
		select @domusers=@domain + '\Domain Users'
		-- See if the Domain Users account is set up in SQL security.
		--select @validcnt = -1
		select @validcnt = count(*)
		--from master..syslogins s
		from sys.server_principals s
		where s.name = @domusers
		if @validcnt <> 1
		begin
 			select @errmsg = 'User "' + @user + '" is not setup with a SQL Login and "' + @domusers + '" account not found'
 			goto error
		end
	end
	else
	begin
		select @errmsg = 'User is not setup with a SQL Login and the user name is not a domain user name'
		goto error
	end
end
*/

-- add HQMA audit
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vDDUP', 'Name: ' + VPUserName, null, 'A', null, null, null, getdate(), ORIGINAL_LOGIN()
from inserted

return
 
error:
	select @errmsg = @errmsg + ' - cannot insert User Profile!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[vtDDUPu] on [dbo].[vDDUP] for UPDATE
/************************************
* Created: GG 01/26/06
* Modified: DANF 07/19/07 - Correct Auditing to insert the Table name of vDDUP into HQMA
* Modified: Dan Sochacki 11/09/2007 - Added Auditing AND Validation for 2 newly added columns
*			CC 02/03/2009 - Remove validation for HRCo & HRRef
*			mh 07/01/2009 - Added audit entries for PRCo and Employee
*			RM 09/02/2010 - Added auditing for UseRecordingFramework,RecordUsage,ContinuousRecording
*			PW 09/21/2012 - Removed Recording Framwork columns
*			GPT 04/24/2013 - TFS 47567- Use ORIGINAL_LOGIN for audit of DDUP updates.
*
* Update trigger on vDDUP (DD User Profile)
*
* Rejects update if any of the following conditions exist:
*	Change VPUserName
*
* Adds DD Audit entries for some changed values
*
************************************/

as


declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
  
-- check for key changes 
select @validcnt = count(*) from inserted i join deleted d	on i.VPUserName = d.VPUserName
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Cannot change User name'
  	goto error
  	end
  	
-- Audit updates for some fields
if update(ShowRates)
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'vDDUP', 'VPUserName: ' + i.VPUserName, null, 'C', 'ShowRates',
		 d.ShowRates, i.ShowRates, getdate(), ORIGINAL_LOGIN() 
   	from inserted i
   	join deleted d on i.VPUserName = d.VPUserName 
   	where d.ShowRates <> i.ShowRates
if update(RestrictedBatches)
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'vDDUP', 'VPUserName: ' + i.VPUserName, null, 'C', 'RestrictedBatches',
		 d.RestrictedBatches, i.RestrictedBatches, getdate(), ORIGINAL_LOGIN() 
   	from inserted i
   	join deleted d on i.VPUserName = d.VPUserName 
   	where d.RestrictedBatches <> i.RestrictedBatches
if update(MenuAdmin)
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'vDDUP', 'VPUserName: ' + i.VPUserName, null, 'C', 'MenuAdmin',
		 d.MenuAdmin, i.MenuAdmin, getdate(), ORIGINAL_LOGIN() 
   	from inserted i
   	join deleted d on i.VPUserName = d.VPUserName 
   	where d.MenuAdmin <> i.MenuAdmin
if update(FormAdmin)
   	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'vDDUP', 'VPUserName: ' + i.VPUserName, null, 'C', 'FormAdmin',
		 d.FormAdmin, i.FormAdmin, getdate(), ORIGINAL_LOGIN() 
   	from inserted i
   	join deleted d on i.VPUserName = d.VPUserName 
   	where d.FormAdmin <> i.FormAdmin
if update(MaxLookupRows)
	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'vDDUP', 'VPUserName: ' + i.VPUserName, null, 'C', 'MaxLookupRows',
		 d.MaxLookupRows, i.MaxLookupRows, getdate(), ORIGINAL_LOGIN() 
	from inserted i
  	join deleted d on i.VPUserName = d.VPUserName 
  	where isnull(i.MaxLookupRows,0) <> isnull(d.MaxLookupRows,0)
if update(MaxFilterRows)
	insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'vDDUP', 'VPUserName: ' + i.VPUserName, null, 'C', 'MaxFilterRows',
		 d.MaxFilterRows, i.MaxFilterRows, getdate(), ORIGINAL_LOGIN() 
	from inserted i
  	join deleted d on i.VPUserName = d.VPUserName 
  	where isnull(i.MaxFilterRows,0) <> isnull(d.MaxFilterRows,0)

-- Dan Sochacki - update 11/09/2007
IF update(HRCo)
   	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'vDDUP', 'VPUserName: ' + i.VPUserName, null, 'C', 'HRCo',
			   d.HRCo, i.HRCo, getdate(), ORIGINAL_LOGIN() 
   	      FROM inserted i
   	      JOIN deleted d ON i.VPUserName = d.VPUserName 
   	     WHERE isnull(d.HRCo,0) <> isnull(i.HRCo,0)
IF update(HRRef)
   	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'vDDUP', 'VPUserName: ' + i.VPUserName, null, 'C', 'HRRef',
		       d.HRRef, i.HRRef, getdate(), ORIGINAL_LOGIN() 
   	      FROM inserted i
   	      JOIN deleted d ON i.VPUserName = d.VPUserName 
   	     WHERE isnull(d.HRRef,0) <> isnull(i.HRRef,0)
-----------------------------------

IF update(PRCo)
   	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'vDDUP', 'VPUserName: ' + i.VPUserName, null, 'C', 'PRCo',
			   d.HRCo, i.HRCo, getdate(), ORIGINAL_LOGIN() 
   	      FROM inserted i
   	      JOIN deleted d ON i.VPUserName = d.VPUserName 
   	     WHERE isnull(d.HRCo,0) <> isnull(i.HRCo,0)
IF update(Employee)
   	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   		SELECT 'vDDUP', 'VPUserName: ' + i.VPUserName, null, 'C', 'Employee',
		       d.HRRef, i.HRRef, getdate(),ORIGINAL_LOGIN() 
   	      FROM inserted i
   	      JOIN deleted d ON i.VPUserName = d.VPUserName 
   	     WHERE isnull(d.HRRef,0) <> isnull(i.HRRef,0)

return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update User Profile!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_AccessibleOnly] CHECK (([AccessibleOnly]='Y' OR [AccessibleOnly]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_ConfirmUpdate] CHECK (([ConfirmUpdate]='Y' OR [ConfirmUpdate]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_DefaultDestType] CHECK (([DefaultDestType]='Viewpoint' OR [DefaultDestType]='EMail'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_EnterAsTab] CHECK (([EnterAsTab]='Y' OR [EnterAsTab]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_ExtendControls] CHECK (([ExtendControls]='Y' OR [ExtendControls]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_FormAdmin] CHECK (([FormAdmin]='Y' OR [FormAdmin]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_HideModFolders] CHECK (([HideModFolders]='Y' OR [HideModFolders]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_MenuAdmin] CHECK (([MenuAdmin]='Y' OR [MenuAdmin]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_MinimizeUse] CHECK (([MinimizeUse]='Y' OR [MinimizeUse]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_MultiFormInstance] CHECK (([MultiFormInstance]='Y' OR [MultiFormInstance]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_RestrictedBatches] CHECK (([RestrictedBatches]='Y' OR [RestrictedBatches]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_SavePrinterSettings] CHECK (([SavePrinterSettings]='Y' OR [SavePrinterSettings]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_ShowRates] CHECK (([ShowRates]='Y' OR [ShowRates]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_SmartCursor] CHECK (([SmartCursor]='Y' OR [SmartCursor]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_ToolTipHelp] CHECK (([ToolTipHelp]='Y' OR [ToolTipHelp]='N'))
GO
ALTER TABLE [dbo].[vDDUP] WITH NOCHECK ADD CONSTRAINT [CK_vDDUP_UseColorGrad] CHECK (([UseColorGrad]='Y' OR [UseColorGrad]='N' OR [UseColorGrad] IS NULL))
GO
ALTER TABLE [dbo].[vDDUP] ADD CONSTRAINT [PK_vDDUP] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viDDUP] ON [dbo].[vDDUP] ([VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
