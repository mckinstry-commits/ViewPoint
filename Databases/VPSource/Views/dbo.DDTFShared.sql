SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE      view [dbo].[DDTFShared]
/****************************************
 * Created: Dave C 05/14/2009
 * 
 * Combines standard and custom Template form information
 * from vDDTF and vDDTFc.  
 *
 ****************************************/
as
select isnull(a.FolderTemplate, b.FolderTemplate) as FolderTemplate,
	isnull(a.Title, b.Title) as Title,
	isnull(a.[Mod],b.[Mod]) as [Mod],
	isnull(b.Active, 'Y') as Active
from dbo.vDDTF a
full outer join dbo.vDDTFc b on a.FolderTemplate = b.FolderTemplate



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[vtdDDTFShared] on [dbo].[DDTFShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: Dave C 05/15/2009
--
-- Processes deletions to DDTFShared, a view combining standard
-- and custom template forms, into their respective tables.
--
-- Deleting any template removes its overridden or custom entry from vDDTFc.
-- When logged in as 'viewpointcs', standard templates can be deleted from vDDTF.
--
-- Delete triggers on vDDTF and vDDTFc perform cascading deletes to remove all
-- related data referencing the deleted standard or custom template.
--
-- =============================================
declare @errmsg varchar(255)

set nocount on

-- Prevent Standard Templates from being removed, unless login is viewpointcs

IF suser_name() = 'viewpointcs'
	BEGIN
		DELETE vDDTF
		FROM vDDTF t INNER JOIN deleted d on
		t.FolderTemplate = d.FolderTemplate
		WHERE d.FolderTemplate < 10000
	
		DELETE vDDTFc
		FROM vDDTFc c INNER JOIN deleted d on
		c.FolderTemplate = d.FolderTemplate
	END
ELSE
		DELETE vDDTFc
		FROM vDDTFc c INNER JOIN deleted d on
		c.FolderTemplate = d.FolderTemplate
		WHERE c.FolderTemplate > 9999



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE TRIGGER [dbo].[vtiDDTFShared] on [dbo].[DDTFShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: Dave C 05/15/2009	
--
-- Processes inserts to DDTFShared, a view combining standard
-- and custom templates, into their respective tables.
--
-- Adding a Standard Template when logged in as 'viewpointcs' inserts vDDTF.
-- Standard Templates with 'Active' flag set to 'N' also get added to vDDTFc.
-- Standard Templates can only be added from the 'viewpointcs' login.
-- Adding a Custom Templates inserts vDDTFc regardless of login.
--
-- =============================================
   
set nocount on

-- Insert Standard Templates (FolderTemplate #s < 10000) into vDDTF. If Standard Template has 'Active' flag set to 'N',
-- create a copy in DDTFc. Only available to 'viewpointcs' login.
IF suser_name() = 'viewpointcs'
	BEGIN
		INSERT vDDTF (FolderTemplate, Title, [Mod])
		SELECT i.FolderTemplate, i.Title, i.[Mod]
		FROM inserted i
		WHERE i.FolderTemplate < 10000
		
		INSERT vDDTFc (FolderTemplate, Title, [Mod], Active)
		SELECT i.FolderTemplate, i.Title, i.[Mod], i.Active
		FROM inserted i
		WHERE i.Active = 'N' and i.FolderTemplate < 10000
		
		INSERT vDDTFc (FolderTemplate, Title, [Mod], Active)
		SELECT i.FolderTemplate, i.Title, i.[Mod], i.Active
		FROM inserted i
		WHERE i.FolderTemplate > 9999
	END
ELSE
-- Insert Custom Templates (FolderTemplate #s > 9999) into vDDTFc.
	INSERT vDDTFc (FolderTemplate, Title, [Mod], Active)
	SELECT i.FolderTemplate, i.Title, i.[Mod], i.Active
	FROM inserted i
	WHERE i.FolderTemplate > 9999



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtuDDTFShared] on [dbo].[DDTFShared] INSTEAD OF UPDATE AS
-- ============================================
-- Created: Dave C 05/15/2009	

--
-- Processes updates to DDTFShared, a view combining standard
-- and custom templates into their respective tables.
--
-- Updating a standard template when logged in as 'viewpointcs' updates vDDTF.
-- The only field on a standard template that can be changed from other logins insert/updates is the 'Active' flag.
-- Updating a custom template updates vDDTFc regardless of login.
--
-- =============================================
   
set nocount on

-- handle standard reports (report id#s < 10000)
-- if using the 'viewpointcs' login allow Standard Template updates
IF suser_name() = 'viewpointcs'
	BEGIN
		UPDATE vDDTF SET Title = i.Title, [Mod] = i.[Mod]
		FROM inserted i
		INNER JOIN vDDTF t ON i.FolderTemplate = t.FolderTemplate
		WHERE i.FolderTemplate < 10000
		
		UPDATE vDDTFc SET Title = i.Title, [Mod] = i.[Mod], Active = i.Active
		FROM inserted i
		INNER JOIN vDDTFc t ON i.FolderTemplate = t.FolderTemplate
		WHERE i.FolderTemplate > 9999	
	END
ELSE
	UPDATE vDDTFc SET Title = i.Title, [Mod] = i.[Mod], Active = i.Active
	FROM inserted i
	INNER JOIN vDDTFc t ON i.FolderTemplate = t.FolderTemplate
	WHERE i.FolderTemplate > 9999
	
	IF NOT EXISTS(
			SELECT TOP 1 1
			FROM vDDTFc t
			INNER JOIN inserted i ON t.FolderTemplate = i.FolderTemplate
			WHERE i.FolderTemplate < 10000)
				BEGIN
					INSERT INTO vDDTFc (FolderTemplate, Title, [Mod], Active)
					SELECT i.FolderTemplate, i.Title, i.[Mod], i.Active
					FROM inserted i
					WHERE i.Active = 'N' and i.FolderTemplate < 10000	
				END
		ELSE
			BEGIN
				DELETE FROM vDDTFc
				WHERE FolderTemplate IN(
					SELECT t.FolderTemplate
					FROM vDDTFc t
					INNER JOIN inserted i ON t.FolderTemplate = i.FolderTemplate
					WHERE t.Active = 'N' and i.Active = 'Y' and i.FolderTemplate < 10000)
			END

GO
GRANT SELECT ON  [dbo].[DDTFShared] TO [public]
GRANT INSERT ON  [dbo].[DDTFShared] TO [public]
GRANT DELETE ON  [dbo].[DDTFShared] TO [public]
GRANT UPDATE ON  [dbo].[DDTFShared] TO [public]
GO
