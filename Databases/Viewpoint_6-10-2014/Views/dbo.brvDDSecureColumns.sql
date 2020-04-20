SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvDDSecureColumns]
    as
    select Datatype=systypes.name,TableName=sysobjects.name,ColName=syscolumns.name
     from syscolumns 
     join sysobjects on syscolumns.id=sysobjects.id
     join systypes on syscolumns.usertype=systypes.usertype
    where sysobjects.type='U' 
    and systypes.name in ('bCMAcct','bJob','bEmployee','bCompany','bContract')

GO
GRANT SELECT ON  [dbo].[brvDDSecureColumns] TO [public]
GRANT INSERT ON  [dbo].[brvDDSecureColumns] TO [public]
GRANT DELETE ON  [dbo].[brvDDSecureColumns] TO [public]
GRANT UPDATE ON  [dbo].[brvDDSecureColumns] TO [public]
GRANT SELECT ON  [dbo].[brvDDSecureColumns] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvDDSecureColumns] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvDDSecureColumns] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvDDSecureColumns] TO [Viewpoint]
GO
