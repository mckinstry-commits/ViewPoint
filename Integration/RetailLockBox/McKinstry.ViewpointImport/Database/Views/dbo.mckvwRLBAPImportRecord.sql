USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'mckvwRLBAPImportRecord')
DROP VIEW [dbo].[mckvwRLBAPImportRecord]
GO

CREATE VIEW [dbo].[mckvwRLBAPImportRecord] AS

SELECT Detail.RLBImportBatchID, Record.*
FROM
RLBAPImportRecord Record
JOIN  RLBAPImportDetail Detail ON
Detail.RLBAPImportDetailID = Record.RLBAPImportDetailID

GO