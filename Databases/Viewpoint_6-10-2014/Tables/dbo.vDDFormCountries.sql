CREATE TABLE [dbo].[vDDFormCountries]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDFormCountries] ADD CONSTRAINT [PK_vDDFormCountries] PRIMARY KEY CLUSTERED  ([Form], [Country]) ON [PRIMARY]
GO
