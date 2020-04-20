SET QUOTED_IDENTIFIER OFF
GO
/****** Object:  Default dbo.bdCurrentMonth    Script Date: 8/28/99 9:25:57 AM ******/
CREATE DEFAULT [dbo].[bdCurrentMonth] AS STUFF(CONVERT (varchar(8), getdate(), 1),4,2,'01')


