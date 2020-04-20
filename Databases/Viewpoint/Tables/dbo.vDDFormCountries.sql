CREATE TABLE [dbo].[vDDFormCountries]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_DDFormCountries] ON [dbo].[vDDFormCountries] ([Form], [Country]) ON [PRIMARY]
GO
