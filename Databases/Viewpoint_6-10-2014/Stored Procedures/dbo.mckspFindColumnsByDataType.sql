SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[mckspFindColumnsByDataType]
(
	@VPDataType varchar(30)
)
as
SELECT
	fd.Description,so.name AS TableName, sc.name AS ColumnName,st.name AS ColumnType, tf.FormName
FROM
	sysobjects so JOIN
	syscolumns sc ON so.id=sc.id JOIN
	systypes st ON sc.usertype=st.usertype LEFT OUTER JOIN
	vDDTH fd ON so.name LIKE '%' + fd.TableName + '%'
	LEFT OUTER JOIN vDDTableForms tf ON SUBSTRING(fd.TableName,2,4) = tf.TableName
WHERE
	so.type='U'
AND	st.name=@VPDataType
ORDER BY
	so.name, sc.name, st.name
GO
