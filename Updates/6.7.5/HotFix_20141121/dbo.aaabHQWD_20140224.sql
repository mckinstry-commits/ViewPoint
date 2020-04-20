/*--------------------------------------------------------------
 *  Alter HQWD to add EditDocDefault column
 *
 *  Created By:		SCOTTP 02/24/2014 TFS-74937
 *  Modified By:
 *--------------------------------------------------------------*/
 
IF NOT EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'bHQWD' AND COLUMN_NAME = 'EditDocDefault')
BEGIN
	ALTER TABLE [dbo].[bHQWD] ADD [EditDocDefault] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQWD_EditDocDefault]  DEFAULT ('N')
END
GO

sp_refreshview HQWD
GO


