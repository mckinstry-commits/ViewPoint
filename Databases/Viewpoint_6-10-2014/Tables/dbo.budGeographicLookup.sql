CREATE TABLE [dbo].[budGeographicLookup]
(
[City] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[County] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CreatedBy] [dbo].[bVPUserName] NULL,
[DateCreated] [dbo].[bDate] NULL,
[DateModified] [dbo].[bDate] NULL,
[IsActive] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udGeographicLookup_IsActive] DEFAULT ('N'),
[ManualEntry] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udGeographicLookup_ManualEntry] DEFAULT ('N'),
[McKCityId] [varchar] (6) COLLATE Latin1_General_BIN NOT NULL,
[ModifiedBy] [dbo].[bVPUserName] NULL,
[PostOffice] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[TaxRateEffectiveDate] [dbo].[bDate] NULL,
[ZipCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MatchString] [varchar] (75) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[mtrIU_budGeographicLookup] 
ON  [dbo].[budGeographicLookup]
AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	
	IF ( UPDATE([State]) OR UPDATE([City]) OR UPDATE([ZipCode]) )
	BEGIN
		update budGeographicLookup SET MatchString=UPPER(dbo.mfnStripNonAlphaNumeric(State + ZipCode + City)),DateModified=GETDATE(), ModifiedBy=SUSER_SNAME() 
	END

	IF ( UPDATE([County]) OR UPDATE([IsActive]) OR UPDATE([ManualEntry]) OR UPDATE([PostOffice]) )
	BEGIN
		update budGeographicLookup SET DateModified=GETDATE(), ModifiedBy=SUSER_SNAME() 
	END
END
GO
CREATE NONCLUSTERED INDEX [idxbudGeographicLookup_City] ON [dbo].[budGeographicLookup] ([City]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idxbudGeographicLookup_Match] ON [dbo].[budGeographicLookup] ([MatchString]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biudGeographicLookup] ON [dbo].[budGeographicLookup] ([McKCityId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idxbudGeographicLookup_State] ON [dbo].[budGeographicLookup] ([State], [ZipCode]) ON [PRIMARY]
GO
