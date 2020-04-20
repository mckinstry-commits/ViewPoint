USE [Viewpoint]
GO

/****** Object:  View [dbo].[mckARCM_Project]    Script Date: 12/9/2014 2:09:33 PM ******/
DROP VIEW [dbo].[mvwARCM_Project]
GO

/****** Object:  View [dbo].[mvwARCM_Project]    Script Date: 12/9/2014 2:09:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[mvwARCM_Project]
AS
SELECT       b.Co, a.CustGroup, a.Customer, a.Name, a.SortName, 
             a.Status, a.Address, a.Address2, a.City, a.State, a.Zip 
FROM          dbo.ARCM a, dbo.udPIF b, HQCO c
WHERE		  b.Customer = a.Customer and
              b.Co = c.HQCo and
			  a.CustGroup = c.CustGroup



GO

GRANT SELECT ON [dbo].[mvwARCM_Project] to PUBLIC;
GO




