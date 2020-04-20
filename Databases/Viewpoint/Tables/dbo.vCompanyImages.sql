CREATE TABLE [dbo].[vCompanyImages]
(
[Id] [tinyint] NOT NULL,
[CompanyLogo] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vCompanyImages] WITH NOCHECK ADD
CONSTRAINT [FK_vCompanyImages_bHQCO_Id] FOREIGN KEY ([Id]) REFERENCES [dbo].[bHQCO] ([HQCo])
GO
ALTER TABLE [dbo].[vCompanyImages] ADD CONSTRAINT [PK_vCompanyImages] PRIMARY KEY CLUSTERED  ([Id]) ON [PRIMARY]
GO
