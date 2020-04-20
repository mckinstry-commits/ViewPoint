CREATE TABLE [dbo].[vVPQuerySecurity]
(
[Co] [smallint] NOT NULL,
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[SecurityGroup] [int] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Access] [tinyint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPQuerySecurity] ADD CONSTRAINT [PK_vVPQuerySecurity] PRIMARY KEY CLUSTERED  ([Co], [QueryName], [SecurityGroup], [VPUserName]) ON [PRIMARY]
GO
