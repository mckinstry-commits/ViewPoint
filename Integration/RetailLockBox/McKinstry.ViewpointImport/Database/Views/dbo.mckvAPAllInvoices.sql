USE [Viewpoint]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'mvwAPAllInvoices')
DROP VIEW [dbo].[mvwAPAllInvoices]
GO

CREATE VIEW [dbo].[mvwAPAllInvoices] 

AS

SELECT Type='P', APCo=h.APCo, Mth=h.Mth, APTrans=h.APTrans, h.VendorGroup,
   	h.Vendor, h.APRef, h.InvDate, h.Description, h.DueDate, h.InvTotal, h.UniqueAttchID, h.KeyID
   FROM APTH h 

UNION ALL 

SELECT Type='U', APCo=i.APCo, Mth=i.UIMth, APTrans=i.UISeq, i.VendorGroup,
   	i.Vendor, i.APRef, i.InvDate, i.Description, i.DueDate, i.InvTotal, i.UniqueAttchID, i.KeyID
   FROM APUI i

GO