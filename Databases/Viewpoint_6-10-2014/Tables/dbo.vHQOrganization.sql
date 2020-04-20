CREATE TABLE [dbo].[vHQOrganization]
(
[OrganizationID] [uniqueidentifier] NOT NULL,
[OrganizationName] [nvarchar] (64) COLLATE Latin1_General_BIN NOT NULL,
[CreatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[DBCreatedDate] [datetime] NOT NULL,
[UpdatedByUser] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[DBUpdatedDate] [datetime] NULL,
[Version] [int] NOT NULL CONSTRAINT [DF_vHQOrganization_Version] DEFAULT ((1))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQOrganization] ADD CONSTRAINT [PK_vOrganization] PRIMARY KEY CLUSTERED  ([OrganizationID]) ON [PRIMARY]
GO
