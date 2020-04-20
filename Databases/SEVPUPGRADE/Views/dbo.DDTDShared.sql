SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE      view [dbo].[DDTDShared]
/****************************************
 * Created: Dave C 05/20/2009
 * 
 * Combines standard and custom Menu Items
 * from vDDTD and vDDTDc.  
 *
 ****************************************/
as
select a.FolderTemplate, a.ItemType, a.MenuItem, a.MenuSeq from dbo.vDDTD a
UNION ALL
select b.FolderTemplate, b.ItemType, b.MenuItem, b.MenuSeq from dbo.vDDTDc b



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE TRIGGER [dbo].[vtdDDTDShared] on [dbo].[DDTDShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: Dave C 05/20/2009
--
-- Processes deletions to DDTDShared, a view combining standard
-- and custom template Menu Items, into their respective tables.
--
-- Deleting any template removes it from the appropriate table.
-- When logged in as 'viewpointcs', standard template items can be deleted from vDDTD.
-- All other logins may only delete custom template items.
--
--
-- =============================================

set nocount on

-- Prevent Standard Template Items from being removed, unless login is viewpointcs

IF suser_name() = 'viewpointcs'
	BEGIN
		DELETE vDDTD
		FROM vDDTD t INNER JOIN deleted d on
		t.FolderTemplate = d.FolderTemplate and
		t.ItemType = d.ItemType and
		t.MenuItem = d.MenuItem
		WHERE d.FolderTemplate < 10000
	END

-- Delete Custom Template Items
DELETE vDDTDc
FROM vDDTDc t INNER JOIN deleted d on
t.FolderTemplate = d.FolderTemplate and
t.ItemType = d.ItemType and
t.MenuItem = d.MenuItem
WHERE d.FolderTemplate > 9999


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[vtiDDTDShared] on [dbo].[DDTDShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: Dave C 05/20/2009	
--
-- Processes inserts to DDTDShared, a view combining standard
-- and custom templates items, into their respective tables.
--
-- Adding Standard Template Items when logged in as 'viewpointcs' inserts vDDTD.
-- Standard Templates Items can only be added from the 'viewpointcs' login.
-- Adding a Custom Templates Items inserts vDDTDc regardless of login.
--
-- =============================================
   
set nocount on

-- Insert Standard Template Items (FolderTemplate #s < 10000) into vDDTD.
IF suser_name() = 'viewpointcs'
	BEGIN
		INSERT vDDTD (FolderTemplate, ItemType, MenuItem, MenuSeq)
		SELECT i.FolderTemplate, i.ItemType, i.MenuItem, i.MenuSeq
		FROM inserted i
		WHERE i.FolderTemplate < 10000
	END
		
-- Insert Custom Templates (FolderTemplate #s > 9999) into vDDTDc.
INSERT vDDTDc (FolderTemplate, ItemType, MenuItem, MenuSeq)
SELECT i.FolderTemplate, i.ItemType, i.MenuItem, i.MenuSeq
FROM inserted i
WHERE i.FolderTemplate > 9999



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[vtuDDTDShared] on [dbo].[DDTDShared] INSTEAD OF UPDATE AS
-- ============================================
-- Created: Dave C 05/20/2009	
--
-- Processes updates to DDTDShared, a view combining standard
-- and custom templates items into their respective tables.
--
-- Updating standard template items when logged in as 'viewpointcs' updates vDDTD.
-- Updating custom template items updates vDDTDc regardless of login.
--
-- =============================================
   
set nocount on

-- handle standard reports (report id#s < 10000)
-- if using the 'viewpointcs' login allow Standard Template Item updates
IF suser_name() = 'viewpointcs'
	BEGIN
		UPDATE vDDTD SET MenuSeq = i.MenuSeq
		FROM inserted i
		INNER JOIN vDDTD t ON
		i.FolderTemplate = t.FolderTemplate and
		i.ItemType = t.ItemType and
		i.MenuItem = t.MenuItem
		WHERE i.FolderTemplate < 10000
	END
	
-- Update the Custom Template Items			
UPDATE vDDTDc SET MenuSeq = i.MenuSeq
FROM inserted i
INNER JOIN vDDTD t ON
i.FolderTemplate = t.FolderTemplate and
i.ItemType = t.ItemType and
i.MenuItem = t.MenuItem
WHERE i.FolderTemplate > 9999


GO
GRANT SELECT ON  [dbo].[DDTDShared] TO [public]
GRANT INSERT ON  [dbo].[DDTDShared] TO [public]
GRANT DELETE ON  [dbo].[DDTDShared] TO [public]
GRANT UPDATE ON  [dbo].[DDTDShared] TO [public]
GO
