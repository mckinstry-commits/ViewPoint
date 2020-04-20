SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[RPFRShared] AS
/***********************************************
 * Created:
 * Modified: GG 10/27/06
 *
 * Combines standard and custom Form Report assignments 
 * from vRPFR and vRPFRc.
 *
 * Uses 'instead of triggers' to handle data modifications 
 *
 *******************************************/
SELECT	ISNULL(c.Form, r.Form) AS Form,
		ISNULL(c.ReportID, r.ReportID) AS ReportID,
		ISNULL(c.Active, 'Y') AS Active,
		ISNULL(c.OvrDocumentTitle,r.OvrDocumentTitle) AS OvrDocumentTitle,
		CASE WHEN c.ReportID IS NOT NULL THEN 1 ELSE 0 END AS Custom,
		CASE WHEN c.ReportID IS NULL and r.ReportID IS NOT NULL THEN 'Standard' 
				 WHEN c.ReportID IS NOT NULL and r.ReportID IS NOT NULL THEN 'Override' 
				 WHEN c.ReportID IS NOT NULL and r.ReportID IS  NULL THEN 'Custom' 
				ELSE 'Unknown' END AS Status
FROM dbo.vRPFRc AS c
FULL OUTER JOIN dbo.vRPFR AS r ON r.Form = c.Form AND r.ReportID = c.ReportID

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtdRPFRShared] on [dbo].[RPFRShared] INSTEAD OF DELETE AS
-- =============================================
-- Created: GG 10/31/06		
-- Modified:
--		CJG 05/18/2010 - Issue 139460 - Keep from deleting entire RPFRc table.
--
-- Processes deletions to RPFRShared, a view combining standard
-- and custom report links, into their respective tables.
--
-- When logged in as 'viewpointcs', standard form report assignments are deleted
-- from vRPFR, and custom assignments are removed from vRPFRc only if they have no 
-- corresponding standard entry.
--
-- All other logins delete custom form report assignments only.
--
-- =============================================
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- 'viewpointcs' login will delete custom and standard form report assignments
if suser_name() = 'viewpointcs'
	begin
	-- remove custom form reports only if they have no corresponding standard entry
	delete dbo.vRPFRc
	from deleted d
	left join dbo.vRPFR f (nolock) on f.Form = d.Form and f.ReportID = d.ReportID 
	where f.Form is null
	and vRPFRc.Form = d.Form and vRPFRc.ReportID = d.ReportID -- Join removes all rows.  Need to filter.
	-- remove any existing standard form reports
	delete dbo.vRPFR
	from deleted d
	join dbo.vRPFR f on f.Form = d.Form and f.ReportID = d.ReportID 
	end
else
	-- all other logins, remove existing custom form report assignments only
	delete dbo.vRPFRc
	from deleted d
	join dbo.vRPFRc f on f.Form = d.Form and f.ReportID = d.ReportID 
	
return

	








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtiRPFRShared] on [dbo].[RPFRShared] INSTEAD OF INSERT AS
-- =============================================
-- Created: GG 10/31/06		
-- Modified: AR 05/28/2013 - adding the override for the document title
--
-- Processes inserts to RPFRShared, a view combining standard
-- and custom form report links, into their respective tables.
--
-- When using the 'viewpointcs' login, adding standard form/report combinations will 
-- insert entries in vRPFR, and those.  Form/report combinations added for non-standard
-- forms or reports will be inserted as custom entries in vRPFRc.
--
-- Adding form/report combinations for any other login inserts custom entries in vRPFRc.
--
-- =============================================
declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- 'viewpointcs' login will insert custom and standard form/report combinations
if suser_name() = 'viewpointcs'
	begin
	-- insert standard form/report combos for standard forms and reports
	insert dbo.vRPFR(Form, ReportID, OvrDocumentTitle)
	select i.Form, i.ReportID, i.OvrDocumentTitle
	from inserted i
	join dbo.vDDFH h (nolock) on h.Form = i.Form		-- must be a standard form
	join dbo.vRPRT t (nolock) on t.ReportID = i.ReportID	-- must be a standard report
	left join dbo.vRPFR f on f.Form = i.Form and f.ReportID = i.ReportID 
	where f.ReportID is null -- exclude existing entries
	-- insert custom form/report combos for non-standard forms or reports
	insert dbo.vRPFRc(Form, ReportID, Active)
	select i.Form, i.ReportID, i.Active
	from inserted i
	left join dbo.vDDFH h (nolock) on h.Form = i.Form		
	left join dbo.vRPRT t (nolock) on t.ReportID = i.ReportID	
	left join dbo.vRPFRc f on f.Form = i.Form and f.ReportID = i.ReportID 
	where (h.Form is null or t.ReportID is null) and f.ReportID is null -- exclude standard form/report combos and existing entries
	end
else
	-- insert custom form reports form all other logins
	insert dbo.vRPFRc(Form, ReportID, Active,OvrDocumentTitle)
	select i.Form, i.ReportID, i.[Active],i.OvrDocumentTitle
	from inserted i
	left join dbo.vRPFRc f on f.Form = i.Form and f.ReportID = i.ReportID 
	where f.ReportID is null -- exclude existing entries


return
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtuRPFRShared] ON [dbo].[RPFRShared]
    INSTEAD OF UPDATE
AS
    -- =============================================
-- Created: GG 10/31/06		
-- Modified: GG 04/05/07 - remove unecessary custom RPFRc entries
--		    CJG 05/18/2010 - Issue 139460 - Keep from updating entire RPFRc table.
--			AMR 05/22/2013 - TFS 47607 - Adding OvrDocumentTitle
--			GP	05/28/2013 - TFS 47308 - Added update for OvrDocumentTitle column
--
-- Processes updates to RPFRShared, a view combining standard
-- and custom report links, into their respective tables.
--
-- When using the 'viewpointcs' login, no updates to standard form/report combinations in vRPFR.
-- Custom combinations will update vRPFRc only if they have no corresponding standard entry,
-- to prevent overwritting custom info.
--
-- Updating form/reports for any other login inserts/updates custom entries in vRPFRc.
--
--
-- =============================================
    DECLARE @numrows INT
   
    SELECT  @numrows = @@rowcount
    IF @numrows = 0 
        RETURN
   
    SET nocount ON

-- 'viewpointcs' login will update custom form/report combinations only, nothing to update on standard entries
    IF SUSER_NAME() = 'viewpointcs'
	BEGIN
	-- update existing custom form/report combos without standard entries
        UPDATE  dbo.vRPFRc
        SET     Active = i.Active
        FROM    inserted i
                LEFT JOIN dbo.vRPFR f ( NOLOCK ) ON f.Form = i.Form
                                                    AND f.ReportID = i.ReportID
        WHERE   f.Form IS NULL	-- exclude form/report combos with standard entries
                AND vRPFRc.Form = i.Form
                AND vRPFRc.ReportID = i.ReportID -- Join updates all rows.  Need to filter.

		UPDATE dbo.vRPFR
		SET OvrDocumentTitle = i.OvrDocumentTitle
		FROM INSERTED i
		JOIN dbo.vRPFR ON vRPFR.Form = i.Form AND vRPFR.ReportID = i.ReportID
	END
    ELSE
	BEGIN
		-- update override info (done first incase record exists before insert attempt)
		UPDATE dbo.vRPFRc
		SET Active = i.Active, 
			OvrDocumentTitle = i.OvrDocumentTitle
		FROM inserted i
		JOIN dbo.vRPFRc f ON f.Form = i.Form
		AND f.ReportID = i.ReportID 

		-- insert/update custom form/report combinations from all other logins
		-- add override records for standard parameters not already in vRPFDc
		INSERT  dbo.vRPFRc
		( Form,
			ReportID,
			Active,
			OvrDocumentTitle
		)
		SELECT  i.Form,
				i.ReportID,
				i.[Active],
				i.OvrDocumentTitle
		FROM    inserted i
				LEFT JOIN dbo.vRPFRc f ON f.Form = i.Form
											AND f.ReportID = i.ReportID
		WHERE   f.Form IS NULL	-- exclude existing entries
	END


    RETURN
GO
GRANT SELECT ON  [dbo].[RPFRShared] TO [public]
GRANT INSERT ON  [dbo].[RPFRShared] TO [public]
GRANT DELETE ON  [dbo].[RPFRShared] TO [public]
GRANT UPDATE ON  [dbo].[RPFRShared] TO [public]
GRANT SELECT ON  [dbo].[RPFRShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPFRShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPFRShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPFRShared] TO [Viewpoint]
GO
