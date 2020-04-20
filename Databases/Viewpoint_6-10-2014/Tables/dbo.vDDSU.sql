CREATE TABLE [dbo].[vDDSU]
(
[SecurityGroup] [int] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 9/12/13
-- Description:	Fire procedure to update user records
-- =============================================
CREATE TRIGGER [dbo].[mckUpdateUserRecords2] 
   ON  [dbo].[vDDSU] 
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	DECLARE @InsertedTable TABLE (VPUserName bVPUserName, SecurityGroup INT)
    DECLARE @Company int, @Employee INT, @VPUserName varchar(50), @SecurityGroup INT
    
	INSERT INTO @InsertedTable
	SELECT VPUserName, SecurityGroup
	FROM INSERTED


	DECLARE inserted_crsr CURSOR FOR
	SELECT i.VPUserName,SecurityGroup, u.PRCo, u.Employee
	FROM @InsertedTable i
		JOIN DDUP u ON u.VPUserName = i.VPUserName

	OPEN inserted_crsr
	FETCH NEXT FROM inserted_crsr INTO @VPUserName, @SecurityGroup, @Company, @Employee
	
	WHILE @@FETCH_STATUS=0
	BEGIN
		--SET @VPUserName = (SELECT i.VPUserName FROM INSERTED i);
    
		-- Set Default columns for JC Cost Projections and JC Revenue Projections (JCUO)
		IF EXISTS(SELECT VPUserName FROM INSERTED i WHERE i.SecurityGroup IN (200,201,202))
		BEGIN
			IF EXISTS(SELECT TOP 1 1 FROM JCUO u WHERE u.UserName = @VPUserName)	
			BEGIN
				--SET @Company = (SELECT TOP 1 u.DefaultCompany FROM DDUP u INNER JOIN INSERTED i ON u.VPUserName = i.VPUserName);
			
				EXEC mckspJCCPColDef @Company, @VPUserName
				GOTO reviewer
			END
		END
		

		--BEGIN REVIEWERS ADD--
		reviewer:
			--Conditional for existing assigned reviewer
		IF EXISTS(
				SELECT TOP 1 1 FROM vDDUP u
				INNER JOIN INSERTED i ON i.VPUserName = u.VPUserName
				WHERE u.udReviewer IS NULL AND u.Employee IS NOT NULL
					)
			BEGIN
				--Conditional for existing reviewer with matching VPUserName
				 
			IF EXISTS(
				SELECT i.VPUserName 
				FROM inserted i 
				WHERE i.SecurityGroup = 200 OR i.SecurityGroup = 201 OR i.SecurityGroup = 202 OR 
					i.SecurityGroup = 10 OR i.SecurityGroup = 11 OR i.SecurityGroup = 12
				) 
					BEGIN
					--NEED TO ADD WHERE CLAUSE OR JOIN
			
									

						SET @Company = (SELECT TOP 1 u.PRCo FROM vDDUP u
										INNER JOIN inserted i ON u.VPUserName = i.VPUserName)
						SET @Employee = (SELECT TOP 1 u.Employee FROM vDDUP u
											INNER JOIN inserted i ON i.VPUserName = u.VPUserName)
						SET @VPUserName = (Select i.VPUserName FROM inserted i)
				
			
						EXEC dbo.mckInsertReviewer @Company, @Employee, @VPUserName
					END
					
			END
			FETCH NEXT FROM inserted_crsr INTO @VPUserName, @SecurityGroup, @Company, @Employee
		END
		CLOSE inserted_crsr
		DEALLOCATE inserted_crsr
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  trigger [dbo].[vtDDSUd] on [dbo].[vDDSU] for DELETE 
/*-----------------------------------------------------------------
 *	Created: GG 7/31/03
 *	Modified: AL Added HQMA Auditing
 *
 *	This trigger deletes entries in vDDDU (Data Security Users) if  
 *	a delete was made to vDDSU (Security Groups Users) and that
 *	group exists in vDDDS
 *		
 *		
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @validcnt int

if @@rowcount = 0 return
set nocount on

-- remove User Data Security for the deleted SecurityGroup and User
delete dbo.vDDDU
from deleted t
join dbo.vDDDS s (nolock) on s.SecurityGroup = t.SecurityGroup
join dbo.vDDDU u on s.Datatype = u.Datatype and s.Qualifier = u.Qualifier and s.Instance = u.Instance
		and u.VPUserName = t.VPUserName
where not exists(select top 1 1 from dbo.vDDSU d
					join dbo.vDDDS s2 on s2.SecurityGroup = d.SecurityGroup and s2.Datatype = u.Datatype
						and s2.Qualifier = u.Qualifier and s2.Instance = u.Instance and u.VPUserName=d.VPUserName
					where s2.SecurityGroup <> t.SecurityGroup)
					
	
	-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDSU', 'D', 'SecurityGroup: ' + rtrim(SecurityGroup) + ' VPUserName: ' + rtrim(VPUserName), null, null,
	null, getdate(), SUSER_SNAME() from deleted
 
return






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  trigger [dbo].[vtDDSUi] on [dbo].[vDDSU] for INSERT 
/*-----------------------------------------------------------------
 *	Created GG 7/31/03
 *	Modified: AL 9/2/08: Added distinct check to avoid duplicate inserts.
 *						 Issue #129688
 *										 AL 03/02/09 - Added HQMA auditing 
 *	This trigger rejects insertion in vDDSU (Security Group Users) if
 *	any of the following error conditions exist:
 *
 *		Invalid Security Group
 *		Invalid User
 * 
 *	Add entries to vDDDU (Data Security Users) for all instances
 *	of secured data based on inserted Security Group and User
 *
 */----------------------------------------------------------------

as


declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
 
-- validate Security Group
select @validcnt = count(*) from dbo.vDDSG g (nolock)
join inserted i on g.SecurityGroup = i.SecurityGroup
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Invalid Security Group'
  	goto error
  	end
 
-- validate User 
select @validcnt = count(*) from dbo.vDDUP u (nolock)
join inserted i on  u.VPUserName = i.VPUserName
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Invalid User'
  	goto error
  	end
 
-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDSU', 'I', 'SecurityGroup: ' + rtrim(SecurityGroup) + ' VPUserName: ' + rtrim(VPUserName), null, null,
	null, getdate(), SUSER_SNAME() from inserted

-- add User Data Security for data accessible by the Security Group
insert dbo.vDDDU (Datatype, Qualifier, Instance, VPUserName)
select distinct s.Datatype, s.Qualifier, s.Instance, i.VPUserName -- added distinct to prevent duplicates
from inserted i
join dbo.vDDDS s (nolock) on i.SecurityGroup = s.SecurityGroup
      and not exists (select top 1 1 from dbo.vDDDU u
                                    where u.Datatype = s.Datatype and u.Qualifier = s.Qualifier
                                          and u.Instance = s.Instance and u.VPUserName = i.VPUserName)


return
 
error:
	select @errmsg = @errmsg + ' - cannot insert in Security Group User!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   trigger [dbo].[vtDDSUu] on [dbo].[vDDSU] for UPDATE 
/*-----------------------------------------------------------------
 *	Created: GG 7/31/03	
 *	Modified:
 *
 *	This trigger rejects update in vDDSU (Security Group Users) if any
 *	of the following error conditions exist:
 *
 *		Cannot change Security Group or User
 *
 */----------------------------------------------------------------
as


declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
 
/* check for changes to Security Group Users */
select @validcnt = count(*)
from inserted i
join deleted d	on i.SecurityGroup = d.SecurityGroup and i.VPUserName = d.VPUserName
if @validcnt <> @numrows
	begin
 	select @errmsg = 'Cannot change Security Group or User'
 	goto error
 	end
 
return
 
error:
     select @errmsg = @errmsg + ' - cannot update Security Group Users!'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
 
 






GO
CREATE UNIQUE CLUSTERED INDEX [viDDSU] ON [dbo].[vDDSU] ([SecurityGroup], [VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
