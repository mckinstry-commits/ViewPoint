-- ================================================
-- Template generated from Template Explorer using:
-- Create Trigger (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- See additional Create Trigger templates for more
-- examples of different Trigger statements.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER mtrI_budGeographicLookup 
   ON  dbo.budGeographicLookup
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	IF EXISTS ( SELECT 1 FROM inserted i JOIN deleted d ON i.McKCityId=d.McKCityId)
		UPDATE budGeographicLookup SET DateModified=GETDATE(), ModifiedBy=SUSER_SNAME() 
		FROM INSERTED i WHERE i.McKCityId=budGeographicLookup.McKCityId
 	ELSE
		UPDATE budGeographicLookup SET DateCreated=GETDATE(),CreatedBy=SUSER_SNAME(),DateModified=GETDATE(), ModifiedBy=SUSER_SNAME()	
		FROM INSERTED i WHERE i.McKCityId=budGeographicLookup.McKCityId

END
GO
