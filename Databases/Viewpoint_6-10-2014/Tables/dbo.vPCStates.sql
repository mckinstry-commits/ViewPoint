CREATE TABLE [dbo].[vPCStates]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[License] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Expiration] [dbo].[bDate] NULL,
[SalesTaxNo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UINo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[vtPCStatesi] 
   ON  [dbo].[vPCStates]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @errMsg VARCHAR(255)
    
--Country/State validation
	-- Validate Country
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE Country NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid Country'
		GOTO error
	END
	
	-- Validate State
	IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE [State] NOT IN(SELECT [State] FROM HQST (NOLOCK)))
	BEGIN
		SELECT @errMsg = 'Invalid State'
		GOTO error
	END
	
	-- Validate Country/State combinations
	IF EXISTS(
		SELECT TOP 1 1 
		FROM (SELECT [State], Country FROM INSERTED WHERE Country IS NOT NULL AND [State] IS NOT NULL) i 
		LEFT JOIN HQST hqst(NOLOCK) ON i.Country = hqst.Country AND i.State = hqst.[State]
		WHERE hqst.[State] IS NULL)
	BEGIN
		SELECT @errMsg = 'Invalid Country and State combination'
		GOTO error
	END
	
	RETURN

error:
	SELECT @errMsg = @errMsg +  ' - cannot insert PC States!'
	RAISERROR(@errMsg, 11, -1);
	ROLLBACK TRANSACTION

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[vtPCStatesu]
   ON  [dbo].[vPCStates]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @errMsg VARCHAR(255)
    
--Country/State validation
	-- Validate Country
	IF UPDATE(Country)
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE Country NOT IN(SELECT Country FROM HQCountry (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid Country'
			GOTO error
		END
	END
	
	-- Validate State
	IF UPDATE([State])
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM INSERTED WHERE [State] NOT IN(SELECT [State] FROM HQST (NOLOCK)))
		BEGIN
			SELECT @errMsg = 'Invalid State'
			GOTO error
		END
	END
	
	-- Validate Country/State combinations
	IF UPDATE(Country) OR UPDATE([State])
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1 
			FROM (SELECT [State], Country FROM INSERTED WHERE Country IS NOT NULL AND [State] IS NOT NULL) i 
			LEFT JOIN HQST hqst(NOLOCK) ON i.Country = hqst.Country AND i.State = hqst.[State]
			WHERE hqst.[State] IS NULL)
		BEGIN
			SELECT @errMsg = 'Invalid Country and State combination'
			GOTO error
		END
	END

	RETURN
	
error:
	SELECT @errMsg = @errMsg +  ' - cannot insert PC States!'
	RAISERROR(@errMsg, 11, -1);
	ROLLBACK TRANSACTION
END

GO
ALTER TABLE [dbo].[vPCStates] ADD CONSTRAINT [PK_vPCStates] PRIMARY KEY CLUSTERED  ([VendorGroup], [Vendor], [Country], [State]) ON [PRIMARY]
GO
