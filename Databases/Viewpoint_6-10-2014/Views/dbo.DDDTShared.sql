SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   view [dbo].[DDDTShared]
/****************************************
* Created: 06/09/03 GG
* Modified: 11/21/06 JRK "Secure" used to default to 'N' but then inserts failed due to constant.
*			05/18/07 - return Secure as 'N' if entry does not exist in vDDDTc
*			12/06/07 JonathanP - #126413 - added InputType to vDDDTc
*			04/07/08 CC - #127214 - added TextID to view for international labeling
*
* Combines standard and custom Datatype information
* from vDDDT and vDDDTc
*
****************************************/
as
select d.Datatype, d.Description, 
	isnull(c.InputType,d.InputType) as InputType,
	isnull(c.InputMask,d.InputMask) as InputMask,
	isnull(c.InputLength,d.InputLength) as InputLength,
	isnull(c.Prec,d.Prec) as Prec,
	isnull(c.Secure, 'N') as Secure,
	c.DfltSecurityGroup, 
	c.Label, d.MasterTable, d.MasterColumn, d.MasterDescColumn,
	d.QualifierColumn, d.Lookup, d.SetupForm,
	d.ReportLookup, d.SQLDatatype, d.ReportOnly, d.TextID
from dbo.vDDDT d (nolock)
left outer join dbo.vDDDTc c on  c.Datatype = d.Datatype



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL
-- Create date: 7/9/07
-- Description:	In instead of insert trigger to handle inserts into the
--				DDDTShared table
-- =============================================
CREATE TRIGGER [dbo].[vtuDDDTShared] on [dbo].[DDDTShared] INSTEAD OF UPDATE AS
  declare @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 RETURN

-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
IF UPDATE([Label])	
update DDDTc set DDDTc.[Label] = i.Label 
	from inserted i
	join DDDTc c on c.[Datatype] = i.Datatype

--IF UPDATE([Label])
--	SET 
--	UPDATE [DDDTc]
--	SET DDDTc.Label = i.[Label]
--	WHERE DDDTc.[Datatype] = i.[Datatype]
--END
	

RETURN

GO
GRANT SELECT ON  [dbo].[DDDTShared] TO [public]
GRANT INSERT ON  [dbo].[DDDTShared] TO [public]
GRANT DELETE ON  [dbo].[DDDTShared] TO [public]
GRANT UPDATE ON  [dbo].[DDDTShared] TO [public]
GRANT SELECT ON  [dbo].[DDDTShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDDTShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDDTShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDDTShared] TO [Viewpoint]
GO
