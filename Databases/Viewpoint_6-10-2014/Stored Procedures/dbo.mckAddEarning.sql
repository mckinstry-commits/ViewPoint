SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mahendar B
-- Create date: 4/1/2014
-- Description:	Add new Earning from Union Class Excel.
-- =============================================
CREATE PROCEDURE [dbo].[mckAddEarning] 
@PRCo as tinyint
,@Craft as bCraft 
,@Class as bClass 
,@EarnCode as bEDLCode
,@Factor as bRate
,@OldRate AS bUnitCost 
,@NewRate as bUnitCost

AS
BEGIN


INSERT INTO [Viewpoint].[dbo].[PRCF]
           ([PRCo]
           ,[Craft]
           ,[Class]
           ,[EarnCode]
           ,[Factor]
           ,[OldRate]
           ,[NewRate])

     VALUES
           (@PRCo
           ,@Craft
           ,@Class
           ,@EarnCode
           ,@Factor
           ,@OldRate
           ,@NewRate)
END

GO
