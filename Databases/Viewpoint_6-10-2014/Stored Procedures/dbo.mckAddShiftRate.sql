SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mahendar B
-- Create date: 4/1/2014
-- Description:	Add new ShiftRate from Union Class Excel.
-- =============================================
CREATE PROCEDURE [dbo].[mckAddShiftRate] 
@PRCo as tinyint
,@Craft as bCraft 
,@Class as bClass 
,@Shift as tinyint
,@OldRate AS bUnitCost 
,@NewRate as bUnitCost

AS
BEGIN


INSERT INTO [Viewpoint].[dbo].[PRCP]
           ([PRCo]
           ,[Craft]
           ,[Class]
           ,[Shift]
           ,[OldRate]
           ,[NewRate])

     VALUES
           (@PRCo
           ,@Craft
           ,@Class
           ,@Shift
           ,@OldRate
           ,@NewRate)

END

GO
