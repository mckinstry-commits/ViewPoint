CREATE TABLE [dbo].[bHQCountry]
(
[Country] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[CountryName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_bHQCountry_Country] ON [dbo].[bHQCountry] ([Country]) ON [PRIMARY]
GO
