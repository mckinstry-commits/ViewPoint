SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* CREATED:	3/28/99
* MODIFIED:	AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
*
* Purpose:  used to generate a list of columns in a specific table 
			owned by user 

* returns 1 and error msg if failed
*
*************************************************************************/
CREATE PROCEDURE [dbo].[bspRPRPGetColumns]
(
  @Table char(30),
  @username varchar(30)
)
AS 
SET nocount ON
SELECT  FieldName = b.name + '.' + a.name,
        a.colid,
        a.[type],
        a.[length],
        c.name,
        a.usertype,
        c.[type]
FROM    syscolumns a
			JOIN sysobjects b ON a.id = b.id
			JOIN systypes c ON a.usertype = c.usertype
WHERE   b.[type] IN ( 'U', 'V', 'P' )
        AND c.[type] IN ( 38, 39, 47, 48, 52, 56, 58, 60, 61, 62, 109, 110, 111,
                        122 )
        AND b.name = @Table
        AND b.[uid] = USER_ID(@username)
ORDER BY a.colid

GO
GRANT EXECUTE ON  [dbo].[bspRPRPGetColumns] TO [public]
GO
