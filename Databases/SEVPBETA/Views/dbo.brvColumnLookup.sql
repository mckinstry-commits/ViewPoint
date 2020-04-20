SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[brvColumnLookup]
    AS
    SELECT     Name = c.name, Sysname = o.name
    FROM         dbo.syscolumns c join sysobjects o on c.id = object_id(o.name)

GO
GRANT SELECT ON  [dbo].[brvColumnLookup] TO [public]
GRANT INSERT ON  [dbo].[brvColumnLookup] TO [public]
GRANT DELETE ON  [dbo].[brvColumnLookup] TO [public]
GRANT UPDATE ON  [dbo].[brvColumnLookup] TO [public]
GO
