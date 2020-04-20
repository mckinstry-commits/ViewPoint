SET QUOTED_IDENTIFIER OFF
GO

/****** Object:  Default dbo.dbCurrentDate    Script Date: 8/28/99 9:47:21 AM ******/
CREATE DEFAULT [dbo].[dbCurrentDate] AS CONVERT(smalldatetime,(CONVERT (varchar(8), getdate(), 1)))




