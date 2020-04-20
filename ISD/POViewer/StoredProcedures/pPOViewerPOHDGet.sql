if exists (select * from sysobjects where id = object_id(N'pPOViewerPOHDGet') and sysstat & 0xf = 4) drop procedure pPOViewerPOHDGet 
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


