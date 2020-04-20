USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckfnAPCompanyMoveError]') AND xtype IN (N'FN', N'IF', N'TF'))
	DROP FUNCTION [dbo].[mckfnAPCompanyMoveError]
GO

CREATE FUNCTION [dbo].[mckfnAPCompanyMoveError] 
(
	@LogFileName varchar(200)
)

RETURNS TABLE

AS

RETURN 
(
	SELECT APMove.HeaderSuccess AS HeaderMoved, APMove.AttachSuccess AS AttachmentsMoved, APMove.AttachCopySuccess AS AttachmentsCopied, APMove.Co, 
	APMove.Mth, APMove.UISeq, APMove.Vendor, APMove.APRef, APMove.InvTotal, Note.ProcessNotes as Notes
	FROM APCompanyMove APMove
	JOIN RLBProcessNotes Note ON Note.RLBProcessNotesID = APMove.RLBProcessNotesID
	WHERE APMove.LogFileName = @LogFileName 
	AND ((ISNULL(APMove.HeaderSuccess, 0) = 0) OR (ISNULL(APMove.AttachSuccess, 0) = 0) OR (ISNULL(APMove.AttachCopySuccess, 0) = 0))
) 

GO