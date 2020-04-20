SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   view [dbo].[DDDTSecurable]
/****************************************
* Created: 11/21/06 JRK based on DDDTShared but limiting the datatypes.
* Modified:			DRC 4/21/2010 - #132526 Remove bRQCo
*					GF 09/22/2011 - TK-08517 added bSMCo as securable datatype
*
*
* Combines standard and custom Datatype information
* from vDDDT and vDDDTc but limits to securable data types
*
* Important: Data security is implemented via the triggers on the 
* master tables for these dataypes.  Any alterations to this list
* will require modifications to their triggers.
*
****************************************/
as
select Datatype, Description, InputType, InputMask, InputLength,
	Prec, Secure, DfltSecurityGroup, Label, MasterTable, MasterColumn,
	QualifierColumn, Lookup, SetupForm, ReportLookup, SQLDatatype, ReportOnly
from dbo.DDDTShared (nolock)
where Datatype in ('bAPCo', 'bARCo', 'bCMCo', 'bEMCo', 'bGLCo', 'bHQCo', 
'bINCo', 'bJCCo', 'bMSCo', 'bPOCo', 'bPRCo', 'bSLCo',  'bCMAcct', 'bEmployee', 
'bContract', 'bJob', 'bLoc','bHRRef','bJBCo', 'bHRCo', 'bPMCo', 'bSMCo')


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtuDDDTSecurable] on [dbo].[DDDTSecurable] INSTEAD OF UPDATE AS
-- =============================================
-- Created: GG 05/03/07		
--
-- Modified: JonathanP 06/12/07 - Added INSERT code that runs if the update returns 0 rows.
--
-- DDDTSecurable comes from the DDDTShared view, which in turn comes from the 2 tables, vDDDT and 
-- vDDDTc. When an update is done on DDDTSecurable, only vDDDTc should be updated. This update 
-- trigger will make sure that happens.
--
-- =============================================
declare @numrows int, @updaterows int
   
select @numrows = @@rowcount
if @numrows = 0 return
   
set nocount on

-- Update vDDDTc where insert rows exist in vDDDTc.
UPDATE v
SET Secure = i.Secure, DfltSecurityGroup = i.DfltSecurityGroup
FROM dbo.vDDDTc v
join inserted i on v.Datatype = i.Datatype

set @updaterows = @@rowcount

if @updaterows <> @numrows
	begin
	-- Insert rows into vDDDTc where inserted rows do not exist in vDDDTc.
	INSERT dbo.vDDDTc(Datatype, Secure, DfltSecurityGroup)
	SELECT i.Datatype, i.Secure, i.DfltSecurityGroup
	FROM inserted i
	left join dbo.vDDDTc v on v.Datatype = i.Datatype
	where isnull(v.Datatype,'') = ''
	end


return








GO
GRANT SELECT ON  [dbo].[DDDTSecurable] TO [public]
GRANT INSERT ON  [dbo].[DDDTSecurable] TO [public]
GRANT DELETE ON  [dbo].[DDDTSecurable] TO [public]
GRANT UPDATE ON  [dbo].[DDDTSecurable] TO [public]
GO
