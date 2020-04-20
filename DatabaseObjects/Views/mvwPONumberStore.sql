USE [Viewpoint]
GO

/****** Object:  View [dbo].[mvwPONumberStore]    Script Date: 11/5/2014 8:52:19 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER VIEW [dbo].[mvwPONumberStore]
AS 
SELECT udMCKPONumber AS udMCKPONumber
FROM dbo.POHD WITH (HOLDLOCK)
UNION
SELECT MCKPONumber AS udMCKPONumber
FROM mckMCKPONumberStore WITH (HOLDLOCK)



GO


