CREATE TABLE [dbo].[pEmailTemplateField]
(
[EmailTemplateFieldID] [int] NOT NULL IDENTITY(1, 1),
[EmailTemplateID] [int] NOT NULL,
[EmailFieldID] [int] NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[pEmailTemplateField] ADD 
CONSTRAINT [PK_pEmailTemplateField] PRIMARY KEY CLUSTERED  ([EmailTemplateFieldID]) WITH (FILLFACTOR=90) ON [PRIMARY]
ALTER TABLE [dbo].[pEmailTemplateField] WITH NOCHECK ADD
CONSTRAINT [FK_pEmailTemplateField_pEmailField] FOREIGN KEY ([EmailFieldID]) REFERENCES [dbo].[pEmailField] ([EmailFieldID])
ALTER TABLE [dbo].[pEmailTemplateField] WITH NOCHECK ADD
CONSTRAINT [FK_pEmailTemplateField_pEmailTemplate] FOREIGN KEY ([EmailTemplateID]) REFERENCES [dbo].[pEmailTemplate] ([EmailTemplateID])
GO

GRANT SELECT ON  [dbo].[pEmailTemplateField] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pEmailTemplateField] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pEmailTemplateField] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pEmailTemplateField] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pEmailTemplateField] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pEmailTemplateField] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pEmailTemplateField] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pEmailTemplateField] TO [viewpointcs]
GO
