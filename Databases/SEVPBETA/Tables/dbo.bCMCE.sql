CREATE TABLE [dbo].[bCMCE]
(
[CMCo] [dbo].[bCompany] NOT NULL,
[UploadDate] [dbo].[bDate] NOT NULL,
[Seq] [int] NOT NULL,
[BankAcct] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ChkNo] [dbo].[bCMRef] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[ClearDate] [dbo].[bDate] NULL,
[ErrorText] [varchar] (60) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC 8/11/07
-- Create date: 8/11/07 Issue #128506 - Prevent invalid BankAccount from being inserted
-- Description:	
-- =============================================
CREATE TRIGGER [dbo].[vtCMCEi] 
   ON  [dbo].[bCMCE] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here

	IF EXISTS (SELECT TOP 1 1 FROM 
				(
				SELECT inserted.CMCo, inserted.BankAcct
					FROM inserted

				EXCEPT

				SELECT inserted.CMCo, inserted.BankAcct
					FROM CMAC
					INNER JOIN inserted ON CMAC.CMCo = inserted.CMCo AND CMAC.BankAcct = inserted.BankAcct
				) AS InvalidRecords
			  )
		BEGIN
			DECLARE @errmsg VARCHAR(255)		
			SELECT @errmsg = 'Invalid Company/Bank Account combination.'
			RAISERROR(@errmsg, 11, -1);
			ROLLBACK TRANSACTION
		END
			
END

GO
CREATE UNIQUE CLUSTERED INDEX [IX_bCMCE_CMCo_UPloadDate_Seq] ON [dbo].[bCMCE] ([CMCo], [UploadDate], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bCMCE] WITH NOCHECK ADD CONSTRAINT [FK_bCMCE_bCMCO_CMCo] FOREIGN KEY ([CMCo]) REFERENCES [dbo].[bCMCO] ([CMCo])
GO
