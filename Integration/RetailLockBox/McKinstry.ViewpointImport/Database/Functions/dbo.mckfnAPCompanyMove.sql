USE [Viewpoint]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckfnAPCompanyMove]') AND xtype IN (N'FN', N'IF', N'TF'))
	DROP FUNCTION [dbo].[mckfnAPCompanyMove]
GO

CREATE FUNCTION [dbo].[mckfnAPCompanyMove] ()

RETURNS TABLE

AS

RETURN 
(
	SELECT Header.APCo, Header.UIMth, Header.UISeq, Header.VendorGroup, Header.Vendor, Header.APRef, Header.Description, Header.Notes,
	Header.InvDate, Header.InvTotal, Header.UniqueAttchID, Header.udDestAPCo AS DestAPCo, Header.KeyID, Header.udFreightCost AS FreightCost,
	CAST((SELECT COUNT(*) FROM APUI i WITH (NOLOCK) WHERE i.UniqueAttchID = Header.UniqueAttchID) AS int) AS AttachmentCount,
	CAST(CASE WHEN EXISTS(SELECT 1 FROM APUL Detail WITH (NOLOCK) WHERE Detail.APCo=Header.APCo and Detail.UIMth=Header.UIMth
    		AND Detail.UISeq=Header.UISeq) THEN 1 ELSE 0 END AS bit) AS HasDetailLine
	FROM APUI Header
	WHERE Header.udDestAPCo > 0 AND (Header.APCo <> Header.udDestAPCo)
) 

GO