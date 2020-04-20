CREATE TABLE [dbo].[vDMAnnotations]
(
[AttachmentID] [int] NOT NULL,
[AnnotationData] [varbinary] (max) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDMAnnotations] ADD CONSTRAINT [PK_vDMAnnotations] PRIMARY KEY CLUSTERED  ([AttachmentID]) ON [PRIMARY]
GO
